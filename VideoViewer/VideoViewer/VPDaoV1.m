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
#import "Captions.h"

NSString *baseUrl = @"http://salesmanbuddyserver.elasticbeanstalk.com/v1/salesmanbuddy/";
NSString *getMediasUrl = @"medias";
NSString *mediaUrl = @"mediaFile";
NSString *videoUrl = @"https://s3-us-west-2.amazonaws.com/";
NSString *imagesUrl = @"https://s3-us-west-2.amazonaws.com/";


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

enum{
    Junk = 0, ConfirmUserType = 1, StoreType = 5, NormalType = 9
};

-(instancetype)init{
    self = [super init];
    if (self != nil) {
        NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        videoFilePath = [NSString stringWithFormat:@"%@/%@", docPath, @"videos"];
        imagesFilePath = [NSString stringWithFormat:@"%@/%@", docPath, @"images"];
    }
    return self;
}

-(NSString *)getUniqueId{
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

-(NSString *)getVideoUrl{
    return videoUrl;
}

-(void)getVideoData:(id<VPDaoV1DelegateProtocol>)delegate media:(Medias *)media{
    
    NSString *fullFileName = [NSString stringWithFormat:@"%@%@", media.filenameInBucket, media.extension];
    NSString *fileString = [NSString stringWithFormat:@"%@/%@", videoFilePath, fullFileName];
    if([self pathForFileInBundleWithFilename:media.filenameInBucket extension:media.extension] != nil){
        NSLog(@"found in bundle");
        [self respondWithThisFile:[self pathForFileInBundleWithFilename:media.filenameInBucket extension:media.extension] toDelegate:delegate selector:nil];
    }else if ([self doesFileExist:fileString]) {
        [self respondWithThisFile:fileString toDelegate:delegate selector:nil];
    }else{
        // go get it
        void(^success)(NSData *, void(^)()) = ^void(NSData *data, void(^cleanUp)()){
            NSString *fullFilePath = [self saveThisFile:data filename:fullFileName folderContainingFile:videoFilePath];
            [self respondWithThisFile:fullFilePath toDelegate:delegate selector:nil];
        };
        
        NSString *url = [NSString stringWithFormat:@"%@%@/%@", videoUrl, media.bucketName, media.filenameInBucket];
        [self genericGetFunctionForDelegate:delegate forUrl:url requestType:NormalType success:success error:[self errorTemplateForDelegate:delegate selectorOnError:nil] then:[self thenTemplateForDelegate:delegate selectorOnThen:@selector(videoDataThen:progress:)]];
    }
}

-(void)getImageData:(id<VPDaoV1DelegateProtocol>)delegate subPopup:(SubPopups *)sub{
    
    NSString *fullFileName = [NSString stringWithFormat:@"%@%@", sub.filenameInBucket, sub.extension];
    NSString *fileString = [NSString stringWithFormat:@"%@/%@", imagesFilePath, fullFileName];
    if([self pathForFileInBundleWithFilename:sub.filenameInBucket extension:sub.extension] != nil){
        NSLog(@"found in bundle");
        [self respondWithThisFile:[self pathForFileInBundleWithFilename:sub.filenameInBucket extension:sub.extension] toDelegate:delegate selector:@selector(fileDataForRequestedImage:)];
    }else if ([self doesFileExist:fileString]) {
        [self respondWithThisFile:fileString toDelegate:delegate selector:@selector(fileDataForRequestedImage:)];
    }else{
        // go get it
        void(^success)(NSData *, void(^)()) = ^void(NSData *data, void(^cleanUp)()){
            NSString *fullFilePath = [self saveThisFile:data filename:fullFileName folderContainingFile:imagesFilePath];
            [self respondWithThisFile:fullFilePath toDelegate:delegate selector:@selector(fileDataForRequestedImage:)];
        };
        
        NSString *url = [NSString stringWithFormat:@"%@%@/%@", imagesUrl, sub.bucketName, sub.filenameInBucket];
        [self genericGetFunctionForDelegate:delegate forUrl:url requestType:NormalType success:success error:[self errorTemplateForDelegate:delegate selectorOnError:nil] then:[self thenTemplateForDelegate:delegate selectorOnThen:@selector(imageDataThen:progress:)]];
    }
}

-(NSString *)pathForFileInBundleWithFilename:(NSString *)filename extension:(NSString *)extension{
    // add ability for extension to be null and pull the extension off of the filename
    if (extension == nil) {
        return nil;// doesnt do that yet
    }
    NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:extension];
    return path;
}

