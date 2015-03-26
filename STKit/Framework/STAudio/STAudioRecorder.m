//
//  STAudioRecorder.m
//  STKit
//
//  Created by SunJiangting on 13-10-5.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import "STAudioRecorder.h"

#import <CoreGraphics/CoreGraphics.h>

void STAudioInputCallback(void *inUserData, // Custom audio metadata
                          AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime, UInt32 inNumberPacketDescriptions,
                          const AudioStreamPacketDescription *inPacketDescs);

void STAudioRuningCallback(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID);

#define AudioQueueBufSize 0x1000 // Number of bytes in each audio queue buffer
#define AudioQueueBufs 3

@interface STAudioRecorder () {

    AudioFileID _audioFileID;
    AudioStreamBasicDescription _audioFormat;
    AudioQueueRef _audioQueue;
    AudioQueueBufferRef _audioQueueBuffer[3]; // audio queue buffers

    AudioQueueLevelMeterState *_audioQueueLevel;
    double _currentPacket;
    NSTimeInterval _duration;
    NSTimer *_displayTimer;

    BOOL _paused;
}

@property(nonatomic, copy) STAudioRecordHandler audioHandler;
@property(nonatomic, copy) STAudioDataHandler dataHandler;

- (void)loadAudioFormat:(AudioStreamBasicDescription *)format;

- (BOOL)openAudioQueueWithError:(NSError **)error;
- (void)closeAudioQueue;

- (void)audioQueueInputwithQueue:(AudioQueueRef)audioQue
                     queueBuffer:(AudioQueueBufferRef)audioQueueBuf
                       timeStamp:(const AudioTimeStamp *)inStartTime
                         numPack:(UInt32)inNumberPacketDescriptions
                 withDescription:(const AudioStreamPacketDescription *)inPacketDescs;

- (void)stopInternalWithError:(NSError *)error;

@end

@implementation STAudioRecorder

- (void)dealloc {
    if (_audioQueueLevel) {
        free(_audioQueueLevel);
        _audioQueueLevel = NULL;
    }
    [_displayTimer invalidate];
    self.audioHandler = nil;
    self.dataHandler = nil;
    [self stop];
}

- (id)init {
    self = [super init];
    if (self) {
        self.sampleRate = 44100;
    }
    return self;
}

/**
 * @abstract 开始录音
 *
 * @param    path           音频文件将要保存的路径
 * @param    audioHandler   用于录音状态时界面的相应。该回调不会返回音频数据，每次需要绘制的时候则会回调，默认1s调用60次。
 *
 * @discussion  录音时，界面如果需要响应，比如 显示音波效果等，就需要从audioHandler回调中取得值
 */
// 以下两个方法均为录音方法。 如果需要得到原始音频数据，则需要使用第二个方法。
- (void)startRecordWithPath:(NSString *)path handler:(STAudioRecordHandler)audioHandler {
    [self startRecordWithPath:path handler:audioHandler dataHandler:nil];
}

- (void)startRecordWithPath:(NSString *)path handler:(STAudioRecordHandler)audioHandler dataHandler:(STAudioDataHandler)dataHandler {
    [self stopInternalWithError:nil];
    if (!path) {
        NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
        NSString *name = [NSString stringWithFormat:@"%lld.caf", (long long int)timeInterval];
        path = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
    }
    _path = [path copy];

    self.audioHandler = audioHandler;
    self.dataHandler = dataHandler;

    [self loadAudioFormat:&_audioFormat];
    NSError *error;
    [self openAudioQueueWithError:&error];

    if (error) {
        if (_path.length > 0) {
            unlink([_path UTF8String]);
        }
        if (self.audioHandler) {
            self.audioHandler(STAudioRecorderFailed, nil, error);
        }
        self.audioHandler = nil;
        self.dataHandler = nil;
    } else {
        if (self.audioHandler) {
            self.audioHandler(STAudioRecorderBegan, @{ STAudioRecorderKeyDuration : @(0) }, nil);
        }
        if (!_displayTimer) {
            _displayTimer = [NSTimer timerWithTimeInterval:1 / 60 target:self selector:@selector(audioRunLoop) userInfo:nil repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:_displayTimer forMode:NSRunLoopCommonModes];
        }
    }
}

- (void)pause {
    if (self.recording && !_paused) {
        AudioQueuePause(_audioQueue);
        _paused = YES;
    } else if (self.recording && _paused) {
        AudioQueueStart(_audioQueue, NULL);
        _paused = NO;
    }
}

/// 停止录音
- (void)stop {
    if (!self.recording) {
        return;
    }
    AudioQueueStop(_audioQueue, YES);
    [self stopInternalWithError:nil];
}

/// 是否处于录音状态
- (BOOL)recording {
    return !!(_audioQueue);
}

