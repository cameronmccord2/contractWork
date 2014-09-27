//
//  CallQueue.h
//  Item Mapper
//
//  Created by Cameron McCord on 8/23/13.
//  Copyright (c) 2013 McCord Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSURLConnectionWithExtras.h"

@protocol ShowAuthModalDelegateProtocol;

@interface CallQueue : NSObject

@property(nonatomic)BOOL alreadySent;
@property(nonatomic, weak)id<ShowAuthModalDelegateProtocol> delegate;
@property(nonatomic, weak)id authDelegate;
@property(nonatomic, strong)NSMutableURLRequest *request;
@property(nonatomic, copy)void (^success)(NSData *, void(^)());
@property(nonatomic, copy)void (^error)(NSData *, NSError *, void(^)());
@property(nonatomic, copy)void (^then)(NSData *, NSURLConnectionWithExtras *, NSProgress *);
@property(nonatomic)NSInteger type;

+(instancetype)queueItemWithRequest:(NSMutableURLRequest *)request delegate:(id)delegate authDelegate:(id<ShowAuthModalDelegateProtocol>)authDelegate requestType:(NSInteger)type success:(void (^)(NSData *, void(^)()))success error:(void (^)(NSData *, NSError *, void(^)()))error then:(void (^)(NSData *, NSURLConnectionWithExtras *, NSProgress *))then;

@end