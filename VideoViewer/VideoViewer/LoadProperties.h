//
//  LoadProperties.h
//  VideoViewer
//
//  Created by Cameron McCord on 9/27/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface LoadProperties : NSManagedObject

@property (nonatomic, retain) NSNumber * attempts;
@property (nonatomic, retain) NSString * loadStatus;
@property (nonatomic, retain) NSDate * loadStatusChanged;

@end
