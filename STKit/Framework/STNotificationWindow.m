//
//  STNotificationWindow.m
//  STKit
//
//  Created by SunJiangting on 13-11-28.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import "STNotificationWindow.h"
#import "STImageView.h"
#import "UIKit+STKit.h"
#import "Foundation+STKit.h"
#import "STLabel.h"
#import <QuartzCore/QuartzCore.h>

@class STNotificationWindow;
@interface STNotificationView ()

@property(nonatomic, strong) STNotificationWindow *notificationWindow;

@property(nonatomic, strong) UIView *contentView;
@property(nonatomic, strong) STImageView *imageView;
@property(nonatomic, strong) STLabel *textLabel;
@property(nonatomic, strong) STLabel *detailLabel;

@property(nonatomic, strong) UIButton *closeButton;

@property(nonatomic, strong) UIButton *controlButton;

@end

@implementation STNotificationView
- (void)dealloc {
    [self.imageView removeObserver:self forKeyPath:@"image"];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView = [[UIView alloc] initWithFrame:self.bounds];
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.contentView.backgroundColor = [UIColor st_colorWithRGB:0xB6D334];
        [self addSubview:self.contentView];

        CGFloat offsetY = (STGetSystemVersion() >= 7) ? 20 : 0;
        self.imageView = [[STImageView alloc] initWithFrame:CGRectMake(5, 5 + offsetY, 34, 34)];
        self.imageView.autoresizingMask =
            UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        [self.contentView addSubview:self.imageView];

        self.textLabel = [[STLabel alloc] initWithFrame:CGRectMake(20, 3 + offsetY, 230, 17)];
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.textColor = [UIColor st_colorWithRGB:0x232424];
        self.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:15];
        self.textLabel.verticalAlignment = STVerticalAlignmentMiddle;
        self.textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:self.textLabel];

        self.detailLabel = [[STLabel alloc] initWithFrame:CGRectMake(20, 22 + offsetY, 230, 15)];
        self.detailLabel.backgroundColor = [UIColor clearColor];
        self.detailLabel.textColor = [UIColor st_colorWithRGB:0x232424];
        self.detailLabel.numberOfLines = 0;
        self.detailLabel.verticalAlignment = STVerticalAlignmentTop;
        self.detailLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:12];
        ;
        self.detailLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.detailLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:self.detailLabel];

        self.controlButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.controlButton addTarget:self action:@selector(controlButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
        self.controlButton.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds) - 44, CGRectGetHeight(self.bounds));
        self.controlButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:self.controlButton];
        
        self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.closeButton.frame = CGRectMake(CGRectGetMaxX(self.contentView.frame) - 44, offsetY, 44, self.contentView.height - offsetY);
        [self.closeButton addTarget:self action:@selector(closeMessage:) forControlEvents:UIControlEventTouchUpInside];
        self.closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:self.closeButton];
        
        [self.imageView addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (self.imageView.image) {
        self.textLabel.left = 44;
        self.detailLabel.left = 44;
    } else {
        self.textLabel.left = 20;
        self.detailLabel.left = 20;
    }
}

- (void)controlButtonDidClick:(id)sender {
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)closeMessage:(id)sender {
    [self.notificationWindow popNotificationViewAnimated:YES];
}

@end

@interface STNotificationWindow ()

@property(nonatomic, weak) UIWindow *belowWindow;

@property(nonatomic, strong) NSMutableArray *notificationViewArray;

@property(nonatomic, assign) BOOL dismissing;

@end

@implementation STNotificationWindow

- (void)dealloc {
}

- (id)initWithFrame:(CGRect)frame {
    CGRect rect0 = [UIScreen mainScreen].applicationFrame;
    rect0.size.height = 44;
    if (STGetSystemVersion() >= 7) {
        rect0.size.height = 64;
        rect0.origin.y = 0;
    }

    self = [super initWithFrame:rect0];
    if (self) {
        // Initialization code
        self.windowLevel = UIWindowLevelNormal + 1;
        self.backgroundColor = [UIColor blackColor];

        _maximumNumberOfWindows = 1;
        _displayDuration = 5.0;
        _notificationViewArray = [NSMutableArray arrayWithCapacity:5];
        _belowWindow = [UIApplication sharedApplication].keyWindow;
        self.windowLevel = _belowWindow.windowLevel;
        [self makeKeyAndVisible];
    }
    return self;
}

