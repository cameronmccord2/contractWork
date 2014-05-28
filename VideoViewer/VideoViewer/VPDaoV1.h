//
//  SBDaoV1.h
//  SalesmanBuddyiOS
//
//  Created by Cameron McCord on 12/5/13.
//  Copyright (c) 2013 McCord Inc. All rights reserved.
//

#import "DAOManager.h"
#import "Medias.h"
#import "SubPopups.h"

@protocol VPDaoV1DelegateProtocol <DAOManagerDelegateProtocol>

@optional

-(void)gotMedias;
-(void)errorGettingMedias;
-(void)videoDataThen:(NSURLConnectionWithExtras *)connection progress:(NSProgress *)progress;
-(void)imageDataThen:(NSURLConnectionWithExtras *)connection progress:(NSProgress *)progress;
-(void)filePathForRequestedFile:(NSString *)filePath;
-(void)fileDataForRequestedFile:(NSData *)fileData;
-(void)fileDataForRequestedImage:(NSData *)imageData;

@end


@interface VPDaoV1 : DAOManager{
    NSString *videoFilePath;
    NSString *imagesFilePath;
}



+(instancetype)sharedManager;
-(void)getMedias:(id<VPDaoV1DelegateProtocol>)delegate forContext:(NSManagedObjectContext *)context reload:(BOOL)reload;
-(void)getVideoData:(id<VPDaoV1DelegateProtocol>)delegate media:(Medias *)media;
-(void)getPopupData:(id<VPDaoV1DelegateProtocol>)delegate popup:(Popups *)popup;
-(void)getImageData:(id<VPDaoV1DelegateProtocol>)delegate subPopup:(SubPopups *)sub;

@end
