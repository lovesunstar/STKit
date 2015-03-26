//
//  STVisualBlurView.m
//  STKit
//
//  Created by SunJiangting on 14-9-22.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STVisualBlurView.h"
#import "UIKit+STKit.h"

@interface STVisualBlurView () {
    __weak UIView *_contentView;
}

@property(nonatomic, strong) UIView *visualView;

@end

@implementation STVisualBlurView

- (instancetype)initWithBlurEffectStyle:(STBlurEffectStyle)blurEffectStyle {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        if (blurEffectStyle != STBlurEffectStyleNone) {
            if (STGetSystemVersion() >= 8) {
                UIVisualEffectView *view =
                    [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:[self effectStyleWithSTStyle:blurEffectStyle]]];
                self.visualView = view;
                _contentView = view.contentView;
            } else if (STGetSystemVersion() >= 7) {
                UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:CGRectZero];
                toolBar.translucent = YES;
                toolBar.barTintColor = [self tintColorWithSTBlurStyle:blurEffectStyle];
                self.visualView = toolBar;
                _contentView = toolBar;
            } else {
                return nil;
            }
        } else {
            self.visualView = [[UIView alloc] initWithFrame:self.bounds];
            self.visualView.backgroundColor = [UIColor grayColor];
        }
        self.visualView.frame = self.bounds;
        self.visualView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        if (self.visualView != self && self.visualView) {
            [self addSubview:self.visualView];
        }
    }
    return self;
}

- (UIColor *)tintColorWithSTBlurStyle:(STBlurEffectStyle)blurEffectStyle {
    UIColor *tintColor;
    switch (blurEffectStyle) {
    case STBlurEffectStyleLight:
        tintColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        break;
    case STBlurEffectStyleDark:
        tintColor = [UIColor colorWithWhite:0.11 alpha:0.73];
        break;
    case STBlurEffectStyleExtraLight:
    default:
        tintColor = [UIColor colorWithWhite:0.97 alpha:0.82];
    }
    return tintColor;
}

- (UIBlurEffectStyle)effectStyleWithSTStyle:(STBlurEffectStyle)style {
    switch (style) {
    case STBlurEffectStyleDark:
        return UIBlurEffectStyleDark;
    case STBlurEffectStyleLight:
        return UIBlurEffectStyleLight;
    case STBlurEffectStyleExtraLight:
    default:
        return UIBlurEffectStyleExtraLight;
    }
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [self initWithBlurEffectStyle:STBlurEffectStyleExtraLight];
    if (self) {
        self.frame = frame;
    }
    return self;
}

- (UIView *)contentView {
    return _contentView;
}

- (void)setTintColor:(UIColor *)tintColor {
    if ([self.visualView respondsToSelector:@selector(setBarTintColor:)]) {
        [self.visualView performSelector:@selector(setBarTintColor:) withObject:tintColor];
    } else if ([self.visualView respondsToSelector:@selector(setTintColor:)]) {
        self.visualView.tintColor = tintColor;
    } else {
        self.visualView.backgroundColor = tintColor;
    }
    _tintColor = tintColor;
}

- (void)setHasBlurEffect:(BOOL)hasBlurEffect {
    self.visualView.hidden = !hasBlurEffect;
    _hasBlurEffect = hasBlurEffect;
}

@end
