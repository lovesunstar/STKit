//
//  STPaginationControl.m
//  STKit
//
//  Created by SunJiangting on 14-9-17.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STPaginationControl.h"

@interface STPaginationControl () {
    BOOL _isObservingContentOffset;
}

@property(nonatomic, weak) UIScrollView *scrollView;

@end

@implementation STPaginationControl

- (void)dealloc {
    [self stopObservingContentOffset];
}

- (void)removeFromSuperview {
    [super removeFromSuperview];
    [self stopObservingContentOffset];
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    self.hidden = !enabled;
}

- (void)setPaginationState:(STPaginationControlState)paginationState {
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
        [self stopObservingContentOffset];
    }
    _scrollView = scrollView;
    [self startObservingContentOffset];
}


- (void)startObservingContentOffset {
    if (!_isObservingContentOffset) {
        if (_scrollView) {
            [_scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:NULL];
            _isObservingContentOffset = YES;
        }
    }
}

- (void)stopObservingContentOffset {
    if (_isObservingContentOffset) {
        [_scrollView removeObserver:self forKeyPath:@"contentOffset" context:NULL];
        _isObservingContentOffset = NO;
    }
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

- (void)paginationTest {
    [self _paginationTestInScrollView:self.scrollView force:YES];
}

- (void)_paginationTestInScrollView:(UIScrollView *)scrollView force:(BOOL)force {
    CGFloat contentOffsetY = scrollView.contentOffset.y;
    if (!force && contentOffsetY <= 0) {
        return;
    }
    if (contentOffsetY + scrollView.contentInset.top >= 0) {
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self _paginationTestInScrollView:scrollView force:NO];
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
        self.reloadButton.frame = CGRectMake(10, 5, CGRectGetWidth(frame) - 20,
                                             CGRectGetHeight(frame) - 10);
        self.reloadButton.autoresizingMask =
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.reloadButton.layer.borderColor = [UIColor st_colorWithRGB:0xCCCCCC].CGColor;
        self.reloadButton.titleLabel.font = [UIFont systemFontOfSize:17];
        self.reloadButton.layer.cornerRadius = 5;
        self.reloadButton.layer.borderWidth = 1;
        [self.reloadButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.reloadButton addTarget:self action:@selector(_reloadActionFired:) forControlEvents:UIControlEventTouchUpInside];
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
    [self setNeedsLayout];
}

- (void)setTitle:(NSString *)title forState:(STPaginationControlState)state {
    NSString *key = [NSString stringWithFormat:@"%ld", (long)state];
    _titles[key] = title;
}

- (NSString *)titleForState:(STPaginationControlState)state {
    NSString *key = [NSString stringWithFormat:@"%ld", (long)state];
    return _titles[key];
}

- (void)_reloadActionFired:(id)sender {
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    self.paginationState = STPaginationControlStateLoading;
}

@end

CGSize const STPaginationControlSize = {320, 50};
