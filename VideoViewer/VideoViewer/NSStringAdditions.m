//
//  NSStringAdditions.m
//  TallVocabGame
//
//  Created by Cameron McCord on 11/26/13.
//  Copyright (c) 2013 Cameron McCord. All rights reserved.
//

#import "NSStringAdditions.h"

@implementation NSString (Additions)

- (NSURL *)URLByAppendingQueryStringKey:(NSString *)queryStringKey value:(NSString *)queryStringValue {
    if (![queryStringKey length]) {
        return [NSURL URLWithString:self];
    }
    NSString *queryString = [NSString stringWithFormat:@"%@=%@", queryStringKey, queryStringValue];
    
    NSString *URLString = [[NSString alloc] initWithFormat:@"%@%@%@", self,
                           [self rangeOfString:@"?"].length > 0 ? @"&" : @"?", [queryString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *theURL = [NSURL URLWithString:URLString];
    return theURL;
}

- (NSString *)URLStringByAppendingQueryStringKey:(NSString *)queryStringKey value:(NSString *)queryStringValue {
    if (![queryStringKey length]) {
        return self;
    }
    
    NSString *queryString = [NSString stringWithFormat:@"%@=%@", queryStringKey, queryStringValue];
    
    return [NSString stringWithFormat:@"%@%@%@", self,
            [self rangeOfString:@"?"].length > 0 ? @"&" : @"?", [queryString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

@end
