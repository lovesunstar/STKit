//
//  STAudioCenter.m
//  STKit
//
//  Created by SunJiangting on 13-10-5.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import "STAudioCenter.h"

#import "STAudioRecorder.h"
#import <AudioToolbox/AudioToolbox.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVAudioSession.h>

@interface STAudioCenter () {
    id _enterBackgroundObserver;
    id _becomeActiveObserver;
  @public
    CGFloat _previousVolume;
}

@property(nonatomic, assign) BOOL audioSessionLocked;
- (void)setAudioSessionEnabled:(BOOL)audioSessionEnabled wantRecording:(BOOL)wantRecording;

@property(nonatomic, strong) STAudioRecorder *audioRecorder;

@end

static void STAudioSessionInterruptionListener(void *inClientData, UInt32 inInterruptionState);
static void STAudioSessionRouteChangedListener(void *inClientData, AudioSessionPropertyID inID, UInt32 inDataSize, const void *inData);
static void STAudioSessionOutputVolumeChangedListener(void *inClientData, AudioSessionPropertyID inID, UInt32 inDataSize, const void *inData);

@implementation STAudioCenter

static STAudioCenter *_sharedAudioCenter;
static BOOL _otherAudioSessionIsPlaying;

+ (instancetype)sharedAudioCenter {
    if (!_sharedAudioCenter) {
        @synchronized(self) {
            _sharedAudioCenter = STAudioCenter.new;
        }
    }
    return _sharedAudioCenter;
}

+ (void)setAudioSessionEnabled:(BOOL)audioSessionEnabled wantRecording:(BOOL)wantRecording {
    [[STAudioCenter sharedAudioCenter] setAudioSessionEnabled:audioSessionEnabled wantRecording:wantRecording];
}

- (void)dealloc {
    [self unloadAudioSession];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.audioRecorder stop];
}
- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadAudioSession];
    }
    return self;
}

- (void)playVibrations {
}
- (void)setAudioSessionEnabled:(BOOL)audioSessionEnabled wantRecording:(BOOL)wantRecording {
#if TARGET_OS_IPHONE
    if (audioSessionEnabled) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateOtherAudioPlayingStatus) object:nil];
        if (wantRecording) {
            UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
            AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
            UInt32 enableMixer = ![self hasHeadset];
            AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(enableMixer), &enableMixer);
            BOOL hasHeadset = [self hasHeadset];
            UInt32 audioRouteOverride = hasHeadset ? kAudioSessionOverrideAudioRoute_None : kAudioSessionOverrideAudioRoute_Speaker;
            AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride), &audioRouteOverride);
        } else {
            UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
            if (!wantRecording && [UIDevice currentDevice].proximityState == YES) {
                sessionCategory = kAudioSessionCategory_PlayAndRecord;
            }
            AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
        }
        if (_otherAudioSessionIsPlaying || wantRecording) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_disableSession) object:nil];
            [[AVAudioSession sharedInstance] setActive:YES error:nil];
        }
    } else {
        if (wantRecording) {
            UInt32 enableMixer = 0;
            AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(enableMixer), &enableMixer);
            UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_None;
            AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride), &audioRouteOverride);
            //        [[AVAudioSession sharedInstance] setActive:NO withFlags:AVAudioSessionSetActiveFlags_NotifyOthersOnDeactivation error:nil];
            if (self.audioSessionLocked || !_otherAudioSessionIsPlaying) {
                [self setAudioSessionEnabled:NO wantRecording:NO];
            }
            return;
        }
        if (self.audioSessionLocked || !_otherAudioSessionIsPlaying) {
            return;
        }
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_disableSession) object:nil];
        [self performSelector:@selector(_disableSession) withObject:nil afterDelay:1.5];
    }
#endif
}

#pragma mark - AVAudioSession
- (void)loadAudioSession {
#if TARGET_OS_IPHONE
    //初始化Audiosession环境
    AudioSessionInitialize(NULL, NULL, STAudioSessionInterruptionListener, (__bridge void *)(self));
    [self updateOtherAudioPlayingStatus];
    [self setAudioSessionEnabled:YES wantRecording:NO];

    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride), &audioRouteOverride);

    [self obtainCurrentVolume];

    AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, STAudioSessionRouteChangedListener, (__bridge void *)(self));
    AudioSessionAddPropertyListener(kAudioSessionProperty_CurrentHardwareOutputVolume, STAudioSessionOutputVolumeChangedListener,
                                    (__bridge void *)(self));
    // enable bluetooth
    UInt32 enableBluetooth = 1;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryEnableBluetoothInput, sizeof(enableBluetooth), &enableBluetooth);
