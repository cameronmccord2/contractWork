//
//  HighlightButton.m
//  VideoViewer
//
//  Created by Cameron McCord on 5/29/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import "HighlightButton.h"

@implementation HighlightButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColorNormal = [UIColor whiteColor];
        self.backgroundColorHighlighted = [UIColor whiteColor];
        self.borderColorHighlighted = [UIColor whiteColor];
        self.borderColorNormal = [UIColor whiteColor];
    }
    return self;
}

- (void) setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    if (highlighted) {
        if(self.backgroundColorHighlighted)
            [self setBackgroundColor:self.backgroundColorHighlighted];
        if(self.borderColorHighlighted)
            self.layer.borderColor = self.borderColorHighlighted.CGColor;
    }
    else {
        if(self.backgroundColorNormal)
            [self setBackgroundColor:self.backgroundColorNormal];
        if(self.borderColorNormal)
            self.layer.borderColor = self.borderColorNormal.CGColor;
    }
}

@end
