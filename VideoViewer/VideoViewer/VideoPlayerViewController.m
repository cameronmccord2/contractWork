//
//  VideoPlayerViewController.m
//  VideoViewer
//
//  Created by Cameron McCord on 4/17/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import "VideoPlayerViewController.h"
#import "Captions.h"
#import "Popups.h"
#import "HighlightButton.h"


@interface VideoPlayerViewController ()

@end

/*
 -have the caption box grow upward so it doesn't cover the controls, have bottom edge against the controls
 - make popups work
 */

@implementation VideoPlayerViewController

- (id)initWithContext:(NSManagedObjectContext *)context media:(Medias *)media{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.managedObjectContext = context;
        self.media = media;
        self.title = media.name;
        self.currentCaptions = [[NSMutableArray alloc] initWithCapacity:1];
        self.currentPopups = [[NSMutableArray alloc] initWithCapacity:3];
        self.currentCaptionLabels = [[NSMutableArray alloc] initWithCapacity:1];
        self.currentPopupButtons = [[NSMutableArray alloc] initWithCapacity:10];
        self.spots = [@[@(0), @(0), @(0)] mutableCopy];
        self.automaticallyAdjustsScrollViewInsets = NO;
        
        self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 70, [self screenWidth], 30)];
        [self.progressView setProgress:0.0f];
        
        [self registerForOrientationChanges];
    }
    return self;
}

enum {
    WasLandscape, WasPortrait
};

- (void)viewDidLoad{
    [super viewDidLoad];
    [[VPDaoV1 sharedManager] getVideoData:self media:self.media];
}

-(void)viewWillDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    [self.connection cancel];
    [self.timer invalidate];
    self.timer = nil;
    [self.player pause];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)filePathForRequestedFile:(NSString *)filePath{
    self.videoPath = filePath;
    
    [self generatePopupList];
    
    // Core Data init stuff
    self.predicateString = [NSString stringWithFormat:@"(mediaId == %@) AND ($currentTime < endTime) AND (startTime =< $currentTime) AND NOT(id IN $ids)", self.media.id];//@"NOT (id IN $currentIds) && startTime < $currentTime && endTime > $currentTime"
    self.predicate = [NSPredicate predicateWithFormat:self.predicateString];
    self.variablesDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:0,@"currentTime", [[NSMutableArray alloc] init],@"ids", nil];
    
    [self buildView];
}

-(void)videoDataThen:(NSURLConnectionWithExtras *)connection progress:(NSProgress *)progress{
    if (!self.scrollView) {
        self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, [self view].frame.size.width, [self view].frame.size.height)];
        [self.scrollView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
        [self.scrollView setBackgroundColor:[UIColor whiteColor]];
        [self makeLabelWithText:@"Loading your video" frame:CGRectMake(0, 100, [self screenWidth], 30) view:self.scrollView backgroundColor:[UIColor redColor] alignToCenter:YES addToList:self.currentCaptionLabels fontColor:[UIColor blackColor] font:[UIFont systemFontOfSize:[UIFont systemFontSize]] sizeToFit:NO];
        [self.progressView setProgress:progress.fractionCompleted];
        [self.scrollView addSubview:self.progressView];
        [self.view addSubview:self.scrollView];
        self.connection = connection;
    }
    
    [self.progressView setProgress:progress.fractionCompleted];
}

- (void)registerForVideoPlayerNotifications{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerStateChanged:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerWillExitFullscreen:) name:MPMoviePlayerWillExitFullscreenNotification object:nil];
}

-(void)registerForOrientationChanges{
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(orientationChanged:)
     name:UIDeviceOrientationDidChangeNotification
     object:[UIDevice currentDevice]];
}

-(void)willReturn{
    [self registerForVideoPlayerNotifications];
    [self registerForOrientationChanges];
    if(([self isLandscape] && self.portraitOrLandscape == WasPortrait) || (![self isLandscape] && self.portraitOrLandscape == WasLandscape))
        [self fixEverything];
//    [self.player play];
}

-(void)moviePlayerWillExitFullscreen:(NSNotification *)notification{
    [self registerForVideoPlayerNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerWillExitFullscreenNotification object:nil];
}

