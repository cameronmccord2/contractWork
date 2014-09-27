//
//  DAOManager.m
//  SalesmanBuddyiOS
//
//  Created by Cameron McCord on 10/17/13.
//  Copyright (c) 2013 McCord Inc. All rights reserved.
//

#import "DAOManager.h"

@implementation DAOManager{
    NSString *networkErrorMessage;
}
// implement:
// {cache:true}
// endpoint doesn't require oauth


+(DAOManager *)sharedManager{
    static DAOManager *sharedManager;
    @synchronized(self){// this is if multiple threads do this at the exact same time
        if (!sharedManager) {
            sharedManager = [[DAOManager alloc] init];
        }
        return sharedManager;
    }
}

-(id)init{
    self = [super init];
    if (self) {
        callQueue = [[NSMutableArray alloc] init];
        blockingRequestRunning = false;
        dataFromConnectionByTag = [[NSMutableDictionary alloc] init];
        connections = [[NSMutableDictionary alloc] init];
        connectionNumber = [NSDecimalNumber zero];
    }
    return self;
}

-(NSDecimalNumber *)getConnectionNumber{
    connectionNumber = [connectionNumber decimalNumberByAdding:[NSDecimalNumber one]];
    return connectionNumber;
}


#pragma mark - Utilities

-(void)incrementNetworkActivity{
    self.networkActivityCounter++;
    if (self.networkActivityCounter == 1) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
}

-(void)decrementNetworkActivity{
    self.networkActivityCounter--;
    if (self.networkActivityCounter == 0) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
    assert(self.networkActivityCounter > -1);
}

-(void)callSelector:(SEL)selector onDelegate:(id)delegate{
    [self callSelector:selector onDelegate:delegate withObject:NULL];
}

-(void)callSelector:(SEL)selector onDelegate:(id)delegate withObject:(id)object {
    if (delegate == nil) {
        //		DLog(@"Delegate is null, do nothing");
        return;
    }
    if (selector == nil) {
        DLog(@"callselectorWithObject selector: %@ is null, why call this with a null selector? Doing nothing.", NSStringFromSelector(selector));
        return;
    }
    if ([delegate respondsToSelector:selector]) {
        //		DLog(@"%@ responds to selector, %@", NSStringFromClass([delegate class]), NSStringFromSelector(selector));
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if (object == NULL) {// NULL is passed only from callSelector:OnDelegate: so if object is nil then we must want to pass nil
            [delegate performSelector:selector];
        }else{
            [delegate performSelector:selector withObject:object];
        }
#pragma clang diagnostic pop
    }else{
        DLog(@"cannot send delegate %@ selector: %@", NSStringFromClass([delegate class]), NSStringFromSelector(selector));
    }
}

#pragma mark - Block Templates

-(void (^)(NSData *, NSError *, void(^)()))errorTemplateForDelegate:(id)delegate selectorOnError:(SEL)errorSelector{
    
    void(^error)(NSData *, NSError *, void(^)()) = ^void(NSData *data, NSError *error, void(^cleanUp)()){
        if (error == nil) {
            DLog(@"error was nil in error template, this shouldnt ever happen");
        }
        if (errorSelector == nil) {
            DLog(@"There was no error selector specified for delegate: %@. This error template function doesn't do anything without a selector.", delegate);
            return;
        }
        
        [self callSelector:errorSelector onDelegate:delegate];
        cleanUp();
    };
    return error;
}

-(void (^)(NSData *, NSURLConnectionWithExtras *, NSProgress *))thenTemplateForDelegate:(id)delegate selectorOnThen:(SEL)thenSelector{
    void(^then)(NSData *, NSURLConnectionWithExtras *, NSProgress *) = ^void(NSData *data, NSURLConnectionWithExtras *connection, NSProgress *nsProgress){
        if (delegate == nil) {
            DLog(@"delegate is nil in thenTemplateForDelegate, dont do anything");
            return;
        }
        if (thenSelector == nil) {
            DLog(@"There was no then selector specified for the delegate: %@. This then template function doesn't do anything without a selector", NSStringFromClass([delegate class]));
            return;
        }
        [self callSelector:thenSelector onDelegate:delegate];
    };
    return then;
}

