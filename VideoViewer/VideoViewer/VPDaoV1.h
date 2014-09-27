//
//  SBDaoV1.h
//  SalesmanBuddyiOS
//
//  Created by Cameron McCord on 12/5/13.
//  Copyright (c) 2013 McCord Inc. All rights reserved.
//

#import "DAOManager+Protected.h"
#import "Medias.h"
#import "LoadProperties+Extras.h"
#import "SubPopups.h"

// Internet change broadcast values
static NSString *HAS_INTERNET = @"HasInternet";
static NSString *HAS_NO_INTERNET = @"HasNoInternet";
static NSString *LOG_ON_MAIN_THREAD = @"logOnMainThread";

// file types
static NSString *FileTypeFromMTC = @"fromMTC";
static NSString *FileTypeFromUser = @"fromUser";

// file status
static NSString *LoadStatusNone = @"noLoadStatus";
static NSString *LoadStatusNotDownloaded = @"notDownloaded";
static NSString *LoadStatusDownloaded = @"downloaded";
static NSString *LoadStatusDownloading = @"downloading";
static NSString *LoadStatusTryDownloadingLater = @"tryDownloadingLater";
static NSString *LoadStatusNotUploaded = @"notUploaded";
static NSString *LoadStatusUploading = @"uploading";
static NSString *LoadStatusUploaded = @"uploaded";
static NSString *LoadStatusTryUploadingLater = @"tryUploadingLater";


@interface VPDaoV1 : DAOManager{
    NSString *saveFilePath;
}



+(instancetype)sharedManager;

-(void)setLoadStatus:(NSString *)loadStatus forLoadProperties:(LoadProperties *)loadProperties;


-(void)getFilesThatDontExistForDelegate:(id)delegate inContext:(NSManagedObjectContext *)context; // this is for the developer to easily get all the needed files

@end
