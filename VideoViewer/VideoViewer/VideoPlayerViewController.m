//
//  VideoPlayerViewController.m
//  VideoViewer
//
//  Created by Cameron McCord on 4/17/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import "VideoPlayerViewController.h"

@interface VideoPlayerViewController ()

@end

@implementation VideoPlayerViewController

- (id)initWithContext:(NSManagedObjectContext *)context media:(Medias *)media{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.media = media;
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    [[VPDaoV1 sharedManager] getVideoData:self media:self.media];
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
    
}

-(void)buildView{
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, [self view].frame.size.width, [self view].frame.size.height)];
    [self.scrollView setBackgroundColor:[UIColor whiteColor]];
    int yValue = 0;
    
    self.player = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:self.videoPath]];
    
    self.player.view.frame = CGRectMake(0, 0, [self screenWidth], 300);
    yValue += 3000;
    
    [self.scrollView addSubview:self.player.view];
    
    [self.view addSubview:self.scrollView];
    
    [self.scrollView setContentSize:CGSizeMake([self screenWidth], yValue)];
    [self.player play];
}

-(BOOL)isLandscape{
    return UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
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

@end
