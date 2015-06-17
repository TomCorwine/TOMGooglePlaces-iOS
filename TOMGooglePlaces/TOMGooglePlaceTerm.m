//
//  TOMGooglePlaceTerm.m
//  TOMGooglePlaces
//
//  Created by Tom Corwine on 5/7/15.
//

#import "TOMGooglePlaceTerm.h"

@interface TOMGooglePlaceTerm ()

@property (nonatomic, strong) NSNumber *offsetN;
@property (nonatomic, strong) NSString *value;

@end

@implementation TOMGooglePlaceTerm

#pragma mark - Factory

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    
    self.offsetN = dictionary[@"offset"];
    self.value = dictionary[@"value"];
    
    return self;
}

#pragma mark - Accessors

- (NSUInteger)offset
{
    return self.offsetN.unsignedIntegerValue;
}

#pragma mark - NSObject Overrides

- (NSString *)description
{
    return self.value;
}

@end
