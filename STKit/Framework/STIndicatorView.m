//
//  STIndicatorView.m
//  STKit
//
//  Created by SunJiangting on 14-7-3.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STIndicatorView.h"
#import "Foundation+STKit.h"
#import "UIKit+STKit.h"
#import "STPersistence.h"
#import "STVisualBlurView.h"

@interface STIndicatorView () {
    CGAffineTransform _rotationTransform;
}

@property(nonatomic, weak)   UIView  *parentView;

@property(nonatomic, strong) UILabel *textLabel;
@property(nonatomic, strong) UILabel *detailLabel;
@property(nonatomic, strong) UIView  *activityIndicatorView;

@property(nonatomic, strong) UIView  *backgroundView;

@property(nonatomic, assign) CGSize size;
@property(nonatomic, assign) CGFloat subviewPadding;

@end

@implementation STIndicatorView

- (void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_textLabel removeObserver:self forKeyPath:@"text"];
    [_textLabel removeObserver:self forKeyPath:@"font"];

    [_detailLabel removeObserver:self forKeyPath:@"text"];
    [_detailLabel removeObserver:self forKeyPath:@"font"];
}

+ (instancetype)showInView:(UIView *)view animated:(BOOL)animated {
    STIndicatorView *indicatorView = [[STIndicatorView alloc] initWithView:view];
    [indicatorView showAnimated:animated];
    return indicatorView;
}

+ (BOOL)hideInView:(UIView *)view animated:(BOOL)animated {
    NSArray *viewToRemove = [self allIndicatorInView:view];
    if (viewToRemove.count == 0) {
        return NO;
    }
    [viewToRemove enumerateObjectsUsingBlock:^(STIndicatorView *indicatorView, NSUInteger idx, BOOL *stop) {
        indicatorView.removeWhenStopped = YES;
        [indicatorView hideAnimated:animated];
    }];
    return YES;
}

+ (instancetype)indicatorInView:(UIView *)view {
    NSArray *indicatorViews = [self allIndicatorInView:view];
    if (indicatorViews.count == 0) {
        return nil;
    }
    return [indicatorViews objectAtIndex:0];
}

+ (NSArray *)allIndicatorInView:(UIView *)view {
    NSMutableArray *indicatorViews = [NSMutableArray array];
    NSArray *subviews = view.subviews;
    for (UIView *subview in subviews) {
        if ([subview isKindOfClass:[self class]]) {
            [indicatorViews addObject:subview];
        }
    }
    return [NSArray arrayWithArray:indicatorViews];
}

