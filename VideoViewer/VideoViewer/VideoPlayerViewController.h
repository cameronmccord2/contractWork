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

@interface VideoPlayerViewController : UIViewController<VPDaoV1DelegateProtocol>

@property(nonatomic, strong)NSManagedObjectContext *managedObjectContext;
@property(nonatomic, strong)Medias *media;
@property(nonatomic, strong)UIScrollView *scrollView;
@property(nonatomic, strong)MPMoviePlayerController *player;
@property(nonatomic, strong)NSString *videoPath;

- (id)initWithContext:(NSManagedObjectContext *)context media:(Medias *)media;

@end
