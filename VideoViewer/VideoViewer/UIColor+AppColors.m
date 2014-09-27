//
//  UIColor+AppColors.m
//  VPPlusBook
//
//  Created by Cameron McCord on 9/5/14.
//  Copyright (c) 2014 MTC. All rights reserved.
//

#import "UIColor+AppColors.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@implementation UIColor (AppColors)

+(UIColor *)colorNoDivideWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha {
	return [UIColor colorWithRed:red/255.0f green:green/255.0f blue:blue/255.0f alpha:alpha];
}

+(UIColor *)flagGreen {
    return UIColorFromRGB(0x009b3a);
}

+(UIColor *)lightBlue {
    return UIColorFromRGB(0xfffef5);
//    return [UIColor colorNoDivideWithRed:51.0f green:156.0f blue:196.0f alpha:1.0f];
}

@end
