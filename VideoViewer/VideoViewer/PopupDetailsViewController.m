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
#import "Files+Extras.h"
#import "NSAttributedString+Scale.h"

@interface PopupDetailsViewController ()
// TODO add play button
@end

@implementation PopupDetailsViewController{
    NSManagedObjectContext *context;
    Popups *popup;
    NSArray *subPopups;
    NSTimer *sliderTimer;
    AVAudioPlayer *player;
    UISlider *slider;
    UILabel *textLabel;
    UIView *sliderBackground;
    UIButton *playPauseButton;
    UIImageView *imageView;
    UIView *contentView;
    SubPopups *currentSubPopup;
}

- (instancetype)initWithPopup:(Popups *)newPopup context:(NSManagedObjectContext *)managedObjectContext {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        popup = newPopup;
        subPopups = [[popup subPopups] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES]]];
        context = managedObjectContext;
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];

    NSError *error = nil;
    if(!player){
        NSData *audioData = [NSData dataWithContentsOfFile:[popup.file bundleFilePath]];
        if (audioData == nil) {
            DLog(@"this should never be nil");
        }
        player = [[AVAudioPlayer alloc] initWithData:audioData fileTypeHint:AVFileTypeMPEGLayer3 error:&error];
        if(error)
            NSLog(@"avaudioplayer had an error: %@", [error localizedDescription]);
        
    }
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    // setup the content view
    contentView = [UIView new];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView setBackgroundColor:[UIColor clearColor]];
    
    textLabel = [UILabel new];
    textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [textLabel setBackgroundColor:[UIColor clearColor]];
    textLabel.numberOfLines = 0;
    textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [contentView addSubview:textLabel];
    
    imageView = [UIImageView new];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [imageView setBackgroundColor:[UIColor clearColor]];
    [contentView addSubview:imageView];
    
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(imageView, textLabel);
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[textLabel]-[imageView]|"
                                                                        options:0
                                                                        metrics:0
                                                                          views:viewsDictionary]];
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-62-[imageView]"
                                                                        options:0
                                                                        metrics:0
                                                                          views:viewsDictionary]];
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-90-[textLabel]"
                                                                        options:0
                                                                        metrics:0
                                                                          views:viewsDictionary]];
    [contentView addConstraint:[NSLayoutConstraint constraintWithItem:textLabel
                                                            attribute:NSLayoutAttributeWidth
                                                            relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                               toItem:contentView
                                                            attribute:NSLayoutAttributeWidth
                                                           multiplier:0.5f
                                                             constant:0]];
    [contentView addConstraint:[NSLayoutConstraint constraintWithItem:imageView
                                                            attribute:NSLayoutAttributeWidth
                                                            relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                               toItem:imageView
                                                            attribute:NSLayoutAttributeHeight
                                                           multiplier:1.0f
                                                             constant:0]];
    
    // setup audio control view
    slider = [UISlider new];
    slider.translatesAutoresizingMaskIntoConstraints = NO;
    slider.minimumValue = 0;
    slider.maximumValue = player.duration;
    [slider addTarget:self action:@selector(seekTime:) forControlEvents:UIControlEventValueChanged];
    
    playPauseButton = [UIButton new];
    playPauseButton.translatesAutoresizingMaskIntoConstraints = NO;
    UIImage *buttonImage = [UIImage imageNamed:@"pause.png"];
    [playPauseButton setImage:buttonImage forState:UIControlStateNormal];
    [playPauseButton addTarget:self action:@selector(playPauseButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    sliderBackground = [UIView new];
    sliderBackground.translatesAutoresizingMaskIntoConstraints = NO;
    [sliderBackground setBackgroundColor:[UIColor whiteColor]];
    
    UIView *topLine = [UIView new];
    topLine.translatesAutoresizingMaskIntoConstraints = NO;
    [topLine setBackgroundColor:[UIColor blackColor]];
    [sliderBackground addSubview:topLine];
    
    [sliderBackground addSubview:playPauseButton];
    [sliderBackground addSubview:slider];
    
    viewsDictionary = NSDictionaryOfVariableBindings(playPauseButton, slider, topLine);
    [sliderBackground addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[playPauseButton]-[slider]-|"
                                                                             options:NSLayoutFormatAlignAllCenterY
                                                                             metrics:0
                                                                               views:viewsDictionary]];
    [sliderBackground addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[topLine]|"
                                                                             options:0
                                                                             metrics:0
                                                                               views:viewsDictionary]];
    [sliderBackground addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topLine(2)]-8-[playPauseButton]-8-|"
                                                                             options:0
                                                                             metrics:0
                                                                               views:viewsDictionary]];
    [sliderBackground addConstraint:[NSLayoutConstraint constraintWithItem:playPauseButton
                                                                 attribute:NSLayoutAttributeWidth
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:playPauseButton
                                                                 attribute:NSLayoutAttributeHeight
                                                                multiplier:1.0f
                                                                  constant:0]];
    [sliderBackground addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topLine(2)]-[slider]-|"
                                                                             options:0
                                                                             metrics:0
                                                                               views:viewsDictionary]];
    
    [self.view addSubview:sliderBackground];
    [self.view addSubview:contentView];
    
    viewsDictionary = NSDictionaryOfVariableBindings(sliderBackground, contentView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[sliderBackground]|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:viewsDictionary]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[contentView][sliderBackground(60)]|"
                                                                     options:NSLayoutFormatAlignAllCenterX
                                                                     metrics:0
                                                                       views:viewsDictionary]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contentView]|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:viewsDictionary]];
    
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    sliderTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(timerTick) userInfo:nil repeats:YES];
    [player play];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if([player isPlaying])
        [player stop];
    player = nil;
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

