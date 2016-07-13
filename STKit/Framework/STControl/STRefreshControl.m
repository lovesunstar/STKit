//
//  STRefreshControl.m
//  STKit
//
//  Created by SunJiangting on 14-9-17.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STRefreshControl.h"
#import "STResourceManager.h"

#pragma mark - STRefhresControl
@interface STRefreshControl () {
    BOOL _isObservingContentInset;
    BOOL _isObservingContentOffset;
}

@property(nonatomic) CGFloat contentInsetTop;
@property(nonatomic) CGFloat notifyHeight;

@property(nonatomic) STRefreshControlState refreshControlState;

@property(nonatomic, weak) UIScrollView *scrollView;
@property(nonatomic, strong) NSDate     *startLoadingDate;


@end

@implementation STRefreshControl

- (void)dealloc {
    [self stopObservingContentInset];
    [self stopObservingContentOffset];
}

- (void)removeFromSuperview {
    [super removeFromSuperview];
    [self stopObservingContentInset];
    [self stopObservingContentOffset];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.animationDuration = 0.25;
    }
    return self;
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    self.hidden = !enabled;
}

- (void)beginRefreshing {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _changedRefreshControlToState:STRefreshControlStateLoading animated:YES];
    });
}

- (void)notifyResultsWithHeight:(CGFloat)height {
    if (self.refreshControlState != STRefreshControlStateLoading && self.refreshControlState != STRefreshControlStateNormal) {
        return;
    }
    self.notifyHeight = height;
    [self _changedRefreshControlToState:STRefreshControlStateNotifyingResults animated:NO];
}

- (void)endRefreshing {
    NSTimeInterval duration = self.minimumLoadingDuration;
    if (self.startLoadingDate) {
        duration = [[NSDate date] timeIntervalSinceDate:self.startLoadingDate];
    }
//    CGFloat delay = MAX(0, self.minimumLoadingDuration - duration);
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
       [self _changedRefreshControlToState:STRefreshControlStateNormal animated:YES];
//    });
}

- (void)refreshControlWillChangedToState:(STRefreshControlState)refreshControlState {
    
}
- (void)refreshControlDidChangedToState:(STRefreshControlState)refreshControlState {
    
}

- (void)_changedRefreshControlToState:(STRefreshControlState)refreshControlState animated:(BOOL)animated {
    if (_refreshControlState != STRefreshControlStateLoading && _refreshControlState != STRefreshControlStateNotifyingResults) {
        /// 如果不是刷新/Notify状态，则一定读取到正确的contentInset
        self.contentInsetTop = self.scrollView.contentInset.top;
    }
    if (_refreshControlState == refreshControlState) {
        return;
    }
    __weak UIScrollView *scrollView = self.scrollView;
    void (^animations)(void) = ^{
        CGFloat height = CGRectGetHeight(self.frame);
        UIEdgeInsets inset = scrollView.contentInset;
        if (refreshControlState == STRefreshControlStateLoading) {
            // 如果要变成刷新状态，则改变inset.top
            inset.top = self.contentInsetTop + height;
            if (_isObservingContentOffset) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self stopObservingContentOffset];
                    scrollView.contentOffset = CGPointMake(0, -inset.top);
                    [self startObservingContentOffset];
                    
                });
            } else {
                scrollView.contentOffset = CGPointMake(0, -inset.top);
            }
        } else if (refreshControlState == STRefreshControlStateNotifyingResults) {
            inset.top = self.contentInsetTop + self.notifyHeight;
            if (_isObservingContentOffset) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self stopObservingContentOffset];
                    scrollView.contentOffset = CGPointMake(0, -inset.top);
                    [self startObservingContentOffset];
                    
                });
            } else {
                scrollView.contentOffset = CGPointMake(0, -inset.top);
            }
        } else {
            inset.top = self.contentInsetTop;
        }
        if (_isObservingContentInset) {
            [self stopObservingContentInset];
            scrollView.contentInset = inset;
            [self startObservingContentInset];
        } else {
            scrollView.contentInset = inset;
        }
        [self refreshControlWillChangedToState:refreshControlState];
    };
    _refreshControlState = refreshControlState;
    void (^completion)(BOOL) = ^(BOOL finished) {
        if (refreshControlState == STRefreshControlStateLoading) {
            [self sendActionsForControlEvents:UIControlEventValueChanged];
            self.startLoadingDate = [NSDate date];
        }
        [self refreshControlDidChangedToState:refreshControlState];
    };
    if (animated) {
        [UIView animateWithDuration:self.animationDuration
                         animations:animations
                         completion:completion];
    } else {
        animations();
        completion(YES);
    }
}

