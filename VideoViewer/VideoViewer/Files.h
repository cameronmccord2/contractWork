//
//  Files.h
//  VideoViewer
//
//  Created by Cameron McCord on 9/27/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "LoadProperties.h"

@class AwsFile;

@interface Files : LoadProperties

@property (nonatomic, retain) NSString * localUrl;
@property (nonatomic, retain) NSString * remoteUrl;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSNumber * isInBundle;
@property (nonatomic, retain) AwsFile *awsFile;

@end
