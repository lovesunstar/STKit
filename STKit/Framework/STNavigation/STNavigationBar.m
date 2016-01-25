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
#import <objc/runtime.h>

@interface UIButton (STNavigationBack)

@property(nonatomic, strong, setter=st_setOriginalImage:) UIImage *st_originalImage;

@end


typedef NS_ENUM(NSInteger, STNavigationTintFlags) {
    STNavigationTintFlagLeftItem = 1,
    STNavigationTintFlagRightItem = 1 << 1,
};

@interface STNavigationBar () {
    NSInteger _tintFlags;
}
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) STVisualBlurView *backgroundView;
@property(nonatomic, strong) UIView *transitionView;
@property(nonatomic, strong) UIView *separatorView;
@property(nonatomic, strong) UIView *contentView;
@property(nonatomic, strong) UIImageView *backgroundImageView;
@property(nonatomic, strong) UIColor *defaultBackgroundColor;
@end

@implementation STNavigationBar

- (id)initWithFrame:(CGRect)frame {
    CGFloat height = 64;
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
        
        self.backgroundView.frame = self.bounds;
        self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.backgroundView];

        CGFloat transitionHeight = 44;
        CGFloat topMargin = CGRectGetHeight(frame) - transitionHeight;
        self.transitionView = [[UIView alloc] initWithFrame:CGRectMake(0, topMargin, CGRectGetWidth(self.bounds), transitionHeight)];
        self.transitionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.transitionView.clipsToBounds = YES;
        [self.backgroundView.contentView addSubview:self.transitionView];

        self.contentView = [[UIView alloc] initWithFrame:self.transitionView.bounds];
        [self.transitionView addSubview:self.contentView];

        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.textColor = [UIColor st_colorWithRGB:0xFF7300];
        self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.titleLabel.font = [UIFont boldSystemFontOfSize:19.];
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleView = self.titleLabel;
        
        self.separatorView = [[UIView alloc] init];
        [self addSubview:self.separatorView];
    
        self.separatorView.backgroundColor = [UIColor st_colorWithRGB:0x999999];
    }
    return self;
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    self.backgroundImageView.image = backgroundImage;
}

- (UIImage *)backgroundImage {
    return self.backgroundImageView.image;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    self.backgroundView.tintColor = backgroundColor;
}

- (UIColor *)backgroundColor {
    return self.backgroundView.tintColor;
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
        sideItemWidth = MAX(sideItemWidth, 60);
    }
    CGFloat titleWidth = self.titleView.width;
    if (titleWidth == 0 || titleWidth > CGRectGetWidth(self.frame) - 2 * sideItemWidth) {
        titleWidth = CGRectGetWidth(self.frame) - 2 * sideItemWidth;
    }
    CGFloat titleLeft = (CGRectGetWidth(self.frame) - titleWidth) / 2;
    self.leftBarView.frame = CGRectMake(0, 0, sideItemWidth, CGRectGetHeight(self.leftBarView.frame));
    self.titleView.frame = CGRectMake(titleLeft, 0, titleWidth, CGRectGetHeight(self.titleView.frame));
    self.rightBarView.frame = CGRectMake(CGRectGetWidth(self.bounds) - sideItemWidth, 0, sideItemWidth, CGRectGetHeight(self.rightBarView.frame));

    [self fitLocationWithView:self.leftBarView];
    [self fitLocationWithView:self.titleView];
    [self fitLocationWithView:self.rightBarView];
}

- (void)setBarTintColor:(UIColor * __nullable)barTintColor {
    _barTintColor = barTintColor;
    self.backgroundView.color = barTintColor;
    self.backgroundColor = barTintColor;
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
    [self _retintItems];
}

- (void)setTranslucent:(BOOL)translucent {
    _translucent = translucent;
    self.backgroundView.hasBlurEffect = translucent;
}

- (void)_retintItems {
    if (!!(_tintFlags & STNavigationTintFlagLeftItem)) {
        /// retint Left
        [self _tintView:self.leftBarView usingTextAttributes:self.titleTextAttributes];
    }
    if (!!(_tintFlags & STNavigationTintFlagRightItem)) {
        /// re tintRight
        [self _tintView:self.rightBarView usingTextAttributes:self.titleTextAttributes];
    }
}