-(void)getPopupData:(id<VPDaoV1DelegateProtocol>)delegate popup:(Popups *)popup{
    
    NSString *fullFileName = [NSString stringWithFormat:@"%@%@", popup.filenameInBucket, popup.extension];
    NSString *fileString = [NSString stringWithFormat:@"%@/%@", videoFilePath, fullFileName];
    
    if([self pathForFileInBundleWithFilename:popup.filenameInBucket extension:popup.extension] != nil){
//        NSLog(@"found in bundle");
        [self respondWithThisFile:[self pathForFileInBundleWithFilename:popup.filenameInBucket extension:popup.extension] toDelegate:delegate selector:nil];
    }else if ([self doesFileExist:fileString]) {
        [self respondWithThisFile:fileString toDelegate:delegate selector:nil];
    }else{
        
        void(^success)(NSData *, void(^)()) = ^void(NSData *data, void(^cleanUp)()){
            NSString *fullFilePath = [self saveThisFile:data filename:fullFileName folderContainingFile:videoFilePath];
            [self respondWithThisFile:fullFilePath toDelegate:delegate selector:nil];
        };
        
        NSString *url = [NSString stringWithFormat:@"%@%@/%@", videoUrl, popup.bucketName, popup.filenameInBucket];
        [self genericGetFunctionForDelegate:delegate forUrl:url requestType:NormalType success:success error:[self errorTemplateForDelegate:delegate selectorOnError:nil] then:[self thenTemplateForDelegate:delegate selectorOnThen:@selector(videoDataThen:progress:)]];
    }
}

-(void)getMedias:(id<VPDaoV1DelegateProtocol>)delegate forContext:(NSManagedObjectContext *)context reload:(BOOL)reload{
    
    
    SEL successSelector = @selector(gotMedias);
    
    if(reload){
        NSString *url = [NSString stringWithFormat:@"%@%@", baseUrl, getMediasUrl];
        url = [url URLStringByAppendingQueryStringKey:@"version" value:@"1"];
        
        void(^success)(NSData *, void(^)()) = ^void(NSData *data, void(^cleanUp)()){
            __block NSError *e = nil;
            
            // delete the old data
            [self deleteAllObjectsWithEntityDescription:@"Captions" context:context];
            [self deleteAllObjectsWithEntityDescription:@"SubPopups" context:context];
            [self deleteAllObjectsWithEntityDescription:@"Popups" context:context];
            [self deleteAllObjectsWithEntityDescription:@"Medias" context:context];
            [self deleteAllObjectsWithEntityDescription:@"Languages" context:context];
            
            if (![context save:&e]) {
                NSLog(@"Whoops, couldn't save deletions: %@", e);
            }else
                NSLog(@"No errors! Saving deletions finished");
            
            
            
            NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&e];
            __block int i = 0;
            if (e != nil) {
                [self doJsonError:data error:e];
            }else if ([delegate respondsToSelector:successSelector]) {
                // parse out the data into core data
                
                __block Languages *language = nil;
                __block NSMutableSet *medias = [[NSMutableSet alloc] initWithCapacity:[jsonArray count]];
                [jsonArray enumerateObjectsUsingBlock:^(id d, NSUInteger idx, BOOL *stop){
                    i++;
                    // language
                    if (language == nil) {
                        NSDictionary *lang = d[@"language"];
                        // parse language
                        language = [NSEntityDescription insertNewObjectForEntityForName:@"Languages" inManagedObjectContext:context];
                        language.name = lang[@"name"];
                        language.code1 = lang[@"code1"];
                        language.code2 = lang[@"code2"];
                        language.mtcId = lang[@"mtcId"];
                        language.id = lang[@"id"];
                        language.nativeName = lang[@"nativeName"];
                    }
                    
                    // media
                    // parse media
                    Medias *media = [NSEntityDescription insertNewObjectForEntityForName:@"Medias" inManagedObjectContext:context];
                    media.name = d[@"name"];
                    media.id = d[@"id"];
                    media.filename = d[@"filename"];
                    media.filenameInBucket = d[@"filenameInBucket"];
                    media.audioLanguageId = d[@"audioLanguageId"];
                    media.bucketId = d[@"bucketId"];
                    media.type = d[@"type"];
                    media.extension = d[@"extension"];
                    media.language = language;
                    media.bucketName = d[@"bucketName"];
                    
                    // captions
                    NSMutableSet *captions = [[NSMutableSet alloc] initWithCapacity:[d[@"captions"] count]];
                    for (NSDictionary *d2 in d[@"captions"]) {
                        // parse captions
                        Captions *c = [NSEntityDescription insertNewObjectForEntityForName:@"Captions" inManagedObjectContext:context];
                        c.id = d2[@"id"];
                        c.caption = d2[@"caption"];
                        c.mediaId = d2[@"mediaId"];
                        c.startTime = d2[@"startTime"];
                        c.endTime = d2[@"endTime"];
                        c.languageId = d2[@"languageId"];
                        c.type = d2[@"type"];
                        c.language = language;
                        c.media = media;
                        [captions addObject:c];
                    }
                    media.captions = captions;
                    
                    // popups
                    NSMutableSet *popups = [[NSMutableSet alloc] initWithCapacity:[d[@"popups"] count]];
                    for (NSDictionary *d2 in d[@"popups"]) {
                        // parse popups
                        Popups *p = [NSEntityDescription insertNewObjectForEntityForName:@"Popups" inManagedObjectContext:context];
                        p.displayName = d2[@"displayName"];
                        p.popupText = d2[@"popupText"];
                        p.mediaId = d2[@"mediaId"];
                        p.languageId = d2[@"languageId"];
                        p.startTime = d2[@"startTime"];
                        p.endTime = d2[@"endTime"];
                        p.filename = d2[@"filename"];
                        p.bucketId = d2[@"bucketId"];
                        p.filenameInBucket = d2[@"filenameInBucket"];
                        p.extension = d2[@"extension"];
                        p.bucketName = d2[@"bucketName"];
                        p.id = d2[@"id"];
                        p.language = language;
                        p.media = media;
                        
                        NSMutableSet *subPopups = [[NSMutableSet alloc] initWithCapacity:[d2[@"subPopups"] count]];
                        for (NSDictionary *d3 in d2[@"subPopups"]) {
                            SubPopups *s = [NSEntityDescription insertNewObjectForEntityForName:@"SubPopups" inManagedObjectContext:context];
                            s.bucketId = d2[@"bucketId"];
                            s.bucketName = d2[@"bucketName"];
                            s.popupText = d3[@"popupText"];
                            s.endTime = d3[@"endTime"];
                            s.startTime = d3[@"startTime"];
                            s.extension = d3[@"extension"];
                            s.filename = d3[@"filename"];
                            s.filenameInBucket = d3[@"filenameInBucket"];
                            s.id = d3[@"id"];
                            s.popupId = d3[@"popupId"];
                            s.popup = p;
                            [subPopups addObject:s];
                        }
                        p.subPopups = subPopups;
                        
                        [popups addObject:p];
                    }
                    media.popups = popups;
                    
                    [medias addObject:media];
                    
                    if (![context save:&e]) {
                        NSLog(@"Whoops, couldn't save: %@, %ld", e, (long)i);
                    }else
                        NSLog(@"No errors! Saving complete. %ld", (long)i);
                }];
                language.medias = medias;
                
                if (![context save:&e]) {
                    NSLog(@"Whoops, couldn't save: %@, %ld", e, (long)i);
                }else
                    NSLog(@"No errors! Saving complete. ALL DONE!");
                
                
                //            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
                //            NSEntityDescription *entity = [NSEntityDescription entityForName:@"Captions" inManagedObjectContext:context];
                //
                //            [fetchRequest setEntity:entity];
                //
                //            // Create the sort descriptors array.
                //            NSSortDescriptor *authorDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
                //            NSArray *sortDescriptors = @[authorDescriptor];
                //            [fetchRequest setSortDescriptors:sortDescriptors];
                //
                //            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name like '%'"];
                //            [fetchRequest setPredicate:predicate];
                //            // Create and initialize the fetch results controller.
                //            NSFetchedResultsController * fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:@"Root"];// nil was @"author"
                //
                //            NSLog(@"%ld", (long)[fetchedResultsController.fetchedObjects count]);
                
                
                // finished
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [delegate performSelector:successSelector];
#pragma clang diagnostic pop
            }else
                NSLog(@"cannot send list to delegate: %@, doesnt repond to the specified successSelector: %@", NSStringFromClass([delegate class]), NSStringFromSelector(successSelector));
            
            cleanUp();
        };
        
        
        [self genericGetFunctionForDelegate:delegate forUrl:url requestType:normal success:success error:[self errorTemplateForDelegate:delegate selectorOnError:@selector(errorGettingMedias)] then:nil];
    }else{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [delegate performSelector:successSelector];
#pragma clang diagnostic pop
    }
}