- (instancetype)initWithView:(UIView *)view {
    if (!view) {
        view = [UIApplication sharedApplication].keyWindow;
    }
    self = [super initWithFrame:view.bounds];
    if (self) {
        self.minimumSize = CGSizeMake(80, 80);
        self.parentView = view;

        _rotationTransform = CGAffineTransformIdentity;
        if ([view isKindOfClass:[UIWindow class]]) {
            [self transformCurrentOrientationAnimated:NO];
        }
        self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin |
                                UIViewAutoresizingFlexibleRightMargin;
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
        self.alpha = 0.0f;

        self.backgroundView = UIView.new;
        self.backgroundView.layer.masksToBounds = YES;
        [self addSubview:self.backgroundView];

        self.indicatorType = STIndicatorTypeWaiting;
        _contentInsets = UIEdgeInsetsMake(15, 15, 15, 15);
        self.cornerRadius = 10.;
        _subviewPadding = 8.;

        _textLabel = [[UILabel alloc] initWithFrame:self.bounds];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.font = [UIFont systemFontOfSize:16.];
        _textLabel.adjustsFontSizeToFitWidth = NO;
        _textLabel.opaque = NO;
        _textLabel.backgroundColor = [UIColor clearColor];
        _textLabel.textColor = [UIColor whiteColor];
        [self addSubview:_textLabel];

        _detailLabel = [[UILabel alloc] initWithFrame:self.bounds];
        _detailLabel.textAlignment = NSTextAlignmentCenter;
        _detailLabel.font = [UIFont systemFontOfSize:12.];
        _detailLabel.adjustsFontSizeToFitWidth = NO;
        _detailLabel.opaque = NO;
        _detailLabel.backgroundColor = [UIColor clearColor];
        _detailLabel.textColor = [UIColor whiteColor];
        _detailLabel.numberOfLines = 0;
        _detailLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self addSubview:_detailLabel];

        [self layoutCustomView];
        NSUInteger options = (NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew);
        [_textLabel addObserver:self forKeyPath:@"text" options:options context:NULL];
        [_textLabel addObserver:self forKeyPath:@"font" options:options context:NULL];

        [_detailLabel addObserver:self forKeyPath:@"text" options:options context:NULL];
        [_detailLabel addObserver:self forKeyPath:@"font" options:options context:NULL];

        self.blurEffectStyle = STBlurEffectStyleDark;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(deviceOrientationDidChange:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    return [self initWithView:[UIApplication sharedApplication].keyWindow];
}

- (void)showAnimated:(BOOL)animated {
    if (!self.superview) {
        [self.parentView addSubview:self];
    }
    self.alpha = 1.0;
    if (animated) {
        self.alpha = 0.0f;
        self.transform = CGAffineTransformConcat(_rotationTransform, CGAffineTransformMakeScale(0.5f, 0.5f));
        [UIView animateWithDuration:0.3
            animations:^{
                self.alpha = 1.0;
                self.transform = _rotationTransform;
            }
            completion:^(BOOL finished) { self.transform = _rotationTransform; }];
    } else {
        self.transform = _rotationTransform;
    }
}

- (void)hideAnimated:(BOOL)animated {
    [self hideAnimated:animated afterDelay:0.0];
}

/// 延时关闭
- (void)hideAnimated:(BOOL)animated afterDelay:(NSTimeInterval)delay {
    [self hideAnimated:animated afterDelay:delay completion:NULL];
}

- (void)hideAnimated:(BOOL)animated afterDelay:(NSTimeInterval)delay completion:(void (^)(void))completion {
    self.removeWhenStopped = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self _hideAnimated:animated
                 completion:^(BOOL finished) {
                     if (completion) {
                         completion();
                     }
                 }];
    });
}

#pragma mark - OverrideMethod

