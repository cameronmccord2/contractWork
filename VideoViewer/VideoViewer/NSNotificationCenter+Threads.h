//
//  NSNotificationCenter+Threads.h
//  SLE
//
//  Created by Cameron McCord on 8/20/14.
//  Copyright (c) 2014 Missionary Training Center. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSNotificationCenter (Threads)

-(void)postNotificationOnMainThread:(NSNotification *)notification;
-(void)postNotificationNameOnMainThread:(NSString *)name object:(id)object;
-(void)postNotificationNameOnMainThread:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo;

@end
