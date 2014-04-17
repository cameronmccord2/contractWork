//
//  CallQueue.m
//  Item Mapper
//
//  Created by Cameron McCord on 8/23/13.
//  Copyright (c) 2013 McCord Inc. All rights reserved.
//

#import "CallQueue.h"
#import "DAOManager.h"

@implementation CallQueue

+(instancetype)initWithRequest:(NSMutableURLRequest *)request authDelegate:(id<DAOManagerDelegateProtocol>)authDelegate requestType:(NSInteger)type success:(void (^)(NSData *, void(^)()))success error:(void (^)(NSData *, NSError *, void(^)()))error then:(void (^)(NSData *, NSURLConnectionWithExtras *, NSProgress *))then{
    CallQueue *item = [[CallQueue alloc] init];
    item.request = request;
    item.delegate = authDelegate;
    item.success = success;
    item.error = error;
    item.then = then;
    item.alreadySent = NO;
    item.type = type;
    return item;
}
@end
