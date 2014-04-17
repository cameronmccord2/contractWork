//
//  Medias.h
//  VideoViewer
//
//  Created by Cameron McCord on 4/17/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Captions, Languages, Popups;

@interface Medias : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSString * filenameInBucket;
@property (nonatomic, retain) NSNumber * audioLanguageId;
@property (nonatomic, retain) NSNumber * bucketId;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSString * extension;
@property (nonatomic, retain) NSSet *captions;
@property (nonatomic, retain) NSSet *popups;
@property (nonatomic, retain) Languages *language;
@end

@interface Medias (CoreDataGeneratedAccessors)

- (void)addCaptionsObject:(Captions *)value;
- (void)removeCaptionsObject:(Captions *)value;
- (void)addCaptions:(NSSet *)values;
- (void)removeCaptions:(NSSet *)values;

- (void)addPopupsObject:(Popups *)value;
- (void)removePopupsObject:(Popups *)value;
- (void)addPopups:(NSSet *)values;
- (void)removePopups:(NSSet *)values;

@end
