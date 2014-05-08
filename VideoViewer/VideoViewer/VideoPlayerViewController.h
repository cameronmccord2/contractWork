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

@interface VideoPlayerViewController : UIViewController<VPDaoV1DelegateProtocol, NSFetchedResultsControllerDelegate, PopupDetailsViewControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, strong)Medias *media;
@property(nonatomic, strong)UIScrollView *scrollView;
@property(nonatomic, strong)MPMoviePlayerController *player;
@property(nonatomic, strong)NSString *videoPath;
@property(nonatomic, strong)NSTimer *timer;
@property(nonatomic, strong)UILabel *captionLabel;
@property(nonatomic, strong)NSString *predicateString;
@property(nonatomic, strong)NSPredicate *predicate;
@property(nonatomic, strong)NSMutableDictionary *variablesDictionary;
@property(nonatomic, strong)NSMutableArray *currentPopups;
@property(nonatomic, strong)NSMutableArray *currentCaptions;
@property(nonatomic, strong)NSMutableArray *currentPopupButtons;
@property(nonatomic, strong)NSMutableArray *currentCaptionLabels;
@property(nonatomic, strong)NSString *entity;
@property(nonatomic, strong)NSString *sortKey;
@property(nonatomic, strong)UIProgressView *progressView;
@property(nonatomic, strong)UILabel *loadingLabel;
@property(nonatomic, weak)NSURLConnectionWithExtras *connection;
@property(nonatomic, strong)NSMutableArray *spots;
@property(nonatomic)NSInteger portraitOrLandscape;

- (id)initWithContext:(NSManagedObjectContext *)context media:(Medias *)media;
-(void)popupTapped:(id)sender;


#pragma mark - PopupDetailsViewControllerDelegate functions
-(void)willReturn;

@end