- (void)moviePlayerStateChanged:(NSNotification *)notification{

    switch (self.player.playbackState) {
        case MPMoviePlaybackStateInterrupted:
            NSLog(@"interrupted");
            [self.captionLabel removeFromSuperview];
            self.captionLabel = nil;
            // remove onscreen items? maybe only a few of the states remove them?
//            break;
        
        case MPMoviePlaybackStateStopped:
            NSLog(@"stopped");
        case MPMoviePlaybackStatePaused:
            NSLog(@"pause");
            // stop timers
            if (self.timer) {
                [self.timer invalidate];
                self.timer = nil;
            }
            break;
            
        case MPMoviePlaybackStateSeekingBackward:
            NSLog(@"backward");
        case MPMoviePlaybackStateSeekingForward:
            NSLog(@"forward");
        
        case MPMoviePlaybackStatePlaying:
            NSLog(@"play");
            if (!self.timer) {
                self.timer = [NSTimer scheduledTimerWithTimeInterval:0.033 target:self selector:@selector(checkCaptionsPopups) userInfo:nil repeats:YES];
                [self.timer fire];
            }
            break;
            
        default:
            break;
    }
}

-(void)checkCaptionsPopups{
    [self checkCaptions];
}

-(void)checkCaptions{
    NSError *error = nil;
    NSTimeInterval currentTime = self.player.currentPlaybackTime * 1000;
    if (currentTime != currentTime)
        currentTime = 0;
    
    [self.captionLabel setText:[NSString stringWithFormat:@"%f", currentTime]];
    [self.variablesDictionary setObject:@[] forKey:@"ids"];
    
    [self.variablesDictionary setObject:@(currentTime) forKey:@"currentTime"];
    self.sortKey = @"startTime";
    self.entity = @"Captions";
    self.fetchedResultsController = nil;
    [self fetchedResultsController];
    [self.fetchedResultsController performFetch:&error];
    if (error)
        NSLog(@"error getting captions: %@", [error localizedDescription]);
    
    if ([self.fetchedResultsController.fetchedObjects count]) {
        
        NSInteger yValue = [self getCaptionsStartingY];// TODO change this to be the starting, whatever that may be
        // clear out current lists
        [self.currentCaptions removeAllObjects];
        for (UILabel *l in self.currentCaptionLabels) {
            [l removeFromSuperview];
        }
        
        for (Captions *c in [self.fetchedResultsController fetchedObjects]) {
            [self.currentCaptions addObject:c];
            
            UIColor *captionBackground = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5f];
            UIFont *labelFont = [self getCaptionFont];
            
            yValue = [self makeLabelWithText:c.caption frame:[self getCaptionFrameForString:c.caption yValue:yValue topPad:0 font:labelFont] view:self.scrollView backgroundColor:captionBackground alignToCenter:YES addToList:self.currentCaptionLabels fontColor:[UIColor whiteColor] font:labelFont sizeToFit:YES];
        }
    }
    self.fetchedResultsController = nil;
}

-(CGRect)getCaptionFrameForString:(NSString *)title yValue:(NSInteger)yValue topPad:(NSInteger)topPad font:(UIFont *)font{
    
    NSInteger requiredWidth = [self getVideoPlayerFrame].size.width - ([self getVideoPlayerFrame].size.width * 0.1f);
    
     CGRect stringFrame = [title boundingRectWithSize:CGSizeMake(requiredWidth, 1000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : font} context:nil];
    int requiredHeight = stringFrame.size.height * 1.5f;
    
    int leftPad = ([self getVideoPlayerFrame].size.width - requiredWidth) / 2.0f;
    if([self isLandscape] && [self.currentPopups count] > 0)
        leftPad = [self getPopupScrollViewFrame].size.width + ([self getVideoPlayerFrame].size.width - requiredWidth) / 2.0f;
    return CGRectMake(leftPad, yValue + topPad, requiredWidth, requiredHeight);
}

-(void)popupTapped:(HighlightButton *)sender{
    [self.player pause];
    self.portraitOrLandscape = WasPortrait;
    
    if([self isLandscape])
        self.portraitOrLandscape = WasLandscape;
    NSLog(@"in tapped");
    for (Popups *p in self.currentPopups) {
        NSLog(@"looping, %@, %@", sender.titleLabel.text, p.displayName);
        if ([sender.titleLabel.text isEqualToString:p.displayName]) {
            NSLog(@"running popup");
            PopupDetailsViewController *pdvc = [[PopupDetailsViewController alloc] initWithPopup:p context:self.managedObjectContext];
            [pdvc setWillReturnDelegate:self];
            [self.navigationController pushViewController:pdvc animated:YES];
            break;
        }
    }
}

