//
//  PopupDetailsViewController.m
//  VideoViewer
//
//  Created by Cameron McCord on 4/17/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import "PopupDetailsViewController.h"
#import "Popups.h"
#import "SubPopups.h"

@interface PopupDetailsViewController ()
// TODO add play button
@end

@implementation PopupDetailsViewController

- (instancetype)initWithPopup:(Popups *)popup context:(NSManagedObjectContext *)context{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.popup = popup;
        self.managedObjectContext = context;
        self.automaticallyAdjustsScrollViewInsets = NO;
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(orientationChanged:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:[UIDevice currentDevice]];
        
        // Core Data init stuff
        NSString *predicateString = [NSString stringWithFormat:@"(popupId == %@) AND ($currentTime < endTime) AND (startTime =< $currentTime) AND NOT(id IN $ids)", self.popup.id];//@"NOT (id IN $currentIds) && startTime < $currentTime && endTime > $currentTime"
        self.predicate = [NSPredicate predicateWithFormat:predicateString];
        self.variablesDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:0,@"currentTime", [[NSMutableArray alloc] init],@"ids", nil];
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    [[VPDaoV1 sharedManager] getPopupData:self popup:self.popup];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.player = nil;
    NSLog(@"will return");
    [self.delegate willReturn];
}

-(void)setWillReturnDelegate:(id<PopupDetailsViewControllerDelegate>)delegate{
    self.delegate = delegate;
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

-(void)fileDataForRequestedFile:(NSData *)fileData{
    self.fileData = fileData;
    [self buildView];
}

-(void)buildView{
    NSError *error = nil;
    if(!self.player){
        self.player = [[AVAudioPlayer alloc] initWithData:self.fileData fileTypeHint:AVFileTypeMPEGLayer3 error:&error];
        if(error)
            NSLog(@"avaudioplayer had an error: %@", [error localizedDescription]);
        [self.player play];
    }
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:[self getScrollViewFrame]];
    [self.scrollView setBackgroundColor:[UIColor whiteColor]];
    
    [self.view addSubview:self.scrollView];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.sliderTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(updatePlayerTime) userInfo:nil repeats:YES];
    
    self.slider = [[UISlider alloc] initWithFrame:[self getSliderFrame]];
    self.slider.minimumValue = 0;
    self.slider.maximumValue = self.player.duration;
    [self.slider addTarget:self action:@selector(seekTime:) forControlEvents:UIControlEventValueChanged];
    
    self.playPauseButton = [[UIButton alloc] initWithFrame:CGRectMake(60, 5, 30, 30)];
    [self.playPauseButton setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
    [self.playPauseButton addTarget:self action:@selector(playPauseButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    
    self.sliderBackground = [[UIView alloc] initWithFrame:[self getSliderBackgroundFrame]];
    NSLog(@"y: %f", self.sliderBackground.frame.origin.y);
    [self.sliderBackground setBackgroundColor:[UIColor whiteColor]];
    
    [self.sliderBackground addSubview:self.playPauseButton];
    [self.sliderBackground addSubview:self.slider];
    [self.view addSubview:self.sliderBackground];
}

-(void)playPauseButtonTapped:(UIButton *)sender{
    if([self.player isPlaying]){
        [self.player pause];
        [self.playPauseButton setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
    }else{
        [self.player play];
        [self.playPauseButton setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
    }
}

-(NSAttributedString *)getAttributedStringForText:(NSString *)text{
    return [[NSAttributedString alloc] initWithData:[text dataUsingEncoding:NSUTF8StringEncoding]
                                            options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                      NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                                        documentAttributes:nil error:nil];
}

-(CGRect)getLabelFrameForText:(NSString *)text{
    NSAttributedString *ats = [self getAttributedStringForText:text];
    return [ats boundingRectWithSize:CGSizeMake([self screenWidth], 10000.0f) options:(NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin) context:nil];
}

- (void) orientationChanged:(NSNotification *)note{
    NSLog(@"fixing");
    [self fixSliderBackground];
    [self.descriptionLabel setFrame:[self getLabelFrameForText:self.popup.popupText]];
    [self.descriptionLabel setFrame:CGRectMake(10, 66, self.descriptionLabel.frame.size.width - 20, self.descriptionLabel.frame.size.height + 30)];
    //    NSLog(@"new thing");
//    UIDevice * device = note.object;
//    switch(device.orientation){
    
//        case UIDeviceOrientationPortrait:
//        case UIDeviceOrientationPortraitUpsideDown:// move popups up or down depending on where they currently are and where they need to be when it rotates
//        case UIDeviceOrientationLandscapeLeft:
//        case UIDeviceOrientationLandscapeRight:
//            [self.scrollView setContentSize:[self getScrollViewContentSize]];
//            [self.scrollView setFrame:[self getScrollViewFrame]];
//            [self.scrollView setContentInset:[self getScrollViewContentInsets]];
//            [self.slider setFrame:[self getSliderFrame]];
//            [self fixScrollViewWidth];
//            [self.descriptionLabel setFrame:[self getLabelFrameForText:self.popup.popupText]];
//            break;
//            
//        default:
//            break;
//    };
//    [self buildView];
}

-(void)fixScrollViewWidth{
    if (self.scrollView.frame.size.width < [self view].frame.size.width) {
        [self.scrollView setFrame:CGRectMake(self.scrollView.frame.origin.x, self.scrollView.frame.origin.y, [self view].frame.size.width, self.scrollView.frame.size.height)];
    }
}

-(void)fixSliderBackground{
    [self.sliderBackground setFrame:[self getSliderBackgroundFrame]];
}

-(UIEdgeInsets)getScrollViewContentInsets{
    if([self isLandscape])
        return UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    return UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
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

-(CGRect)getSliderBackgroundFrame{
    int height = 40;
    if([self isLandscape])
        return CGRectMake(0, [self screenHeight] - height, [self screenWidth], height);
    return CGRectMake(0, [self screenHeight] - height, [self screenWidth], height);
}

-(CGRect)getScrollViewFrame{
    NSInteger adjustment = 62;
    if([self isLandscape])
        return CGRectMake(0, adjustment, [self screenHeight] / 2, [self screenWidth] - 20);// split the slider background height, half here, half image
    return CGRectMake(0, adjustment, [self screenWidth], [self screenHeight] / 2 - 20);// split the slider background height, half here, half image
}

-(CGSize)getScrollViewContentSize{
    if([self isLandscape])
        return CGSizeMake([self view].frame.size.width, [self view].frame.size.height);
    return CGSizeMake([self view].frame.size.width, [self view].frame.size.height);
}
                       
-(CGRect)getSliderFrame{// 20 up from the bottom of the view
    NSInteger height = 20;
    NSInteger yValue = 10;
    NSInteger leftPad = 100;
    NSInteger width = ([self view].frame.size.width - leftPad) / 2.0f;
    return CGRectMake(leftPad, yValue, width, height);
}

-(BOOL)isLandscape{
    return UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
}

-(void)updatePlayerTime{
    float progress = self.player.currentTime;
    [self.slider setValue:progress animated:NO];
    [self updateSubPopupWithLongTime:progress * 1000];
}

- (IBAction)seekTime:(id)sender {
    self.player.currentTime = self.slider.value;
}

-(void)updateSubPopupWithLongTime:(float)currentTime{

    if (currentTime != currentTime)
        currentTime = 0;
    
    // setup vars for core data request
    [self.variablesDictionary setObject:@[] forKey:@"ids"];
    if(self.descriptionLabel != nil)
        [self.variablesDictionary setObject:@[@(self.descriptionLabel.tag)] forKey:@"ids"];
    
    [self.variablesDictionary setObject:@(currentTime) forKey:@"currentTime"];
    self.sortKey = @"startTime";
    self.entity = @"SubPopups";
    [self fetchedResultsController];
    NSError *error = nil;
    [self.fetchedResultsController performFetch:&error];
    if (error)
        NSLog(@"error getting sub popups: %@", [error localizedDescription]);
    
    if ([self.fetchedResultsController.fetchedObjects count] > 0) {
        
        for (SubPopups *sub in [self.fetchedResultsController fetchedObjects]) {
            if(self.descriptionLabel != nil)
                [self.descriptionLabel removeFromSuperview];
            
            self.descriptionLabel = [[UILabel alloc] initWithFrame:[self getLabelFrameForText:sub.popupText]];
            [self.descriptionLabel setNumberOfLines:0];
            self.descriptionLabel.tag = [sub.id integerValue];
            
            [self.descriptionLabel setFrame:CGRectMake(10, 0, [self getLabelWidth] - 10, self.descriptionLabel.frame.size.height + 30)];
            NSLog(@"%f %f %f %f", self.descriptionLabel.frame.origin.x, self.descriptionLabel.frame.origin.y, self.descriptionLabel.frame.size.width, self.descriptionLabel.frame.size.height);
            
            [self.descriptionLabel setAttributedText:[self getAttributedStringForText:sub.popupText]];
//            NSLog(@"text y: %ld", (long)self.descriptionLabel.frame.origin.y);
//            [self.view addSubview:self.descriptionLabel];
            [self.scrollView addSubview:self.descriptionLabel];
            [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width, self.descriptionLabel.frame.size.height)];
            
            // do scroll view and content height?
        }
    }
    self.fetchedResultsController = nil;
}

-(float)getLabelWidth{
    if([self isIpad])
        return 384 - 20;// 10 pad on each side
    return 320 - 20;// 10 pad on each side
}

-(BOOL)isIpad{
    if([[[UIDevice currentDevice]model] isEqualToString:@"iPad"] || [[[UIDevice currentDevice] model] isEqualToString:@"iPad Simulator"])
        return YES;
    return NO;
}

#pragma mark Core Data Stuff

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































