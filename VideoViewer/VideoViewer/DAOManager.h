//
//  DAOManager.h
//  SalesmanBuddyiOS
//
//  Created by Cameron McCord on 10/17/13.
//  Copyright (c) 2013 McCord Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "NSURLConnectionWithExtras.h"
#import "NSURLAdditions.h"
#import "NSStringAdditions.h"
#import "Random.h"
#import "CallQueue.h"

@protocol DAOManagerDelegateProtocol <NSObject>

@end

@protocol DAOManagerParseObjectProtocol <NSObject>

@optional

+(NSArray *)arrayFromDictionaryList:(NSArray *)array;
+(instancetype)objectFromDictionary:(NSDictionary *)dictionary;

@end

@interface DAOManager : NSObject<CLLocationManagerDelegate, NSXMLParserDelegate>{
    NSMutableArray *callQueue;
    NSDecimalNumber *connectionNumber;
    NSMutableDictionary *dataFromConnectionByTag;
    NSMutableDictionary *connections;
}

@property(nonatomic, strong)NSString *error;
@property(nonatomic, strong)NSXMLParser *parser;
@property(nonatomic, strong)NSMutableArray *timers;

/// Gets the shared manager of the DAO, There is only ever one instance of this.
/// @return DAOManager's shared manager
+(DAOManager *)sharedManager;

/// Generic GET function for DAOManager. All connection handling is behind the scenes.
/// @param delegate Source timeline entity ID
/// @param destId Destination timeline entity ID
/// @param name Message name
/// @return A newly created message instance
-(void)genericGetFunctionForDelegate:(id<DAOManagerDelegateProtocol>)delegate forUrl:(NSString *)url requestType:(NSInteger)type success:(void (^)(NSData *, void(^)()))success error:(void (^)(NSData *, NSError *, void(^)()))error then:(void (^)(NSData *, NSURLConnectionWithExtras *, NSProgress *))then;

/// Make an NSURLRequest with any verb. All connection handling is behind the scenes.
/// @param verb Rest verb for the request: GET, PUT, POST, DELETE, etc.
/// @param url The full url for the request including the http or https in NSString format.
/// @param bodyDictionary The dictionary to be sent. Will be converted into NSData. This is for STRUCTURED data only such as JSON. Can be nil.
/// @param bodyData The data to be sent in the body. Can be nil.
/// @param authDelegate The delegate must conform to DAOManagerDelegateProtocol. This is so the delegate can show the login modal.
/// @param contentType The content type of the body. 'application/json' or 'image/jpeg' or something else.
/// @param success A block function that is called when the connection successfully completes. Can be nil.
/// @param error A block function that is called when the connection errors. This function is called when connection:didFailWithError: is called by ios. Can be nil.
/// @param then A block function that is called when the connection is created(data will be nil), when any response is recieved(status code gets set) or when didSendBodyData:, and when the connection closes in a non-error state. Can be nil.
-(void)makeRequestWithVerb:(NSString *)verb forUrl:(NSString *)url bodyDictionary:(NSDictionary *)bodyDictionary bodyData:(NSData *)bodyData authDelegate:(id<DAOManagerDelegateProtocol>)delegate contentType:(NSString *)contentType requestType:(NSInteger)type success:(void (^)(NSData *, void(^)()))success error:(void (^)(NSData *, NSError *, void(^)()))error then:(void (^)(NSData *, NSURLConnectionWithExtras *, NSProgress *))then;

/// Template error block function.
/// @param delegate The delegate to send the specified selector to.
/// @param errorSelector The selector to be performed on the delegate. Two objects are sent with the selector: NSData *, NSError *.
-(void (^)(NSData *, NSError *, void(^)()))errorTemplateForDelegate:(id)delegate selectorOnError:(SEL)errorSelector;

/// Template then block function
/// @param delegate The delegate to send the specified selector to.
/// @param thenSelector The selector to be performed on the delegate. Two objects are sent with the selector: NSURLConnectionWithExtras *, NSProgress *.
-(void (^)(NSData *, NSURLConnectionWithExtras *, NSProgress *))thenTemplateForDelegate:(id)delegate selectorOnThen:(SEL)thenSelector;

/// Runs the fetch queue. Blocking requests are run first, then all other requests in order of when they were recieved. Queue gets paused if requests cannot be authorized. Requests that came back 401 get added back to the queue in the order they were first recieved. Queue resumes when authentication gets resolved.
-(void)runRequestQueue;

/// Takes the data and runs it on an xml parser, removes the tags, and then prints it to the console. This is so an html error can be seen by humans.
/// @param data The data to parse
/// @param error The error's localizedDescription gets printed to the console with 'error deserializing json: ' on the front.
-(void)doJsonError:(NSData *)data error:(NSError *)error;




-(void)genericListGetForDelegate:(id)delegate url:(NSString *)url selector:(SEL)selector parseClass:(Class)parseClass requestType:(NSInteger)type;
-(void)genericObjectGetForDelegate:(id)delegate url:(NSString *)url selector:(SEL)selector parseClass:(Class)parseClass requestType:(NSInteger)type;
-(void (^)(NSData *, void(^cleanUp)()))successTemplateForDelegate:(id)delegate selectorOnSuccess:(SEL)successSelector parseClass:(Class)parseClass resultIsArray:(BOOL)resultIsArray;

@end






































































