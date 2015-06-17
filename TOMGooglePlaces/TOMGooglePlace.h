//
//  TOMGooglePlace.h
//  TOMGooglePlaces
//
//  Created by Tom Corwine on 5/7/15.
//

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>

typedef NS_ENUM(short, TOMGooglePlaceError) {
    TOMGooglePlaceErrorNone,            // No error
    TOMGooglePlaceErrorUnknown,         // An error that's not documented
    TOMGooglePlaceErrorDenied,          // Denied by Google - perhaps API key is bad
    TOMGooglePlaceErrorExceedsQuota,    // Exceeded Google's Quota
    TOMGooglePlaceErrorRequestInvalid,  // Request missing parameters, probably blank string
    TOMGooglePlaceErrorNetworkError     // The network connection failed in some way
};

typedef void (^TOMGooglePlaceResults)(NSArray *places, TOMGooglePlaceError error);
typedef void (^TOMGooglePlaceDetailsResult)(NSString *establishmentName, NSString *streetAddress, NSString *city, NSString *state, NSString *postalCode, TOMGooglePlaceError error);

@interface TOMGooglePlace : NSObject

+ (void)placesFromString:(NSString *)string location:(CLLocation *)location apiKey:(NSString *)apiKey completionBlock:(TOMGooglePlaceResults)completionBlock;

@property (nonatomic, strong, readonly) NSString *identifier;
@property (nonatomic, strong, readonly) NSString *addressDescription;
@property (nonatomic, strong, readonly) NSString *placeID;
@property (nonatomic, strong, readonly) NSString *reference;
@property (nonatomic, strong, readonly) NSArray *matchedSubstrings;
@property (nonatomic, strong, readonly) NSArray *terms;
@property (nonatomic, strong, readonly) NSArray *types;

@property (nonatomic, strong, readonly) NSString *establishmentName;
@property (nonatomic, strong, readonly) NSString *fullAddress;
@property (nonatomic, strong, readonly) NSString *streetAddress;
@property (nonatomic, strong, readonly) NSString *municipality;

@property (nonatomic, readonly) BOOL isStreetAddress;
@property (nonatomic, readonly) BOOL isEstablishment;
@property (nonatomic, readonly) BOOL isRoute;
@property (nonatomic, readonly) BOOL isTrainStation;

@property (nonatomic, readonly) NSRange establishmentNameHighlightRange;
@property (nonatomic, readonly) NSRange streetAddressHighlightRange;

- (void)detailsWithAPIKey:(NSString *)apiKey completionBlock:(TOMGooglePlaceDetailsResult)completionBlock;

@end
