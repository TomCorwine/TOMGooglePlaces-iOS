//
//  TOMGooglePlace.m
//  TOMGooglePlaces
//
//  Created by Tom Corwine on 5/7/15.
//

#import "TOMGooglePlace.h"

#import "TOMGooglePlaceTerm.h"

#import "NSURL+URLParameters.h"

typedef void (^NetworkCompletionBlock)(NSDictionary *results, NSError *error);

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

    NSMutableDictionary *parameters = @{
                                 @"input": string,
                                 @"key": (apiKey ?: kGoogleAPIKey),
                                 @"types": @"address",
                                 @"language": @"en"
                                 }.mutableCopy;

    if (location)
    {
        CLLocationCoordinate2D coordinate = location.coordinate;
        NSString *locationString = [NSString stringWithFormat:@"%f,%f", coordinate.latitude, coordinate.longitude];
        [parameters addEntriesFromDictionary:@{@"location": locationString, @"radius": @"500"}];
    }

    [self networkCallToURLString:@"https://maps.googleapis.com/maps/api/place/autocomplete/json" parameters:parameters completionBlock:^(NSDictionary *results, NSError *error) {

        if (error) {
            completionBlock(nil, error);
            return;
        }

        NSArray *predictions = results[@"predictions"];

        NSMutableArray *mutableArray = @[].mutableCopy;
        for (NSDictionary *dictionary in predictions)
        {
            TOMGooglePlace *place = [[TOMGooglePlace alloc] initWithDictionary:dictionary];
            [mutableArray addObject:place];
        }

        completionBlock([NSArray arrayWithArray:mutableArray], error);
    }];
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

- (NSString *)streetAddress
{
    NSMutableArray *mutableArray = @[].mutableCopy;
    for (TOMGooglePlaceTerm *term in self.terms)
    {
        // I'm just guessing the anything that starts before 10 characters
        // should be part of the street address, and everthing after it is
        // the city, state, etc.
        // Not very robust
        if (term.offset > 10) {
            break;
        }

        [mutableArray addObject:term.value];
    }

    return [mutableArray componentsJoinedByString:@" "];
}

#pragma mark - Details

- (void)detailsWithAPIKey:(NSString *)apiKey completionBlock:(TOMGooglePlaceDetailsResult)completionBlock
{
    NSAssert(completionBlock, @"What'd think you're doing calling this without a completion block?");

    NSDictionary *parameters = @{
                                 @"placeid": self.placeID,
                                 @"key": (apiKey ?: kGoogleAPIKey)
                                 };

    [[self class] networkCallToURLString:@"https://maps.googleapis.com/maps/api/place/details/json" parameters:parameters completionBlock:^(NSDictionary *results, NSError *error) {

        if (error) {
            completionBlock(nil, nil, nil, nil, error);
            return;
        }

        NSArray *array = results[@"result"][@"address_components"];

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

        NSString *streetAddress = [NSString stringWithFormat:@"%@ %@", streetNumber, route];
        completionBlock(streetAddress, city, state, postalCode, nil);
    }];
}

#pragma mark - Helpers

+ (void)networkCallToURLString:(NSString *)urlString parameters:(NSDictionary *)parameters completionBlock:(NetworkCompletionBlock)completionBlock
{
    NSURL *url = [NSURL URLWithString:urlString];
    url = [url urlParamters_URLWithQueryParameters:parameters];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

        NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

        if (200 != httpResponse.statusCode)
        {
            completionBlock(nil, connectionError);
            return;
        }

        NSError *error;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (nil == dictionary || error)
        {
            completionBlock(nil, error);
            return;
        }

        NSString *status = dictionary[@"status"];

        if (NO == [status isEqualToString:@"OK"])
        {
            completionBlock(nil, connectionError);
            return;
        }

        completionBlock(dictionary, nil);
    }];
}

@end
