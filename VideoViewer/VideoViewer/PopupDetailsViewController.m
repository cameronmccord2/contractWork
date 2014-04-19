//
//  PopupDetailsViewController.m
//  VideoViewer
//
//  Created by Cameron McCord on 4/17/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import "PopupDetailsViewController.h"
#import "Popups.h"

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
        [[NSNotificationCenter defaultCenter]
         addObserver:self selector:@selector(orientationChanged:)
         name:UIDeviceOrientationDidChangeNotification
         object:[UIDevice currentDevice]];
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
        self.popup.popupText = [NSString stringWithFormat:@"%@%@%@%@%@%@", self.popup.popupText,self.popup.popupText,self.popup.popupText,self.popup.popupText,self.popup.popupText,self.popup.popupText];
    }
    
    NSInteger yValue = 62;
    self.scrollView = [[UIScrollView alloc] initWithFrame:[self getScrollViewFrame]];
    [self.scrollView setContentSize:[self getScrollViewContentSize]];
    [self.scrollView setBackgroundColor:[UIColor whiteColor]];
    self.slider = [[UISlider alloc] initWithFrame:[self getSliderFrame]];
    self.slider.minimumValue = 0;
    self.slider.maximumValue = self.player.duration;
    [self.slider addTarget:self action:@selector(seekTime:) forControlEvents:UIControlEventValueChanged];
    
    // put title above?
    CGRect labelFrame = [self getLabelFrameForText:[self.popup popupText]];
    NSInteger finalWidth = labelFrame.size.width - (labelFrame.size.width * 0.1f);
    NSInteger leftPad = (labelFrame.size.width * 0.1f) / 2;
    labelFrame = CGRectMake(leftPad, 20, finalWidth, labelFrame.size.height);
    yValue += labelFrame.size.height;
    self.descriptionLabel = [[UILabel alloc] initWithFrame:labelFrame];
    [self.descriptionLabel setNumberOfLines:0];
    [self.descriptionLabel setAttributedText:[self getAttributedStringForText:self.popup.popupText]];
    [self.scrollView addSubview:self.descriptionLabel];
    
    
    self.sliderTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
    if (yValue > self.scrollView.contentSize.height)
        [self.scrollView setContentSize:CGSizeMake(self.scrollView.contentSize.width, yValue)];
    
    [self.view addSubview:self.scrollView];
    [self.view addSubview:self.slider];
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
    [self buildView];
}

-(void)fixScrollViewWidth{
    if (self.scrollView.frame.size.width < [self view].frame.size.width) {
        [self.scrollView setFrame:CGRectMake(self.scrollView.frame.origin.x, self.scrollView.frame.origin.y, [self view].frame.size.width, self.scrollView.frame.size.height)];
    }
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

-(CGRect)getScrollViewFrame{
    NSInteger adjustment = 62;
    if([self isLandscape])
        return CGRectMake(0, adjustment, [self view].frame.size.width, [self view].frame.size.height - adjustment);
    return CGRectMake(0, adjustment, [self view].frame.size.width, [self view].frame.size.height - adjustment);
}

-(CGSize)getScrollViewContentSize{
    if([self isLandscape])
        return CGSizeMake([self view].frame.size.width, [self view].frame.size.height);
    return CGSizeMake([self view].frame.size.width, [self view].frame.size.height);
}
                       
-(CGRect)getSliderFrame{// 20 up from the bottom of the view
    NSInteger height = 20;
    NSInteger bottomPad = 20;
    NSInteger y = [self view].frame.size.height - height - bottomPad;
    NSInteger leftPad = 20;
    NSInteger width = ([self view].frame.size.width - leftPad) / 2.0f;
    if([self isLandscape])
        return CGRectMake(leftPad, y, width, height);
    return CGRectMake(leftPad, y, width, height);
}

-(BOOL)isLandscape{
    return UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
}

-(void)updateSlider{
    float progress = self.player.currentTime;
    [self.slider setValue:progress animated:NO];
}

- (IBAction)seekTime:(id)sender {
    self.player.currentTime = self.slider.value;
}

@end































