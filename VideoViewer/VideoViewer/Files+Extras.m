//
//  Files+Extras.m
//  VPPlusBook
//
//  Created by Cameron McCord on 9/4/14.
//  Copyright (c) 2014 MTC. All rights reserved.
//

#import "Files+Extras.h"
#import "VPDaoV1.h"

@implementation Files (Extras)

+(Files *)getFileForRemoteUrl:(NSString *)remoteUrl fromContext:(NSManagedObjectContext *)context {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Files" inManagedObjectContext:context];
	[fetchRequest setEntity:entity];
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"remoteUrl == %@", remoteUrl]];
	NSError *error = nil;
	NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
	if ([results count] == 1) {
		return [results objectAtIndex:0];
	}
	return nil;
}

+(NSString *)documentPath {
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath_ = [searchPaths objectAtIndex:0];
    return  documentPath_;
}

+(NSString *)uniqueFilename {
	
	NSString *uniqueFileName = [NSString stringWithFormat:@"%@", [[NSUUID UUID] UUIDString]];
	return uniqueFileName;
}

+(void)deleteAllFilesInContext:(NSManagedObjectContext *)context {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Files" inManagedObjectContext:context];
	[fetchRequest setEntity:entity];
	NSError *error = nil;
	NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
	DLog(@"deleting %lu files", (unsigned long)[results count]);
	for (Files *f in [results mutableCopy]) {
		[[NSFileManager defaultManager] removeItemAtPath:f.localUrl error:&error];
		if (error) {
			DLog(@"delete file error: %@", error);
		}
		[context deleteObject:f];
	}
}

+(NSArray *)getAllFilesWithLoadStatus:(NSString *)loadStatus inContext:(NSManagedObjectContext *)context {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Files" inManagedObjectContext:context];
	[fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"loadStatus == %@", loadStatus]];
	NSError *error = nil;
	NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    return results;
}

+(NSString *)cdnUrlForPartialUrl:(NSString *)partialUrl {
    if([partialUrl rangeOfString:@".mp3"].location == NSNotFound)
        partialUrl = [NSString stringWithFormat:@"%@.mp3", partialUrl];
    
    if ([partialUrl rangeOfString:@"cdn.mtc.byu.edu"].location == NSNotFound)
        partialUrl = [NSString stringWithFormat:@"http://cdn.mtc.byu.edu/TALL%@", partialUrl];
    
    return partialUrl;
}

+(Files *)newFileForRemoteFilename:(NSString *)remoteUrl type:(NSString *)type inContext:(NSManagedObjectContext *)context {
    
    Files *file = [NSEntityDescription insertNewObjectForEntityForName:@"Files" inManagedObjectContext:context];
    [file setRemoteUrl:remoteUrl];
    [file setType:type];
    [[VPDaoV1 sharedManager] setLoadStatus:LoadStatusNotDownloaded forLoadProperties:file];
    return file;
}

+(Files *)newFileForFilename:(NSString *)filename extension:(NSString *)extension intoContext:(NSManagedObjectContext *)context {
    
    NSString *fullFilename = [NSString stringWithFormat:@"%@%@", filename, extension];
    Files *file = [Files getFileForRemoteUrl:fullFilename fromContext:context];
    if (file == nil) {
        file = [Files newFileForRemoteFilename:fullFilename type:FileTypeFromMTC inContext:context];
        if(filename == nil || [filename length] == 0){
            [[VPDaoV1 sharedManager] setLoadStatus:LoadStatusNone forLoadProperties:file];
        }else{
            
            [[VPDaoV1 sharedManager] setLoadStatus:LoadStatusNotDownloaded forLoadProperties:file];
            
            // find out where the file is
            NSString *localPath = [Files pathForFileInBundleWithFilename:filename extension:extension];
            if (localPath != nil) {
                [file setIsInBundle:@(1)];
                [[VPDaoV1 sharedManager] setLoadStatus:LoadStatusDownloaded forLoadProperties:file];
            }else {
                DLog(@"cant find the file in the bundle");
            }
        }
    }
    return file;
}

+(NSString *)pathForFileInBundleWithFilename:(NSString *)filename extension:(NSString *)extension {
    // add ability for extension to be null and pull the extension off of the filename
    if (extension == nil) {
        return nil;// doesnt do that yet
    }
    NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:extension];
    if(path == nil){
        NSError *error = nil;
        NSString * resourcePath = [[NSBundle mainBundle] resourcePath];
        NSString * documentsPath = [resourcePath stringByAppendingPathComponent:@"Documents"];
        NSArray * directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsPath error:&error];
        DLog(@"%@", directoryContents);
    }
    return path;
}

-(NSString *)bundleFilePath {
    return [Files pathForFileInBundleWithFilename:self.awsFile.filenameInBucket extension:self.awsFile.extension];
}

//+(BOOL)doesFileExist:(NSString *)filePath {
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    if([fileManager fileExistsAtPath:filePath])
//        return YES;
//    
//    return NO;
//}

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



@end




































