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
#import "NSArray+Random.h"
#import "CallQueue.h"


enum{
    Junk = 0, GetUserType = 1, AppendTokenType = 2, StoreType = 5, IncreasedTimeoutType = 8, NormalType = 9
};

@protocol ShowAuthModalDelegateProtocol <NSObject>

-(void)showAuthModal:(UIViewController *)viewController;
-(void)dismissAuthModal:(UIViewController *)viewController;

@end

@protocol AuthDelegateProtocol <NSObject>

//-(void)makeAuthViableAndExecuteCallQueue:(id)delegate;
-(BOOL)isTryingToAuthenticate;
-(void)setTryingToAuthenticate:(BOOL)trying;
-(NSString *)tokenForTokenInfo;
-(void)authorizeRequest:(NSMutableURLRequest *)request completionHandler:(void (^)(NSError *error))handler;
-(BOOL)isAuthenticationNil;
-(BOOL)canAuthAuthorize;
-(void)showLoginUsingDelegate:(id<ShowAuthModalDelegateProtocol>)delegate whenAuthIsReady:(void (^)())whenAuthIsReady;

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
    BOOL blockingRequestRunning;
}


@property(nonatomic, strong)NSXMLParser *parser;
@property(nonatomic, strong)NSMutableArray *timers;
@property(nonatomic, strong)NSString *baseUrl;
@property(nonatomic, strong)NSString *userUrl;
@property(nonatomic)BOOL hasInternetConnection;
@property(nonatomic)NSInteger networkActivityCounter;
@property(nonatomic, weak)id<AuthDelegateProtocol> authDelegate;

/// Gets the shared manager of the DAO, There is only ever one instance of this.
/// @return DAOManager's shared manager
+(DAOManager *)sharedManager;



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

-(void)doFetchQueue;


-(void)callSelector:(SEL)selctor onDelegate:(id)delegate;
-(void)callSelector:(SEL)selector onDelegate:(id)delegate withObject:(id)object;

-(void (^)(NSData *, void(^cleanUp)()))successTemplateForDelegate:(id)delegate selectorOnSuccess:(SEL)successSelector parseClass:(Class)parseClass resultIsArray:(BOOL)resultIsArray;

@end






































































