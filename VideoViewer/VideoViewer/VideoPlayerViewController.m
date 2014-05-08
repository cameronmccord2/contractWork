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
        self.currentCaptions = [[NSMutableArray alloc] initWithCapacity:1];
        self.currentPopups = [[NSMutableArray alloc] initWithCapacity:3];
        self.currentCaptionLabels = [[NSMutableArray alloc] initWithCapacity:1];
        self.currentPopupButtons = [[NSMutableArray alloc] initWithCapacity:3];
        self.spots = [@[@(0), @(0), @(0)] mutableCopy];
        self.predicateString = [NSString stringWithFormat:@"(mediaId == %@) AND ($currentTime < endTime) AND (startTime =< $currentTime) AND NOT(id IN $ids)", self.media.id];//@"NOT (id IN $currentIds) && startTime < $currentTime && endTime > $currentTime"
        self.predicate = [NSPredicate predicateWithFormat:self.predicateString];
        
        self.automaticallyAdjustsScrollViewInsets = NO;
        
        self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 70, [self screenWidth], 30)];
        [self.progressView setProgress:0.0f];
        self.variablesDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:0,@"currentTime", [[NSMutableArray alloc] init],@"ids", nil];
        
       
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
    [self buildView];
}

-(void)videoDataThen:(NSURLConnectionWithExtras *)connection progress:(NSProgress *)progress{
    if (!self.scrollView) {
        self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, [self view].frame.size.width, [self view].frame.size.height)];
        [self.scrollView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
        [self.scrollView setBackgroundColor:[UIColor whiteColor]];
        [self makeLabelWithText:@"Loading your video" x:0 y:20 width:[self screenWidth] height:30 topPad:10 view:self.scrollView backgroundColor:[UIColor redColor] alignToCenter:YES addToList:self.currentCaptionLabels fontColor:[UIColor blackColor] font:[UIFont systemFontOfSize:[UIFont systemFontSize]] sizeToFit:NO];
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

- (void)moviePlayerStateChanged:(NSNotification*)notification{

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
    NSError *error = nil;
    NSTimeInterval currentTime = self.player.currentPlaybackTime * 1000;
    if (currentTime != currentTime)
        currentTime = 0;
    
    [self.captionLabel setText:[NSString stringWithFormat:@"%f", currentTime]];
    [self.variablesDictionary setObject:@[] forKey:@"ids"];
    
    [self.variablesDictionary setObject:@(currentTime) forKey:@"currentTime"];
    self.sortKey = @"startTime";
    self.entity = @"Captions";
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
            NSInteger requiredWidth = [self screenWidth] - ([self screenWidth] * 0.1f);
            UIFont *labelFont = [UIFont systemFontOfSize:14.0f];
            NSString *bigString = [NSString stringWithFormat:@"%@%@%@", c.caption, c.caption, c.caption];
            CGRect stringFrame = [bigString boundingRectWithSize:CGSizeMake(requiredWidth, 1000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : labelFont} context:nil];
            int requiredHeight = stringFrame.size.height * 1.5f;
            int leftPad = ([self screenWidth] - requiredWidth) / 2.0f;
            yValue = [self makeLabelWithText:bigString x:leftPad y:yValue width:requiredWidth height:requiredHeight topPad:0 view:self.scrollView backgroundColor:captionBackground alignToCenter:YES addToList:self.currentCaptionLabels fontColor:[UIColor whiteColor] font:labelFont sizeToFit:YES];
        }
    }
    self.fetchedResultsController = nil;
    
    self.entity = @"Popups";
    
    [self.fetchedResultsController performFetch:&error];
    if (error)
        NSLog(@"error getting popups: %@", [error localizedDescription]);
    
    if ([self.fetchedResultsController.fetchedObjects count]) {
        
        NSArray *currentIds = [self.currentPopups valueForKeyPath:@"@distinctUnionOfObjects.id"];
        NSArray *fetchedIds = [self.fetchedResultsController.fetchedObjects valueForKeyPath:@"@distinctUnionOfObjects.id"];
        
//        NSPredicate *toKeepPredicate = [NSPredicate predicateWithFormat:@"id IN $ids"];
//        NSArray *toKeep = [self.currentPopups filteredArrayUsingPredicate:[toKeepPredicate predicateWithSubstitutionVariables:@{@"ids": fetchedIds}]];
        NSPredicate *toRemoveKeepPredicate = [NSPredicate predicateWithFormat:@"NOT (id IN $ids)"];
        NSArray *toRemove = [self.currentPopups filteredArrayUsingPredicate:[toRemoveKeepPredicate predicateWithSubstitutionVariables:@{@"ids": fetchedIds}]];
        NSArray *toAdd = [self.fetchedResultsController.fetchedObjects filteredArrayUsingPredicate:[toRemoveKeepPredicate predicateWithSubstitutionVariables:@{@"ids": currentIds}]];
                                                                                                                                                               
//        if ([toRemove count] > 0)
//            NSLog(@"Removing %ld", (long)[toRemove count]);
//        if([toKeep count] == 0)
//            NSLog(@"removing all");
//        if([toAdd count] > 0)
//            NSLog(@"adding %ld", (long)[toAdd count]);
        
        
        NSInteger yValue = [self popupStartingY];
        int leftPad = 10;
        int height = 50;
        int topPad = 0;
        
        
        for (Popups *p in toRemove) {
            for (UIButton *b in self.currentPopupButtons) {
                if (b.tag == [p.id integerValue]) {
                    [self.currentPopupButtons removeObject:b];
                    [b removeFromSuperview];
                    break;
                }
            }
            for (int i = 0; i < [self.spots count]; i++) {
                if ([[self.spots objectAtIndex:i] integerValue] == [p.id integerValue]) {
                    [self.spots replaceObjectAtIndex:i withObject:@(0)];
                    break;
                }
            }
            
            [self.currentPopups removeObject:p];
        }
        
        
        
        for (Popups *p in toAdd) {
            [self.currentPopups addObject:p];
            NSInteger startingYAdd = 0;
            for (int i = 0; i < [self.spots count]; i++) {
                if ([[self.spots objectAtIndex:i] integerValue] == 0) {
                    [self.spots replaceObjectAtIndex:i withObject:p.id];
                    startingYAdd = (height + topPad) * i;
                    break;
                }
            }

            yValue = [self makeUIButtonWithTitle:p.displayName x:leftPad y:yValue + startingYAdd width:[self screenWidth] height:height topPad:topPad view:self.scrollView backgroundColor:[UIColor greenColor] alignToCenter:YES selectorToDo:@selector(popupTapped:) forControlEvent:UIControlEventTouchUpInside target:self addToList:self.currentPopupButtons sizeToFit:YES tag:[p.id integerValue]];
        }
    }
    self.fetchedResultsController = nil;
}