-(void (^)(NSData *, void(^cleanUp)()))successTemplateForDelegate:(id)delegate selectorOnSuccess:(SEL)successSelector parseClass:(Class)parseClass resultIsArray:(BOOL)resultIsArray{
    
    SEL parseJsonArraySelector = @selector(arrayFromDictionaryList:);
    SEL initObjectWithDictionary = @selector(objectFromDictionary:);
    
    void(^success)(NSData *, void(^)()) = ^void(NSData *data, void(^cleanUp)()){
        NSError *e = nil;
        if (resultIsArray) {
            NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&e];
            //            NSLog(@"got Array");
            //            NSLog(@"%@", jsonArray);
            if (e != nil) {
                [self doJsonError:data error:e];
            }else if ([delegate respondsToSelector:successSelector]) {
                //                DLog(@"responds to success selector: %@", NSStringFromSelector(successSelector));
                if ([parseClass respondsToSelector:parseJsonArraySelector]) {
                    //                    NSLog(@"parseClass responds to selector: %@", NSStringFromSelector(parseJsonArraySelector));
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    NSArray *array = [parseClass performSelector:parseJsonArraySelector withObject:jsonArray];
                    //                    NSLog(@"parsed list");
                    [self callSelector:successSelector onDelegate:delegate withObject:array];
#pragma clang diagnostic pop
                }else{
                    DLog(@"parseClass cannot respond to %@, class: %@", NSStringFromSelector(parseJsonArraySelector), parseClass);
                }
            }else
                DLog(@"cannot send list to delegate: %@, doesnt repond to the specified successSelector: %@", NSStringFromClass([delegate class]), NSStringFromSelector(successSelector));
        }else{
            NSDictionary *d = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&e];
            //            NSLog(@"got Dictionary");
            if (e != nil) {
                [self doJsonError:data error:e];
            }else if ([delegate respondsToSelector:successSelector]) {
                //                DLog(@"responds to success selector: %@", NSStringFromSelector(successSelector));
                if ([parseClass respondsToSelector:initObjectWithDictionary]) {
                    //                    NSLog(@"parseClass responds to selector: %@", NSStringFromSelector(initObjectWithDictionary));
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    [self callSelector:successSelector onDelegate:delegate withObject:[parseClass performSelector:initObjectWithDictionary withObject:d]];
#pragma clang diagnostic pop
                }else{
                    DLog(@"parseClass: %@, cant respond to selector: %@", NSStringFromClass([parseClass class]), NSStringFromSelector(initObjectWithDictionary));
                }
            }else{
                DLog(@"cannot send result to delegate %@", NSStringFromClass([delegate class]));
            }
        }
        cleanUp();
    };
    return success;
}


#pragma mark - Fetch Queue

-(void)runRequestQueue{
    [self doFetchQueue];
}

-(void)doFetchQueue{
//    if (!self.hasInternetConnection) {
//        //		[NSException raise:@"Should have internet here always" format:@"asdf"];
//        return;
//    }
    //    NSLog(@"doing fetch queue, %hhd, %hhd", tryingToAuthenticate, blockingRequestRunning);
    for (int i = 0; i < 10; i++) {// loop through all the priorities
        for (CallQueue *cq in callQueue) {
            if(![self.authDelegate isTryingToAuthenticate] && !blockingRequestRunning){
                if (!cq.alreadySent && cq.type == i) {
                    
//                    if (!self.hasInternetConnection) {
//                        // send the request back by calling the error on it
//                        void (^cleanUp)() = ^void(){
//                            
//                        };
//                        cq.alreadySent = YES;
//                        NSError *error = nil;
//                        cq.error(nil, error, cleanUp);
//                        
//                    }else{
                        if(i < 6)// everything under 6 is a blocking request priority
                            blockingRequestRunning = YES;
                        [self doRequest:cq];
                        return;
//                    }
                }
            }else
                return;
        }
    }
}

-(void)fetchQueueTimerFinish{
    blockingRequestRunning = false;
    [self runRequestQueue];
}

