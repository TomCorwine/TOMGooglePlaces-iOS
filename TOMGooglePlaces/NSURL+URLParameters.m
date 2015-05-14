//
//  NSURL+URLParameters.m
//  Pods
//
//  Created by Tom Corwine on 4/29/15.
//
//

#import "NSURL+URLParameters.h"

#import "NSString+URLEscaping.h"

@implementation NSURL (URLParameters)

- (NSURL *)urlParamters_URLWithQueryParameters:(NSDictionary *)parameters
{
    NSString *queryString = [[self class] urlParamters_StringFromQueryParameters:parameters];
    queryString = [@"?" stringByAppendingString:queryString];
    return [self URLByAppendingPathComponent:queryString];
}

+ (NSString *)urlParamters_StringFromQueryParameters:(NSDictionary *)parameters
{
    NSMutableArray *queryComponents = @[].mutableCopy;

    for (NSString *key in parameters)
    {
        NSString *value = parameters[key];
        NSString *escapedkey = [key URLEscaping_percentEscapedString];
        NSString *escapedValue = [value URLEscaping_percentEscapedString];
        
        NSArray *keyValueComponents = @[escapedkey, escapedValue];
        NSString *keyValueString = [keyValueComponents componentsJoinedByString:@"="];
        
        [queryComponents addObject:keyValueString];
    }
    
    return [queryComponents componentsJoinedByString:@"&"];
}

@end
