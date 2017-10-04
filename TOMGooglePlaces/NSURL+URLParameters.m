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
    NSString *urlString = [self.absoluteString stringByAppendingString:queryString];
    return [NSURL URLWithString:urlString];
}

- (NSDictionary *)urlParameters_DictionaryFromQueryParameters
{
    NSString *urlString = self.absoluteString;
    NSArray *components = [urlString componentsSeparatedByString:@"?"];

    if (components.count < 2) {
        return @{};
    }

    NSString *parametersString = components.lastObject;

    NSArray *parameters = [parametersString componentsSeparatedByString:@"&"];
    NSMutableDictionary *mutableDictionary = @{}.mutableCopy;

    for (NSString *string in parameters)
    {
        NSArray *keyValue = [string componentsSeparatedByString:@"="];

        if (keyValue.count != 2) {
            continue;
        }

        NSString *key = keyValue[0];
        NSString *value = keyValue[1];

        key = [key stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

        mutableDictionary[key] = value;
    }

    return mutableDictionary.copy;
}

+ (NSString *)urlParamters_StringFromQueryParameters:(NSDictionary *)parameters
{
    NSMutableArray *queryComponents = @[].mutableCopy;

    for (NSString *key in parameters)
    {
        id value = parameters[key];

        if ([value isKindOfClass:[NSArray class]])
        {
            NSString *arrayKey = [key stringByAppendingString:@"[]"];

            for (id item in value)
            {
                NSString *keyValueString = [self keyValueStringFromKey:arrayKey value:item];
                [queryComponents addObject:keyValueString];
            }
        }
        else
        {
            NSString *keyValueString = [self keyValueStringFromKey:key value:value];
            [queryComponents addObject:keyValueString];
        }
    }

    return [queryComponents componentsJoinedByString:@"&"];
}

#pragma mark - Helpers

+ (NSString *)keyValueStringFromKey:(NSString *)key value:(id)value
{
    NSString *escapedkey = [key URLEscaping_percentEscapedString];

    NSString *stringValue = [self stringFromValue:value];
    NSString *escapedValue = [stringValue URLEscaping_percentEscapedString];

    NSArray *keyValueComponents = @[escapedkey, escapedValue];
    NSString *keyValueString = [keyValueComponents componentsJoinedByString:@"="];

    return keyValueString;
}

+ (NSString *)stringFromValue:(id)value
{
    if ([value isKindOfClass:[NSString class]])
    {
        return value;
    }
    else if ([value isKindOfClass:[NSNumber class]])
    {
        /*
        static NSNumberFormatter *numberFormatter;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            numberFormatter = [[NSNumberFormatter alloc] init];
            numberFormatter.numberStyle = NSNumberFormatterNoStyle;
        });

        value = [numberFormatter stringFromNumber:value];
        return [value URLEscaping_percentEscapedString];
         */

        NSNumber *number = value;
        NSString *string = number.stringValue;

        return string;
    }
    else
    {
        NSAssert(NO, @"Parameter value must be a NSString or NSNumber.");
        return nil;
    }
}

@end
