//
//  TOMGooglePlaceTerm.m
//  TOMGooglePlaces
//
//  Created by Tom Corwine on 5/7/15.
//

#import "TOMGooglePlaceTerm.h"

@interface TOMGooglePlaceTerm ()

@property (nonatomic, strong) NSNumber *offset;
@property (nonatomic, strong) NSString *value;

@end

@implementation TOMGooglePlaceTerm

#pragma mark - Factory

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    
    self.offset = dictionary[@"offset"];
    self.value = dictionary[@"value"];
    
    return self;
}

@end
