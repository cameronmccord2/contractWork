//
//  Files+Extras.h
//  VPPlusBook
//
//  Created by Cameron McCord on 9/4/14.
//  Copyright (c) 2014 MTC. All rights reserved.
//

#import "Files.h"

@interface Files (Extras)

+(void)deleteAllFilesInContext:(NSManagedObjectContext *)context;
+(NSString *)uniqueFilename;
+(NSString *)documentPath;
+(Files *)getFileForRemoteUrl:(NSString *)remoteUrl fromContext:(NSManagedObjectContext *)context;
+(NSString *)cdnUrlForPartialUrl:(NSString *)partialUrl;
+(Files *)newFileForRemoteFilename:(NSString *)remoteFilename type:(NSString *)type inContext:(NSManagedObjectContext *)context;
+(NSArray *)getAllFilesWithLoadStatus:(NSString *)loadStatus inContext:(NSManagedObjectContext *)context;
+(NSString *)pathForFileInBundleWithFilename:(NSString *)filename extension:(NSString *)extension;
+(BOOL)doesFileExist:(NSString *)filePath;
+(Files *)newFileForFilename:(NSString *)filename extension:(NSString *)extension intoContext:(NSManagedObjectContext *)context;


-(NSString *)bundleFilePath;


@end
