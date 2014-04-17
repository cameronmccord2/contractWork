//
//  SBDaoV1.h
//  SalesmanBuddyiOS
//
//  Created by Cameron McCord on 12/5/13.
//  Copyright (c) 2013 McCord Inc. All rights reserved.
//

#import "DAOManager.h"
#import "Medias.h"

@protocol VPDaoV1DelegateProtocol <DAOManagerDelegateProtocol>

@optional

-(void)gotMedias;
-(void)errorGettingMedias;
-(void)videoDataThen:(NSURLConnectionWithExtras *)connection progress:(NSProgress *)progress;
-(void)filePathForRequestedFile:(NSString *)filePath;
-(void)fileDataForRequestedFile:(NSData *)fileData;

@end


@interface VPDaoV1 : DAOManager{
    NSString *videoFilePath;
}



+(instancetype)sharedManager;
-(void)getMedias:(id<VPDaoV1DelegateProtocol>)delegate forContext:(NSManagedObjectContext *)context;
-(void)getVideoData:(id<VPDaoV1DelegateProtocol>)delegate media:(Medias *)media;

@end
