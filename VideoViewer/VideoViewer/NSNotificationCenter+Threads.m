//
//  NSNotificationCenter+Threads.m
//  SLE
//
//  Created by Cameron McCord on 8/20/14.
//  Copyright (c) 2014 Missionary Training Center. All rights reserved.
//

#import "NSNotificationCenter+Threads.h"

@implementation NSNotificationCenter (Threads)

-(void)postNotificationOnMainThread:(NSNotification *)notification{
    [self performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:NO];
}

-(void)postNotificationNameOnMainThread:(NSString *)name object:(id)object{
    [self postNotificationNameOnMainThread:name object:object userInfo:nil];
}

-(void)postNotificationNameOnMainThread:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self postNotificationName:name object:object userInfo:userInfo];
    });
}

@end
