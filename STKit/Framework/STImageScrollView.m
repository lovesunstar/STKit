//
//  STImageScrollView.m
//  STKit
//
//  Created by SunJiangting on 13-12-25.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import "STImageScrollView.h"
#import "STImageLoader.h"
#import "STRoundProgressView.h"
#import "STImageCache.h"
#import "UIImageView+STImageLoader.h"

@interface STImageScrollView () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property(nonatomic, strong) UIImageView *imageView;
@property(nonatomic, assign) NSTimeInterval previousTapTimeInterval;
@property(nonatomic, strong) STRoundProgressView *roundProgressView;
@property(nonatomic, assign) BOOL                 respondsToGesture;

@end

@implementation STImageScrollView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.delegate = self;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.minimumZoomScale = 1.0;
        self.delaysContentTouches = NO;

        self.autoFitImageView = YES;
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:self.imageView];

        self.roundProgressView = [[STRoundProgressView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
        self.roundProgressView.center = self.imageView.center;
        self.roundProgressView.hidden = YES;
        [self.imageView addSubview:self.roundProgressView];


        UITapGestureRecognizer *singleTapGestureRecognizer =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestureRecognizerFired:)];
        singleTapGestureRecognizer.numberOfTouchesRequired = 1;
        singleTapGestureRecognizer.numberOfTapsRequired = 1;
        [self addGestureRecognizer:singleTapGestureRecognizer];

        UITapGestureRecognizer *doubleTapGestureRecognizer =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapGestureRecognizerFired:)];
        doubleTapGestureRecognizer.numberOfTouchesRequired = 1;
        doubleTapGestureRecognizer.numberOfTapsRequired = 2;
        [self addGestureRecognizer:doubleTapGestureRecognizer];

        UILongPressGestureRecognizer *longPressRecognizer =
            [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressRecognizerFired:)];
        longPressRecognizer.minimumPressDuration = 0.5;
        [self addGestureRecognizer:longPressRecognizer];
        [singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
    }
    return self;
}

- (void)setImage:(UIImage *)image animated:(BOOL)animated {
    void (^animations)() = ^{
        self.imageView.image = image;
        [self zoomToFitImage:image];
        [self maximumZoomScaleToFit];
    };
    if (animated) {
        [UIView animateWithDuration:0.5 animations:animations];
    } else {
        animations();
    }
}

- (void)setImageURL:(NSString *)imageURL animated:(BOOL)animated {
    self.pinchGestureRecognizer.enabled = YES;
    self.respondsToGesture = YES;
    UIImage *cachedImage = [STImageCache cachedImageForKey:imageURL];
    if (cachedImage) {
        [self setImage:cachedImage animated:NO];
        self.roundProgressView.hidden = YES;
        return;
    }
    self.pinchGestureRecognizer.enabled = NO;
    self.respondsToGesture = NO;
    self.roundProgressView.completion = 0;
    self.roundProgressView.hidden = NO;
    self.roundProgressView.center = CGPointMake(self.imageView.bounds.size.width / 2, self.imageView.bounds.size.height / 2);
    self.imageView.placeholderImage = self.imageView.image;
    static NSString *previousURLString;
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(displayImageWithURL:) object:previousURLString];
    previousURLString = imageURL;
    [self performSelector:@selector(displayImageWithURL:) withObject:imageURL afterDelay:0.5];
}

- (void)displayImageWithURL:(NSString *)URLString {
    __weak STImageScrollView *weakSelf = self;
    [self.imageView setImageWithURLString:URLString
        progressHandler:^(CGFloat completion) { [weakSelf.roundProgressView setCompletion:completion animated:YES]; }
        finishedHandler:^(UIImage *image, NSString *URLString, BOOL usingCache, NSError *error) {
            if (image) {
                weakSelf.roundProgressView.hidden = YES;
                weakSelf.pinchGestureRecognizer.enabled = YES;
                weakSelf.respondsToGesture = YES;
                [weakSelf setImage:image animated:YES];
            }
        }];
}

- (void)zoomToFit {
    [self zoomToFitImage:self.imageView.image];
}

- (void)zoomToFitImage:(UIImage *)image {
    self.zoomScale = 1.0;
    CGSize size = self.bounds.size;
    CGSize preferredSize = [self preferredSizeForImage:image];
    CGRect imageFrame =
        CGRectMake((size.width - preferredSize.width) / 2, (size.height - preferredSize.height) / 2, preferredSize.width, preferredSize.height);
    self.imageView.frame = imageFrame;
}