- (void)audioRunLoop {
    if (self.recording && self.audioHandler) {
        CGFloat averagePower = 0.0f, peakPower = 0.0f;
        UInt32 size = sizeof(AudioQueueLevelMeterState) * _audioFormat.mChannelsPerFrame;
        OSStatus status = AudioQueueGetProperty(_audioQueue, kAudioQueueProperty_CurrentLevelMeterDB, _audioQueueLevel, &size);
        if (status == noErr) {
            averagePower = _audioQueueLevel[0].mAveragePower;
            peakPower = _audioQueueLevel[0].mPeakPower;
        }
        _duration = [self progressedTimeInterval];
        NSDictionary *userInfo = @{
            STAudioRecorderKeyDuration : @(_duration),
            STAudioRecorderKeyAveragePower : @(averagePower),
            STAudioRecorderKeyPeakPower : @(peakPower)
        };
        if (self.audioHandler) {
            self.audioHandler(STAudioRecorderProgressed, userInfo, nil);
        }
    }
}

/// 录音时常
- (NSTimeInterval)progressedTimeInterval {
    if (!_audioQueue) {
        return 0.0f;
    }
    AudioTimeStamp queueTime;
    Boolean discontinuity;
    OSStatus status = AudioQueueGetCurrentTime(_audioQueue, NULL, &queueTime, &discontinuity);
    if (status != noErr) {
        if (status != kAudioQueueErr_InvalidRunState)
            NSLog(@"get audio queue time error.");
        return 0.0;
    }
    return queueTime.mSampleTime / _audioFormat.mSampleRate;
}

/// 设置录音的一些基本参数
- (void)loadAudioFormat:(AudioStreamBasicDescription *)format {
    format->mSampleRate = self.sampleRate;
    format->mFormatID = kAudioFormatLinearPCM;
    format->mFramesPerPacket = 1;
    format->mChannelsPerFrame = 1;
    format->mBytesPerFrame = 2;
    format->mBytesPerPacket = 2;
    format->mBitsPerChannel = 16;
    format->mReserved = 0;
    format->mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
}

- (BOOL)openAudioQueueWithError:(NSError **)error {
    NSError *audioError;
    OSStatus status = AudioQueueNewInput(&_audioFormat, STAudioInputCallback, (__bridge void *)(self), CFRunLoopGetCurrent(), kCFRunLoopCommonModes,
                                         0, &_audioQueue);
    if (status != noErr) {
        NSString *errorMsg = @"AudioQueueNewOutput error";
        audioError = [NSError errorWithDomain:STAudioRecorderKeyErrorDomain code:status userInfo:@{STAudioRecorderKeyErrorData : errorMsg}];
        if (error) {
            *error = audioError;
        }
        return NO;
    }
    status = AudioQueueAddPropertyListener(_audioQueue, kAudioQueueProperty_IsRunning, STAudioRuningCallback, (__bridge void *)(self));
    if (status != noErr) {
        NSString *errorMsg = @"AudioQueueAddPropertyListener called with kAudioQueueProperty_IsRunning error";
        audioError = [NSError errorWithDomain:STAudioRecorderKeyErrorDomain code:status userInfo:@{STAudioRecorderKeyErrorData : errorMsg}];
        if (error) {
            *error = audioError;
        }
        return NO;
    }

    for (int i = 0; i < AudioQueueBufs; i++) {
        OSStatus status = AudioQueueAllocateBuffer(_audioQueue, AudioQueueBufSize, &_audioQueueBuffer[i]);
        if (status != noErr) {
            NSString *errorMsg = @"AudioQueueAllocateBuffer error";
            audioError = [NSError errorWithDomain:STAudioRecorderKeyErrorDomain code:status userInfo:@{STAudioRecorderKeyErrorData : errorMsg}];
            if (error) {
                *error = audioError;
            }
            return NO;
        }
        status = AudioQueueEnqueueBuffer(_audioQueue, _audioQueueBuffer[i], 0, NULL);
        if (status != noErr) {
            NSString *errorMsg = @"AudioQueueEnqueueBuffer error";
            audioError = [NSError errorWithDomain:STAudioRecorderKeyErrorDomain code:status userInfo:@{STAudioRecorderKeyErrorData : errorMsg}];
            if (error) {
                *error = audioError;
            }
            return NO;
        }
    }

    UInt32 val = 1;
    status = AudioQueueSetProperty(_audioQueue, kAudioQueueProperty_EnableLevelMetering, &val, sizeof(UInt32));
    if (status != noErr) {
        NSString *errorMsg = @"AudioQueueSetProperty called with kAudioQueueProperty_EnableLevelMetering error";
        audioError = [NSError errorWithDomain:STAudioRecorderKeyErrorDomain code:status userInfo:@{STAudioRecorderKeyErrorData : errorMsg}];
        if (error) {
            *error = audioError;
        }
        return NO;
    }
    CFURLRef url = CFURLCreateFromFileSystemRepresentation(NULL, (UInt8 *)[_path UTF8String], _path.length, false);
    status = AudioFileCreateWithURL(url, kAudioFileCAFType, &_audioFormat, kAudioFileFlags_EraseFile, &_audioFileID);
    CFRelease(url);
    if (status != noErr) {
        NSString *errorMsg = @"AudioFileCreateWithURL error";
        audioError = [NSError errorWithDomain:STAudioRecorderKeyErrorDomain code:status userInfo:@{STAudioRecorderKeyErrorData : errorMsg}];
        if (error) {
            *error = audioError;
        }
        return NO;
    }
    _currentPacket = 0;
    _duration = 0;

    status = AudioQueueStart(_audioQueue, NULL);
    if (status != noErr) {
        NSString *errorMsg = @"AudioQueueStart error";
        audioError = [NSError errorWithDomain:STAudioRecorderKeyErrorDomain code:status userInfo:@{STAudioRecorderKeyErrorData : errorMsg}];
        if (error) {
            *error = audioError;
        }
        return NO;
    }
    _audioQueueLevel = (AudioQueueLevelMeterState *)realloc(_audioQueueLevel, _audioFormat.mChannelsPerFrame * sizeof(AudioQueueLevelMeterState));
    if (!_audioQueueLevel) {
        NSString *errorMsg = @"malloc AudioQueueLevelMeterState error";
        audioError = [NSError errorWithDomain:STAudioRecorderKeyErrorDomain code:-1 userInfo:@{STAudioRecorderKeyErrorData : errorMsg}];
    }
    if (error) {
        *error = audioError;
        return NO;
    }
    return YES;
}

