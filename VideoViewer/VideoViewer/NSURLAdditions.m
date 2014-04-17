//
//  NSURLAdditions.m
//  TallVocabGame
//
//  Created by Cameron McCord on 11/26/13.
//  Copyright (c) 2013 Cameron McCord. All rights reserved.
//

#import "NSURLAdditions.h"

@implementation NSURL (Additions)

- (NSURL *)URLByAppendingQueryStringKey:(NSString *)queryStringKey value:(NSString *)queryStringValue {
    if (![queryStringKey length]) {
        return self;
    }
    
    NSString *queryString = [NSString stringWithFormat:@"%@=%@", queryStringKey, queryStringValue];
    
    NSString *URLString = [[NSString alloc] initWithFormat:@"%@%@%@", [self absoluteString],
                           [self query] ? @"&" : @"?", [queryString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *theURL = [NSURL URLWithString:URLString];
    return theURL;
}

@end
