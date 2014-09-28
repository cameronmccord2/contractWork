//
//  EasyTouchSlider.m
//  VideoViewer
//
//  Created by Cameron McCord on 9/27/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import "EasyTouchSlider.h"

@implementation EasyTouchSlider

+(instancetype)newWithExtraSize:(NSInteger)size {
    EasyTouchSlider *slider = [EasyTouchSlider new];
    [slider setExtraSize:size];
    return slider;
}

+(instancetype)new {
    EasyTouchSlider *slider = [super new];
    [slider setExtraSize:0];
    return slider;
}

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect bounds = self.bounds;
    bounds = CGRectInset(bounds, 0, -self.extraSize);
    return CGRectContainsPoint(bounds, point);
}

@end
