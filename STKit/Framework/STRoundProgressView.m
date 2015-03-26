//
//  STRoundProgressView.m
//  STKit
//
//  Created by SunJiangting on 13-11-26.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import "STRoundProgressView.h"

#import <QuartzCore/QuartzCore.h>

#define DEGREES_TO_RADIANS(x) (x) / 180.0 * M_PI
#define RADIANS_TO_DEGREES(x) (x) / M_PI * 180.0

@interface STRoundProgressLayer : CALayer

@property(nonatomic, strong) UIColor *tintColor;

@end

@implementation STRoundProgressLayer

- (id)init {
    self = [super init];
    if (self) {
        self.contentsScale = [UIScreen mainScreen].scale;
    }
    return self;
}

- (void)setTintColor:(UIColor *)tintColor {
    _tintColor = tintColor;
    [self setNeedsDisplay];
}

- (void)drawInContext:(CGContextRef)ctx {
    CGContextSetFillColorWithColor(ctx, self.tintColor.CGColor);
    CGContextSetStrokeColorWithColor(ctx, self.tintColor.CGColor);
    CGContextStrokeEllipseInRect(ctx, CGRectInset(self.bounds, 1, 1));
    CGContextFillRect(ctx, CGRectMake(CGRectGetMidX(self.bounds) - 4, CGRectGetMidY(self.bounds) - 4, 8, 8));
}

@end

@interface STRoundProgressView ()

@property(nonatomic, strong) STRoundProgressLayer *backgroundLayer;
@property(nonatomic, strong) CAShapeLayer *shapeLayer;

@end

@implementation STRoundProgressView {
    UIColor *_progressTintColor;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (frame.size.width == 0) {
        frame.size = CGSizeMake(56, 56);
    }
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {

    _progressTintColor = [UIColor blackColor];

    // Set up the background layer

    STRoundProgressLayer *backgroundLayer = [[STRoundProgressLayer alloc] init];
    backgroundLayer.frame = self.bounds;
    backgroundLayer.tintColor = self.progressTintColor;
    [self.layer addSublayer:backgroundLayer];
    self.backgroundLayer = backgroundLayer;

    // Set up the shape layer

    CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
    shapeLayer.frame = self.bounds;
    shapeLayer.fillColor = nil;
    shapeLayer.strokeColor = self.progressTintColor.CGColor;

    [self.layer addSublayer:shapeLayer];
    self.shapeLayer = shapeLayer;
    [self startIndeterminateAnimation];
}

#pragma mark - Accessors

- (void)setCompletion:(CGFloat)completion animated:(BOOL)animated {
    CGFloat cc = _completion;
    [super willChangeValueForKey:@"completion"];
    _completion = completion;
    [super willChangeValueForKey:@"completion"];
    if (completion > 0) {
        BOOL startingFromIndeterminateState = [self.shapeLayer animationForKey:@"indeterminateAnimation"] != nil;
        [self stopIndeterminateAnimation];
        self.shapeLayer.lineWidth = 3;
        CGFloat midX = CGRectGetMidX(self.bounds);
        CGFloat midY = CGRectGetMidY(self.bounds);
        self.shapeLayer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(midX, midY)
                                                              radius:self.bounds.size.width / 2 - 2
                                                          startAngle:3 * M_PI_2
                                                            endAngle:3 * M_PI_2 + 2 * M_PI
                                                           clockwise:YES].CGPath;

        if (animated) {
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
            animation.fromValue = (startingFromIndeterminateState) ? @0 : @(cc);
            animation.toValue = [NSNumber numberWithFloat:completion];
            animation.duration = 1;
            self.shapeLayer.strokeEnd = completion;
            [self.shapeLayer addAnimation:animation forKey:@"animation"];
        } else {
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            self.shapeLayer.strokeEnd = completion;
            [CATransaction commit];
        }
    } else {
        // If progress is zero, then add the indeterminate animation
        [self.shapeLayer removeAnimationForKey:@"animation"];
        [self startIndeterminateAnimation];
    }
}

- (void)setCompletion:(CGFloat)completion {
    [self setCompletion:completion animated:NO];
}

- (void)setProgressTintColor:(UIColor *)progressTintColor {
    if ([self respondsToSelector:@selector(setTintColor:)]) {
        [self performSelector:@selector(setTintColor:) withObject:progressTintColor];
    } else {
        _progressTintColor = progressTintColor;
        [self tintColorDidChange];
    }
}

- (UIColor *)progressTintColor {
    if ([self respondsToSelector:@selector(tintColor)]) {
        return [self valueForKey:@"tintColor"];
    } else {
        return _progressTintColor;
    }
}

#pragma mark - UIControl overrides

- (void)sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
    // Ignore touches that occur before progress initiates
    if (self.completion > 0) {
        [super sendAction:action to:target forEvent:event];
    }
}

#pragma mark - Other methods

- (void)tintColorDidChange {
    self.backgroundLayer.tintColor = self.progressTintColor;
    self.shapeLayer.strokeColor = self.progressTintColor.CGColor;
}

- (void)startIndeterminateAnimation {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    self.backgroundLayer.hidden = YES;

    self.shapeLayer.lineWidth = 1;
    self.shapeLayer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
                                                          radius:self.bounds.size.width / 2 - 1
                                                      startAngle:DEGREES_TO_RADIANS(348)
                                                        endAngle:DEGREES_TO_RADIANS(12)
                                                       clockwise:NO].CGPath;
    self.shapeLayer.strokeEnd = 1;

    [CATransaction commit];

    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    rotationAnimation.toValue = [NSNumber numberWithFloat:2 * M_PI];
    rotationAnimation.duration = 1.0;
    rotationAnimation.repeatCount = HUGE_VALF;

    [self.shapeLayer addAnimation:rotationAnimation forKey:@"indeterminateAnimation"];
}

- (void)stopIndeterminateAnimation {
    [self.shapeLayer removeAnimationForKey:@"indeterminateAnimation"];

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.backgroundLayer.hidden = NO;
    [CATransaction commit];
}

@end
