//
//  VideoPlayerViewController.m
//  VideoViewer
//
//  Created by Cameron McCord on 4/17/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import "VideoPlayerViewController.h"
#import "Captions.h"
#import "Popups+Extras.h"
#import "Files+Extras.h"
#import "HighlightButton.h"


@interface VideoPlayerViewController ()

@end

/*
 -have the caption box grow upward so it doesn't cover the controls, have bottom edge against the controls
 - make popups work
 */

@implementation VideoPlayerViewController{
    NSManagedObjectContext *context;
    Medias *media;
    MPMoviePlayerController *player;
    NSArray *popups;
    NSArray *captions;
    Captions *currentCaption;
    Popups *currentPopup;
    UILabel *captionLabel;
    BOOL firstTimeOnPage;
    NSTimer *timer;
}

- (id)initWithContext:(NSManagedObjectContext *)managedObjectContext media:(Medias *)newMedia{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        context = managedObjectContext;
        media = newMedia;
        popups = [media.popups sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES]]];
        captions = [media.captions sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES]]];
        self.title = media.name;
        firstTimeOnPage = YES;
    }
    return self;
}

enum {
    WasLandscape, WasPortrait, PopupButtonTag
};

- (void)viewDidLoad{
    [super viewDidLoad];
    
    [self registerForVideoPlayerNotifications];
    
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.tableView = [UITableView new];
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.tableView setSeparatorColor:[UIColor clearColor]];
    [self.view addSubview:self.tableView];
    
    // setup the video player
    [self registerForVideoPlayerNotifications];
    
    NSString *videoPath = media.file.localUrl;
    if ([media.file.isInBundle boolValue])
        videoPath = [media.file bundleFilePath];
    
    player = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:videoPath]];
    player.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:player.view];
    
    // Setup caption label
    captionLabel = [UILabel new];
    [captionLabel setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5f]];
    [captionLabel setFont:[self getCaptionFont]];
    captionLabel.numberOfLines = 0;
    captionLabel.preferredMaxLayoutWidth = 1000;// check this
    captionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    captionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [captionLabel setTextAlignment:NSTextAlignmentCenter];
    [captionLabel setTextColor:[UIColor whiteColor]];
    [player.view addSubview:captionLabel];
    
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(captionLabel);
    [player.view addConstraint:[NSLayoutConstraint constraintWithItem:captionLabel
                                                            attribute:NSLayoutAttributeWidth
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:player.view
                                                            attribute:NSLayoutAttributeWidth
                                                           multiplier:0.8f
                                                             constant:0]];
    
    [player.view addConstraint:[NSLayoutConstraint constraintWithItem:captionLabel
                                                            attribute:NSLayoutAttributeBottom
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:player.view
                                                            attribute:NSLayoutAttributeBottom
                                                           multiplier:0.7f
                                                             constant:0]];
    
    [player.view addConstraint:[NSLayoutConstraint constraintWithItem:captionLabel
                                                            attribute:NSLayoutAttributeCenterX
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:player.view
                                                            attribute:NSLayoutAttributeCenterX
                                                           multiplier:1.0f
                                                             constant:0]];
    
    
//    [player.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[captionLabel]-200-|"
//                                                                        options:NSLayoutFormatAlignAllCenterX
//                                                                        metrics:0
//                                                                          views:viewsDictionary]];
    
//    [player.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[captionLabel]|"
//                                                                        options:NSLayoutFormatAlignAllCenterX
//                                                                        metrics:0
//                                                                          views:viewsDictionary]];
    
    UIView *playerView = player.view;
    viewsDictionary = NSDictionaryOfVariableBindings(_tableView, playerView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_tableView]-[playerView]|"
                                                                      options:NSLayoutFormatAlignAllCenterY
                                                                      metrics:0
                                                                        views:viewsDictionary]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:playerView
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:0.3f
                                                           constant:0]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_tableView]|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:viewsDictionary]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[playerView]|"
                                                                      options:NSLayoutFormatAlignAllCenterY
                                                                      metrics:0
                                                                        views:viewsDictionary]];
}

