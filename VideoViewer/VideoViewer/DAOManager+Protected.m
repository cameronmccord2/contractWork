//
//  DAOManager+Protected.m
//  SLE
//
//  Created by Cameron McCord on 8/30/14.
//  Copyright (c) 2014 Missionary Training Center. All rights reserved.
//

#import "DAOManager+Protected.h"

@implementation DAOManager (Protected)

#pragma mark - Generic Functions

-(void)makeRequestWithVerb:(NSString *)verb
					forUrl:(NSString *)url
			bodyDictionary:(NSDictionary *)bodyDictionary
				  bodyData:(NSData *)bodyData
			   contentType:(NSString *)contentType
			   requestType:(NSInteger)type
				   success:(void (^)(NSData *, void(^)()))success
					 error:(void (^)(NSData *, NSError *, void(^)()))error
					  then:(void (^)(NSData *, NSURLConnectionWithExtras *, NSProgress *))then {
	
	DLog(@"making %@ request to url:%@, without auth", verb, url);
    NSError *e = nil;
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [req setHTTPMethod:verb];
	[req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [req setTimeoutInterval:360];
    [self addBodyDataToRequest:req bodyDictionary:bodyDictionary bodyData:bodyData contentType:contentType error:&e];
	
    if (e != nil) {
        NSLog(@"make %@ reuqest error: %@", verb, e.localizedDescription);
    }else{
        [callQueue addObject:[CallQueue queueItemWithRequest:req delegate:nil authDelegate:nil requestType:type success:success error:error then:then]];
		[self doFetchQueue];
	}
}

-(void)addBodyDataToRequest:(NSMutableURLRequest *)req bodyDictionary:(NSDictionary *)bodyDictionary bodyData:(NSData *)bodyData contentType:(NSString *)contentType error:(NSError *__autoreleasing *)e{
    
    if(bodyData != nil && bodyDictionary != nil){
        DLog(@"Warning! You defined body data and body dictionary. The dictionary-->data will replace the data you specified");
    }
	
    if(bodyDictionary)
        bodyData = [NSJSONSerialization dataWithJSONObject:bodyDictionary options:0 error:e];
    
    if(bodyData){
        [req setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[bodyData length]] forHTTPHeaderField:@"Content-Length"];
        if (contentType == nil) {
			DLog(@"content type was nil, setting to default of application/json");
            contentType = @"application/json";
        }else{
			[req setValue:contentType forHTTPHeaderField:@"Content-Type"];
		}
        [req setHTTPBody:bodyData];
    }
}

-(void)genericGetFunctionForDelegate:(id)delegate forUrl:(NSString *)url requestType:(NSInteger)type success:(void (^)(NSData *, void(^)()))success error:(void (^)(NSData *, NSError *, void(^)()))error then:(void (^)(NSData *, NSURLConnectionWithExtras *, NSProgress *))then {
	
//    if([url rangeOfString:@"TALL/audio/media/"].location == NSNotFound)
        DLog(@"making GET request to url:%@, by: %@", url, NSStringFromClass([delegate class]));
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	[req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
//    if (type == IncreasedTimeoutType) {
        [req setTimeoutInterval:360];
//    }
	[callQueue addObject:[CallQueue queueItemWithRequest:req delegate:nil authDelegate:nil requestType:type success:success error:error then:then]];
	[self doFetchQueue];
}



-(void)genericListGetForDelegate:(id)delegate url:(NSString *)url selector:(SEL)selector parseClass:(Class)parseClass requestType:(NSInteger)type{
    [self genericGetFunctionForDelegate:delegate forUrl:url requestType:type success:[self successTemplateForDelegate:delegate selectorOnSuccess:selector parseClass:parseClass resultIsArray:YES] error:nil then:nil];
}



-(void)genericObjectGetForDelegate:(id)delegate url:(NSString *)url selector:(SEL)selector parseClass:(Class)parseClass requestType:(NSInteger)type{
    [self genericGetFunctionForDelegate:delegate forUrl:url requestType:type success:[self successTemplateForDelegate:delegate selectorOnSuccess:selector parseClass:parseClass resultIsArray:NO] error:nil then:nil];
}



@end
