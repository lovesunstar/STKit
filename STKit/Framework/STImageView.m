//
//  STImageView.m
//  STKit
//
//  Created by SunJiangting on 13-11-26.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import "STImageView.h"

#import "STRoundProgressView.h"
#import "UIImageView+STImageLoader.h"
#import "STImageLoader.h"
#import "STImage.h"

@interface STImageView () {
    STImage     *_gifImage;
}

@property(nonatomic, strong) STRoundProgressView *progressView;
@property(nonatomic, strong) NSTimer             *displayTimer;
@property (nonatomic, strong) NSString   *playInMode;

/// GIF是否循环播放
@property (nonatomic, assign) BOOL  repeats;
/// 是否正在播放GIF
@property (nonatomic, assign, getter=isPlaying) BOOL  playing;
@property (nonatomic, assign) BOOL  automaticallyPlay;
@property (nonatomic, strong) void (^completionHandler)(STImageView *imageView, BOOL finished);
@property (nonatomic, assign) NSInteger     currentPlayIndex;

@end

@implementation STImageView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.progressView = [[STRoundProgressView alloc] initWithFrame:CGRectMake(0, 0, 56, 56)];
        self.progressView.completion = 0.0;
        self.progressView.hidden = YES;
        [self addSubview:self.progressView];
        self.playInMode = NSDefaultRunLoopMode;
    }
    return self;
}

- (void)setImage:(UIImage *)image {
    if (image == _gifImage) {
        return;
    }
    if (!image) {
        _gifImage = nil;
        [super setImage:nil];
        if (self.displayTimer) {
            [self.displayTimer invalidate];
            self.displayTimer = nil;
        }
        return;
    }
    if ([image isKindOfClass:[STImage class]]) {
        _gifImage = (STImage *)image;
        _currentPlayIndex = 0;
        [super setImage:_gifImage];
        if (self.automaticallyPlay) {
            [self play];
        }
    } else {
        _gifImage = nil;
        [super setImage:image];
    }
}

- (UIImage *)image {
    if (_gifImage) {
        return _gifImage;
    }
    return [super image];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize size = self.frame.size;
    self.progressView.center = CGPointMake(size.width / 2, size.height / 2);
}

- (void)setShowProgressWhenLoading:(BOOL)showProgressWhenLoading {
    self.progressView.hidden = !showProgressWhenLoading;
    _showProgressWhenLoading = showProgressWhenLoading;
}

- (void)setURLString:(NSString *)URLString {
    if (![URLString isEqualToString:_URLString]) {
        if (self.showProgressWhenLoading) {
            self.progressView.hidden = NO;
        }
        __weak STImageView *this = self;
        [self st_setImageWithURLString:URLString
            progressHandler:^(CGFloat completion) { [this.progressView setCompletion:completion animated:YES]; }
            finishedHandler:^(UIImage *image, NSString *URLString, BOOL usingCache, NSError *error) { this.progressView.hidden = YES; }];
        _URLString = URLString;
    }
}

- (void)removeFromSuperview{
    [self pause];
    [super removeFromSuperview];
}

- (void)setAutomaticallyPlay:(BOOL)automaticallyPlay {
    _automaticallyPlay = automaticallyPlay;
    if (!self.playing && _gifImage) {
        [self play];
    }
}

@end

@implementation STImageView (STGIFImage)

- (void)play {
    if (!_gifImage.isGIFImage) {
        return;
    }
    if (!self.playing) {
        NSInteger prevIndex = self.currentPlayIndex - 1;
        if (prevIndex >= 0 && prevIndex < _gifImage.numberOfImages) {
            NSTimeInterval delay = 0;
            [_gifImage imageAtIndex:prevIndex duration:&delay];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self _playNextFrame];
            });
        } else {
            [self _playNextFrame];
        }
    }
    self.playing = YES;
}

- (void)_playNextFrame {
    [self.displayTimer invalidate];
    self.displayTimer = nil;
    BOOL hasNextFrame = (self.currentPlayIndex < _gifImage.numberOfImages);
    if (hasNextFrame) {
        NSTimeInterval duration;
        UIImage *image = [_gifImage imageAtIndex:self.currentPlayIndex duration:&duration];
        [super setImage:image];
        self.currentPlayIndex ++;
        self.displayTimer = [NSTimer timerWithTimeInterval:duration target:self selector:@selector(_playNextFrame) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:self.displayTimer forMode:self.playInMode];
    } else {
        if (!self.repeats) {
            [self _stopCausedByUser:NO];
        } else {
            self.currentPlayIndex = 0;
            NSTimeInterval duration;
            UIImage *image = [_gifImage imageAtIndex:self.currentPlayIndex duration:&duration];
            [super setImage:image];
            self.currentPlayIndex ++;
            self.displayTimer = [NSTimer timerWithTimeInterval:duration target:self selector:@selector(_playNextFrame) userInfo:nil repeats:NO];
            [[NSRunLoop currentRunLoop] addTimer:self.displayTimer forMode:self.playInMode];
        }
    }
}

- (void)pause {
    if (!_gifImage.isGIFImage) {
        return;
    }
    if (self.playing) {
        [self.displayTimer invalidate];
        self.displayTimer = nil;
    }
    self.playing = NO;
}

- (void)replay {
    if (!_gifImage.isGIFImage) {
        return;
    }
    [self.displayTimer invalidate];
    self.displayTimer = nil;
    self.currentPlayIndex = 0;
    self.playing = NO;
    [self play];
}

- (void)stop {
    [self _stopCausedByUser:YES];
}

- (void)_stopCausedByUser:(BOOL)causedByUser {
    if (!_gifImage.isGIFImage) {
        return;
    }
    // 如果不是正在播放
    if (!self.playing) {
        if (self.currentPlayIndex != 0) {
            // 如果没有到第0桢，就说明现在被暂停了
            if (self.completionHandler) {
                self.completionHandler(self, NO);
            }
        }
    } else {
        [self.displayTimer invalidate];
        self.displayTimer = nil;
        if (self.completionHandler) {
            self.completionHandler(self, !causedByUser);
        }
    }
    self.playing = NO;
    self.currentPlayIndex = 0;
}

@end
