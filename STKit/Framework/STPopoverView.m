//
//  STPopoverView.m
//  STKit
//
//  Created by SunJiangting on 14-5-23.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STPopoverView.h"
#import "UIKit+STKit.h"

typedef enum _STPopoverState {
    _STPopoverStateWillAppear,
    _STPopoverStateDidAppear,
    _STPopoverStateWillDisappear,
    _STPopoverStateDidDisappear,
} _STPopoverState;

@interface STPopoverView () <UIGestureRecognizerDelegate>

@property(nonatomic, strong) UIView *backgroundView;
@property(nonatomic, strong) UIView *contentView;

@property(nonatomic, weak) UIView *parentView;
@property(nonatomic, assign) BOOL visible;

@property(nonatomic, assign) _STPopoverState state;

@end

@implementation STPopoverView

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.backgroundView.backgroundColor = [UIColor colorWithRGB:0 alpha:1];
        [self addSubview:self.backgroundView];

        self.contentView = [[UIView alloc] initWithFrame:CGRectZero];
        self.contentView.clipsToBounds = YES;
        [self addSubview:self.contentView];

        self.state = _STPopoverStateDidDisappear;

        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissActionFired:)];
        tapGesture.numberOfTapsRequired = 1;
        [self.backgroundView addGestureRecognizer:tapGesture];

        __weak STPopoverView *weakSelf = self;
        self.hitTestBlock = ^(CGPoint point, UIEvent *event, BOOL *returnSuper) {
            if (point.y < weakSelf.contentOffset.y) {
                return weakSelf.backgroundView;
            }
            *returnSuper = YES;
            return (UIView *)nil;
        };

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(statusBarFrameDidChanged:)
                                                     name:UIApplicationWillChangeStatusBarFrameNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(statusBarOrientationDidChange:)
                                                     name:UIApplicationDidChangeStatusBarOrientationNotification
                                                   object:nil];
    }
    return self;
}

- (void)showInView:(UIView *)view animated:(BOOL)animated {
    if (self.state != _STPopoverStateDidDisappear) {
        return;
    }
    self.state = _STPopoverStateWillAppear;

    if (!view) {
        view = [UIApplication sharedApplication].keyWindow;
        [view addSubview:self];
        [self transformCurrentOrientationAnimated:NO];
    } else {
        self.frame = view.bounds;
        [view addSubview:self];
    }

    self.autoresizingMask = [self autoresizeMaskWithDirection:self.direction];
    CGRect frame = [self rectWithSuperView:view direction:self.direction contentOffset:self.contentOffset];
    {
        self.parentView = view;
        self.backgroundView.frame = frame;
        CGFloat targetTop = [self contentOffsetY:[UIApplication sharedApplication].statusBarFrame];
        self.top = targetTop;
        self.height -= targetTop;
    }

    self.backgroundView.alpha = 0.0;

    CGRect fromRect = frame, targetRect = frame;
    switch (self.direction) {
    case STPopoverViewDirectionDown:
        fromRect.size.height = 0;
        break;
    case STPopoverViewDirectionUp:
        fromRect.size.height = 0;
        fromRect.origin.y = CGRectGetMaxY(frame);
        break;
    case STPopoverViewDirectionRight:
        fromRect.size.width = 0;
        break;
    case STPopoverViewDirectionLeft:
        fromRect.size.width = 0;
        fromRect.origin.x = CGRectGetMaxX(frame);
    default:
        break;
    }

    self.contentView.frame = fromRect;
    void (^animation)(void) = ^(void) {
        self.backgroundView.alpha = 0.5;
        self.contentView.frame = targetRect;
    };
    void (^completion)(BOOL) = ^(BOOL finished) {
        self.visible = YES;
        self.state = _STPopoverStateDidAppear;
        CGFloat targetTop = [self contentOffsetY:[UIApplication sharedApplication].statusBarFrame];
        self.top = targetTop;
        self.height -= targetTop;
    };
    if (animated) {
        [UIView animateWithDuration:0.35 animations:animation completion:completion];
    }
}

