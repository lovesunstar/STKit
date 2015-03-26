//
//  STAudioPlayer.m
//  STKit
//
//  Created by SunJiangting on 13-10-5.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import "STAudioPlayer.h"

#import <AudioToolbox/AudioToolbox.h>

#import <AVFoundation/AVFoundation.h>
#import <MapKit/MapKit.h>

/// 共3个AudioQueue缓冲区
const NSInteger STAudioQueueBufferCount = 3;
/// AudioQueue的每个buffer 4k大小
const NSInteger STAudioQueueBufferSize = 0x1000;

@interface STAudioPlayer () {
    AudioQueueRef _audioQueueRef;
    AudioQueueBufferRef _audioQueueBuffers[STAudioQueueBufferCount];

    UInt32 _packetIndex;
}

- (void)enqueueAudioData:(NSData *)audioData;

@property(nonatomic, assign) AudioFileID audioFileID;

@end

@implementation STAudioPlayer

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)playWithURLString:(NSString *)URLString {

    NSURL *URL = [NSURL fileURLWithPath:URLString];
    OSStatus status = AudioFileOpenURL((__bridge CFURLRef)URL, kAudioFileReadPermission, 0, &_audioFileID);
    if (status != noErr) {
        NSLog(@"Open File Error %@", URLString);
        return;
    }
    UInt32 size;
    status = AudioFileGetProperty(_audioFileID, kAudioFilePropertyDataFormat, &size, &_audioDataFormat);
    if (status != noErr) {
        NSLog(@"Get Property Error %@", URLString);
        return;
    }
    status = AudioQueueNewOutput(&_audioDataFormat, STAudioQueueOutputCallback, (__bridge void *)(self), NULL, NULL, 0, &_audioQueueRef);
    if (status != noErr) {
        NSLog(@"AudioQueueNewOutput Error %@", URLString);
        return;
    }
    for (int i = 0; i < STAudioQueueBufferCount; i++) {
        AudioQueueEnqueueBuffer(_audioQueueRef, _audioQueueBuffers[i], 0, nil);
    }

    /*
    //计算单位时间包含的包数
    if (dataFormat.mBytesPerPacket==0 || dataFormat.mFramesPerPacket==0) {
        size=sizeof(maxPacketSize);
        AudioFileGetProperty(audioFile, kAudioFilePropertyPacketSizeUpperBound, &size, &maxPacketSize);
        if (maxPacketSize > gBufferSizeBytes) {
            maxPacketSize= gBufferSizeBytes;
        }
        //算出单位时间内含有的包数
        numPacketsToRead = gBufferSizeBytes/maxPacketSize;
        packetDescs=malloc(sizeof(AudioStreamPacketDescription)*numPacketsToRead);
    }else {
        numPacketsToRead= gBufferSizeBytes/dataFormat.mBytesPerPacket;
        packetDescs=nil;
    }

    //设置Magic Cookie，参见第二十七章的相关介绍
    AudioFileGetProperty(audioFile, kAudioFilePropertyMagicCookieData, &size, nil);
    if (size >0) {
        cookie=malloc(sizeof(char)*size);
        AudioFileGetProperty(audioFile, kAudioFilePropertyMagicCookieData, &size, cookie);
        AudioQueueSetProperty(queue, kAudioQueueProperty_MagicCookie, cookie, size);
    }

    //创建并分配缓冲空间
    packetIndex=0;
    for (i=0; i<NUM_BUFFERS; i++) {
        AudioQueueAllocateBuffer(queue, gBufferSizeBytes, &buffers[i]);
        //读取包数据
        if ([self readPacketsIntoBuffer:buffers[i]]==1) {
            break;
        }
    }

    Float32 gain=1.0;
    //设置音量
    AudioQueueSetParameter(queue, kAudioQueueParam_Volume, gain);
    //队列处理开始，此后系统开始自动调用回调(Callback)函数
    AudioQueueStart(queue, nil);
     */
}

- (void)pause {
}

#pragma mark - Play
- (void)enqueueAudioData:(NSData *)audioData {
}

- (UInt8)fillPacketsIntoAudioBuffer:(AudioQueueBufferRef)audioQueueBuffer {
    UInt32 numBytes, numPackets;
    /*
    //从文件中接受数据并保存到缓存(buffer)中
    AudioFileReadPackets(audioFile, NO, &numBytes, packetDescs, _packetIndex, &numPackets, AudioQueueBufferRef->mAudioData);
    if(numPackets >0){
        buffer->mAudioDataByteSize=numBytes;
        AudioQueueEnqueueBuffer(queue, buffer, (packetDescs ? numPackets : 0), packetDescs);
        packetIndex += numPackets;
    }
    else{
        return 1;//意味着我们没有读到任何的包
    }
     */
    return 0; // 0代表正常的退出
}

@end