-(void)timerTick {
    float progress = player.currentTime;
    [slider setValue:progress animated:NO];
    [self updateSubPopup];
}

-(void)playPauseButtonTapped:(UIButton *)sender{
    if([player isPlaying]){
        [player pause];
        [playPauseButton setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
    }else{
        [player play];
        [playPauseButton setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
    }
}

- (void)seekTime:(id)sender {
    player.currentTime = slider.value;
}

-(float)currentPlayerTime {
    return player.currentTime * 1000;// need the 1000?
}

-(NSAttributedString *)getAttributedStringForText:(NSString *)text{
    return [[NSAttributedString alloc] initWithData:[text dataUsingEncoding:NSUTF8StringEncoding]
                                            options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                      NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                                        documentAttributes:nil error:nil];
}

-(void)updateSubPopup {

    float currentTime = [self currentPlayerTime];
    if (currentTime != currentTime)
        currentTime = 0;
    
    NSArray *filteredSubPopups = [subPopups filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%f < endTime AND startTime =< %f", currentTime, currentTime]];
    SubPopups *subPopup = [filteredSubPopups firstObject];
    if (subPopup != nil && currentSubPopup != subPopup) {
        
        currentSubPopup = subPopup;
        
        NSMutableAttributedString *ats = [[NSMutableAttributedString alloc] initWithData:[[NSString stringWithFormat:@"%@", currentSubPopup.popupText] dataUsingEncoding:NSUTF8StringEncoding]
                                                                          options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                                    NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                                               documentAttributes:nil
                                                                            error:nil];
        ats = [[ats attributedStringWithScale:35.0/12.0] mutableCopy];// 12 is the default nsattributedstring size, we want it to be 35 point
        [ats beginEditing];
        [ats addAttributes:@{NSForegroundColorAttributeName: [UIColor blackColor]} range:NSMakeRange(0, ats.length)];
        [ats endEditing];
        [textLabel setAttributedText:ats];
        DLog(@"%@, %@", currentSubPopup.popupText, ats);
        // setup image for current subpopup
        if (currentSubPopup.file && [currentSubPopup.file.loadStatus isEqualToString:LoadStatusDownloaded] && [currentSubPopup.file isInBundle]) {
            NSData *imageData = [NSData dataWithContentsOfFile:[currentSubPopup.file bundleFilePath]];
            if (imageData == nil)
                DLog(@"this shouldnt happen");
            [imageView setImage:[UIImage imageWithData:imageData]];
        }else{
            [imageView setImage:nil];// will that work?
        }
    }
}

@end