- (void)dismissAnimated:(BOOL)animated {
    [self _dismissAnimated:animated completion:NULL];
}

#pragma mark - PrivateMethod
- (void)dismissActionFired:(UITapGestureRecognizer *)sender {
    BOOL shouldDismiss = YES;
    if ([self.delegate respondsToSelector:@selector(popoverViewShouldDismiss:)]) {
        shouldDismiss = [self.delegate popoverViewShouldDismiss:self];
    }
    if (shouldDismiss) {
        [self _dismissAnimated:YES
                    completion:^(BOOL finished) {
                        if ([self.delegate respondsToSelector:@selector(popoverViewDidDismiss:)]) {
                            [self.delegate popoverViewDidDismiss:self];
                        }
                    }];
    }
}

- (void)_dismissAnimated:(BOOL)animated completion:(void (^)(BOOL))_completion {
    if (self.state != _STPopoverStateDidAppear) {
        return;
    }
    self.state = _STPopoverStateWillDisappear;

    self.backgroundView.alpha = 0.5;
    CGRect fromRect = self.contentView.frame, targetRect = self.contentView.frame;
    self.contentView.frame = fromRect;
    switch (self.direction) {
    case STPopoverViewDirectionDown:
        targetRect.size.height = 0;
        break;
    case STPopoverViewDirectionUp:
        targetRect.origin.y = CGRectGetMaxY(targetRect);
        targetRect.size.height = 0;
        break;
    case STPopoverViewDirectionRight:
        targetRect.size.width = 0;
        break;
    case STPopoverViewDirectionLeft:
        targetRect.origin.x = CGRectGetMaxX(targetRect);
        targetRect.size.width = 0;
    default:
        break;
    }

    void (^animation)(void) = ^(void) {
        self.backgroundView.alpha = 0.0;
        self.contentView.frame = targetRect;
    };
    void (^completion)(BOOL) = ^(BOOL finished) {
        self.visible = NO;
        self.state = _STPopoverStateDidDisappear;
        if (_completion) {
            _completion(finished);
        }
        [self removeFromSuperview];
    };
    if (animated) {
        [UIView animateWithDuration:0.35 animations:animation completion:completion];
    } else {
        animation();
        completion(YES);
    }
}

- (NSUInteger)autoresizeMaskWithDirection:(STPopoverViewDirection)direction {
    switch (direction) {
    case STPopoverViewDirectionUp:
        return UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    case STPopoverViewDirectionDown:
        return UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    case STPopoverViewDirectionLeft:
        return UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    case STPopoverViewDirectionRight:
        return UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
    }
    return UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin |
           UIViewAutoresizingFlexibleBottomMargin;
}

/*

 switch (interfaceOrientation) {
 case UIInterfaceOrientationPortraitUpsideDown:
 switch (direction) {
 case STPopoverViewDirectionUp:
 direction = STPopoverViewDirectionDown;
 break;
 case STPopoverViewDirectionLeft:
 direction = STPopoverViewDirectionRight;
 break;
 case STPopoverViewDirectionRight:
 direction = STPopoverViewDirectionLeft;
 break;
 case STPopoverViewDirectionDown:
 direction = STPopoverViewDirectionUp;
 break;
 default:
 break;
 }
 break;
 case UIInterfaceOrientationLandscapeLeft:
 switch (direction) {
 case STPopoverViewDirectionUp:
 direction = STPopoverViewDirectionLeft;
 break;
 case STPopoverViewDirectionDown:
 direction = STPopoverViewDirectionRight;
 break;
 case STPopoverViewDirectionLeft:
 direction = STPopoverViewDirectionUp;
 break;
 case STPopoverViewDirectionRight:
 direction = STPopoverViewDirectionDown;
 break;
 default:
 break;
 }
 break;
 case UIInterfaceOrientationLandscapeRight:
 switch (direction) {
 case STPopoverViewDirectionUp:
 direction = STPopoverViewDirectionRight;
 break;
 case STPopoverViewDirectionDown:
 direction = STPopoverViewDirectionLeft;
 break;
 case STPopoverViewDirectionLeft:
 direction = STPopoverViewDirectionDown;
 break;
 case STPopoverViewDirectionRight:
 direction = STPopoverViewDirectionUp;
 break;
 default:
 break;
 }
 break;
 case UIInterfaceOrientationPortrait:
 default:
 break;
 }

 */

