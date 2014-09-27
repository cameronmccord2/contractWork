//
//  NSDictionary+SafeJson.m
//  SLE
//
//  Created by Cameron McCord on 6/19/14.
//  Copyright (c) 2014 Missionary Training Center. All rights reserved.
//

#import "NSDictionary+SafeJson.h"

@implementation NSDictionary (SafeJson)

-(NSDictionary *)removeNullValues{
	NSMutableDictionary *mutDictionary = [self mutableCopy];
	NSMutableArray *keysToDelete = [NSMutableArray array];
	[mutDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		if (obj == [NSNull null]) {
			[keysToDelete addObject:key];
		}
	}];
    [mutDictionary removeObjectsForKeys:keysToDelete];
    return [mutDictionary copy];
}

@end
