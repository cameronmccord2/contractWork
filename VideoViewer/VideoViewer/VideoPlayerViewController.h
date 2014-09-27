//
//  VideoPlayerViewController.h
//  VideoViewer
//
//  Created by Cameron McCord on 4/17/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "Medias.h"
#import "VPDaoV1.h"
#import "PopupDetailsViewController.h"

@interface VideoPlayerViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, strong)UITableView *tableView;

- (id)initWithContext:(NSManagedObjectContext *)context media:(Medias *)media;

@end
