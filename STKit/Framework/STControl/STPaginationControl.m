//
//  STPaginationControl.m
//  STKit
//
//  Created by SunJiangting on 14-9-17.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STPaginationControl.h"
#import "UIKit+STKit.h"

@interface STPaginationControl ()

@property(nonatomic, weak) UIScrollView *scrollView;

@end

@implementation STPaginationControl

- (void)dealloc {
    self.scrollView = nil;
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    self.hidden = !enabled;
}

- (void)setPaginationState:(STPaginationControlState)paginationState {
    if (_paginationState == paginationState) {
        return;
    }
    _paginationState = paginationState;
    [self paginationControlDidChangedToState:paginationState];
}

- (void)paginationControlDidChangedToState:
(STPaginationControlState)controlState {
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if ([newSuperview isKindOfClass:[UIScrollView class]]) {
        self.scrollView = (UIScrollView *)newSuperview;
    } else {
        self.scrollView = nil;
    }
    [super willMoveToSuperview:newSuperview];
}

- (void)setScrollView:(UIScrollView *)scrollView {
    if (_scrollView) {
        [_scrollView removeObserver:self forKeyPath:@"contentOffset" context:NULL];
    }
    [scrollView addObserver:self
                 forKeyPath:@"contentOffset"
                    options:NSKeyValueObservingOptionNew
                    context:NULL];
    _scrollView = scrollView;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (object == self.scrollView && [keyPath isEqualToString:@"contentOffset"]) {
        if (self.enabled && CGRectGetHeight(self.frame) > 20 && !self.hidden) {
            [self scrollViewDidScroll:self.scrollView];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat contentOffsetY = scrollView.contentOffset.y;
    if (contentOffsetY > 0) {
        //// 等待触发加载更多
        if (self.paginationState != STPaginationControlStateNormal || self.hidden ||
            !self.superview || CGRectGetHeight(self.frame) <= 20) {
            /// 如果分页状态不正常，或者分页控件不可见，或者分页控件没有被添加到父View上，则不会触发加载更多
            return;
        }
        CGFloat contentOffset =
        scrollView.contentOffset.y + scrollView.contentInset.top;
        CGFloat contentHeight = scrollView.contentSize.height;
        CGFloat offset =
        (contentOffset + CGRectGetHeight(scrollView.frame)) - contentHeight;
        if (offset >= -self.threshold) {
            /// 开始加载更多
            [self sendActionsForControlEvents:UIControlEventValueChanged];
            self.paginationState = STPaginationControlStateLoading;
        }
    }
}

- (CGFloat)threshold {
    if (_threshold == 0) {
        return CGRectGetHeight(self.bounds);
    }
    return _threshold;
}

@end

@implementation STDefaultPaginationControl {
    NSMutableDictionary *_titles;
}

- (instancetype)initWithFrame:(CGRect)frame {
    frame.size = STPaginationControlSize;
    self = [super initWithFrame:frame];
    if (self) {
        _titles = [NSMutableDictionary dictionaryWithCapacity:3];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.titleLabel = [[UILabel alloc] initWithFrame:self.bounds];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.autoresizingMask =
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.titleLabel];
        
        self.reloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.reloadButton.frame = CGRectMake(10, 10, CGRectGetWidth(frame) - 20,
                                             CGRectGetHeight(frame) - 20);
        self.reloadButton.autoresizingMask =
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.reloadButton setTitleColor:UIColor.blackColor
                                forState:UIControlStateNormal];
        UIImage *bkgImage = [[UIImage imageNamed:@"button_border_bkg"]
                             resizableImageWithCapInsets:UIEdgeInsetsMake(15, 30, 15, 30)
                             resizingMode:UIImageResizingModeStretch];
        [self.reloadButton setBackgroundImage:bkgImage
                                     forState:UIControlStateNormal];
        [self addSubview:self.reloadButton];
        
        self.indicatorView = [[UIActivityIndicatorView alloc]
                              initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.indicatorView.frame = CGRectMake(20, 5, 40, 40);
        self.indicatorView.autoresizingMask =
        UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleBottomMargin |
        UIViewAutoresizingFlexibleRightMargin;
        self.indicatorView.hidesWhenStopped = YES;
        [self addSubview:self.indicatorView];
        
        self.paginationState = STPaginationControlStateNormal;
    }
    return self;
}

- (void)paginationControlDidChangedToState:(STPaginationControlState)controlState {
    switch (controlState) {
        case STPaginationControlStateNormal:
            self.titleLabel.hidden = NO;
            if (self.indicatorView.isAnimating) {
                [self.indicatorView stopAnimating];
            }
            self.reloadButton.hidden = YES;
            self.titleLabel.text = [self titleForState:STPaginationControlStateNormal];
            self.titleLabel.frame = self.bounds;
            break;
        case STPaginationControlStateLoading:
            self.titleLabel.hidden = NO;
            self.reloadButton.hidden = YES;
            self.titleLabel.text = [self titleForState:STPaginationControlStateLoading];
            [self.indicatorView startAnimating];
            break;
        case STPaginationControlStateFailed:
            self.titleLabel.hidden = YES;
            if ([self.indicatorView isAnimating]) {
                [self.indicatorView stopAnimating];
            }
            self.reloadButton.hidden = NO;
            [self.reloadButton setTitle:[self titleForState:STPaginationControlStateFailed] forState:UIControlStateNormal];
            break;
        case STPaginationControlStateReachedEnd:
        default:
            self.titleLabel.hidden = NO;
            if ([self.indicatorView isAnimating]) {
                [self.indicatorView stopAnimating];
            }
            self.reloadButton.hidden = YES;
            self.titleLabel.text = [self titleForState:STPaginationControlStateReachedEnd];
            break;
    }
}

- (void)setTitle:(NSString *)title forState:(STPaginationControlState)state {
    NSString *key = [NSString stringWithFormat:@"%ld", (long)state];
    _titles[key] = title;
}

- (NSString *)titleForState:(STPaginationControlState)state {
    NSString *key = [NSString stringWithFormat:@"%ld", (long)state];
    return _titles[key];
}

@end

CGSize const STPaginationControlSize = {320, 50};
