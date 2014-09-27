//
//  DAOManager+Protected.h
//  SLE
//
//  Created by Cameron McCord on 8/30/14.
//  Copyright (c) 2014 Missionary Training Center. All rights reserved.
//

#import "DAOManager.h"

@interface DAOManager (Protected)

-(void)addBodyDataToRequest:(NSMutableURLRequest *)req bodyDictionary:(NSDictionary *)bodyDictionary bodyData:(NSData *)bodyData contentType:(NSString *)contentType error:(NSError *__autoreleasing *)e;

/// Make an NSURLRequest with any verb. All connection handling is behind the scenes.
/// @param verb Rest verb for the request: GET, PUT, POST, DELETE, etc.
/// @param url The full url for the request including the http or https in NSString format.
/// @param bodyDictionary The dictionary to be sent. Will be converted into NSData. This is for STRUCTURED data only such as JSON. Can be nil.
/// @param bodyData The data to be sent in the body. Can be nil.
/// @param contentType The content type of the body. 'application/json' or 'image/jpeg' or something else.
/// @param success A block function that is called when the connection successfully completes. Can be nil.
/// @param error A block function that is called when the connection errors. This function is called when connection:didFailWithError: is called by ios. Can be nil.
/// @param then A block function that is called when the connection is created(data will be nil), when any response is recieved(status code gets set) or when didSendBodyData:, and when the connection closes in a non-error state. Can be nil.
-(void)makeRequestWithVerb:(NSString *)verb
					forUrl:(NSString *)url
			bodyDictionary:(NSDictionary *)bodyDictionary
				  bodyData:(NSData *)bodyData
			   contentType:(NSString *)contentType
			   requestType:(NSInteger)type
				   success:(void (^)(NSData *, void(^)()))success
					 error:(void (^)(NSData *, NSError *, void(^)()))error
					  then:(void (^)(NSData *, NSURLConnectionWithExtras *, NSProgress *))then;

#pragma mark Generic Get
/// Generic GET function for DAOManager. All connection handling is behind the scenes.
/// @param delegate Source timeline entity ID
/// @param destId Destination timeline entity ID
/// @param name Message name
/// @return A newly created message instance
-(void)genericGetFunctionForDelegate:(id)delegate forUrl:(NSString *)url requestType:(NSInteger)type success:(void (^)(NSData *, void(^)()))success error:(void (^)(NSData *, NSError *, void(^)()))error then:(void (^)(NSData *, NSURLConnectionWithExtras *, NSProgress *))then;

#pragma mark List Get
-(void)genericListGetForDelegate:(id)delegate url:(NSString *)url selector:(SEL)selector parseClass:(Class)parseClass requestType:(NSInteger)type;

#pragma mark Object Get
-(void)genericObjectGetForDelegate:(id)delegate url:(NSString *)url selector:(SEL)selector parseClass:(Class)parseClass requestType:(NSInteger)type;


@end

















