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
    UIView *_containerView;
}

@property(nonatomic, strong) UIView *visualView;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@end

@implementation STVisualBlurView

- (instancetype)initWithBlurEffectStyle:(STBlurEffectStyle)blurEffectStyle {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        if (blurEffectStyle != STBlurEffectStyleNone && STGetSystemVersion() >= 8) {
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:[self _effectStyleWithSTStyle:blurEffectStyle]];
            UIVisualEffectView *view = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            self.visualView = view;
        } else {
            UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:CGRectZero];
            toolBar.translucent = (blurEffectStyle != STBlurEffectStyleNone);
            toolBar.barTintColor = [self _tintColorWithSTBlurStyle:blurEffectStyle];
            self.visualView = toolBar;
        }
        self.visualView.frame = self.bounds;
        self.visualView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.visualView];
        
        _containerView = [[UIView alloc] initWithFrame:self.bounds];
        _containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        if (blurEffectStyle != STBlurEffectStyleNone) {
            self.hasBlurEffect = YES;
        }
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [self initWithBlurEffectStyle:STBlurEffectStyleExtraLight];
    if (self) {
        self.frame = frame;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (UIView *)contentView {
    return _containerView;
}

- (void)setColor:(UIColor * __nullable)color {
    if ([_visualView isKindOfClass:NSClassFromString(@"UIVisualEffectView")]) {
        ((UIVisualEffectView *)_visualView).contentView.backgroundColor = color;
    } else {
        [self.visualView st_performSelector:@selector(setBarTintColor:) withObjects:color, nil];
    }
    _color = color;
    self.hasBlurEffect = self.hasBlurEffect;
}

- (void)setHasBlurEffect:(BOOL)hasBlurEffect {
    if (hasBlurEffect || (!hasBlurEffect && [self.visualView isKindOfClass:[UIToolbar class]])) {
        if (!self.visualView.superview) {
            self.visualView.frame = self.bounds;
            [self addSubview:self.visualView];
        }
        if ([self.visualView isKindOfClass:[UIToolbar class]]) {
            if (_containerView.superview != self.visualView) {
                [_containerView removeFromSuperview];
                [self.visualView addSubview:_containerView];
            }
        } else {
            UIVisualEffectView *effectView = (UIVisualEffectView *)_visualView;
            if (_containerView.superview != effectView.contentView) {
                [effectView.contentView addSubview:_containerView];
            }
        }
        self.backgroundColor = nil;
    } else {
        [self.visualView removeFromSuperview];
        if (_containerView.superview != self) {
            [_containerView removeFromSuperview];
            _containerView.frame = self.bounds;
            [self addSubview:_containerView];
        }
        self.backgroundColor = _color?:[UIColor whiteColor];
    }
    if ([self.visualView isKindOfClass:[UIToolbar class]]) {
        UIToolbar *toolbar = (UIToolbar *)_visualView;
        toolbar.translucent = hasBlurEffect;
    }
    _hasBlurEffect = hasBlurEffect;
}


- (UIColor *)_tintColorWithSTBlurStyle:(STBlurEffectStyle)blurEffectStyle {
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

- (UIBlurEffectStyle)_effectStyleWithSTStyle:(STBlurEffectStyle)style {
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

@end
