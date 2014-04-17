//
//  Captions.h
//  VideoViewer
//
//  Created by Cameron McCord on 4/17/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Languages, Medias;

@interface Captions : NSManagedObject

@property (nonatomic, retain) NSString * caption;
@property (nonatomic, retain) NSNumber * endTime;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSNumber * languageId;
@property (nonatomic, retain) NSNumber * mediaId;
@property (nonatomic, retain) NSNumber * startTime;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) Languages *language;
@property (nonatomic, retain) Medias *media;

@end
