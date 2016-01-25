//
//  STTabBar.m
//  STKit
//
//  Created by SunJiangting on 14-2-13.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STTabBar.h"
#import "STTabBarItem.h"
#import "UIKit+STKit.h"
#import "STVisualBlurView.h"

@interface STTabButton : UIButton

- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image highlightedImage:(UIImage *)highlightedImage;

@property(nonatomic, assign) CGRect imageFrame;
@property(nonatomic, assign) CGRect titleFrame;

@property(nonatomic, weak) STTabBarItem *tabBarItem;

@property(nonatomic, strong) UILabel *badgeLabel;
@end

@implementation STTabButton

- (void)dealloc {
    self.tabBarItem = nil;
}

- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image highlightedImage:(UIImage *)highlightedImage {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.exclusiveTouch = YES;
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = [UIFont systemFontOfSize:11.0f];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.clipsToBounds = YES;

        [self setTitle:title forState:UIControlStateNormal];

        [self setTitleColor:[UIColor st_colorWithRGB:0xACACAC] forState:UIControlStateNormal];
        [self setTitleColor:[UIColor st_colorWithRGB:0xACACAC] forState:UIControlStateHighlighted];
        [self setTitleColor:[UIColor st_colorWithRGB:0xFF7300] forState:UIControlStateSelected];
        [self setTitleColor:[UIColor st_colorWithRGB:0xFF7300] forState:UIControlStateSelected | UIControlStateHighlighted];

        [self setImage:image forState:UIControlStateNormal];
        [self setImage:image forState:UIControlStateHighlighted];
        [self setImage:highlightedImage forState:UIControlStateSelected];
        [self setImage:highlightedImage forState:UIControlStateSelected | UIControlStateHighlighted];

        self.badgeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 40, 16)];
        self.badgeLabel.backgroundColor = [UIColor redColor];
        self.badgeLabel.textColor = [UIColor whiteColor];
        self.badgeLabel.textAlignment = NSTextAlignmentCenter;
        self.badgeLabel.font = [UIFont boldSystemFontOfSize:13.];
        self.badgeLabel.layer.cornerRadius = 8;
        self.badgeLabel.layer.masksToBounds = YES;
        self.badgeLabel.userInteractionEnabled = NO;
        self.badgeLabel.hidden = YES;
        [self addSubview:self.badgeLabel];
    }
    return self;
}

- (void)setTabBarItem:(STTabBarItem *)tabBarItem {
    _tabBarItem = tabBarItem;
    [self setBadgeValue:tabBarItem.badgeValue];
}

const CGFloat STTitleOffset = 5;
- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    STTabBar *tabBar = (STTabBar *)[self st_superviewWithClass:[STTabBar class]];
    if ([[tabBar st_valueForVar:@"_actualHeight"] floatValue] > 1) {
        viewHeight = [[tabBar st_valueForVar:@"_actualHeight"] floatValue];
    }
    CGFloat contentOffset = CGRectGetHeight(self.bounds) - viewHeight;
    CGFloat height = (CGRectIsEmpty(self.imageFrame) ? CGRectGetHeight(self.imageView.frame) : CGRectGetHeight(self.imageFrame)) +
                     (CGRectIsEmpty(self.titleFrame) ? CGRectGetHeight(self.titleLabel.frame) : CGRectGetHeight(self.titleFrame));

    CGFloat offset = STTitleOffset;
    if (CGRectIsEmpty(self.imageFrame)) {
        CGFloat leftMargin = (CGRectGetWidth(self.bounds) - CGRectGetWidth(self.imageView.frame)) / 2;
        CGFloat topMargin = (viewHeight - height - 5) / 2;
        if (topMargin < 0) {
            topMargin = (viewHeight - height) / 2;
            offset = viewHeight - topMargin * 2 - height;
        }
        if (topMargin < 0) {
            topMargin = 0;
            offset = 0;
        }
        if (topMargin > 2) {
            topMargin += 2;
            offset -= 2;
        }

        CGRect frame = self.imageView.frame;
        frame.origin = CGPointMake((NSInteger)leftMargin, (NSInteger)(topMargin + contentOffset));
        self.imageView.frame = frame;
    } else {
        self.imageView.frame = self.imageFrame;
    }

    if (CGRectIsEmpty(self.titleFrame)) {
        CGFloat leftMargin = (CGRectGetWidth(self.bounds) - CGRectGetWidth(self.titleLabel.frame)) / 2;
        CGFloat topMargin = (CGRectGetHeight(self.bounds) - CGRectGetHeight(self.titleLabel.frame)) / 2;
        if (self.imageView.image) {
             topMargin = CGRectGetMaxY(self.imageView.frame) + offset;
        }
        CGRect frame = self.titleLabel.frame;
        frame.origin = CGPointMake((NSInteger)leftMargin, (NSInteger)topMargin);
        self.titleLabel.frame = frame;
    } else {
        self.titleLabel.frame = self.titleFrame;
    }

    CGRect frame = self.badgeLabel.frame;
    frame.origin.x = CGRectGetMaxX(self.imageView.frame) - 2;
    frame.origin.y = CGRectGetMinY(self.imageView.frame) + 2;
    frame.size.width = MIN(40, frame.size.width + 4);
    self.badgeLabel.frame = frame;
}

