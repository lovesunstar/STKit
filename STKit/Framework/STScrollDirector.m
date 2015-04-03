//
//  STScrollDirector.m
//  STKit
//
//  Created by SunJiangting on 14-5-10.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STScrollDirector.h"
#import "STResourceManager.h"

@implementation STAccessoryView

- (instancetype)initWithFrame:(CGRect)frame {
    if (frame.size.width < STAccessoryViewMinimumSize.width) {
        frame.size.width = STAccessoryViewMinimumSize.width;
    }
    if (frame.size.height < STAccessoryViewMinimumSize.height) {
        frame.size.height = STAccessoryViewMinimumSize.height;
    }
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat width = CGRectGetWidth(frame), height = CGRectGetHeight(frame);
        CGFloat leftMargin = (width - STAccessoryViewMinimumSize.width) / 2, topMargin = (height - STAccessoryViewMinimumSize.height) / 2;

        UIView *contentView =
            [[UIView alloc] initWithFrame:CGRectMake(leftMargin, topMargin, STAccessoryViewMinimumSize.width, STAccessoryViewMinimumSize.height)];
        contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [self addSubview:contentView];

        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(77, 10, 45, 45)];
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [contentView addSubview:self.imageView];

        self.textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 70, 200, 20)];
        self.textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        [contentView addSubview:self.textLabel];
    }
    return self;
}

@end

CGSize const STAccessoryViewMinimumSize = {200, 100};

@interface STScrollDirector ()

@property(nonatomic, strong) NSMutableDictionary *titleDictionary;

@end

@implementation STScrollDirector

- (void)dealloc {
    self.scrollView = nil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.titleDictionary = [NSMutableDictionary dictionaryWithCapacity:5];
    }
    return self;
}

- (STPaginationControl *)paginationControl {
    if (!_paginationControl) {
        STDefaultPaginationControl *paginatinControl = [[STDefaultPaginationControl alloc] init];
        if ([self titleForState:STScrollDirectorStatePaginationNormal]) {
            [paginatinControl setTitle:[self titleForState:STScrollDirectorStatePaginationNormal] forState:STPaginationControlStateNormal];
            ;
        }
        if ([self titleForState:STScrollDirectorStatePaginationLoading]) {
            [paginatinControl setTitle:[self titleForState:STScrollDirectorStatePaginationLoading] forState:STPaginationControlStateLoading];
        }
        if ([self titleForState:STScrollDirectorStatePaginationFailed]) {
            [paginatinControl setTitle:[self titleForState:STScrollDirectorStatePaginationFailed] forState:STPaginationControlStateFailed];
        }
        if ([self titleForState:STPaginationControlStateReachedEnd]) {
            [paginatinControl setTitle:[self titleForState:STScrollDirectorStatePaginationReachedEnd] forState:STPaginationControlStateReachedEnd];
        }
        _paginationControl = paginatinControl;
    }
    return _paginationControl;
}

- (STRefreshControl *)refreshControl {
    if (!_refreshControl) {
        STDefaultRefreshControl *refreshControl = [[STDefaultRefreshControl alloc] init];
        if ([self titleForState:STScrollDirectorStateRefreshNormal]) {
            [refreshControl setTitle:[self titleForState:STScrollDirectorStateRefreshNormal] forState:STRefreshControlStateNormal];
        }
        if ([self titleForState:STScrollDirectorStateRefreshReachedThreshold]) {
            [refreshControl setTitle:[self titleForState:STScrollDirectorStateRefreshReachedThreshold]
                            forState:STRefreshControlStateReachedThreshold];
        }
        if ([self titleForState:STScrollDirectorStateRefreshLoading]) {
            [refreshControl setTitle:[self titleForState:STScrollDirectorStateRefreshLoading] forState:STRefreshControlStateLoading];
        }
        _refreshControl = refreshControl;
    }
    if (!_refreshControl.superview && self.scrollView) {
        [self.scrollView addSubview:_refreshControl];
    }
    return _refreshControl;
}

- (void)setScrollView:(UIScrollView *)scrollView {
    if (_scrollView) {
        [_refreshControl removeFromSuperview];
        [_paginationControl removeFromSuperview];
    }
    if (_refreshControl) {
        [scrollView addSubview:_refreshControl];
    }
    _scrollView = scrollView;
}

@end

@implementation STScrollDirector (STDefaultControl)

- (NSString *)titleForState:(NSInteger)state {
    NSString *key = [NSString stringWithFormat:@"%ld", (long)state];
    return [self.titleDictionary valueForKey:key];
}

- (void)setTitle:(NSString *)title forState:(STScrollDirectorState)state {
    NSString *key = [NSString stringWithFormat:@"%ld", (long)state];
    [self.titleDictionary setValue:title forKey:key];
    if (state < 10) {
        if (_refreshControl && [_refreshControl isKindOfClass:[STDefaultRefreshControl class]]) {
            [((STDefaultRefreshControl *)_refreshControl)setTitle:title forState:state - 1];
        }
    } else {
        if (_paginationControl && [_paginationControl isKindOfClass:[STDefaultPaginationControl class]]) {
            [((STDefaultPaginationControl *)_paginationControl)setTitle:title forState:state - 11];
        }
    }
}

@end