- (void)layoutSubviews {
    [super layoutSubviews];

    if (self.superview) {
        self.frame = self.superview.bounds;
    }
    CGRect bounds = self.bounds;
    CGFloat horizontalMargin = (self.contentInsets.left + self.contentInsets.right);
    CGFloat verticalMargin = (self.contentInsets.top + self.contentInsets.bottom);

    CGFloat maxWidth = bounds.size.width - 2 * horizontalMargin;

    CGSize totalSize = CGSizeZero;
    CGRect indicatorFrame = self.activityIndicatorView.bounds;

    indicatorFrame.size.width = MIN(indicatorFrame.size.width, maxWidth);
    totalSize.width = MAX(totalSize.width, indicatorFrame.size.width);
    totalSize.height += CGRectGetHeight(indicatorFrame);

    CGSize textSize = (self.textLabel.text.length == 0) ? CGSizeZero : [self.textLabel.text sizeWithFont:self.textLabel.font];
    textSize.width = MIN(textSize.width, maxWidth);
    totalSize.width = MAX(totalSize.width, textSize.width);
    totalSize.height += textSize.height;

    if (textSize.height > 0.f && indicatorFrame.size.height > 0.f) {
        totalSize.height += self.subviewPadding;
    }

    CGFloat remainingHeight = bounds.size.height - totalSize.height - 4.0 - 2 * (verticalMargin + horizontalMargin);

    CGSize maxSize = CGSizeMake(maxWidth, remainingHeight);

    CGSize detailSize =
        (self.detailLabel.text.length == 0)
            ? CGSizeZero
            : [self.detailLabel.text sizeWithFont:self.detailLabel.font constrainedToSize:maxSize lineBreakMode:self.detailLabel.lineBreakMode];

    totalSize.width = MAX(totalSize.width, detailSize.width);
    totalSize.height += detailSize.height;
    if (detailSize.height > 0.f && (indicatorFrame.size.height > 0.f || textSize.height > 0.f)) {
        totalSize.height += self.subviewPadding;
    }

    totalSize.width += horizontalMargin;
    totalSize.height += verticalMargin;

    CGFloat yPos = round(((bounds.size.height - totalSize.height) / 2)) + self.contentInsets.top + self.contentOffset.y;
    CGFloat xPos = self.contentOffset.x;

    indicatorFrame.origin.x = round((bounds.size.width - indicatorFrame.size.width) / 2) + xPos;
    indicatorFrame.origin.y = yPos;
    self.activityIndicatorView.frame = indicatorFrame;
    yPos += indicatorFrame.size.height;

    if (textSize.height > 0.f && indicatorFrame.size.height > 0.f) {
        yPos += self.subviewPadding;
    }
    CGRect textFrame;
    textFrame.origin.x = round((bounds.size.width - textSize.width) / 2) + xPos;
    textFrame.origin.y = yPos;
    textFrame.size = textSize;
    _textLabel.frame = textFrame;
    yPos += textFrame.size.height;

    if (detailSize.height > 0.f && (indicatorFrame.size.height > 0.f || textSize.height > 0.f)) {
        yPos += self.subviewPadding;
    }
    CGRect detailLabelFrame;
    detailLabelFrame.origin.x = round((bounds.size.width - detailSize.width) / 2) + xPos;
    detailLabelFrame.origin.y = yPos;
    detailLabelFrame.size = detailSize;
    _detailLabel.frame = detailLabelFrame;

    // Enforce minsize and quare rules
    if (self.forceSquare) {
        CGFloat max = MAX(totalSize.width, totalSize.height);
        if (max <= bounds.size.width - horizontalMargin) {
            totalSize.width = max;
        }
        if (max <= bounds.size.height - verticalMargin) {
            totalSize.height = max;
        }
    }
    if (totalSize.width < self.minimumSize.width) {
        totalSize.width = self.minimumSize.width;
    }
    if (totalSize.height < self.minimumSize.height) {
        totalSize.height = self.minimumSize.height;
    }
    self.size = totalSize;
    self.backgroundView.size = self.size;
    self.backgroundView.center = self.inCenter;
}

#pragma mark - Private Method
- (void)layoutCustomView {
    BOOL isActivityIndicator = [self.activityIndicatorView isKindOfClass:[UIActivityIndicatorView class]];
    if (self.indicatorType == STIndicatorTypeWaiting && !isActivityIndicator) {
        // Update to indeterminate indicator
        [self.activityIndicatorView removeFromSuperview];
        UIActivityIndicatorView *indicatorView =
            [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [indicatorView startAnimating];
        indicatorView.hidesWhenStopped = YES;
        [self addSubview:indicatorView];
        self.activityIndicatorView = indicatorView;
    } else if (self.indicatorType == STIndicatorTypeCustom && self.customView != self.activityIndicatorView) {
        // Update custom view indicator
        [self.activityIndicatorView removeFromSuperview];
        self.activityIndicatorView = self.customView;
        [self addSubview:self.activityIndicatorView];
    } else if (self.indicatorType == STIndicatorTypeText) {
        [self.activityIndicatorView removeFromSuperview];
        self.activityIndicatorView = nil;
    }
}

- (void)displayBlurImage {
    if ([self.activityIndicatorView isKindOfClass:[UIActivityIndicatorView class]]) {
        UIActivityIndicatorView *indicatorView = (UIActivityIndicatorView *)self.activityIndicatorView;
        if (self.blurEffectStyle == STBlurEffectStyleNone || self.blurEffectStyle == STBlurEffectStyleDark) {
            indicatorView.color = [UIColor whiteColor];
        } else {
            indicatorView.color = [UIColor colorWithRGB:0x999999 alpha:0.8];
        }
    }

    if (self.blurEffectStyle == STBlurEffectStyleNone || self.blurEffectStyle == STBlurEffectStyleDark) {
        self.textLabel.textColor = [UIColor whiteColor];
        self.detailLabel.textColor = [UIColor whiteColor];
    } else {
        self.textLabel.textColor = [UIColor colorWithRGB:0x0 alpha:0.8];
        self.detailLabel.textColor = [UIColor colorWithRGB:0x0 alpha:0.8];
    }

    [self setNeedsDisplay];
}

- (void)_hideAnimated:(BOOL)animated completion:(void (^)(BOOL))_completion {
    [self setNeedsDisplay];
    void (^completion)(BOOL) = ^(BOOL finished) {
        self.alpha = 0.0f;
        [(NSObject *)self.delegate performSelector:@selector(indicatorViewDidHidden:) withObjects:nil];
        if (self.removeWhenStopped) {
            [self removeFromSuperview];
        }
        if (_completion) {
            _completion(finished);
        }
    };
    if (animated) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.transform = CGAffineTransformConcat(_rotationTransform, CGAffineTransformMakeScale(0.5f, 0.5f));
                             self.alpha = 0.4f;
                         }
                         completion:completion];
    } else {
        completion(YES);
    }
}

