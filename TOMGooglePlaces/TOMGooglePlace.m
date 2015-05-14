//
//  TOMGooglePlace.m
//  TOMGooglePlaces
//
//  Created by Tom Corwine on 5/7/15.
//

#import "TOMGooglePlace.h"

#import "TOMGooglePlaceTerm.h"

#import "NSURL+URLParameters.h"

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

+ (void)placesFromString:(NSString *)string location:(CLLocation *)location completionBlock:(TOMGooglePlaceResults)completionBlock
{
    NSAssert(completionBlock, @"What'd think you're doing calling this without a completion block?");
    NSAssert(string, @"Ummm, the string is nil.");

    NSMutableDictionary *parameters = @{
                                 @"input": string,
                                 @"key": kGoogleAPIKey,
                                 @"types": @"address",
                                 @"language": @"en"
                                 }.mutableCopy;

    if (location)
    {
        CLLocationCoordinate2D coordinate = location.coordinate;
        NSString *locationString = [NSString stringWithFormat:@"%f,%f", coordinate.latitude, coordinate.longitude];
        [parameters addEntriesFromDictionary:@{@"location": locationString, @"radius": @"500"}];
    }

    NSURL *url = [NSURL URLWithString:@"https://maps.googleapis.com/maps/api/place/autocomplete/json"];
    url = [url urlParamters_URLWithQueryParameters:parameters];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

        if (200 != httpResponse.statusCode)
        {
            completionBlock(nil, connectionError);
            return;
        }

        NSError *error;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (nil == json || error)
        {
            completionBlock(nil, error);
            return;
        }

        NSString *status = json[@"status"];
        NSArray *predictions = json[@"predictions"];

        if (NO == [status isEqualToString:@"OK"])
        {
            completionBlock(nil, connectionError);
            return;
        }

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

@end