#endif

    // 监听程序进入后台动作
    __weak STAudioCenter *weakSelf = self;
    _enterBackgroundObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                                                 object:nil
                                                                                  queue:[NSOperationQueue mainQueue]
                                                                             usingBlock:^(NSNotification *notification) {
                                                                                 weakSelf.audioSessionLocked = NO;
                                                                                 //        if (self.audioRecorder.recording) {
                                                                                 //            [self.audioRecorder stop];
                                                                                 //        } else {
                                                                                 _otherAudioSessionIsPlaying = YES;
                                                                                 ;
                                                                                 [weakSelf setAudioSessionEnabled:NO wantRecording:NO];
                                                                                 //        }
                                                                             }];
    _becomeActiveObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                                              object:nil
                                                                               queue:[NSOperationQueue mainQueue]
                                                                          usingBlock:^(NSNotification *note) {
                                                                              weakSelf.audioSessionLocked = NO;
                                                                              _otherAudioSessionIsPlaying = YES;
                                                                              [weakSelf setAudioSessionEnabled:NO wantRecording:NO];
                                                                              [self obtainCurrentVolume];
                                                                          }];
}

- (void)obtainCurrentVolume {
    if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(outputVolume)]) {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        _previousVolume = audioSession.outputVolume;
    } else {
        UInt32 dataSize = sizeof(float);
        AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareOutputVolume, &dataSize, &_previousVolume);
    }
}

- (void)unloadAudioSession {
    AudioSessionInitialize(NULL, NULL, NULL, (__bridge void *)(self));
    AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_AudioRouteChange, STAudioSessionRouteChangedListener,
                                                   (__bridge void *)(self));
    AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_CurrentHardwareOutputVolume, STAudioSessionOutputVolumeChangedListener,
                                                   (__bridge void *)(self));

    [[NSNotificationCenter defaultCenter] removeObserver:_enterBackgroundObserver name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:_becomeActiveObserver name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
}

- (void)updateOtherAudioPlayingStatus {
    UInt32 otherAudioIsPlaying = 1;
    UInt32 propertySize = sizeof(otherAudioIsPlaying);
    OSStatus status = AudioSessionGetProperty(kAudioSessionProperty_OtherAudioIsPlaying, &propertySize, &otherAudioIsPlaying);
    if (status == kAudioSessionNoError && otherAudioIsPlaying) {
        _otherAudioSessionIsPlaying = YES;
    } else {
        _otherAudioSessionIsPlaying = NO;
    }
}

- (void)_disableSession {
#if TARGET_OS_IPHONE
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    [self performSelector:@selector(updateOtherAudioPlayingStatus) withObject:nil afterDelay:1.0];
#endif
}

- (BOOL)hasHeadset {
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    CFStringRef route = nil;
    UInt32 propertySize = sizeof(CFStringRef);
    AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &propertySize, &route);
    NSString *routeStr = (__bridge NSString *)route;
    if (routeStr.length != 0) {
        NSRange headphoneRange = [routeStr rangeOfString:@"Headphone"];
        NSRange headsetRange = [routeStr rangeOfString:@"Headset"];
        CFRelease(route);
        if (headphoneRange.location != NSNotFound) {
            return YES;
        } else if (headsetRange.location != NSNotFound) {
            return YES;
        }
    }
    return NO;
#endif
}

///
- (void)handleInterruptionChangeToState:(AudioQueuePropertyID)inInterruptionState {
    if (inInterruptionState == kAudioSessionBeginInterruption) {
        self.audioSessionLocked = NO;
        //        if (self.audioRecorder.recording) {
        //            [self.audioRecorder stop];
        //        } else {
        [self setAudioSessionEnabled:NO wantRecording:self.audioRecorder.recording];
        //        }
    } else if (inInterruptionState == kAudioSessionEndInterruption) {
#if TARGET_OS_IPHONE
        _otherAudioSessionIsPlaying = YES;
        self.audioSessionLocked = NO;
        [self setAudioSessionEnabled:self.audioRecorder.recording wantRecording:self.audioRecorder.recording];
        [self obtainCurrentVolume];
#endif
    }
}