- (CGRect)rectWithSuperView:(UIView *)superView direction:(STPopoverViewDirection)direction contentOffset:(CGPoint)offset {

    CGRect rect = superView.frame;
    CGPoint contentOffset = offset;

    UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;

    BOOL keyWindow = [UIApplication sharedApplication].keyWindow == superView;

    CGFloat width = CGRectGetWidth(rect), height = CGRectGetHeight(rect);

    switch (direction) {
    case STPopoverViewDirectionDown:
        if (keyWindow && UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
            rect.origin.y = contentOffset.y;
            rect.size.width = height;
            rect.size.height = width - contentOffset.y;
        } else {
            rect.origin.y = contentOffset.y;
            rect.size.height = height - contentOffset.y;
            rect.size.width = width;
        }
        break;
    case STPopoverViewDirectionUp:
        if (keyWindow && UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
            rect.size.width = height;
            rect.size.height = width - contentOffset.y;
        } else {
            rect.size.height = height - contentOffset.y;
        }

        break;
    case STPopoverViewDirectionLeft:
        rect.size.width = width - contentOffset.x;
        break;
    case STPopoverViewDirectionRight:
        rect.origin.x = contentOffset.x;
        rect.size.width -= contentOffset.x;
        break;
    default:
        break;
    }
    return rect;
}

- (void)statusBarFrameDidChanged:(NSNotification *)notification {
    if (self.state != _STPopoverStateDidAppear) {
        return;
    }
    CGRect statusBarRect = [[notification.userInfo valueForKey:UIApplicationStatusBarFrameUserInfoKey] CGRectValue];
    CGFloat targetTop = [self contentOffsetY:statusBarRect];
    [UIView animateWithDuration:0.35
                     animations:^{
                         self.top = targetTop;
                         self.height -= targetTop;
                     }];
}

- (CGFloat)contentOffsetY:(CGRect)statusBarRect {
    CGFloat statusBarHeight = CGRectGetHeight(statusBarRect);
    if (self.parentView == [UIApplication sharedApplication].keyWindow &&
        UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        /// 这里为什么要判断25 呢，保险一点，如果改变，要么是20，要么是40.这里主要是怕那天navigationBarHeight发生一点小变化
        if (statusBarHeight > 25) {
            return statusBarHeight - 20;
        }
    }
    return 0;
}

- (void)statusBarOrientationDidChange:(NSNotification *)notification {
    if ([self.superview isKindOfClass:[UIWindow class]]) {
        [self transformCurrentOrientationAnimated:YES];
    }
}

- (void)transformCurrentOrientationAnimated:(BOOL)animated {
    if (![self.superview isKindOfClass:[UIWindow class]]) {
        return;
    }
    self.transform = CGAffineTransformIdentity;
    self.frame = self.superview.bounds;
    switch ([UIApplication sharedApplication].statusBarOrientation) {
    case UIInterfaceOrientationPortrait:
        self.transform = CGAffineTransformIdentity;
        break;
    case UIInterfaceOrientationPortraitUpsideDown:
        self.transform = CGAffineTransformMakeRotation(M_PI);
        break;
    case UIInterfaceOrientationLandscapeLeft:
        self.bounds = CGRectMake(0, 0, self.bounds.size.height, self.bounds.size.width);
        self.transform = CGAffineTransformMakeRotation(-M_PI_2);
        break;
    case UIInterfaceOrientationLandscapeRight:
        self.bounds = CGRectMake(0, 0, self.bounds.size.height, self.bounds.size.width);
        self.transform = CGAffineTransformMakeRotation(M_PI_2);
    default:
        break;
    }
}

@end
