//
//  NSURLAdditions.h
//  TallVocabGame
//
//  Created by Cameron McCord on 11/26/13.
//  Copyright (c) 2013 Cameron McCord. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (Additions)

- (NSURL *)URLByAppendingQueryStringKey:(NSString *)queryStringKey value:(NSString *)queryStringValue;

@end