-(void)buildView{
    self.scrollView = [[UIScrollView alloc] initWithFrame:[self getScrollViewFrame]];
    [self.scrollView setContentSize:[self getScrollViewContentSize]];
    [self.scrollView setContentInset:[self getScrollViewContentInsets]];
    [self.scrollView setBackgroundColor:[UIColor whiteColor]];
    int yValue = 0;
    [self registerForVideoPlayerNotifications];
    
    
    self.player = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:self.videoPath]];
    
    self.player.view.frame = [self getVideoPlayerFrame];
    yValue += 3000;
    [self.scrollView setBackgroundColor:[UIColor blackColor]];
    [self.scrollView addSubview:self.player.view];
    [self.scrollView setFrame:[self getScrollViewFrame]];
    [self.scrollView addSubview:self.popupScrollView];
    [self.view addSubview:self.scrollView];
    [self.player play];
}

-(void)generatePopupList{
    self.predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"mediaId == %@", self.media.id]];
    self.entity = @"Popups";
    self.sortKey = @"startTime";
    NSError *error = nil;
    [self fetchedResultsController];
    [self.fetchedResultsController performFetch:&error];
    if(error){
        NSLog(@"get popups list error: %@", [error localizedDescription]);
    }else{
        
        NSInteger yValue = 0;
        
        UIColor *backgroundColor = [UIColor colorWithRed:0.094 green:0.609 blue:0.884 alpha:1];
        UIColor *highlightedColor = [UIColor colorWithRed:0.087 green:0.522 blue:0.754 alpha:1];
        SEL selector = @selector(popupTapped:);
        
        if([self.fetchedResultsController.fetchedObjects count] > 0){
            self.popupScrollView = [[UIScrollView alloc] initWithFrame:[self getPopupScrollViewFrame]];
            [self.popupScrollView setBackgroundColor:[UIColor whiteColor]];
        }
        
        for (Popups *p in self.fetchedResultsController.fetchedObjects) {
            [self.currentPopups addObject:p];
            
            HighlightButton *button = [[HighlightButton alloc] initWithFrame:[self getPopupButtonFrameWithStartingY:yValue addTopPad:YES]];
            button.layer.borderWidth = 1.0;
            button.layer.masksToBounds = YES;
            button.layer.cornerRadius = 5.0;
            button.layer.borderColor = backgroundColor.CGColor;
            
            button.backgroundColorHighlighted = highlightedColor;
            button.backgroundColorNormal = [UIColor whiteColor];
            button.borderColorHighlighted = backgroundColor;
            button.borderColorNormal = backgroundColor;
            
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
            [button setTitleColor:backgroundColor forState:UIControlStateNormal];
            
            [button setBackgroundColor:[UIColor whiteColor]];
            
            [button setTitle:p.displayName forState:UIControlStateNormal];
            [button setTag:[p.id intValue]];
            [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
            [[button titleLabel] setFont:[self getPopupFont]];
            
            [self.popupScrollView addSubview:button];
            [self.currentPopupButtons addObject:button];

            yValue = button.frame.size.height + button.frame.origin.y;
        }
        
        if([self.fetchedResultsController.fetchedObjects count] > 0)
            [self.popupScrollView setContentSize:CGSizeMake(self.popupScrollView.frame.size.width, yValue)];
    }
}

-(CGRect)getPopupButtonFrameWithStartingY:(NSInteger)y addTopPad:(BOOL)addTopPad{
    int xMargin = 5;
    int xValue = 0;
    int width = [self getPopupScrollViewFrame].size.width;
    if([self isIpad] && ![self isLandscape]){
        width = 300;
        xValue = ([self getPopupScrollViewFrame].size.width - width) / 2;
    }
    int height = 30;
    int topPad = 3;
    if([self isIpad])
        topPad = 10;
    if(!addTopPad)
        topPad = 0;
    return CGRectMake(xValue + xMargin, y + topPad, width - xMargin*2, height);
}

-(BOOL)isLandscape{
    return UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
}

- (void) orientationChanged:(NSNotification *)note{
    UIDevice * device = note.object;
    switch(device.orientation){
            
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationPortraitUpsideDown:// move popups up or down depending on where they currently are and where they need to be when it rotates
        case UIDeviceOrientationLandscapeLeft:
        case UIDeviceOrientationLandscapeRight:
            [self fixEverything];
            break;
            
        default:
            break;
    };
}

