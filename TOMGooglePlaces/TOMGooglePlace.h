//
//  TOMGooglePlace.h
//  TOMGooglePlaces
//
//  Created by Tom Corwine on 5/7/15.
//

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>

typedef void (^TOMGooglePlaceResults)(NSArray *places, NSError *error);
typedef void (^TOMGooglePlaceDetailsResult)(NSString *streetAddress, NSString *city, NSString *state, NSString *postalCode, NSError *error);

@interface TOMGooglePlace : NSObject

+ (void)placesFromString:(NSString *)string location:(CLLocation *)location apiKey:(NSString *)apiKey completionBlock:(TOMGooglePlaceResults)completionBlock;

@property (nonatomic, strong, readonly) NSString *identifier;
@property (nonatomic, strong, readonly) NSString *addressDescription;
@property (nonatomic, strong, readonly) NSString *placeID;
@property (nonatomic, strong, readonly) NSString *reference;
@property (nonatomic, strong, readonly) NSArray *matchedSubstrings;
@property (nonatomic, strong, readonly) NSArray *terms;
@property (nonatomic, strong, readonly) NSArray *types;

@property (nonatomic, strong, readonly) NSString *streetAddress;

- (void)detailsWithAPIKey:(NSString *)apiKey completionBlock:(TOMGooglePlaceDetailsResult)completionBlock;

@end