- (void)setBadgeValue:(NSString *)badgeValue {
    self.badgeLabel.hidden = badgeValue.length == 0;
    self.badgeLabel.text = badgeValue;
    [self.badgeLabel sizeToFit];
    [self setNeedsLayout];
}

@end

@interface STTabBar () {
    __weak STTabButton *_selectedTabButton;
    CGFloat _actualHeight;
}

@property(nonatomic, strong) NSMutableArray *subtabButtons;
@property(nonatomic, strong) UIView *backgroundView;

@property(nonatomic, strong) UIImageView *backgroundImageView;
@property(nonatomic, strong) UIView *separatorView;

@end

@implementation STTabBar

- (void)dealloc {
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundView = [[STVisualBlurView alloc] initWithBlurEffectStyle:STBlurEffectStyleExtraLight];
        if (!self.backgroundView) {
            self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        }
        self.backgroundView.frame = self.bounds;
        self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.backgroundView];

        self.backgroundImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.backgroundImageView.hidden = YES;
        [self.backgroundView addSubview:self.backgroundImageView];

        self.subtabButtons = [NSMutableArray arrayWithCapacity:2];
        if (STGetSystemVersion() >= 7) {
            self.separatorView = [[UIView alloc] init];
            self.separatorView.backgroundColor = [UIColor st_colorWithRGB:0x999999];
            [self addSubview:self.separatorView];
        }
    }
    return self;
}

#pragma mark -Public Methods
- (void)setSelectedItem:(STTabBarItem *)selectedItem {
    if (_selectedTabButton) {
        _selectedTabButton.selected = NO;
    }
    STTabButton *tabButton = [self.subtabButtons objectAtIndex:[self.items indexOfObject:selectedItem]];
    ;
    tabButton.selected = YES;
    _selectedTabButton = tabButton;
    _selectedItem = selectedItem;
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    self.backgroundImageView.image = backgroundImage;
    self.backgroundImageView.hidden = !backgroundImage;
}

- (UIImage *)backgroundImage {
    return self.backgroundImageView.image;
}

- (void)setBarTintColor:(UIColor * __nullable)barTintColor {
    _barTintColor = barTintColor;
    if (self.backgroundView == self.backgroundImageView && self.backgroundImageView.image) {
        return;
    }
    if ([self.backgroundView isKindOfClass:[STVisualBlurView class]]) {
        ((STVisualBlurView *)self.backgroundView).color = barTintColor;
    }
}