- (void)closeAudioQueue {
    if (_audioQueue) {
        for (int i = 0; i < AudioQueueBufs; i++) {
            AudioQueueFreeBuffer(_audioQueue, _audioQueueBuffer[i]);
        }
        AudioQueueRemovePropertyListener(_audioQueue, kAudioQueueProperty_IsRunning, STAudioRuningCallback, (__bridge void *)(self));
        AudioQueueStop(_audioQueue, YES);
        _audioQueue = nil;
        if (_audioFileID) {
            AudioFileClose(_audioFileID);
            _audioFileID = nil;
            _currentPacket = 0;
        }
    }
}

- (void)audioQueueInputwithQueue:(AudioQueueRef)audioQue
                     queueBuffer:(AudioQueueBufferRef)audioQueueBuf
                       timeStamp:(const AudioTimeStamp *)inStartTime
                         numPack:(UInt32)inNumberPacketDescriptions
                 withDescription:(const AudioStreamPacketDescription *)inPacketDescs {

    OSStatus status = AudioFileWritePackets(_audioFileID, false, audioQueueBuf->mAudioDataByteSize, inPacketDescs, _currentPacket,
                                            &inNumberPacketDescriptions, audioQueueBuf->mAudioData);
    if (status != noErr) {
        NSString *errorMsg = @"AudioFileWritePackets error";
        [self stopInternalWithError:
                  [NSError errorWithDomain:STAudioRecorderKeyErrorDomain code:status userInfo:@{STAudioRecorderKeyErrorData : errorMsg}]];
    } else {
        _currentPacket += inNumberPacketDescriptions;
        AudioQueueEnqueueBuffer(_audioQueue, audioQueueBuf, 0, NULL);
        if (self.dataHandler) {
            self.dataHandler(audioQueueBuf, nil);
        }
    }
}
/// 停止录音
- (void)stopInternalWithError:(NSError *)error {
    [self closeAudioQueue];
    if (self.audioHandler) {
        NSDictionary *userInfo = @{ STAudioRecorderKeyDuration : @(_duration) };
        if (error) {
            if (_path.length > 0) {
                unlink([_path UTF8String]);
            }
            self.audioHandler(STAudioRecorderCancelled, userInfo, error);
        } else {
            self.audioHandler(STAudioRecorderEnded, userInfo, nil);
        }
    }
    self.audioHandler = nil;
    self.dataHandler = nil;
    [_displayTimer invalidate];
    _displayTimer = nil;
}

@end

NSString *const STAudioRecorderKeyDuration = @"duration";
NSString *const STAudioRecorderKeyPeakPower = @"peakPower";
NSString *const STAudioRecorderKeyAveragePower = @"averagePower";

NSString *const STAudioRecorderKeyErrorDomain = @"com.suen.STKit";
NSString *const STAudioRecorderKeyErrorData = @"data";

void STAudioInputCallback(void *inUserData, // Custom audio metadata
                          AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime, UInt32 inNumberPacketDescriptions,
                          const AudioStreamPacketDescription *inPacketDescs) {

    STAudioRecorder *audioRecorder = (__bridge STAudioRecorder *)inUserData;

    [audioRecorder audioQueueInputwithQueue:inAQ
                                queueBuffer:inBuffer
                                  timeStamp:inStartTime
                                    numPack:inNumberPacketDescriptions
                            withDescription:inPacketDescs];
}

void STAudioRuningCallback(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID) {
    STAudioRecorder *audioRecorder = (__bridge STAudioRecorder *)inUserData;
    UInt32 *runing;
    UInt32 dataSize = sizeof(UInt32);
    OSStatus status = AudioQueueGetProperty(inAQ, inID, &runing, &dataSize);
    if (runing == 0 || status != noErr) {
        // 停止
        [audioRecorder stopInternalWithError:nil];
    }
}
