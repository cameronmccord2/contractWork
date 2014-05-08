//
//  CallQueue.h
//  Item Mapper
//
//  Created by Cameron McCord on 8/23/13.
//  Copyright (c) 2013 McCord Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSURLConnectionWithExtras.h"

@protocol DAOManagerDelegateProtocol;

@interface CallQueue : NSObject

@property(nonatomic)BOOL alreadySent;
@property(nonatomic, weak)id<DAOManagerDelegateProtocol> delegate;
@property(nonatomic, strong)NSMutableURLRequest *request;
//@property(nonatomic, strong)NSData *body;
@property(nonatomic, copy)void (^success)(NSData *, void(^)());
@property(nonatomic, copy)void (^error)(NSData *, NSError *, void(^)());
@property(nonatomic, copy)void (^then)(NSData *, NSURLConnectionWithExtras *, NSProgress *);
@property(nonatomic)NSInteger type;

+(instancetype)initWithRequest:(NSMutableURLRequest *)request authDelegate:(id<DAOManagerDelegateProtocol>)authDelegate requestType:(NSInteger)type success:(void (^)(NSData *, void(^)()))success error:(void (^)(NSData *, NSError *, void(^)()))error then:(void (^)(NSData *, NSURLConnectionWithExtras *, NSProgress *))then;

@end