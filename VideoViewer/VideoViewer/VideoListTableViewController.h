//
//  VideoListTableViewController.h
//  VideoViewer
//
//  Created by Cameron McCord on 4/16/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VPDaoV1.h"

@interface VideoListTableViewController : UITableViewController<NSFetchedResultsControllerDelegate, VPDaoV1DelegateProtocol, UIAlertViewDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, strong)UIAlertView *alert;

-(instancetype)initWithContext:(NSManagedObjectContext *)context;

@end