- (void)pushNotificationView:(STNotificationView *)notificationView animated:(BOOL)animated {
    if (!notificationView) {
        return;
    }
    [[self class] cancelPreviousPerformRequestsWithTarget:self];
    UIView *previousView;
    if (_notificationViewArray.count >= 1) {
        previousView = [_notificationViewArray lastObject];
    } else {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        imageView.image = [self screenshotInView:self.belowWindow rect:self.frame];
        previousView = imageView;
    }

    BOOL hasSuperView = !!(previousView.superview);
    if (!hasSuperView) {
        [self addSubview:previousView];
    }
    notificationView.notificationWindow = self;
    notificationView.frame = self.bounds;

    [self addSubview:notificationView];
    [_notificationViewArray addObject:notificationView];

    [self rolldownFromView:previousView
                    toView:notificationView
                completion:^(BOOL complete) {
                    if (!hasSuperView) {
                        [previousView removeFromSuperview];
                    }
                    if (self.notificationViewArray.count > self.maximumNumberOfWindows && self.maximumNumberOfWindows > 0) {
                        UIView *firstView = [self.notificationViewArray objectAtIndex:0];
                        [self.notificationViewArray removeObject:firstView];
                        [firstView removeFromSuperview];
                    }
                    [self performSelector:@selector(popNotificationViewAnimated:) withObject:@(YES) afterDelay:self.displayDuration];
                }];
}

- (void)popNotificationViewAnimated:(BOOL)animated {
    if (self.dismissing) {
        [[self class] cancelPreviousPerformRequestsWithTarget:self];
        return;
    }
    NSUInteger count = _notificationViewArray.count;
    if (count == 0) {
        if ([self.notificationWindowDelegate respondsToSelector:@selector(allNoticationViewDismissed)]) {
            [self.notificationWindowDelegate allNoticationViewDismissed];
        }
        return;
    }
    self.dismissing = YES;
    /// _messageViews.count >= 1
    UIView *view = [_notificationViewArray lastObject];
    UIView *previousView;
    if (count >= 2) {
        previousView = [_notificationViewArray objectAtIndex:count - 2];
    } else {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        imageView.image = [self screenshotInView:self.belowWindow rect:self.frame];
        previousView = imageView;
    }

    BOOL hasSuperView = !!(previousView.superview);
    if (!hasSuperView) {
        [self addSubview:previousView];
    }
    [self rollupFromView:view
                  toView:previousView
              completion:^(BOOL complete) {
                  if (!hasSuperView) {
                      [previousView removeFromSuperview];
                  }
                  [view removeFromSuperview];
                  [_notificationViewArray removeObject:view];
                  if (self.notificationViewArray.count == 0) {
                      [[self class] cancelPreviousPerformRequestsWithTarget:self];
                      if ([self.notificationWindowDelegate respondsToSelector:@selector(allNoticationViewDismissed)]) {
                          [self.notificationWindowDelegate allNoticationViewDismissed];
                      }
                  } else {
                      [self performSelector:@selector(popNotificationViewAnimated:) withObject:@(YES) afterDelay:self.displayDuration];
                  }
                  self.dismissing = NO;
              }];
}

#pragma mark - Private Method
- (void)rolldownFromView:(UIView *)fromView toView:(UIView *)toView completion:(void (^)(BOOL complete))completion {
    if (!fromView.superview) {
        [self addSubview:fromView];
    }
    if (!toView.superview) {
        [self addSubview:toView];
    }
    self.backgroundColor = [UIColor blackColor];
    fromView.layer.anchorPointZ = 11.547f;
    fromView.layer.doubleSided = NO;
    fromView.layer.zPosition = 2;

    toView.layer.anchorPointZ = 11.547f;
    toView.layer.doubleSided = NO;
    toView.layer.zPosition = 2;

    CATransform3D viewInStartTransform = CATransform3DMakeRotation(STDegreeToRadian(-120), 1.0, 0.0, 0.0);
    viewInStartTransform.m34 = -1.0 / 200.0;
    toView.layer.transform = viewInStartTransform;

    CATransform3D viewOutEndTransform = CATransform3DMakeRotation(STDegreeToRadian(120), 1.0, 0.0, 0.0);
    viewOutEndTransform.m34 = -1.0 / 200.0;

    [UIView animateWithDuration:0.45
        delay:0.0
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
            toView.layer.transform = CATransform3DIdentity;
            fromView.layer.transform = viewOutEndTransform;
        }
        completion:^(BOOL finished) {
            self.backgroundColor = [UIColor clearColor];
            if (completion) {
                completion(finished);
            }
        }];
}

