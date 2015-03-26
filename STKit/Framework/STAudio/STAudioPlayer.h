//
//  STAudioPlayer.h
//  STKit
//
//  Created by SunJiangting on 13-10-5.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import <STKit/STDefines.h>
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

typedef enum STAudioPlayerStatus {
    STAudioPlayerStatusUnknown,
    STAudioPlayerStatusBuffering,   // 可能会涉及到网络文件的播放，当缓冲中，就会处于该状态
    STAudioPlayerStatusReadyToPlay, // 音频数据即将被播放
    STAudioPlayerStatusFailed       // 音频播放失败
} STAudioPlayerStatus;

@interface STAudioPlayer : NSObject

@property(nonatomic, assign) BOOL playing;
@property(nonatomic, readonly, assign) AudioFileID audioFileID;
@property(nonatomic, readonly, assign) AudioStreamBasicDescription audioDataFormat;

- (void)playWithURLString:(NSString *)URLString;

- (void)pause;

@end

static void STAudioQueueOutputCallback(void *oUserData, AudioQueueRef inAQ, AudioQueueBufferRef buffer);