- (void) deleteAllObjectsWithEntityDescription: (NSString *) entityDescription context:(NSManagedObjectContext *)context {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityDescription inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *items = [context executeFetchRequest:fetchRequest error:&error];
    
    
    for (NSManagedObject *managedObject in items) {
    	[context deleteObject:managedObject];
    }
    if (![context save:&error])
    	NSLog(@"Error deleting %@ - error:%@", entityDescription, error);
}


#pragma mark - File Functions


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

-(BOOL)doesFileExist:(NSString *)filePath{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:filePath])
        return YES;

    return NO;
}

-(void)respondWithThisFile:(NSString *)filePath toDelegate:(id<VPDaoV1DelegateProtocol>)delegate selector:(SEL)selector{
//    if ([delegate respondsToSelector:@selector(fileUrlForRequestedFile:)]) {
//        [delegate fileUrlForRequestedFile:[NSURL fileURLWithPath:filePath]];
//    }
    if(selector == nil){
        if ([delegate respondsToSelector:@selector(filePathForRequestedFile:)])
            [delegate filePathForRequestedFile:filePath];
        
        if ([delegate respondsToSelector:@selector(fileDataForRequestedFile:)])
            [delegate fileDataForRequestedFile:[NSData dataWithContentsOfFile:filePath]];
    }else{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if([delegate respondsToSelector:selector])
            [delegate performSelector:selector withObject:[NSData dataWithContentsOfFile:filePath]];
#pragma clang diagnostic pop
    }
}

@end
































