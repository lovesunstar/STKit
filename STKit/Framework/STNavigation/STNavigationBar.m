//
//  STNavigationBar.m
//  STKit
//
//  Created by SunJiangting on 14-2-18.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STNavigationBar.h"
#import "UIKit+STKit.h"
#import "STVisualBlurView.h"
#import "STResourceManager.h"

@interface STNavigationBar ()
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UIView *backgroundView;
@property(nonatomic, strong) UIView *transitionView;
@property(nonatomic, strong) UIView *separatorView;
@property(nonatomic, strong) UIView *contentView;
@property(nonatomic, strong) UIImageView *backgroundImageView;
@property(nonatomic, strong) UIColor *defaultBackgroundColor;
@end

@implementation STNavigationBar

- (id)initWithFrame:(CGRect)frame {
    CGFloat height = (STGetSystemVersion() >= 7) ? 64 : 44;
    if (frame.size.height < height) {
        frame.size.height = height;
    }
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundView = [[STVisualBlurView alloc] initWithBlurEffectStyle:STBlurEffectStyleExtraLight];
        
        self.backgroundImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.backgroundImageView.clipsToBounds = YES;
        [self addSubview:self.backgroundImageView];
        
        if (!self.backgroundView) {
            self.backgroundView = self.backgroundImageView;
        }

        self.backgroundView.frame = self.bounds;
        self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.backgroundView];

        CGFloat transitionHeight = 44;
        CGFloat topMargin = CGRectGetHeight(frame) - transitionHeight;
        self.transitionView = [[UIView alloc] initWithFrame:CGRectMake(0, topMargin, CGRectGetWidth(self.bounds), transitionHeight)];
        self.transitionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.transitionView.clipsToBounds = YES;
        [self addSubview:self.transitionView];

        self.contentView = [[UIView alloc] initWithFrame:self.transitionView.bounds];
        [self.transitionView addSubview:self.contentView];

        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.textColor = [UIColor colorWithRGB:0xFF7300];
        self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.titleLabel.font = [UIFont boldSystemFontOfSize:19.];
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleView = self.titleLabel;
        
        self.separatorView = [[UIView alloc] init];
        [self addSubview:self.separatorView];
        
        if (STGetSystemVersion() >= 7) {
            self.separatorView.backgroundColor = [UIColor colorWithRGB:0x999999];
        } else {
            self.separatorView.backgroundColor = [UIColor colorWithRGB:0xcccccc];
            self.backgroundImage = [STResourceManager imageWithResourceID:STImageResourceNavigationBarID];
        }
    }
    return self;
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    self.backgroundImageView.image = backgroundImage;
}

- (UIImage *)backgroundImage {
    return self.backgroundImageView.image;
}

- (void)setTitle:(NSString *)title {
    _title = [title copy];
    self.titleLabel.text = title;
}

- (void)setTitleView:(UIView *)titleView {
    if (titleView) {
        [_titleView removeFromSuperview];
    }
    _titleView = titleView;
    if (titleView) {
        [self.contentView addSubview:titleView];
        [self relayoutSubviews];
    }
}

- (void)setLeftBarView:(UIView *)leftBarView {
    if (_leftBarView) {
        [_leftBarView removeFromSuperview];
    }
    _leftBarView = leftBarView;
    if (leftBarView) {
        [self.contentView addSubview:leftBarView];
        [self relayoutSubviews];
    }
}

- (void)setRightBarView:(UIView *)rightBarView {
    if (_rightBarView) {
        [_rightBarView removeFromSuperview];
    }
    _rightBarView = rightBarView;
    if (rightBarView) {
        [self.contentView addSubview:rightBarView];
        [self relayoutSubviews];
    }
}

- (void)fitLocationWithView:(UIView *)view {
    CGFloat viewHeight = view.size.height;
    if (viewHeight == 0) {
        viewHeight = 44;
    }
    CGFloat height = MIN(CGRectGetHeight(self.contentView.bounds), viewHeight);
    CGFloat margin = (CGRectGetHeight(self.contentView.bounds) - height) / 2;

    CGRect frame = view.frame;
    frame.origin.y = margin;
    frame.size.height = height;
    view.frame = frame;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];

    self.separatorView.frame = CGRectMake(0, CGRectGetHeight(self.bounds) - STOnePixel(), CGRectGetWidth(self.bounds), STOnePixel());

    CGFloat transitionHeight = 44;
    CGFloat topMargin = MAX(0, CGRectGetHeight(frame) - transitionHeight);
    if (CGRectGetHeight(frame) < 25) {
        topMargin = 0;
        transitionHeight = 0;
    }
    self.transitionView.frame = CGRectMake(0, topMargin, CGRectGetWidth(self.bounds), transitionHeight);

    self.contentView.frame = CGRectMake(0, CGRectGetHeight(self.transitionView.frame) - 44, CGRectGetWidth(self.bounds), 44);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self relayoutSubviews];
}

