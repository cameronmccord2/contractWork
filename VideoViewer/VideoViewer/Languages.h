//
//  Languages.h
//  VideoViewer
//
//  Created by Cameron McCord on 4/17/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Captions, Medias, Popups;

@interface Languages : NSManagedObject

@property (nonatomic, retain) NSString * code1;
@property (nonatomic, retain) NSString * code2;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSString * mtcId;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * nativeName;
@property (nonatomic, retain) NSSet *captions;
@property (nonatomic, retain) NSSet *medias;
@property (nonatomic, retain) NSSet *popups;
@end

@interface Languages (CoreDataGeneratedAccessors)

- (void)addCaptionsObject:(Captions *)value;
- (void)removeCaptionsObject:(Captions *)value;
- (void)addCaptions:(NSSet *)values;
- (void)removeCaptions:(NSSet *)values;

- (void)addMediasObject:(Medias *)value;
- (void)removeMediasObject:(Medias *)value;
- (void)addMedias:(NSSet *)values;
- (void)removeMedias:(NSSet *)values;

- (void)addPopupsObject:(Popups *)value;
- (void)removePopupsObject:(Popups *)value;
- (void)addPopups:(NSSet *)values;
- (void)removePopups:(NSSet *)values;

@end
