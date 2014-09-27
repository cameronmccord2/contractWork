//
//  VideoListTableViewController.h
//  VideoViewer
//
//  Created by Cameron McCord on 4/16/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VPDaoV1.h"

@interface VideoListTableViewController : UITableViewController

-(instancetype)initWithContext:(NSManagedObjectContext *)managedObjectContext;

@end
