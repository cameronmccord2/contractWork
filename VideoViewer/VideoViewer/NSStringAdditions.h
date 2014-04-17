//
//  NSStringAdditions.h
//  TallVocabGame
//
//  Created by Cameron McCord on 11/26/13.
//  Copyright (c) 2013 Cameron McCord. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Additions)

- (NSURL *)URLByAppendingQueryStringKey:(NSString *)queryStringKey value:(NSString *)queryStringValue;
- (NSString *)URLStringByAppendingQueryStringKey:(NSString *)queryStringKey value:(NSString *)queryStringValue;
- (CGFloat)widthWithFont:(UIFont *)font;
- (CGFloat)heightWithWidth:(CGFloat)width andFont:(UIFont *)font;
@end
