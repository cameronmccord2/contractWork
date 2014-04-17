//
//  NSURLConnectionWithExtras.m
//  SalesmanBuddyiOS
//
//  Created by Cameron McCord on 11/29/13.
//  Copyright (c) 2013 McCord Inc. All rights reserved.
//

#import "NSURLConnectionWithExtras.h"

@implementation NSURLConnectionWithExtras

+(instancetype)connectionWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately uniqueTag:(NSDecimalNumber *)uniqueTag finalDelegate:(id)finalDelegate success:(void (^)(NSData *, void (^)()))success error:(void (^)(NSData *, NSError *, void (^)()))error then:(void (^)(NSData *, NSURLConnectionWithExtras *, NSProgress *))then{
    return [[NSURLConnectionWithExtras alloc] initWithRequest:request delegate:delegate startImmediately:startImmediately uniqueTag:uniqueTag finalDelegate:finalDelegate success:success error:error then:then];
}

-(instancetype)initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately uniqueTag:(NSDecimalNumber *)uniqueTag finalDelegate:(id)finalDelegate success:(void (^)(NSData *, void (^)()))success error:(void (^)(NSData *, NSError *, void (^)()))error then:(void (^)(NSData *, NSURLConnectionWithExtras *, NSProgress *))then{
    self = [super initWithRequest:request delegate:delegate startImmediately:startImmediately];
    if (self != nil) {
        self.uniqueTag = uniqueTag;
        self.finalDelegate = finalDelegate;
        self.success = success;
        self.error = error;
        self.then = then;
        self.nsProgress = [[NSProgress alloc] init];
        self.nsProgress.completedUnitCount = 0;
        self.nsProgress.totalUnitCount = 0;
    }
    return self;
}

-(void)setStatusCodeForNow:(NSInteger)statusCode{
    self.statusCode = statusCode;
    self.statusCodeDate = [NSDate date];
}

@end
