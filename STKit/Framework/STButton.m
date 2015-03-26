//
//  STButton.m
//  STKit
//
//  Created by SunJiangting on 14-3-25.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STButton.h"

@interface STButton ()

@property(nonatomic, strong) UIColor *realBackgroundColor;

@end

@implementation STButton

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.usingSystemLayout = NO;
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.usingSystemLayout = YES;
    }
    return self;
}

- (void)layoutSubviews {
    if (self.usingSystemLayout) {
        [super layoutSubviews];
    }
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    self.realBackgroundColor = backgroundColor;
}

- (UIColor *)backgroundColor {
    return self.realBackgroundColor;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    if (highlighted) {
        [super setBackgroundColor:self.highlightedBackgroundColor];
    } else {
        if (self.selected && self.selectedBackgroundColor) {
            [super setBackgroundColor:self.selectedBackgroundColor];
        } else {
            [super setBackgroundColor:self.realBackgroundColor];
        }
    }
    [self.subviews enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
        if ([obj respondsToSelector:@selector(setHighlighted:)]) {
            [obj performSelector:@selector(setHighlighted:) withObject:(__bridge id)((void *)((NSInteger)highlighted))];
        }
    }];
}

- (void)setSelected:(BOOL)selected {
    if (selected) {
        [super setBackgroundColor:self.selectedBackgroundColor];
    } else {
        [super setBackgroundColor:self.realBackgroundColor];
    }
}

@end

@implementation STButton (STKit)

@dynamic normalTitle, highlightedTItle;

- (void)setNormalTitle:(NSString *)normalTitle {
    [self setTitle:normalTitle forState:UIControlStateNormal];
}

- (NSString *)normalTitle {
    return [self titleForState:UIControlStateNormal];
}

- (void)highlightedTitle:(NSString *)highlightedTitle {
    [self setTitle:highlightedTitle forState:UIControlStateHighlighted];
}

- (NSString *)highlightedTitle {
    return [self titleForState:UIControlStateHighlighted];
}

@end
