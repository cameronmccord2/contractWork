//
//  NSAttributedString+Scale.m
//  VideoViewer
//
//  Created by Cameron McCord on 9/27/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import "NSAttributedString+Scale.h"

@implementation NSAttributedString (Scale)

- (NSAttributedString *)attributedStringWithScale:(double)scale {
    if(scale == 1.0)
    {
        return self;
    }
    
    NSMutableAttributedString *copy = [self mutableCopy];
    [copy beginEditing];
    
    NSRange fullRange = NSMakeRange(0, copy.length);
    
    [self enumerateAttribute:NSFontAttributeName inRange:fullRange options:0 usingBlock:^(UIFont *oldFont, NSRange range, BOOL *stop) {
        double currentFontSize = oldFont.pointSize;
        double newFontSize = currentFontSize * scale;
        
        // don't trust -[UIFont fontWithSize:]
        UIFont *scaledFont = [UIFont fontWithName:oldFont.fontName size:newFontSize];
        
        [copy removeAttribute:NSFontAttributeName range:range];
        [copy addAttribute:NSFontAttributeName value:scaledFont range:range];
    }];
    
    [self enumerateAttribute:NSParagraphStyleAttributeName inRange:fullRange options:0 usingBlock:^(NSParagraphStyle *oldParagraphStyle, NSRange range, BOOL *stop) {
        
        NSMutableParagraphStyle *newParagraphStyle = [oldParagraphStyle mutableCopy];
        newParagraphStyle.lineSpacing *= scale;
        newParagraphStyle.paragraphSpacing *= scale;
        newParagraphStyle.firstLineHeadIndent *= scale;
        newParagraphStyle.headIndent *= scale;
        newParagraphStyle.tailIndent *= scale;
        newParagraphStyle.minimumLineHeight *= scale;
        newParagraphStyle.maximumLineHeight *= scale;
        newParagraphStyle.paragraphSpacing *= scale;
        newParagraphStyle.paragraphSpacingBefore *= scale;
        
        [copy removeAttribute:NSParagraphStyleAttributeName range:range];
        [copy addAttribute:NSParagraphStyleAttributeName value:newParagraphStyle range:range];
    }];
    
    [copy endEditing];
    return copy;
}

@end
