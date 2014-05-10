//
//  SubPopups.h
//  VideoViewer
//
//  Created by Cameron McCord on 5/10/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Popups;

@interface SubPopups : NSManagedObject

@property (nonatomic, retain) NSNumber * bucketId;
@property (nonatomic, retain) NSString * bucketName;
@property (nonatomic, retain) NSString * popupText;
@property (nonatomic, retain) NSNumber * endTime;
@property (nonatomic, retain) NSNumber * startTime;
@property (nonatomic, retain) NSString * extension;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSString * filenameInBucket;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSNumber * popupId;
@property (nonatomic, retain) Popups *popup;

@end