- (void)zoomToLocation:(CGPoint)location {
    CGRect zoomRect;
    if ([self isZoomed]) {
        zoomRect = self.bounds;
    } else {
        zoomRect = [self zoomRectForScale:self.maximumZoomScale withCenter:location];
    }
    [self zoomToRect:zoomRect animated:YES];
}

- (CGRect)zoomRectForScale:(CGFloat)scale withCenter:(CGPoint)center {
    CGFloat width = CGRectGetWidth(self.bounds), height = CGRectGetWidth(self.bounds);
    CGRect zoomRect = CGRectZero;
    zoomRect.origin.x = center.x - (width / scale / 2.0);
    zoomRect.origin.y = center.y - (height / scale / 2.0);
    zoomRect.size.width = width / scale;
    zoomRect.size.height = height / scale;
    return zoomRect;
}

#pragma mark - Private Method
- (void)locationToFit {
    CGSize size = self.bounds.size;
    CGSize contentSize = self.contentSize;
    CGFloat centerX = (contentSize.width > size.width) ? contentSize.width / 2 : size.width / 2;
    CGFloat centerY = (contentSize.height > size.height) ? contentSize.height / 2 : size.height / 2;
    self.imageView.center = CGPointMake(centerX, centerY);
}

- (void)maximumZoomScaleToFit {
    CGSize size = self.bounds.size;
    CGSize imageViewSize = self.imageView.bounds.size;
    CGSize imageSize = self.imageView.image.size;

    CGFloat width = size.width, height = size.height;
    CGFloat imageWidth = imageSize.width, imageHeight = imageSize.height;
    CGFloat imageViewWidth = imageViewSize.width, imageViewHeight = imageViewSize.height;
    if (imageWidth == 0 || imageHeight == 0 || imageViewWidth == 0 || imageViewHeight == 0) {
        return;
    }
    CGFloat scale = 1.0, imageRate = imageSize.width / imageSize.height, rate = size.width / size.height;
    if (imageRate > rate) { //偏宽
        scale = (imageHeight * 0.5 > height) ? (imageHeight / (2 * imageViewHeight)) : (height / imageViewHeight);
    } else {
        scale = (imageWidth * 0.5 > width) ? (imageWidth / (2 * imageViewWidth)) : (width / imageViewWidth);
    }
    self.maximumZoomScale = MAX(4, scale);
}

- (BOOL)isZoomed {
    return (self.zoomScale != self.minimumZoomScale);
}

- (CGSize)preferredSizeForImage:(UIImage *)image {
    if (!image) {
        return CGSizeZero;
    }
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat height = CGRectGetHeight(self.bounds);
    CGFloat imageWidth = image.size.width, imageHeight = image.size.height;
    if (imageWidth <= width && imageHeight <= height) {
        return CGSizeMake(imageWidth, imageHeight);
    }
    CGFloat imageRate = imageWidth / imageHeight, viewRate = width / height;
    if (imageRate > viewRate) {
        imageWidth = width;
        imageHeight = imageWidth / imageRate;
    } else {
        imageHeight = height;
        imageWidth = imageHeight * imageRate;
    }
    return CGSizeMake(imageWidth, imageHeight);
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    /// 图片居中显示
    [self locationToFit];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    [scrollView setZoomScale:scale animated:NO];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

#pragma mark - UIGestureRecognizerAction
- (void)longPressRecognizerFired:(UILongPressGestureRecognizer *)sender {
    if (!self.respondsToGesture) {
        sender.enabled = NO;
        sender.enabled = YES;
        return;
    }
    if (sender.state == UIGestureRecognizerStateChanged) {
        if ([self.interactionDelegate respondsToSelector:@selector(imageScrollViewDidLongPressed:)]) {
            [self.interactionDelegate imageScrollViewDidLongPressed:self];
        }
        sender.enabled = NO;
    }
    if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled) {
        sender.enabled = YES;
    }
}

- (void)singleTapGestureRecognizerFired:(UITapGestureRecognizer *)tapGestureRecognizer {
    if ([self.interactionDelegate respondsToSelector:@selector(imageScrollViewDidTapped:)]) {
        [self.interactionDelegate imageScrollViewDidTapped:self];
    }
}

- (void)doubleTapGestureRecognizerFired:(UITapGestureRecognizer *)tapGestureRecognizer {
    if (!self.respondsToGesture) {
        return;
    }
    [self zoomToLocation:[tapGestureRecognizer locationInView:self]];
}

@end
