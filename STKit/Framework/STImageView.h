//
//  STImageView.h
//  STKit
//
//  Created by SunJiangting on 13-11-26.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import <STKit/STDefines.h>
#import <UIKit/UIKit.h>

typedef enum STImageViewState {
    STImageViewStateNormal,
    STImageViewStateDownloadError,
    STImageViewStateDownloadFinished,
} STImageViewState;

@class STRoundProgressView;
/// 支持GIF播放
@interface STImageView : UIImageView

@property(nonatomic, readonly) STRoundProgressView *progressView;

@property(nonatomic, copy) NSString *URLString;
@property(nonatomic, assign) BOOL showProgressWhenLoading;

@end

/// 支持GIF播放的ImageView
@interface STImageView (STGIFImage)
/// GIF是否循环播放
@property(nonatomic, assign) BOOL  repeats;
/// GIF 循环播放时候的时间间隔 （播放完成之后停顿时间）
@property(nonatomic, assign) NSTimeInterval  repeatTimeInterval;
/// 是否正在播放GIF
@property(nonatomic, assign, readonly, getter=isPlaying) BOOL  playing;
@property(nonatomic, assign) BOOL  automaticallyPlay;
@property(nonatomic, strong) void (^GIFPlayCompletionHandler)(STImageView *imageView, BOOL finished);
/// Default NSRunLoopCommonModes
@property(nonatomic, strong) NSString   *playInMode;

- (void)play;
- (void)pause;
- (void)stop;

- (void)replay;

@end