-(void)viewWillDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopTimer];
    [player pause];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    if (player.playbackState == MPMoviePlaybackStatePlaying) {
        [player pause];
    }
    [self stopTimer];
    player = nil;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self registerForVideoPlayerNotifications];
    
    if(firstTimeOnPage){
        [player play];// we dont want this to happen when returning from the details
        firstTimeOnPage = NO;
    }
}

-(void)stopTimer {
    if([timer isValid])
        [timer invalidate];
    timer = nil;
}



#pragma mark Player Notifications and Functions

- (void)registerForVideoPlayerNotifications{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerStateChanged:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerWillExitFullscreen:) name:MPMoviePlayerWillExitFullscreenNotification object:nil];
}

-(void)moviePlayerWillExitFullscreen:(NSNotification *)notification{
    [self registerForVideoPlayerNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerWillExitFullscreenNotification object:nil];
}

- (void)moviePlayerStateChanged:(NSNotification *)notification{

    switch (player.playbackState) {
        case MPMoviePlaybackStateInterrupted:
            NSLog(@"interrupted");
            [captionLabel setHidden:YES];
            currentCaption = nil;
        
        case MPMoviePlaybackStateStopped:
            NSLog(@"stopped");
            
        case MPMoviePlaybackStatePaused:
            NSLog(@"pause, time: %f, %f", [player currentPlaybackTime], player.duration);
            if ([player currentPlaybackTime] == player.duration || [player currentPlaybackTime] == 0) {
                [captionLabel setText:@""];
                currentCaption = nil;
            }
            
#warning change this so it only takes away the caption at the e
            // stop timers
            if (timer) {
                [timer invalidate];
                timer = nil;
            }
            break;
            
        case MPMoviePlaybackStateSeekingBackward:
            NSLog(@"backward");
        case MPMoviePlaybackStateSeekingForward:
            NSLog(@"forward");
        
        case MPMoviePlaybackStatePlaying:
            NSLog(@"play");
            if ([captionLabel isHidden])
                [captionLabel setHidden:NO];

            if (!timer) {
                timer = [NSTimer scheduledTimerWithTimeInterval:0.033 target:self selector:@selector(timerTick) userInfo:nil repeats:YES];
                [timer fire];
            }
            break;
            
        default:
            break;
    }
}

-(float)currentPlayerTime {
    return player.currentPlaybackTime * 1000;
}

-(void)timerTick {
    [self checkCaptions];
    [self scrollToPopup];
}


#pragma mark Change how screen looks

-(void)scrollToPopup {
    float currentTime = [self currentPlayerTime];
    NSArray *remainingPopups = [popups filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"startTime <= %f AND endTime > %f", currentTime, currentTime]];
    Popups *popup = [[remainingPopups sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES]]] firstObject];
    if (popup == nil)
        return;

    currentPopup = popup;// should only scroll once per popup
    NSUInteger index = [popups indexOfObject:popup];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:index] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    
#warning look into highlighting the cells as they are useful
    // change the highlighting of the cell to indicate they are active
//    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:[popups indexOfObject:popup]]];
//    [cell.contentView setBackgroundColor:[UIColor greenColor]];
}

-(void)checkCaptions{
    
    NSTimeInterval currentTime = [self currentPlayerTime];
    if (currentTime != currentTime)
        currentTime = 0;// some weird nullness?

    NSArray *filteredCaptions = [captions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%f >= startTime AND endTime > %f AND self != %@", currentTime, currentTime, currentCaption]];// start time has passed but end time hasnt so it must be on the screen
    filteredCaptions = [filteredCaptions sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES]]];
    
    Captions *caption = [filteredCaptions firstObject];
    if (caption == nil)
        return;
    currentCaption = caption;
    
    [captionLabel setText:currentCaption.caption];
}