-(void)popupTapped:(UIButton *)sender{
//    NSLog(@"tapped");
    [self.player pause];
    self.portraitOrLandscape = WasPortrait;
    if([self isLandscape])
        self.portraitOrLandscape = WasLandscape;
    for (Popups *p in self.currentPopups) {
        if (sender.titleLabel.text == p.displayName) {
//            NSLog(@"found: %@", p);
            PopupDetailsViewController *pdvc = [[PopupDetailsViewController alloc] initWithPopup:p context:self.managedObjectContext];
            [pdvc setWillReturnDelegate:self];
            [self.navigationController pushViewController:pdvc animated:YES];
            break;
        }
    }
}

-(void)buildView{
    
    
    
//    self.scrollView = [[UIScrollView alloc] init];
//    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, [self view].frame.size.width, [self view].frame.size.height)];
    self.scrollView = [[UIScrollView alloc] initWithFrame:[self getScrollViewFrame]];
    [self.scrollView setContentSize:[self getScrollViewContentSize]];
    [self.scrollView setContentInset:[self getScrollViewContentInsets]];
    [self.scrollView setBackgroundColor:[UIColor whiteColor]];
    int yValue = 0;
    [self registerForVideoPlayerNotifications];
    
    
    self.player = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:self.videoPath]];
    
    self.player.view.frame = [self getVideoPlayerFrame];
    yValue += 3000;
    
    [self.scrollView addSubview:self.player.view];
    
    