- (void)_tintView:(UIView *)view usingTextAttributes:(NSDictionary *)textAttributes {
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        if (textAttributes[NSForegroundColorAttributeName]) {
            UIColor *color = textAttributes[NSForegroundColorAttributeName];
            if ([color isKindOfClass:[UIColor class]] || !color) {
                UIColor *normalColor = color, *highlightedColor = [color colorWithAlphaComponent:0.7], *disabledColor = [color colorWithAlphaComponent:0.4];
                [button setTitleColor:normalColor forState:UIControlStateNormal];
                [button setTitleColor:highlightedColor forState:UIControlStateHighlighted];
                [button setTitleColor:disabledColor forState:UIControlStateDisabled];
                if (button.st_originalImage) {
                    [button setImage:[button.st_originalImage st_imageWithRenderingTintColor:color] forState:UIControlStateNormal];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [button setImage:[button.st_originalImage st_imageWithRenderingTintColor:highlightedColor] forState:UIControlStateHighlighted];
                        [button setImage:[button.st_originalImage st_imageWithRenderingTintColor:disabledColor] forState:UIControlStateDisabled];
                    });
                }
            }
        }
        NSShadow *shadow = textAttributes[NSShadowAttributeName];
        button.titleLabel.shadowColor = shadow.shadowColor;
        button.titleLabel.shadowOffset = shadow.shadowOffset;
    }
}

@end

@interface _STBackButton : UIButton

@end

@implementation _STBackButton

- (CGRect)titleRectForContentRect:(CGRect)contentRect {
    return CGRectMake(25, 10, CGRectGetWidth(contentRect) - 30 , 24);
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect {
    return CGRectMake(10, 10, 18, 24);
}

@end


@implementation UIBarButtonItem (STKit)

static NSString *const STNavItemConstructUsingSTKitKey = @"STNavItemConstructUsingSTKitKey";
- (BOOL)st_constructUsingSTKit {
    id value = objc_getAssociatedObject(self, (__bridge const void *)(STNavItemConstructUsingSTKitKey));
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value boolValue];
    }
    return NO;
}

- (void)st_setConstructUsingSTKit:(BOOL)usingSTKit {
    objc_setAssociatedObject(self, (__bridge const void *)(STNavItemConstructUsingSTKitKey), @(usingSTKit), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (instancetype)backBarButtonItemWithTarget:(id)target action:(SEL)action {
    return [[self alloc] initWithBarButtonCustomItem:STBarButtonCustomItemBack target:target action:action];
}

- (instancetype)initWithBarButtonCustomItem:(STBarButtonCustomItem)customItem target:(id)target action:(SEL)action {
    _STBackButton *button = [_STBackButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 60, 44);
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    UIImage *image = [STResourceManager imageWithResourceID:STImageResourceNavigationItemBackID];
    button.st_originalImage = image;
    [button setImage:image forState:UIControlStateNormal];
    button.titleLabel.font=  [UIFont systemFontOfSize:16.f];
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    button.titleLabel.minimumScaleFactor = 0.5;
    [button setTitle:@"返回" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor st_colorWithRGB:0xFF7300] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor st_colorWithRGB:0x883D00] forState:UIControlStateHighlighted];
    button.titleLabel.textAlignment = NSTextAlignmentLeft;
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *buttonItem = [self initWithCustomView:button];
    [buttonItem st_setConstructUsingSTKit:YES];
    return buttonItem;
}

- (instancetype)initWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    return [self initWithTitle:title tintColor:[UIColor st_colorWithRGB:0xFF7300] target:target action:action];
}

- (instancetype)initWithTitle:(NSString *)title tintColor:(UIColor *)tintColor target:(id)target action:(SEL)action {
    if (!tintColor) {
        tintColor = [UIColor blackColor];
    }
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 60, 44);
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font=  [UIFont systemFontOfSize:16.f];
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    button.titleLabel.minimumScaleFactor = 0.5;
    [button setTitleColor:tintColor forState:UIControlStateNormal];
    [button setTitleColor:[tintColor colorWithAlphaComponent:0.7] forState:UIControlStateHighlighted];
    [button setTitleColor:[tintColor colorWithAlphaComponent:0.4] forState:UIControlStateDisabled];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *buttonItem = [self initWithCustomView:button];
    [buttonItem st_setConstructUsingSTKit:YES];
    return buttonItem;
}

- (UIView *)st_customView {
    if (!self.customView) {
        NSString *title = self.title;
        UIImage *image = self.image;
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 0, 60, 44);
        [button addTarget:self.target action:self.action forControlEvents:UIControlEventTouchUpInside];
        if (!title && !image) {
            title = @"Item";
        }
        [button setImage:image forState:UIControlStateNormal];
        button.imageEdgeInsets = self.imageInsets;
        [button setTitle:title forState:UIControlStateNormal];
        button.titleLabel.adjustsFontSizeToFitWidth = YES;
        button.titleLabel.minimumScaleFactor = 0.5;
        self.customView = button;
        [self st_setConstructUsingSTKit:YES];
    }
    return self.customView;
}

@end


@implementation UIButton (STNavigationBack)

static NSString *const STNavigationBackButtonImageKey = @"STNavigationBackButtonImageKey";
- (UIImage *)st_originalImage {
    return objc_getAssociatedObject(self, (__bridge const void *)(STNavigationBackButtonImageKey));
}

- (void)st_setOriginalImage:(UIImage *)st_originalImage {
    objc_setAssociatedObject(self, (__bridge const void *)(STNavigationBackButtonImageKey), st_originalImage, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
