//
//  Popups.h
//  VideoViewer
//
//  Created by Cameron McCord on 5/10/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Languages, Medias, SubPopups;

@interface Popups : NSManagedObject

@property (nonatomic, retain) NSNumber * bucketId;
@property (nonatomic, retain) NSString * bucketName;
@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSNumber * endTime;
@property (nonatomic, retain) NSString * extension;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSString * filenameInBucket;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSNumber * languageId;
@property (nonatomic, retain) NSNumber * mediaId;
@property (nonatomic, retain) NSString * popupText;
@property (nonatomic, retain) NSNumber * startTime;
@property (nonatomic, retain) Languages *language;
@property (nonatomic, retain) Medias *media;
@property (nonatomic, retain) NSSet *subPopups;
@end

@interface Popups (CoreDataGeneratedAccessors)

- (void)addSubPopupsObject:(SubPopups *)value;
- (void)removeSubPopupsObject:(SubPopups *)value;
- (void)addSubPopups:(NSSet *)values;
- (void)removeSubPopups:(NSSet *)values;

@end