- (BOOL)isRefreshing {
    return _refreshControlState == STRefreshControlStateLoading;
}

- (void)scrollViewDidChangeContentOffset:(CGPoint)contentOffset {
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat contentOffsetY = scrollView.contentOffset.y;
    CGFloat absOffsetY = ABS(contentOffsetY);
    if (contentOffsetY < 0 &&
        self.refreshControlState != STRefreshControlStateLoading &&
        !self.hidden && self.enabled == YES) {
        /// 触发下拉刷新
        CGFloat pullDistance = absOffsetY - self.contentInsetTop;
        if (self.scrollView.dragging) {
            if (pullDistance >= self.threshold) {
                /// 松开可以刷新
                [self _changedRefreshControlToState:STRefreshControlStateReachedThreshold animated:YES];
            } else {
                /// 下拉可以刷新
                [self _changedRefreshControlToState:STRefreshControlStateNormal
                                           animated:YES];
            }
        } else {
            if (self.refreshControlState == STRefreshControlStateReachedThreshold) {
                /// 如果状态为松开可以刷新，并且手松开了，则直接刷新
                [self _changedRefreshControlToState:STRefreshControlStateLoading animated:YES];
            }
        }
        [self scrollViewDidChangeContentOffset:CGPointMake(scrollView.contentOffset.x, -pullDistance)];
    }
}

- (CGFloat)threshold {
    if (_threshold == 0) {
        return CGRectGetHeight(self.bounds);
    }
    return _threshold;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if ([newSuperview isKindOfClass:[UIScrollView class]]) {
        self.scrollView = (UIScrollView *)newSuperview;
    } else {
        self.scrollView = nil;
    }
    self.frame = CGRectMake(0, -CGRectGetHeight(self.bounds), CGRectGetWidth(newSuperview.bounds), CGRectGetHeight(self.bounds));
    [self _changedRefreshControlToState:STRefreshControlStateNormal animated:NO];
    [super willMoveToSuperview:newSuperview];
}

- (void)setScrollView:(UIScrollView *)scrollView {
    if (_scrollView) {
        [self stopObservingContentInset];
        [self stopObservingContentOffset];
    }
    _scrollView = scrollView;
    self.contentInsetTop = scrollView.contentInset.top;
    [self startObservingContentOffset];
    [self startObservingContentInset];
}

- (void)startObservingContentInset {
    if (!_isObservingContentInset) {
        if (_scrollView) {
            [_scrollView addObserver:self forKeyPath:@"contentInset" options:NSKeyValueObservingOptionNew context:NULL];
            _isObservingContentInset = YES;
        }
    }
}

- (void)stopObservingContentInset {
    if (_isObservingContentInset) {
        [_scrollView removeObserver:self forKeyPath:@"contentInset" context:NULL];
        _isObservingContentInset = NO;
    }
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
    if (object == self.scrollView) {
        if ([keyPath isEqualToString:@"contentOffset"]) {
            if (self.enabled && CGRectGetHeight(self.frame) > 20 &&
                self.threshold > 20 && !self.hidden) {
                [self scrollViewDidScroll:self.scrollView];
            }
        } else if ([keyPath isEqualToString:@"contentInset"]) {
            if (self.state != STRefreshControlStateLoading) {
                self.contentInsetTop = self.scrollView.contentInset.top;
            }
        }
    }
}

@end

