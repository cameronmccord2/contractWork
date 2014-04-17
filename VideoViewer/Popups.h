//
//  Popups.h
//  VideoViewer
//
//  Created by Cameron McCord on 4/17/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Languages, Medias;

@interface Popups : NSManagedObject

@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSString * popupText;
@property (nonatomic, retain) NSNumber * mediaId;
@property (nonatomic, retain) NSNumber * languageId;
@property (nonatomic, retain) NSNumber * startTime;
@property (nonatomic, retain) NSNumber * endTime;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSNumber * bucketId;
@property (nonatomic, retain) NSString * filenameInBucket;
@property (nonatomic, retain) NSString * extension;
@property (nonatomic, retain) Medias *media;
@property (nonatomic, retain) Languages *language;

@end
