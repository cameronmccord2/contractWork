//
//  AwsFile.h
//  VideoViewer
//
//  Created by Cameron McCord on 9/27/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Files;

@interface AwsFile : NSManagedObject

@property (nonatomic, retain) NSNumber * bucketId;
@property (nonatomic, retain) NSString * bucketName;
@property (nonatomic, retain) NSString * extension;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSString * filenameInBucket;
@property (nonatomic, retain) Files *file;

@end
