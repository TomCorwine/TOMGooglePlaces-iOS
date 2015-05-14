//
//  TOMGooglePlaceTerm.h
//  TOMGooglePlaces
//
//  Created by Tom Corwine on 5/7/15.
//

#import <Foundation/Foundation.h>

@interface TOMGooglePlaceTerm : NSObject

@property (nonatomic, strong, readonly) NSNumber *offset;
@property (nonatomic, strong, readonly) NSString *value;

- (id)initWithDictionary:(NSDictionary *)dictionary;

@end
