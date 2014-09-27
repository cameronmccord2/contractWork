//
//  SubPopups.h
//  VideoViewer
//
//  Created by Cameron McCord on 9/27/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "AwsFile.h"

@class Popups;

@interface SubPopups : AwsFile

@property (nonatomic, retain) NSNumber * endTime;
@property (nonatomic, retain) NSNumber * subPopupId;
@property (nonatomic, retain) NSNumber * popupId;
@property (nonatomic, retain) NSString * popupText;
@property (nonatomic, retain) NSNumber * startTime;
@property (nonatomic, retain) Popups *popup;

@end
