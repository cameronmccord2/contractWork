//
//  HighlightButton.h
//  VideoViewer
//
//  Created by Cameron McCord on 5/29/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HighlightButton : UIButton

@property(nonatomic, strong)UIColor *backgroundColorNormal;
@property(nonatomic, strong)UIColor *backgroundColorHighlighted;
@property(nonatomic, strong)UIColor *borderColorNormal;
@property(nonatomic, strong)UIColor *borderColorHighlighted;

@end
