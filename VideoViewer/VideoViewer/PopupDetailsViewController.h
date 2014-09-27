//
//  PopupDetailsViewController.h
//  VideoViewer
//
//  Created by Cameron McCord on 4/17/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "VPDaoV1.h"

@interface PopupDetailsViewController : UIViewController<AVAudioPlayerDelegate, NSFetchedResultsControllerDelegate>

@property(nonatomic, strong)Popups *popup;
@property(nonatomic, strong)UIScrollView *scrollView;
@property(nonatomic, strong)UISlider *slider;
@property(nonatomic, strong)AVAudioPlayer *player;
@property(nonatomic, strong)NSTimer *sliderTimer;
@property(nonatomic, strong)UILabel *descriptionLabel;
@property(nonatomic, strong)NSData *fileData;
@property(nonatomic, strong)UIView *sliderBackground;
@property(nonatomic, strong)UIButton *playPauseButton;
@property(nonatomic, strong)UIImageView *imageView;

#pragma mark Core Data Stuff
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property(nonatomic, strong)NSString *entity;
@property(nonatomic, strong)NSString *sortKey;
@property(nonatomic, strong)NSPredicate *predicate;
@property(nonatomic, strong)NSMutableDictionary *variablesDictionary;

@property(nonatomic, strong)SubPopups *currentSubPopup;

-(instancetype)initWithPopup:(Popups *)popup context:(NSManagedObjectContext *)managedObjectContext;

@end