- (void)relayoutSubviews {
    CGFloat sideItemWidth = 0;
    if (self.leftBarView || self.rightBarView) {
        sideItemWidth = MAX(CGRectGetWidth(self.leftBarView.frame), CGRectGetWidth(self.rightBarView.frame));
        if (sideItemWidth == 0) {
            sideItemWidth = 60;
        }
    }
    sideItemWidth = MIN(sideItemWidth, 60);

    self.leftBarView.frame = CGRectMake(0, 0, sideItemWidth, CGRectGetHeight(self.leftBarView.frame));
    self.titleView.frame = CGRectMake(sideItemWidth, 0, CGRectGetWidth(self.bounds) - 2 * sideItemWidth, CGRectGetHeight(self.titleView.frame));
    self.rightBarView.frame = CGRectMake(CGRectGetWidth(self.bounds) - sideItemWidth, 0, sideItemWidth, CGRectGetHeight(self.rightBarView.frame));

    [self fitLocationWithView:self.leftBarView];
    [self fitLocationWithView:self.titleView];
    [self fitLocationWithView:self.rightBarView];
}

- (void)setBarTintColor:(UIColor *)barTintColor {
    if (self.backgroundView == self.backgroundImageView && self.backgroundImageView.image) {
        return;
    }
    if ([self.backgroundView respondsToSelector:@selector(setTintColor:)]) {
        [self.backgroundView performSelector:@selector(setTintColor:) withObject:barTintColor];
    } else {
        self.backgroundView.backgroundColor = barTintColor;
    }
}

- (void)setTitleTextAttributes:(NSDictionary *)titleTextAttributes {

    if ([titleTextAttributes valueForKey:NSFontAttributeName]) {
        _titleLabel.font = [titleTextAttributes valueForKey:NSFontAttributeName];
    }
    if ([titleTextAttributes valueForKey:NSForegroundColorAttributeName]) {
        _titleLabel.textColor = [titleTextAttributes valueForKey:NSForegroundColorAttributeName];
    }
    if ([titleTextAttributes valueForKey:NSShadowAttributeName]) {
        NSShadow *shadow = [titleTextAttributes valueForKey:NSShadowAttributeName];
        _titleLabel.shadowColor = shadow.shadowColor;
        _titleLabel.shadowOffset = shadow.shadowOffset;
    }

    _titleTextAttributes = titleTextAttributes;
}
@end


@implementation UIBarButtonItem (STKit)

+ (instancetype)backBarButtonItemWithTarget:(id)target action:(SEL)action {
    return [[self alloc] initWithBarButtonCustomItem:STBarButtonCustomItemBack target:target action:action];
}

- (instancetype)initWithBarButtonCustomItem:(STBarButtonCustomItem)customItem target:(id)target action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 70, 44);
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [button setImage:[STResourceManager imageWithResourceID:STImageResourceNavigationItemBackID] forState:UIControlStateNormal];
    button.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 24);
    button.titleEdgeInsets = UIEdgeInsetsMake(0, 7, 0, 0);
    [button setTitle:@"返回" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithRGB:0xFF7300] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithRGB:0x883D00] forState:UIControlStateHighlighted];
    button.titleLabel.textAlignment = NSTextAlignmentLeft;
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return [self initWithCustomView:button];
}

- (instancetype)initWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    return [self initWithTitle:title tintColor:[UIColor colorWithRGB:0xFF7300] target:target action:action];
}

- (instancetype)initWithTitle:(NSString *)title tintColor:(UIColor *)tintColor target:(id)target action:(SEL)action {
    if (!tintColor) {
        tintColor = [UIColor blackColor];
    }
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 60, 44);
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font=  [UIFont systemFontOfSize:16.];
    [button setTitleColor:tintColor forState:UIControlStateNormal];
    [button setTitleColor:[tintColor colorWithAlphaComponent:0.7] forState:UIControlStateHighlighted];
    [button setTitleColor:[tintColor colorWithAlphaComponent:0.4] forState:UIControlStateDisabled];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return [self initWithCustomView:button];
}

@end
