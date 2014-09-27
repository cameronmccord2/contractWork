//
//  NSArray+Random.m
//  SLE
//
//  Created by Cameron McCord on 8/9/14.
//  Copyright (c) 2014 Missionary Training Center. All rights reserved.
//

#import "NSArray+Random.h"

static inline int randomInt(int low, int high)
{
    return (arc4random() % (high-low+1)) + low;
}

@implementation NSArray (Random)

-(id)randomObject {
    NSUInteger myCount = [self count];
    if (myCount)
        return [self objectAtIndex:arc4random_uniform((uint)myCount)];
    else
        return nil;
}

- (NSArray *)randomize {
	
    NSMutableArray *randomised = [NSMutableArray arrayWithCapacity:[self count]];
	
    for (id object in self) {
        NSUInteger index = randomInt(0, (int)[randomised count]);
        [randomised insertObject:object atIndex:index];
    }
    return randomised;
}

@end
