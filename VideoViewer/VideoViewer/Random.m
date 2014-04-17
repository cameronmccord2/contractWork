//
//  Random.m
//  TallVocabGame
//
//  Created by Cameron McCord on 11/19/13.
//  Copyright (c) 2013 Cameron McCord. All rights reserved.
//

#import "Random.h"

@implementation NSArray (Random)

-(id)randomObject {
    NSUInteger myCount = [self count];
    if (myCount)
        return [self objectAtIndex:arc4random_uniform(myCount)];
    else
        return nil;
}

@end