- (void)rollupFromView:(UIView *)fromView toView:(UIView *)toView completion:(void (^)(BOOL complete))completion {
    if (!fromView.superview) {
        [self addSubview:fromView];
    }
    if (!toView.superview) {
        [self addSubview:toView];
    }
    self.backgroundColor = [UIColor blackColor];
    fromView.layer.anchorPointZ = 11.547f;
    fromView.layer.doubleSided = NO;
    fromView.layer.zPosition = 2;

    toView.layer.anchorPointZ = 11.547f;
    toView.layer.doubleSided = NO;
    toView.layer.zPosition = 2;

    CATransform3D viewInStartTransform = CATransform3DMakeRotation(STDegreeToRadian(120), 1.0, 0.0, 0.0);
    viewInStartTransform.m34 = -1.0 / 200.0;
    toView.layer.transform = viewInStartTransform;

    CATransform3D viewOutEndTransform = CATransform3DMakeRotation(STDegreeToRadian(-120), 1.0, 0.0, 0.0);
    viewOutEndTransform.m34 = -1.0 / 200.0;

    [UIView animateWithDuration:0.45
        delay:0.0
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
            toView.layer.transform = CATransform3DIdentity;
            fromView.layer.transform = viewOutEndTransform;
        }
        completion:^(BOOL finished) {
            self.backgroundColor = [UIColor clearColor];
            if (completion) {
                completion(finished);
            }
        }];
}

- (void)makeKeyAndVisible {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    [super makeKeyAndVisible];
    [keyWindow makeKeyWindow];
}

- (UIImage *)screenshotInView:(UIView *)view rect:(CGRect)rect {
    if (!view) {
        return nil;
    }
    CALayer *layer = view.layer;
    CGFloat scale = [UIScreen mainScreen].scale;
    UIGraphicsBeginImageContextWithOptions(layer.frame.size, NO, scale);
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    rect = CGRectMake(rect.origin.x * scale, rect.origin.y * scale, rect.size.width * scale, rect.size.height * scale);

    CGImageRef imageRef = CGImageCreateWithImageInRect(screenshot.CGImage, rect);
    UIImage *croppedScreenshot = [UIImage imageWithCGImage:imageRef scale:screenshot.scale orientation:screenshot.imageOrientation];
    CGImageRelease(imageRef);
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIImageOrientation imageOrientation = UIImageOrientationUp;
    switch (orientation) {
    case UIDeviceOrientationPortraitUpsideDown:
        imageOrientation = UIImageOrientationDown;
        break;
    case UIDeviceOrientationLandscapeRight:
        imageOrientation = UIImageOrientationRight;
        break;
    case UIDeviceOrientationLandscapeLeft:
        imageOrientation = UIImageOrientationLeft;
        break;
    default:
        break;
    }

    return [[UIImage alloc] initWithCGImage:croppedScreenshot.CGImage scale:croppedScreenshot.scale orientation:imageOrientation];
}

@end

@implementation STNotificationWindow (STNotificationView)

+ (STNotificationView *)notificationViewWithInfo:(NSDictionary *)info {
    CGRect rect0 = [UIScreen mainScreen].applicationFrame;
    rect0.size.height = 44;
    if (STGetSystemVersion() >= 7) {
        rect0.size.height = 64;
        rect0.origin.y = 0;
    }
    STNotificationView *notificationView = [[STNotificationView alloc] initWithFrame:rect0];
    if ([info valueForKey:STNotificationViewImageNameKey]) {
        notificationView.imageView.image = [UIImage imageNamed:[info valueForKey:STNotificationViewImageNameKey]];
    }
    id textValue = [info valueForKey:STNotificationViewTitleTextKey];
    if (textValue) {
        notificationView.textLabel.text = textValue;
    }
    id detailValue = [info valueForKey:STNotificationViewDetailTextKey];
    if (detailValue) {
        notificationView.detailLabel.text = detailValue;
    }
    return notificationView;
}
@end

NSString *const STNotificationViewImageNameKey = @"imageName";
NSString *const STNotificationViewTitleTextKey = @"text";
NSString *const STNotificationViewDetailTextKey = @"detail";