//    if ([self isLandscape]) {
//        NSLog(@"lnschape");
//        [self.navigationController setHidesBottomBarWhenPushed:YES];
////        [self.scrollView setContentSize:CGSizeMake([self view].frame.size.height, [self view].frame.size.width)];
////        [self.scrollView setFrame:CGRectMake(0, 0, [self view].frame.size.height, [self view].frame.size.width)];
////        [self.player.view setFrame:[self getVideoPlayerFrame]];
//    }else{
////        [self.scrollView setContentSize:CGSizeMake([self view].frame.size.height, [self view].frame.size.width)];
////        [self.scrollView setFrame:CGRectMake(0, 0, [self view].frame.size.height, [self view].frame.size.width)];
////        [self.player.view setFrame:[self getVideoPlayerFrame]];
//    }
    [self fixScrollViewWidth];
    [self.view addSubview:self.scrollView];
    [self.player play];
}

-(BOOL)isLandscape{
    return UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
}

- (void) orientationChanged:(NSNotification *)note{
//    NSLog(@"new thing");
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
    [self fixScrollViewWidth];
    [self fixCurrentPopups];
    [self fixCurrentCaptions];
}

-(NSInteger)getCaptionsStartingY{
    if([self isLandscape])
        return 160;
    return 200;
}

-(void)fixCurrentPopups{
    int val = 240;
    if(![self isLandscape])
        val = -240;
    for (UIButton *b in self.currentPopupButtons) {
        [b setFrame:CGRectMake(b.frame.origin.x, b.frame.origin.y - val, b.frame.size.width, b.frame.size.height)];
    }
}

-(void)fixCurrentCaptions{
    for (UILabel *l in self.currentCaptionLabels) {
        [l setFrame:CGRectMake(l.frame.origin.x, [self getCaptionsStartingY], l.frame.size.width, l.frame.size.height)];
    }
}

-(void)fixScrollViewWidth{
    if (self.scrollView.frame.size.width < self.player.view.frame.size.width) {
        [self.scrollView setFrame:CGRectMake(self.scrollView.frame.origin.x, self.scrollView.frame.origin.y, self.player.view.frame.size.width, self.scrollView.frame.size.height)];
    }
}

-(UIEdgeInsets)getScrollViewContentInsets{
    if([self isLandscape])
        return UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    return UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
}

-(CGRect)getVideoPlayerFrame{
    NSInteger heightAdjust = 0;
    if([self isIpad])
        heightAdjust = 400;
    if([self isLandscape])
        return CGRectMake(0, -30, [self screenWidth], 300 + heightAdjust);
    return CGRectMake(0, 0, [self screenWidth], 200 + heightAdjust);
}

-(CGRect)getScrollViewFrame{
    if([self isLandscape])
        return CGRectMake(0, 56, [self view].frame.size.width, [self view].frame.size.height);
    return CGRectMake(0, 56, [self view].frame.size.width, [self view].frame.size.height);
}

-(CGSize)getScrollViewContentSize{
    if([self isLandscape])
        return CGSizeMake([self view].frame.size.width, [self view].frame.size.height);
    return CGSizeMake([self view].frame.size.width, [self view].frame.size.height);
}

-(NSInteger)popupStartingY{
    if([self isLandscape])
        return 10;
    return 250;
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

-(NSInteger)makeLabelWithText:(NSString *)text x:(NSInteger)x y:(NSInteger)y width:(NSInteger)width height:(NSInteger)height topPad:(NSInteger)topPad view:(UIScrollView *)view backgroundColor:(UIColor *)color alignToCenter:(BOOL)alignToCenter addToList:(NSMutableArray *)array fontColor:(UIColor *)fontColor font:(UIFont *)font sizeToFit:(BOOL)sizeToFit{
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(x, y + topPad, width, height)];
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
        [title setFrame:CGRectMake(x, y + topPad, width, title.frame.size.height)];
    }
    return y + height + topPad;
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
    [fetchRequest setPredicate:[self.predicate predicateWithSubstitutionVariables:self.variablesDictionary]];
    
    // Create and initialize the fetch results controller.
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    return _fetchedResultsController;
}

@end
