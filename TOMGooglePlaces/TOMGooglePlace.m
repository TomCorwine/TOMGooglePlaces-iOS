//
//  TOMGooglePlace.m
//  TOMGooglePlaces
//
//  Created by Tom Corwine on 5/7/15.
//

#import "TOMGooglePlace.h"

#import "TOMGooglePlaceTerm.h"

#import "NSURL+URLParameters.h"

typedef void (^NetworkCompletionBlock)(NSDictionary *results, TOMGooglePlaceError error);

const NSString *kGoogleAPIKey = @"";

@interface TOMGooglePlace ()

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *addressDescription;
@property (nonatomic, strong) NSString *placeID;
@property (nonatomic, strong) NSString *reference;
@property (nonatomic, strong) NSArray *matchedSubstrings;
@property (nonatomic, strong) NSArray *terms;
@property (nonatomic, strong) NSArray *types;

@end

@implementation TOMGooglePlace

#pragma mark - Fetching

+ (void)placesFromString:(NSString *)string location:(CLLocation *)location apiKey:(NSString *)apiKey completionBlock:(TOMGooglePlaceResults)completionBlock
{
    NSAssert(completionBlock, @"What'd think you're doing calling this without a completion block?");
    NSAssert(string, @"Ummm, the string is nil.");

    NSDictionary *cachedResults = [self cache][string];
    if (cachedResults)
    {
        [self processResults:cachedResults completionBlock:completionBlock];
        return;
    }

    NSMutableDictionary *parameters = @{
                                 @"input": string,
                                 @"key": (apiKey ?: kGoogleAPIKey),
                                 @"language": @"en",
                                 }.mutableCopy;

    if (location)
    {
        CLLocationCoordinate2D coordinate = location.coordinate;
        NSString *locationString = [NSString stringWithFormat:@"%f,%f", coordinate.latitude, coordinate.longitude];
        [parameters addEntriesFromDictionary:@{@"location": locationString, @"radius": @"500"}];
    }

    [self networkCallToURLString:@"https://maps.googleapis.com/maps/api/place/autocomplete/json" parameters:parameters completionBlock:^(NSDictionary *results, TOMGooglePlaceError error) {

        if (error) {
            completionBlock(nil, error);
            return;
        }
#ifndef DEBUG // Caching makes it harder to debug queries
        [self cache][string] = results;
#endif
        [self processResults:results completionBlock:completionBlock];
    }];
}

+ (void)processResults:(NSDictionary *)results completionBlock:(TOMGooglePlaceResults)completionBlock
{
    NSArray *predictions = results[@"predictions"];

    NSMutableArray *mutableArray = @[].mutableCopy;
    for (NSDictionary *dictionary in predictions)
    {
        TOMGooglePlace *place = [[TOMGooglePlace alloc] initWithDictionary:dictionary];

        // This is to filter out transit stations
        if (place.isEstablishment || place.isStreetAddress || place.isRoute) {
            [mutableArray addObject:place];
        }
    }

    completionBlock([NSArray arrayWithArray:mutableArray], nil);
}

#pragma mark - Caching

+ (NSMutableDictionary *)cache
{
    static NSMutableDictionary *mutableDictionary;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mutableDictionary = @{}.mutableCopy;
    });
    return mutableDictionary;
}

#pragma mark - Factory

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];

    self.identifier = dictionary[@"id"];
    self.addressDescription = dictionary[@"description"];
    self.placeID = dictionary[@"place_id"];
    self.reference = dictionary[@"reference"];

    self.types = dictionary[@"types"];

    NSMutableArray *mutableArray = @[].mutableCopy;
    for (NSDictionary *termDictionary in dictionary[@"terms"])
    {
        TOMGooglePlaceTerm *term = [[TOMGooglePlaceTerm alloc] initWithDictionary:termDictionary];
        [mutableArray addObject:term];
    }
    self.terms = [NSArray arrayWithArray:mutableArray];

    [mutableArray removeAllObjects];
    for (NSDictionary *substringDictionary in dictionary[@"matched_substrings"])
    {
        NSNumber *offset = substringDictionary[@"offset"];
        NSNumber *length = substringDictionary[@"length"];
        NSRange range = NSMakeRange(offset.unsignedIntegerValue, length.unsignedIntegerValue);
        NSValue *rangeValue = [NSValue valueWithRange:range];
        [mutableArray addObject:rangeValue];
    }
    self.matchedSubstrings = [NSArray arrayWithArray:mutableArray];

    return self;
}

#pragma mark - Accessors

- (NSString *)establishmentName
{
    if (0 == self.terms.count) {
        return nil;
    }

    // It seems that if there's only 1 type and it's "establishment", then
    // the first term is the name of an establishment.
    if (1 == self.types.count && self.isEstablishment)
    {
        TOMGooglePlaceTerm *term = self.terms[0];
        return term.value;
    }
    else
    {
        return nil;
    }
}