@implementation STDefaultRefreshControl {
    NSMutableDictionary *_titles;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (frame.size.width < STRefreshControlSize.width) {
        frame.size.width = STRefreshControlSize.width;
    }
    if (frame.size.height < STRefreshControlSize.height) {
        frame.size.height = STRefreshControlSize.height;
    }
    self = [super initWithFrame:frame];
    if (self) {
        _titles = [NSMutableDictionary dictionaryWithCapacity:3];
        [self setTitle:@"下拉可以刷新" forState:STRefreshControlStateNormal];
        [self setTitle:@"正在刷新" forState:STRefreshControlStateLoading];
        [self setTitle:@"松开开始刷新" forState:STRefreshControlStateReachedThreshold];
        self.threshold = STRefreshControlSize.height + 10;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        CGFloat width = CGRectGetWidth(frame), height = CGRectGetHeight(frame);
        self.backgroundColor = [UIColor clearColor];
        {
            UILabel *refreshStatusLabel =
            [[UILabel alloc] initWithFrame:CGRectMake(0, (height - 20) / 2, width, 20)];
            refreshStatusLabel.autoresizingMask =
            UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            refreshStatusLabel.backgroundColor = [UIColor clearColor];
            refreshStatusLabel.font = [UIFont systemFontOfSize:13.];
            refreshStatusLabel.textAlignment = NSTextAlignmentCenter;
            [self addSubview:refreshStatusLabel];
            self.refreshStatusLabel = refreshStatusLabel;
            /// 30 * 80 px
            UIImageView *arrawImageView = [[UIImageView alloc]
                                           initWithImage:
                                           [STResourceManager
                                            imageWithResourceID:STImageResourceRefreshControlArrowID]];
            arrawImageView.frame = CGRectMake(60, (height - 40) / 2, 15, 40);
            arrawImageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin |
            UIViewAutoresizingFlexibleBottomMargin;
            [self addSubview:arrawImageView];
            self.arrowImageView = arrawImageView;
            
            UIActivityIndicatorView *activityIndicatorView =
            [[UIActivityIndicatorView alloc]
             initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            activityIndicatorView.hidesWhenStopped = YES;
            activityIndicatorView.center = arrawImageView.center;
            activityIndicatorView.autoresizingMask = arrawImageView.autoresizingMask;
            [self addSubview:activityIndicatorView];
            self.indicatorView = activityIndicatorView;
        }
        self.enabled = YES;
    }
    return self;
}

#pragma mark - PrivateMethod
- (void)refreshControlWillChangedToState:(STRefreshControlState)refreshControlState {
    BOOL shouldAnimating = NO;
    switch (refreshControlState) {
        case STRefreshControlStateReachedThreshold:
            shouldAnimating = NO;
            self.arrowImageView.hidden = NO;
            self.arrowImageView.transform = CGAffineTransformMakeRotation(M_PI);
            break;
        case STRefreshControlStateLoading:
            self.arrowImageView.hidden = YES;
            self.arrowImageView.transform = CGAffineTransformIdentity;
            shouldAnimating = YES;
            break;
        case STRefreshControlStateNormal:
            shouldAnimating = NO;
            self.arrowImageView.hidden = NO;
            self.arrowImageView.transform = CGAffineTransformIdentity;
            break;
        case STRefreshControlStateNotifyingResults:
            shouldAnimating = NO;
            self.arrowImageView.hidden = YES;
            self.arrowImageView.transform = CGAffineTransformIdentity;
            break;
    }
    self.refreshStatusLabel.text = [self titleForState:refreshControlState];
    if (shouldAnimating && ![self.indicatorView isAnimating]) {
        [self.indicatorView startAnimating];
    }
    if (!shouldAnimating && [self.indicatorView isAnimating]) {
        [self.indicatorView stopAnimating];
    }
}

- (void)setTitle:(NSString *)title forState:(STRefreshControlState)state {
    NSString *key = [NSString stringWithFormat:@"%ld", (long)state];
    _titles[key] = title;
}

- (NSString *)titleForState:(STRefreshControlState)state {
    NSString *key = [NSString stringWithFormat:@"%ld", (long)state];
    return _titles[key];
}

@end

CGSize const STRefreshControlSize = {200, 60};