- (void)deviceOrientationDidChange:(NSNotification *)notification {
    if (!self.superview) {
        return;
    }
    if ([self.superview isKindOfClass:[UIWindow class]]) {
        [self transformCurrentOrientationAnimated:YES];
    } else {
        self.bounds = self.superview.bounds;
        [self setNeedsDisplay];
    }
}

- (void)transformCurrentOrientationAnimated:(BOOL)animated {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    NSInteger degrees = 0;

    // Stay in sync with the superview
    if (self.superview) {
        self.bounds = self.superview.bounds;
        [self setNeedsDisplay];
    }
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        if (orientation == UIInterfaceOrientationLandscapeLeft) {
            degrees = -90;
        } else {
            degrees = 90;
        }
        self.bounds = CGRectMake(0, 0, self.bounds.size.height, self.bounds.size.width);
    } else {
        if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
            degrees = 180;
        } else {
            degrees = 0;
        }
    }
    _rotationTransform = CGAffineTransformMakeRotation(STDegreeToRadian(degrees));
    if (animated) {
        [UIView animateWithDuration:0.5 animations:^{ self.transform = _rotationTransform; }];
    } else {
        self.transform = _rotationTransform;
    }
}

#pragma mark - KVObsercer
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

#pragma mark - Setter
- (void)setIndicatorType:(STIndicatorType)indicatorType {
    _indicatorType = indicatorType;
    [self layoutCustomView];
}

- (void)setCustomView:(UIView *)customView {
    _customView = customView;
    [self layoutCustomView];
}

- (void)setMinimumSize:(CGSize)minimumSize {
    if (self.superview) {
        CGSize size = self.frame.size;
        if (size.width < self.minimumSize.width) {
            size.width = self.minimumSize.width;
        }
        if (size.height < self.minimumSize.height) {
            size.height = self.minimumSize.height;
        }
        self.size = size;
        self.backgroundView.size = self.size;
        self.backgroundView.center = self.inCenter;
    }
    _minimumSize = minimumSize;
}

- (void)setBlurEffectStyle:(STBlurEffectStyle)blurEffectStyle {
    [self.backgroundView removeAllSubviews];
    STVisualBlurView *blurView = [[STVisualBlurView alloc] initWithBlurEffectStyle:blurEffectStyle];
    blurView.frame = self.bounds;
    blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.backgroundView addSubview:blurView];
    _blurEffectStyle = blurEffectStyle;
    [self displayBlurImage];
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    self.backgroundView.layer.cornerRadius = cornerRadius;
    _cornerRadius = cornerRadius;
}

@end