- (NSString *)streetAddress
{
    if (self.terms.count < 2) {
        return nil;
    }

    if (self.isStreetAddress)
    {
        TOMGooglePlaceTerm *term1 = self.terms[0];
        TOMGooglePlaceTerm *term2 = self.terms[1];
        return [@[term1.value, term2.value] componentsJoinedByString:@" "];
    }
    else if (self.isEstablishment)
    {
        TOMGooglePlaceTerm *term = self.terms[1];
        return term.value;
    }
    else if (self.isRoute)
    {
        TOMGooglePlaceTerm *term = self.terms[0];
        return term.value;
    }
    else
    {
        return nil;
    }
}

- (BOOL)isStreetAddress
{
    return [self.types containsObject:@"street_address"];
}

- (BOOL)isEstablishment
{
    return ([self.types containsObject:@"establishment"] && 1 == self.types.count);
}

- (BOOL)isRoute
{
    return [self.types containsObject:@"route"];
}

- (BOOL)isTrainStation
{
    return (
            [self.types containsObject:@"subway_station"]
            || [self.types containsObject:@"train_station"]
            || [self.types containsObject:@"transit_station"]
            );
}

/*
- (NSRange)establishmentNameHighlightRange
{
    return NSMakeRange(0, 0);
}

- (NSRange)streetAddressHighlightRange
{
    return NSMakeRange(0, 0);
}
*/

#pragma mark - Details

- (void)detailsWithAPIKey:(NSString *)apiKey completionBlock:(TOMGooglePlaceDetailsResult)completionBlock
{
    NSAssert(completionBlock, @"What'd think you're doing calling this without a completion block?");

    NSDictionary *parameters = @{
                                 @"placeid": self.placeID,
                                 @"key": (apiKey ?: kGoogleAPIKey)
                                 };

    [[self class] networkCallToURLString:@"https://maps.googleapis.com/maps/api/place/details/json" parameters:parameters completionBlock:^(NSDictionary *results, TOMGooglePlaceError error) {

        if (error) {
            completionBlock(nil, nil, nil, nil, nil, error);
            return;
        }

        NSDictionary *result = results[@"result"];
        NSString *name = result[@"name"];
        NSArray *array = result[@"address_components"];

        NSString *streetNumber;
        NSString *route;
        NSString *city;
        NSString *state;
        NSString *postalCode;

        for (NSDictionary *item in array)
        {
            NSArray *types = item[@"types"];

            if ([types containsObject:@"street_number"]) {
                streetNumber = item[@"short_name"];
            }
            else if ([types containsObject:@"route"]) {
                route = item[@"short_name"];
            }
            else if ([types containsObject:@"locality"]) {
                city = item[@"short_name"];
            }
            else if ([types containsObject:@"administrative_area_level_1"]) {
                state = item[@"short_name"];
            }
            else if ([types containsObject:@"postal_code"]) {
                postalCode = item[@"short_name"];
            }
        }

        NSString *streetAddress;
        if (streetNumber && route) {
            streetAddress = [NSString stringWithFormat:@"%@ %@", streetNumber, route];
        }
        completionBlock(name, streetAddress, city, state, postalCode, nil);
    }];
}

#pragma mark - Helpers

+ (void)networkCallToURLString:(NSString *)urlString parameters:(NSDictionary *)parameters completionBlock:(NetworkCompletionBlock)completionBlock
{
    NSURL *url = [NSURL URLWithString:urlString];
    url = [url urlParamters_URLWithQueryParameters:parameters];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

        //NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

        if (200 != httpResponse.statusCode)
        {
            completionBlock(nil, TOMGooglePlaceErrorNetworkError);
            return;
        }

        NSError *error;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (nil == dictionary || error)
        {
            completionBlock(nil, TOMGooglePlaceErrorNetworkError);
            return;
        }

        NSString *status = dictionary[@"status"];

        if ([status isEqualToString:@"OK"] || [status isEqualToString:@"ZERO_RESULTS"])
        {
            completionBlock(dictionary, TOMGooglePlaceErrorNone);
        }
        else
        {
            TOMGooglePlaceError errorCode = TOMGooglePlaceErrorUnknown;

            if ([status isEqualToString:@"OVER_QUERY_LIMIT"]) {
                errorCode = TOMGooglePlaceErrorExceedsQuota;
            } else if ([status isEqualToString:@"REQUEST_DENIED"]) {
                errorCode = TOMGooglePlaceErrorDenied;
            } else if ([status isEqualToString:@"INVALID_REQUEST"]) {
                errorCode = TOMGooglePlaceErrorRequestInvalid;
            }

            completionBlock(nil, errorCode);
        }
    }];
}

@end