-(void)fixEverything{
    [self.scrollView setContentSize:[self getScrollViewContentSize]];
    [self.scrollView setFrame:[self getScrollViewFrame]];
    [self.player.view setFrame:[self getVideoPlayerFrame]];
    [self.scrollView setContentInset:[self getScrollViewContentInsets]];
    [self fixCurrentPopups];
    [self fixCurrentCaptions];
}

-(NSInteger)getCaptionsStartingY{
    if([self isIpad]){
        if([self isLandscape])
            return 468;
        else
            return 400;
    }
    if([self isLandscape])
        return 160;
    return 120;
}

-(UIFont *)getCaptionFont{
    if([self isIpad])
        return [UIFont systemFontOfSize:18.0f];
    return [UIFont systemFontOfSize:14.0f];
}

-(UIFont *)getPopupFont{
    if([self isIpad])
        return [UIFont systemFontOfSize:18.0f];
    return [UIFont systemFontOfSize:18.0f];
}

-(void)fixCurrentPopups{
    [self.popupScrollView setFrame:[self getPopupScrollViewFrame]];
    int val = 240;
    if(![self isLandscape])
        val = -240;
    for (UIButton *b in self.currentPopupButtons) {
        [b setFrame:[self getPopupButtonFrameWithStartingY:b.frame.origin.y addTopPad:NO]];
        [self.popupScrollView setContentSize:CGSizeMake([self getPopupScrollViewFrame].size.width, b.frame.origin.y + b.frame.size.height)];
    }
}

-(void)fixCurrentCaptions{
    for (UILabel *l in self.currentCaptionLabels) {
        [l setFrame:[self getCaptionFrameForString:l.text yValue:[self getCaptionsStartingY] topPad:0 font:l.font]];
    }
}

-(UIEdgeInsets)getScrollViewContentInsets{
    if([self isLandscape])
        return UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    return UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
}

-(CGRect)getVideoPlayerFrame{
    NSInteger heightAdjust = 0;
    if([self isIpad]){
        if([self isLandscape])
            heightAdjust = 435;
        else
            heightAdjust = 320;
    }
    if([self isLandscape]){
        if([self.currentPopups count] > 0)
            return CGRectMake([self getPopupScrollViewFrame].size.width, -30, [self getScrollViewFrame].size.width - [self getPopupScrollViewFrame].size.width, 300 + heightAdjust);// -30, why?
        else
            return CGRectMake(0, 0, [self getScrollViewFrame].size.width, [self getScrollViewFrame].size.height);
    }
    return CGRectMake(0, 0, [self getScrollViewFrame].size.width, 200 + heightAdjust);
    
}

-(CGRect)getScrollViewFrame{
    int topPad = [self getNavBarHeight];
    return CGRectMake(0, topPad, [self screenWidth], [self screenHeight] - topPad);
}

-(CGRect)getPopupScrollViewFrame{
    int landscapeWidth = 200;
    if([self isIpad])
        landscapeWidth += 100;
    if([self isLandscape])
        return CGRectMake(0, 0, landscapeWidth, [self getScrollViewFrame].size.height);
    return CGRectMake(0, [self getVideoPlayerFrame].size.height, [self getScrollViewFrame].size.width, [self getScrollViewFrame].size.height - [self getVideoPlayerFrame].size.height);
}

-(CGSize)getScrollViewContentSize{
    return [self getScrollViewFrame].size;
}

-(NSInteger)popupStartingY{
    if([self isLandscape])
        return 10;
    return 250;
}

-(int)getNavBarHeight{
    if([self isIpad])
        return 64;
    if([self isLandscape])
        return 52;
    return 56;
}

-(NSInteger)screenWidth{
    if([self isLandscape])
        return [UIScreen mainScreen].bounds.size.height;
    return [UIScreen mainScreen].bounds.size.width;
}

-(NSInteger)screenHeight{
    if([self isLandscape])
        return [UIScreen mainScreen].bounds.size.width;
    return [UIScreen mainScreen].bounds.size.height;
}

-(BOOL)isIphone{
    if([[[UIDevice currentDevice]model] isEqualToString:@"iPhone"] || [[[UIDevice currentDevice] model] isEqualToString:@"iPhone Simulator"])
        return YES;
    return NO;
}