- (void)setItems:(NSArray *)items {
    if (_items == items) {
        return;
    }
    [self.subtabButtons makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.subtabButtons removeAllObjects];
    for (STTabBarItem *tabBarItem in items) {
        UIView *tabBarItemView = [self viewWithTabBarItem:tabBarItem];
        tabBarItemView.hidden = self.customizable;
        [self.subtabButtons addObject:tabBarItemView];
        tabBarItem.itemView = tabBarItemView;
        [self addSubview:tabBarItemView];
    }
    _items = items;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat tabWidth = CGRectGetWidth(self.bounds) / self.subtabButtons.count;
    for (int i = 0; i < self.subtabButtons.count; ++i) {
        UIView *tabButton = [self.subtabButtons objectAtIndex:i];
        tabButton.frame = CGRectMake(i * tabWidth, 0, tabWidth, CGRectGetHeight(self.bounds));
    }
    self.separatorView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), STOnePixel());
}

- (void)setCustomizable:(BOOL)customizable {
    for (int i = 0; i < self.subtabButtons.count; ++i) {
        UIView *tabButton = [self.subtabButtons objectAtIndex:i];
        tabButton.hidden = self.customizable;
    }
    if ([self.backgroundView isKindOfClass:[STVisualBlurView class]]) {
        ((STVisualBlurView *)self.backgroundView).hasBlurEffect = !customizable;
    }
    self.separatorView.hidden = customizable;
    _customizable = customizable;
}

- (void)setBadgeValue:(NSString *)badgeValue forIndex:(NSInteger)index {
    if (index < self.items.count) {
        STTabBarItem *tabBarItem = self.items[index];
        tabBarItem.badgeValue = badgeValue;
    }
}

- (NSString *)badgeValueForIndex:(NSInteger)index {
    if (index < self.items.count) {
        STTabBarItem *tabBarItem = self.items[index];
        return tabBarItem.badgeValue;
    }
    return nil;
}

#pragma mark -Private Method
- (UIView *)viewWithTabBarItem:(STTabBarItem *)tabBarItem {
    STTabButton *button = [[STTabButton alloc] initWithTitle:tabBarItem.title image:tabBarItem.image highlightedImage:tabBarItem.selectedImage];
    [button addTarget:self action:@selector(buttonTouchupInsideActionFired:) forControlEvents:UIControlEventTouchUpInside];
    if (tabBarItem.titleColor) {
        [button setTitleColor:tabBarItem.titleColor forState:UIControlStateNormal];
        [button setTitleColor:tabBarItem.titleColor forState:UIControlStateNormal];
        [button setTitleColor:tabBarItem.titleColor forState:UIControlStateHighlighted];
    }
    if (tabBarItem.selectedTitleColor) {
        [button setTitleColor:tabBarItem.selectedTitleColor forState:UIControlStateSelected];
        [button setTitleColor:tabBarItem.selectedTitleColor forState:UIControlStateSelected | UIControlStateHighlighted];
    }
    if (tabBarItem.titleFont) {
        button.titleLabel.font = tabBarItem.titleFont;
    }
    [button addTarget:self action:@selector(buttonTouchDownActionFired:) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self
                  action:@selector(buttonTouchCancelledActionFired:)
        forControlEvents:UIControlEventTouchCancel | UIControlEventTouchUpOutside];
    button.tabBarItem = tabBarItem;
    return button;
}

- (void)buttonTouchupInsideActionFired:(id)sender {
    [self tabBarButtonSelected:sender];
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(tabBarButtonSelected:) object:sender];
}

- (void)tabBarButtonSelected:(UIButton *)sender {
    STTabBarItem *tabBarItem = [self.items objectAtIndex:[self.subtabButtons indexOfObject:sender]];
    sender.enabled = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(tabBar:didSelectItem:)]) {
        [self.delegate performSelector:@selector(tabBar:didSelectItem:) withObject:self withObject:tabBarItem];
    }
    sender.enabled = YES;
}

- (void)buttonTouchDownActionFired:(id)sender {
    [self performSelector:@selector(tabBarButtonSelected:) withObject:sender afterDelay:0.3];
}

- (void)buttonTouchCancelledActionFired:(id)sender {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(tabBarButtonSelected:) object:sender];
}

- (void)setTranslucent:(BOOL)translucent {
    _translucent = translucent;
    if ([self.backgroundView respondsToSelector:@selector(setHasBlurEffect:)]) {
        ((STVisualBlurView *)self.backgroundView).hasBlurEffect = translucent;
    }
}

@end
