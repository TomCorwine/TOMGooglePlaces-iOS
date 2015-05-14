//
//  NSString+URLEscaping.m
//  Pods
//
//  Created by Tom Corwine on 4/29/15.
//
//

#import "NSString+URLEscaping.h"

@implementation NSString (URLEscaping)

- (NSString *)URLEscaping_percentEscapedString
{
    static NSString *const charactersToEscape = @"!#$&'()*+,/:;=?@";
    CFStringRef stringRef = CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)self, NULL, (__bridge CFStringRef)charactersToEscape, kCFStringEncodingUTF8);
    return (NSString *)CFBridgingRelease(stringRef);
}

@end