-(BOOL)isIpad{
    if([[[UIDevice currentDevice]model] isEqualToString:@"iPad"] || [[[UIDevice currentDevice] model] isEqualToString:@"iPad Simulator"])
        return YES;
    return NO;
}

-(NSInteger)makeLabelWithText:(NSString *)text frame:(CGRect)frame view:(UIScrollView *)view backgroundColor:(UIColor *)color alignToCenter:(BOOL)alignToCenter addToList:(NSMutableArray *)array fontColor:(UIColor *)fontColor font:(UIFont *)font sizeToFit:(BOOL)sizeToFit{
    UILabel *title = [[UILabel alloc] initWithFrame:frame];
    [title setBackgroundColor:color];
    [title setFont:font];
    [title setTextColor:fontColor];
    title.numberOfLines = 0;
    [title setText:text];
    if (alignToCenter) {
        [title setTextAlignment:NSTextAlignmentCenter];
        //        [title alignCenterXWithView:view predicate:nil];
    }
    if (array)
        [array addObject:title];
    
    [view addSubview:title];
    if(sizeToFit){
        [title sizeToFit];
        [title setFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, title.frame.size.height + 10)];
    }
    return frame.size.height + frame.origin.y;
}

-(NSInteger)makeUIButtonWithTitle:(NSString *)title x:(NSInteger)x y:(NSInteger)y width:(NSInteger)width height:(NSInteger)height topPad:(NSInteger)topPad view:(UIScrollView *)view backgroundColor:(UIColor *)color alignToCenter:(BOOL)alignToCenter selectorToDo:(SEL)selector forControlEvent:(UIControlEvents)controlEvent target:(id)target addToList:(NSMutableArray *)array sizeToFit:(BOOL)sizeToFit tag:(NSInteger)tag{
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(x, y + topPad, width, height)];
    [button setTag:tag];
    [button setBackgroundColor:color];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:target action:selector forControlEvents:controlEvent];
    [button.titleLabel setFont:[UIFont systemFontOfSize:26.0f]];
    if (alignToCenter)
        [button setCenter:CGPointMake(self.view.center.x, y + topPad + height * 0.5f)];
    
    [view addSubview:button];
    if(array)
        [array addObject:button];
    if(sizeToFit){
        [button sizeToFit];
        [button setFrame:CGRectMake(x, y + topPad, button.frame.size.width + (button.frame.size.width * 0.4f), button.frame.size.height)];
    }
    return y + topPad + height;
}

-(NSInteger)makePopupListElementWithTitle:(NSString *)title x:(NSInteger)x y:(NSInteger)y width:(NSInteger)width height:(NSInteger)height topPad:(NSInteger)topPad view:(UIScrollView *)view backgroundColor:(UIColor *)color alignToCenter:(BOOL)alignToCenter selectorToDo:(SEL)selector forControlEvent:(UIControlEvents)controlEvent target:(id)target addToList:(NSMutableArray *)array sizeToFit:(BOOL)sizeToFit tag:(NSInteger)tag{
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(x, y + topPad, width, height)];
    [button setTag:tag];
    [button setBackgroundColor:color];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:target action:selector forControlEvents:controlEvent];
    [button.titleLabel setFont:[UIFont systemFontOfSize:26.0f]];
    if (alignToCenter)
        [button setCenter:CGPointMake(self.view.center.x, y + topPad + height * 0.5f)];
    
    [view addSubview:button];
    if(array)
        [array addObject:button];
    if(sizeToFit){
        [button sizeToFit];
        [button setFrame:CGRectMake(x, y + topPad, button.frame.size.width + (button.frame.size.width * 0.4f), button.frame.size.height)];
    }
    return y + topPad + height;
}

-(NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController != nil)
        return _fetchedResultsController;

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:self.entity inManagedObjectContext:self.managedObjectContext];
    
    [fetchRequest setEntity:entity];
    
    // Create the sort descriptors array.
    NSSortDescriptor *authorDescriptor = [[NSSortDescriptor alloc] initWithKey:self.sortKey ascending:YES];
    NSArray *sortDescriptors = @[authorDescriptor];
    [fetchRequest setSortDescriptors:sortDescriptors];
    if(self.variablesDictionary)
        [fetchRequest setPredicate:[self.predicate predicateWithSubstitutionVariables:self.variablesDictionary]];
    else
        [fetchRequest setPredicate:self.predicate];
    
    // Create and initialize the fetch results controller.
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    return _fetchedResultsController;
}

@end
