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

@interface PopupDetailsViewController : UIViewController<AVAudioPlayerDelegate>

-(instancetype)initWithPopup:(Popups *)popup context:(NSManagedObjectContext *)managedObjectContext;

@end