-(void)doRequest:(CallQueue *)cq{
    //    DLog(@"doing request");
    if (cq.authDelegate != nil && self.authDelegate != nil && [self.authDelegate isAuthenticationNil]) {
        DLog(@"THIS SHOULDNT HAPPEN: auth is nil, show login");
        [self.authDelegate showLoginUsingDelegate:cq.authDelegate whenAuthIsReady:^void(){
            [self doFetchQueue];
        }];
    }else{
        //        DLog(@"going to try to authorize");
        cq.alreadySent = true;
        [self incrementNetworkActivity];
        //		DLog(@"auth: %@", self.auth);
        
        
        
        void(^afterAuth)(NSError *) = ^void(NSError *error){
            
            if (self.authDelegate != nil) {
                DLog(@"token: %@", [self.authDelegate tokenForTokenInfo]);
            }
            
            if (error == nil) {// success
                //				NSLog(@"%@", [cq.request allHTTPHeaderFields]);
                if (self.authDelegate != nil) {
                    [self.authDelegate setTryingToAuthenticate:NO];
                }
                
                if(cq.type == AppendTokenType){
                    [cq.request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?access_token=%@", cq.request.URL.absoluteString, [self.authDelegate tokenForTokenInfo]]]];
                }
                
                //				[cq.request setValue:[NSString stringWithFormat:@"Bearer %@", self.dummyAccessToken] forHTTPHeaderField:@"Authorization"];
                NSURLConnectionWithExtras *connectionObject = [NSURLConnectionWithExtras connectionWithRequest:cq.request delegate:self startImmediately:YES uniqueTag:[self getConnectionNumber] finalDelegate:cq.delegate success:cq.success error:cq.error then:cq.then];
                [connections setObject:connectionObject forKey:connectionNumber];
                
                
                [self doThenWithData:nil connection:connectionObject];// hand back the connection object so it can be canceled if desired
                
                [self doFetchQueue];
            }else{
                [self decrementNetworkActivity];
                DLog(@"failed to authorize request, %@", error.localizedDescription);
                DLog(@"errorCode: %ld", (long)error.code);
                cq.alreadySent = false;
                switch (error.code) {
                    case -1009:
                        DLog(@"Cant connect to the internet");
                        blockingRequestRunning = true;
                        [self.timers addObject:[NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(fetchQueueTimerFinish) userInfo:nil repeats:NO]];
                        break;
                        
                    case -1000:
                        DLog(@"User closed the login modal before logging in");
                    default:
                        if (![self.authDelegate canAuthAuthorize]) {
                            DLog(@"auth cannot authorize");
                            if (self.authDelegate != nil) {
                                [self.authDelegate showLoginUsingDelegate:cq.authDelegate whenAuthIsReady:^void(){
                                    [self doFetchQueue];
                                }];
                            }
                        }else{
                            DLog(@"trying again imediately");
                            [self doRequest:cq];
                        }
                        break;
                }
            }
        };
        
        if (self.authDelegate != nil) {
            [self.authDelegate authorizeRequest:cq.request completionHandler:afterAuth];
        }else{
            afterAuth(nil);
        }
    }
}

-(void)doJsonError:(NSData *)data error:(NSError *)error{
    DLog(@"error deserializing json array, %@", error.localizedDescription);
    DLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    NSXMLParser *p = [[NSXMLParser alloc] initWithData:data];
    [p setDelegate:self];
    [p parse];
}


#pragma mark - Execute block convenience functions

-(void)doThenWithData:(NSData *)data connection:(NSURLConnectionWithExtras *)connection{
    if (connection.then != nil)
        connection.then(data, connection, connection.nsProgress);
}

-(void)doErrorWithData:(NSData *)data error:(NSError *)error forConnection:(NSURLConnectionWithExtras *)connection{
    if (data == nil) {
        data = [dataFromConnectionByTag objectForKey:connection.uniqueTag];
    }
    void (^cleanUp)() = ^void(){
        [dataFromConnectionByTag removeObjectForKey:connection.uniqueTag]; // after done using the data, remove it
        [connections removeObjectForKey:connection.uniqueTag];// remove the connection
        [self doFetchQueue];
    };
    
    if (connection.error != nil) {
        connection.error(data, error, cleanUp);
    }
}

#pragma mark - Connection Handling
-(void)connection:(NSURLConnectionWithExtras *)connection didReceiveData:(NSData *)data{
    //	NSLog(@"saving data for unique tag: %@", connection.uniqueTag);
    
    if ([dataFromConnectionByTag objectForKey:connection.uniqueTag] == nil) {
        //        DLog(@"created new connection data for tag: %@, url: %@", connection.uniqueTag, connection.originalRequest.URL);
        NSMutableData *newData = [[NSMutableData alloc] initWithData:data];
        [dataFromConnectionByTag setObject:newData forKey:connection.uniqueTag];
        connection.nsProgress.completedUnitCount = data.length;// first time
        return;
    }else{
        //        NSLog(@"saving data for connection tag: %@, url: %@", connection.uniqueTag, connection.originalRequest.URL);
        [[dataFromConnectionByTag objectForKey:connection.uniqueTag] appendData:data];
        connection.nsProgress.completedUnitCount += data.length;
        [self doThenWithData:[dataFromConnectionByTag objectForKey:connection.uniqueTag] connection:connection];
    }
}

- (void)connection:(NSURLConnectionWithExtras *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite{// for upload progress
    connection.nsProgress.totalUnitCount = totalBytesExpectedToWrite;
    connection.nsProgress.completedUnitCount = totalBytesWritten;
    [self doThenWithData:[[NSData alloc] init] connection:connection];
}

- (void) connection:(NSURLConnectionWithExtras *)connection didReceiveResponse:(NSURLResponse *)response{
    //    DLog(@"did recieve response");
    if([response isKindOfClass:[NSHTTPURLResponse class]]){
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        [connection setStatusCodeForNow:[httpResponse statusCode]];
        //        if ([connection.typeTag isEqualToNumber:typeUserExists]) {
        //            if (status == 403) {
        //                NSLog(@"recieved status unauthorized for typeUserExists");
        //                [connection cancel];
        //                if ([connection.finalDelegate respondsToSelector:@selector(showAuthModal:)]) {
        //                    NewUserModalViewController *rootViewController = [[NewUserModalViewController alloc] initWithNibName:nil bundle:nil];
        //                    UINavigationController *viewController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
        //                    [connection.finalDelegate performSelector:@selector(showAuthModal:) withObject:viewController];
        //                }else
        //                    NSLog(@"cant load new user modal");
        //            }
        //        }
        
        // NSProgress
        connection.nsProgress.totalUnitCount = response.expectedContentLength;
        [self doThenWithData:[dataFromConnectionByTag objectForKey:connection.uniqueTag] connection:connection];
    }
}

-(void)connectionDidFinishLoading:(NSURLConnectionWithExtras *)connection{
    //    DLog(@"connection did finish loading");
    [self decrementNetworkActivity];
    void (^cleanUp)() = ^void(){
        //        DLog(@"connection finished for tag: %@, url: %@", connection.uniqueTag, connection.originalRequest.URL);
        [dataFromConnectionByTag removeObjectForKey:connection.uniqueTag]; // after done using the data, remove it
        [connections removeObjectForKey:connection.uniqueTag];// remove the connection
        [self doFetchQueue];
    };
    
    NSData *data = [dataFromConnectionByTag objectForKey:connection.uniqueTag];
    
    if (connection.success != nil) {
        connection.success(data, cleanUp);
    }
    if (connection.then != nil) {
        connection.nsProgress.completedUnitCount = connection.nsProgress.totalUnitCount;
        connection.then(data, connection, connection.nsProgress);
    }
}

-(void)connection:(NSURLConnectionWithExtras *)conn didFailWithError:(NSError *)error{
    [self decrementNetworkActivity];
    
    // DO A GLOBAL ERROR HANDLER FOR NOW FOR MY DAO
    
    NSString *errorString = [NSString stringWithFormat:@"Fetch failed for url: %@, error: %@", conn.originalRequest.URL.absoluteString, [error localizedDescription]];
    DLog(@"Underlying Error: %@, error: %@", [[error userInfo] objectForKey:@"NSUnderlyingError"], errorString);
    
    NSRange range = [errorString rangeOfString:@"The Internet connection appears to be offline"];
    if (range.location != NSNotFound) {
        self.hasInternetConnection = NO;
    }
    //    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error" message:errorString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    //    [av show];
    [self doErrorWithData:nil error:error forConnection:conn];
}

#pragma mark - XML Parser error functions

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    networkErrorMessage = [NSString stringWithFormat:@"error%@, %@", networkErrorMessage, string];
}

-(void)parserDidEndDocument:(NSXMLParser *)parser{
    DLog(@"error: %@", networkErrorMessage);
    networkErrorMessage = @"";
}






@end








































