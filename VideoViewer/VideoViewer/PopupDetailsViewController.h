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

@protocol PopupDetailsViewControllerDelegate <NSObject>

@optional

-(void)willReturn;

@end

@interface PopupDetailsViewController : UIViewController<VPDaoV1DelegateProtocol, AVAudioPlayerDelegate, NSFetchedResultsControllerDelegate>

@property(nonatomic, strong)Popups *popup;
@property(nonatomic, strong)UIScrollView *scrollView;
@property(nonatomic, strong)UISlider *slider;
@property(nonatomic, strong)AVAudioPlayer *player;
@property(nonatomic, strong)NSTimer *sliderTimer;
@property(nonatomic, strong)UILabel *descriptionLabel;
@property(nonatomic, strong)NSData *fileData;
@property(nonatomic, weak)id<PopupDetailsViewControllerDelegate> delegate;
@property(nonatomic, strong)UIView *sliderBackground;
@property(nonatomic, strong)UIButton *playPauseButton;
@property(nonatomic, strong)UIImageView *imageView;

#pragma mark Core Data Stuff
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property(nonatomic, weak)NSManagedObjectContext *managedObjectContext;
@property(nonatomic, strong)NSString *entity;
@property(nonatomic, strong)NSString *sortKey;
@property(nonatomic, strong)NSPredicate *predicate;
@property(nonatomic, strong)NSMutableDictionary *variablesDictionary;

-(instancetype)initWithPopup:(Popups *)popup context:(NSManagedObjectContext *)context;
-(void)setWillReturnDelegate:(id<PopupDetailsViewControllerDelegate>)delegate;

@end