#pragma mark UITableViewDelegate and Datasource Functions

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [player pause];
    
    Popups *popup = [popups objectAtIndex:[indexPath section]];
    PopupDetailsViewController *pdvc = [[PopupDetailsViewController alloc] initWithPopup:popup context:context];
    [self.navigationController pushViewController:pdvc animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 10.0f;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [UIView new];
    [header setBackgroundColor:[UIColor whiteColor]];
    return header;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [popups count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 35.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"myCell"];
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"myCell"];
        
        [self layoutCell:cell];
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

-(void)layoutCell:(UITableViewCell *)cell {
    
    UIColor *backgroundColor = [UIColor colorWithRed:0.094 green:0.609 blue:0.884 alpha:1];
    UIColor *highlightedColor = [UIColor colorWithRed:0.087 green:0.522 blue:0.754 alpha:1];
    
    cell.layer.borderWidth = 1.0;
    cell.layer.masksToBounds = YES;
    cell.layer.cornerRadius = 5.0;
    cell.layer.borderColor = backgroundColor.CGColor;
//    cell.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    
    UILabel *title = [UILabel new];

    
//    button.backgroundColorHighlighted = highlightedColor;
//    button.backgroundColorNormal = [UIColor whiteColor];
//    button.borderColorHighlighted = backgroundColor;
//    button.borderColorNormal = backgroundColor;
    
//    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [title setTextColor:backgroundColor];
#warning have the cell change background colors
    
    [title setBackgroundColor:[UIColor clearColor]];
    
    [title setFont:[self getPopupFont]];
    [title setTextAlignment:NSTextAlignmentCenter];
    [cell.contentView addSubview:title];
    [title setTag:PopupButtonTag];
    
    // autolayout
//    cell.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    UIView *cellView = cell.contentView;
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(title, cellView);
//    [cell.contentView setBackgroundColor:[UIColor blueColor]];
//    [cell setBackgroundColor:[UIColor orangeColor]];
    [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:title
                                                                 attribute:NSLayoutAttributeCenterX
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:cell.contentView
                                                                 attribute:NSLayoutAttributeCenterX
                                                                multiplier:1.0f
                                                                  constant:0]];
    
    [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:title
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:cell.contentView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1.0f
                                                                  constant:0]];
    
//    [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[title]-5-|"
//                                                                 options:NSLayoutFormatAlignAllCenterY
//                                                                 metrics:0
//                                                                   views:viewsDictionary]];
//    [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-3-[title]-3-|"
//                                                                 options:NSLayoutFormatAlignAllCenterX
//                                                                 metrics:0
//                                                                   views:viewsDictionary]];
//    [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:title
//                                                                  attribute:NSLayoutAttributeWidth
//                                                                  relatedBy:NSLayoutRelationEqual
//                                                                     toItem:cell.contentView
//                                                                  attribute:NSLayoutAttributeWidth
//                                                                 multiplier:0.9f
//                                                                   constant:0]];
//    [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[cellView]-|"
//                                                                 options:NSLayoutFormatAlignAllCenterY
//                                                                 metrics:0
//                                                                   views:viewsDictionary]];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Popups *popup = [popups objectAtIndex:[indexPath section]];
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:PopupButtonTag];
    [label setText:popup.displayName];
}


#pragma mark View Functions

-(UIFont *)getCaptionFont{
    if([self isIpad])
        return [UIFont systemFontOfSize:28.0f];
    return [UIFont systemFontOfSize:14.0f];
}

-(UIFont *)getPopupFont{
    if([self isIpad])
        return [UIFont systemFontOfSize:18.0f];
    return [UIFont systemFontOfSize:18.0f];
}

-(BOOL)isIpad{
    if([[[UIDevice currentDevice]model] isEqualToString:@"iPad"] || [[[UIDevice currentDevice] model] isEqualToString:@"iPad Simulator"])
        return YES;
    return NO;
}

@end


