@end

@implementation STAudioCenter (STAudioRecorder)

- (void)startRecordWithPath:(NSString *)path handler:(STAudioRecordHandler)audioHandler {
    [self startRecordWithPath:path handler:audioHandler dataHandler:nil];
}

- (void)startRecordWithPath:(NSString *)path handler:(STAudioRecordHandler)audioHandler dataHandler:(STAudioDataHandler)dataHandler {
    BOOL sessionLocked = self.audioSessionLocked;
    self.audioSessionLocked = YES;
    if (!sessionLocked) {
        self.audioSessionLocked = NO;
    }
    if (!self.audioRecorder) {
        self.audioRecorder = STAudioRecorder.new;
    }
    [self setAudioSessionEnabled:YES wantRecording:YES];
    [self.audioRecorder startRecordWithPath:path
                                    handler:^(STAudioRecorderState state, id userInfo, NSError *error) {
                                        if (error || state == STAudioRecorderEnded) {
                                            [self setAudioSessionEnabled:NO wantRecording:NO];
                                        }
                                        if (audioHandler) {
                                            audioHandler(state, userInfo, error);
                                        }
                                    }
                                dataHandler:dataHandler];
}

- (void)finishRecord {
    if (self.audioRecorder.recording) {
        [self.audioRecorder stop];
    }
    [self setAudioSessionEnabled:NO wantRecording:NO];
}

@end

NSString *const STAudioSessionOutputVolumeDidChangeNotification = @"STAudioSessionOutputVolumeDidChangeNotification";
NSString *const STAudioSessionOutputVolumeNewValueKey = @"STAudioSessionOutputVolumeNewValueKey";
NSString *const STAudioSessionOutputVolumeOldValueKey = @"STAudioSessionOutputVolumeOldValueKey";

#pragma mark - Callbacks
static void STAudioSessionInterruptionListener(void *inClientData, UInt32 inInterruptionState) {
    [[STAudioCenter sharedAudioCenter] handleInterruptionChangeToState:inInterruptionState];
}

static void STAudioSessionRouteChangedListener(void *inClientData, AudioSessionPropertyID inID, UInt32 inDataSize, const void *inData) {
    if (inID == kAudioSessionProperty_AudioRouteChange) {
        CFDictionaryRef routeChangeDictionary = inData;
        CFNumberRef routeChangeReasonRef = CFDictionaryGetValue(routeChangeDictionary, CFSTR(kAudioSession_AudioRouteChangeKey_Reason));
        SInt32 routeChangeReason;
        CFNumberGetValue(routeChangeReasonRef, kCFNumberSInt32Type, &routeChangeReason);
        if (routeChangeReason != kAudioSessionRouteChangeReason_CategoryChange && routeChangeReason != kAudioSessionRouteChangeReason_Override &&
            routeChangeReason != kAudioSessionRouteChangeReason_WakeFromSleep) {
            // TODO: AudioRouteChanged
            //                STAudioCenter * audioCenter = (__bridge STAudioCenter *) inClientData;
        }
    }
}
static void STAudioSessionOutputVolumeChangedListener(void *inClientData, AudioSessionPropertyID inID, UInt32 inDataSize, const void *inData) {
    STAudioCenter *audioCenter = (__bridge STAudioCenter *)inClientData;
    CGFloat volume = *(CGFloat *)inData;

    NSNotification *notification = [NSNotification notificationWithName:STAudioSessionOutputVolumeDidChangeNotification
                                                                 object:audioCenter
                                                               userInfo:@{
                                                                   STAudioSessionOutputVolumeNewValueKey : @(volume),
                                                                   STAudioSessionOutputVolumeOldValueKey : @(audioCenter->_previousVolume)
                                                               }];
    audioCenter->_previousVolume = volume;
    if ([NSThread isMainThread]) {
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{ [[NSNotificationCenter defaultCenter] postNotification:notification]; });
    }
}