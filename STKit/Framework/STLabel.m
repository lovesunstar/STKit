//
//  STLabel.m
//  STKit
//
//  Created by SunJiangting on 13-10-26.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import "STLabel.h"

@implementation STLabel

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.verticalAlignment = STVerticalAlignmentTop;
    }
    return self;
}

- (void)setVerticalAlignment:(STVerticalAlignment)verticalAlignment {
    _verticalAlignment = verticalAlignment;
    [self setNeedsDisplay];
}

- (void)setContentInsets:(UIEdgeInsets)contentInsets {
    _contentInsets = contentInsets;
    [self setNeedsDisplay];
}

- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines {

    CGRect newBounds = bounds;
    newBounds.origin.y += self.contentInsets.top;
    newBounds.size.height -= (self.contentInsets.top + self.contentInsets.bottom);
    newBounds.origin.x += self.contentInsets.left;
    newBounds.size.width -= (self.contentInsets.left + self.contentInsets.right);

    CGRect rect = [super textRectForBounds:newBounds limitedToNumberOfLines:numberOfLines];
    switch (self.verticalAlignment) {
    case STVerticalAlignmentTop:
        rect.origin.y = bounds.origin.y + self.contentInsets.top;
        break;
    case STVerticalAlignmentBottom:
        rect.origin.y = CGRectGetMaxY(bounds) - self.contentInsets.bottom - rect.size.height;
        break;
    default:
        rect.origin.y = (CGRectGetHeight(bounds) - self.contentInsets.bottom - CGRectGetHeight(rect)) / 2;
        break;
    }
    return rect;
}

- (void)drawTextInRect:(CGRect)rect {
    CGRect textRect = [self textRectForBounds:rect limitedToNumberOfLines:self.numberOfLines];
    [super drawTextInRect:textRect];
}
@end
