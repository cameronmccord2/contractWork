// Do users exists call
//
//
//  SBDaoV1.m
//  SalesmanBuddyiOS
//
//  Created by Cameron McCord on 12/5/13.
//  Copyright (c) 2013 McCord Inc. All rights reserved.
//

#import "VPDaoV1.h"
#import "Languages.h"
#import "Medias.h"
#import "Popups.h"
#import "Files+Extras.h"
#import "Captions.h"

NSString *baseUrl = @"http://salesmanbuddyserver.elasticbeanstalk.com/v1/salesmanbuddy/";
NSString *getMediasUrl = @"medias";
NSString *mediaUrl = @"mediaFile";
NSString *s3Url = @"https://s3-us-west-2.amazonaws.com/";


@implementation VPDaoV1

+(VPDaoV1 *)sharedManager{
    static VPDaoV1 *sharedManager;
    @synchronized(self){// this is if multiple threads do this at the exact same time
        if (!sharedManager) {
            sharedManager = [[VPDaoV1 alloc] init];
        }
        return sharedManager;
    }
}

-(instancetype)init{
    self = [super init];
    if (self != nil) {
        NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        saveFilePath = [NSString stringWithFormat:@"%@/%@", docPath, @"videos"];
    }
    return self;
}

-(void)setLoadStatus:(NSString *)loadStatus forLoadProperties:(LoadProperties *)loadProperties {
    loadProperties.loadStatus = loadStatus;
    loadProperties.loadStatusChanged = [NSDate date];
    if (loadProperties.attempts == nil) {
        loadProperties.attempts = @(0);
    }
    loadProperties.attempts = @([loadProperties.attempts intValue] + 1);
}

-(NSString *)getUniqueId{
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

-(void)getFilesThatDontExistForDelegate:(id)delegate inContext:(NSManagedObjectContext *)context {
    
    NSError *error = nil;
    NSArray *files = [CoreDataTemplates getListForEntity:@"AwsFile" withPredicate:[NSPredicate predicateWithFormat:@"file.loadStatus == %@", LoadStatusNotDownloaded] forContext:context error:&error];
    for (AwsFile *file in files) {
        if(file.bucketName == nil || file.file.remoteUrl == nil)
            continue;
        
        NSString *fullFileName = [NSString stringWithFormat:@"%@%@", file.filenameInBucket, file.extension];
        
        void(^success)(NSData *, void(^)()) = ^void(NSData *data, void(^cleanUp)()){
            NSString *fullFilePath = [self saveThisFile:data filename:fullFileName folderContainingFile:saveFilePath];
            [file.file setLocalUrl:fullFilePath];
            [self setLoadStatus:LoadStatusDownloaded forLoadProperties:file.file];
            DLog(@"downloaded file");
            [CoreDataTemplates saveContext:context sender:self];
        };
        
        void(^errorFunc)(NSData *, NSError *, void(^)()) = ^void(NSData *data, NSError *error, void(^cleanUp)()){
            DLog(@"there was an error getting the file: %@", error);
            cleanUp();
        };
        
        DLog(@"downloading file");
        NSString *url = [NSString stringWithFormat:@"%@%@/%@", s3Url, file.bucketName, file.filenameInBucket];
        [self genericGetFunctionForDelegate:delegate
                                     forUrl:url
                                requestType:NormalType
                                    success:success
                                      error:errorFunc
                                       then:nil];
    }
}

-(NSString *)saveThisFile:(NSData *)data filename:(NSString *)filename folderContainingFile:(NSString *)folderContainingFile{
    NSString *finalFilePath = nil;
    if ([self makeSurePathExists:folderContainingFile]) {
        finalFilePath = [NSString stringWithFormat:@"%@/%@", folderContainingFile, filename];
        if(![data writeToFile:finalFilePath atomically:YES]){
            NSLog(@"file writting failed for folder: %@, filename: %@", folderContainingFile, filename);
        }
    }
    return finalFilePath;
}

-(BOOL)makeSurePathExists:(NSString *)path{
    NSLog(@"path: %@", path);
    path = [NSString stringWithFormat:@"%@/", path];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError* error1;
    if(![fileManager fileExistsAtPath:path]){
        if([fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error1]){
            NSLog(@"success creating path: %@", path);
            return YES;
        }else
            NSLog(@"error making path: %@, error: %@", path, [error1 localizedDescription]);
    }else
        return YES;
    return NO;
}

@end
































