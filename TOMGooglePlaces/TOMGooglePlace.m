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

@property (nonatomic, readonly) NSRange highlightRange;

@end

const NSUInteger kNumberOfMunicipalityItems = 3; // city, state, country

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

        // This is to filter out nonsense stuff
        if ((place.isEstablishment || place.isStreetAddress || place.isRoute)
            && place.terms.count > 3) {
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
    if (NO == self.isEstablishment || self.terms.count < 1) {
        return nil;
    }

    // The first term is the name of an establishment.
    TOMGooglePlaceTerm *term = self.terms[0];
    return term.value;
}

- (NSString *)fullAddress
{
    NSString *streetAddress = self.streetAddress;
    NSString *municipality = self.municipality;

    if (streetAddress && municipality) {
        return [@[streetAddress, municipality] componentsJoinedByString:@"\n"];
    } else if (municipality) {
        return municipality;
    } else if (streetAddress) {
        return streetAddress;
    } else {
        return nil;
    }
}

- (NSString *)streetAddress
{
    NSArray *terms = self.terms;

    // if establishment, remove first term which seems to always be the establishment name
    NSInteger index = (self.isEstablishment ? 1 : 0);
    NSInteger length = terms.count - kNumberOfMunicipalityItems - index;

    if (length < 1) {
        return nil;
    }

    NSRange range = NSMakeRange(index, length);
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
    NSArray *components = [terms objectsAtIndexes:indexSet];

    return [components componentsJoinedByString:@" "];
}

- (NSString *)municipality
{
    NSArray *terms = self.terms;

    // If there's not at least three items, then I don't know what's going on.
    if (terms.count < kNumberOfMunicipalityItems) {
        return nil;
    }

    NSInteger index = terms.count - kNumberOfMunicipalityItems;
    NSRange range = NSMakeRange(index, kNumberOfMunicipalityItems);

    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
    NSArray *components = [terms objectsAtIndexes:indexSet];

    return [components componentsJoinedByString:@", "];
}

- (BOOL)isStreetAddress
{
    return [self.types containsObject:@"street_address"];
}

- (BOOL)isEstablishment
{
    // It seems that if there's only 1 type and it's "establishment", then
    // it's an establishment that's not a train station or something stupid like that
    return (1 == self.types.count && [self.types containsObject:@"establishment"]);
}

- (BOOL)isRoute
{
    return [self.types containsObject:@"route"];
}

- (BOOL)isTrainStation
{
    return (
            [self.types containsObject:@"transit_station"]
            || [self.types containsObject:@"train_station"]
            || [self.types containsObject:@"subway_station"]
            );
}

- (NSRange)establishmentNameHighlightRange
{
    NSUInteger establishmentNameLength = self.establishmentName.length;
    NSRange range = self.highlightRange;

    return (range.location + range.length <= establishmentNameLength ? range : NSMakeRange(0, 0));
}

- (NSRange)streetAddressHighlightRange
{
    NSRange range = self.highlightRange;

    if (self.establishmentNameHighlightRange.length) {
        // If the establishment name is being highlighted, then the address highlight range is 0, 0
        return NSMakeRange(0, 0);
    }

    return (range.location + range.length <= self.streetAddress.length ? range : NSMakeRange(0, 0));
}

#pragma mark - Private Accessors

- (NSRange)highlightRange
{
    NSArray *matchedSubstrings = self.matchedSubstrings;
    
    if (matchedSubstrings.count < 1) {
        return NSMakeRange(0, 0);
    }
    
    NSValue *rangeValue = matchedSubstrings[0];
    return rangeValue.rangeValue;
}

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
#if DEBUG
        NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
#endif
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
