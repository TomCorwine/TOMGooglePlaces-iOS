//
//  TOMGooglePlace.h
//  TOMGooglePlaces
//
//  Created by Tom Corwine on 5/7/15.
//

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>

typedef void (^TOMGooglePlaceResults)(NSArray *places, NSError *error);

@interface TOMGooglePlace : NSObject

+ (void)placesFromString:(NSString *)string coordinate:(CLLocationCoordinate2D)coordinate completionBlock:(TOMGooglePlaceResults)completionBlock;

@property (nonatomic, strong, readonly) NSString *identifier;
@property (nonatomic, strong, readonly) NSString *addressDescription;
@property (nonatomic, strong, readonly) NSString *placeID;
@property (nonatomic, strong, readonly) NSString *reference;
@property (nonatomic, strong, readonly) NSArray *matchedSubstrings;
@property (nonatomic, strong, readonly) NSArray *terms;
@property (nonatomic, strong, readonly) NSArray *types;

@end

/*
 {
     "description" : "Paris, France",
     "id" : "691b237b0322f28988f3ce03e321ff72a12167fd",
     "matched_substrings" : [
         {
             "length" : 5,
             "offset" : 0
         }
     ],
     "place_id" : "ChIJD7fiBh9u5kcRYJSMaMOCCwQ",
     "reference" : "CjQlAAAA_KB6EEceSTfkteSSF6U0pvumHCoLUboRcDlAH05N1pZJLmOQbYmboEi0SwXBSoI2EhAhj249tFDCVh4R-PXZkPK8GhTBmp_6_lWljaf1joVs1SH2ttB_tw",
     "terms" : [
         {
             "offset" : 0,
             "value" : "Paris"
         },
         {
             "offset" : 7,
             "value" : "France"
         }
     ],
     "types" : [
         "locality",
         "political",
         "geocode"
    ]
 },
*/
