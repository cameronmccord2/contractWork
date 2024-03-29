//
//  Medias.h
//  VideoViewer
//
//  Created by Cameron McCord on 9/27/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "AwsFile.h"

@class Captions, Languages, Popups;

@interface Medias : AwsFile

@property (nonatomic, retain) NSNumber * audioLanguageId;
@property (nonatomic, retain) NSNumber * mediaId;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSSet *captions;
@property (nonatomic, retain) Languages *language;
@property (nonatomic, retain) NSSet *popups;
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
