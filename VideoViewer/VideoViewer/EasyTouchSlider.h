//
//  EasyTouchSlider.h
//  VideoViewer
//
//  Created by Cameron McCord on 9/27/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EasyTouchSlider : UISlider

@property(nonatomic)NSInteger extraSize;

+(instancetype)newWithExtraSize:(NSInteger)size;
+(instancetype)new;

@end
