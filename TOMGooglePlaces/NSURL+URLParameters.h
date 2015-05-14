//
//  NSURL+URLParameters.h
//  Pods
//
//  Created by Tom Corwine on 4/29/15.
//
//

#import <Foundation/Foundation.h>

@interface NSURL (URLParameters)

- (NSURL *)urlParamters_URLWithQueryParameters:(NSDictionary *)parameters;
+ (NSString *)urlParamters_StringFromQueryParameters:(NSDictionary *)parameters;

@end
