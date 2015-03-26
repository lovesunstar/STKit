//
//  STReachability.m
//  STKit
//
//  Created by SunJiangting on 13-12-7.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import "STReachability.h"
#import "Foundation+STKit.h"

#import <SystemConfiguration/SystemConfiguration.h>

static void STReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
    STReachability *reachability = (__bridge STReachability *)info;
    @autoreleasepool {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        SEL selector = NSSelectorFromString(@"reachabilityChanged:");
        if ([reachability respondsToSelector:selector]) {
            [reachability performSelector:selector withObject:@(flags)];
        }
#pragma clang diagnostic pop
    }
}

@interface STReachability () {
    SCNetworkReachabilityRef _reachabilityRef;
    dispatch_queue_t _reachabilityQueue;

    BOOL _notifying;
}
@property(nonatomic, strong) NSString *host;

@end

@implementation STReachability

+ (instancetype)reachabilityWithHost:(NSString *)host {
    return [[self alloc] initWithHost:host];
}

- (void)dealloc {
    [self stopNotification];
    if (_reachabilityRef) {
        CFRelease(_reachabilityRef);
    }
}

- (instancetype)initWithHost:(NSString *)host {
    self = [super init];
    if (self) {
        _reachabilityRef = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [host UTF8String]);
    }
    return self;
}

- (instancetype)init {
    return [self initWithHost:@"http://www.baidu.com"];
}

- (BOOL)isReachableWithFlags:(SCNetworkReachabilityFlags)flags {
    if (!(flags & kSCNetworkReachabilityFlagsReachable)) {
        return NO;
    }
    NSUInteger reachabilityFlags = (kSCNetworkReachabilityFlagsInterventionRequired | kSCNetworkReachabilityFlagsTransientConnection);
    if ((flags & reachabilityFlags) == reachabilityFlags) {
        return NO;
    }
    return YES;
}

- (STNetworkStatus)reachabilityStatus {
    if ([self reachable]) {
        if ([self reachWIFI]) {
            return STNetworkStatusReachWIFI;
        }
        if ([self reachWWAN]) {
            return STNetworkStatusReachWWAN;
        }
    }
    return STNetworkStatusReachNone;
}

- (SCNetworkReachabilityFlags)reachabilityFlags {
    SCNetworkReachabilityFlags flags = 0;
    BOOL getFlags = SCNetworkReachabilityGetFlags(_reachabilityRef, &flags);
    if (getFlags) {
        return flags;
    }
    return 0;
}

@end

@implementation STReachability (STNotification)

- (BOOL)startNotification {
    if (_notifying) {
        /// 重复调用开始
        return YES;
    }
    _notifying = YES;
    if (!_reachabilityQueue) {
        _reachabilityQueue = dispatch_queue_create("com.suen.reachability", DISPATCH_QUEUE_SERIAL);
    }
    SCNetworkReachabilityContext context = {0, NULL, NULL, NULL, NULL};
    context.info = (__bridge void *)self;
    BOOL setCallback = SCNetworkReachabilitySetCallback(_reachabilityRef, STReachabilityCallback, &context);
    if (!setCallback) {
        _reachabilityQueue = nil;
        _notifying = NO;
        return NO;
    }
    BOOL setDispatchQueue = SCNetworkReachabilitySetDispatchQueue(_reachabilityRef, _reachabilityQueue);
    if (!setDispatchQueue) {
        _reachabilityQueue = nil;
        SCNetworkReachabilitySetCallback(_reachabilityRef, NULL, NULL);
        _notifying = NO;
        return NO;
    }
    return YES;
}

- (void)stopNotification {
    SCNetworkReachabilitySetCallback(_reachabilityRef, NULL, NULL);
    _reachabilityQueue = nil;
    _notifying = NO;
}

- (void)reachabilityChanged:(SCNetworkReachabilityFlags)flags {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
    [userInfo setValue:self.host forKey:@"STReachabilityHost"];
    [userInfo setValue:@([self reachabilityStatus]) forKey:@"STReachabilityStatus"];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:STReachabilityDidChangedNotification object:self userInfo:userInfo];
}

@end

@implementation STReachability (STAccessor)

- (BOOL)reachable {
    SCNetworkReachabilityFlags flags;
    if (!SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {
        return NO;
    }
    return [self isReachableWithFlags:flags];
}

- (BOOL)reachWWAN {
    SCNetworkReachabilityFlags flags = 0;
    BOOL getFlags = SCNetworkReachabilityGetFlags(_reachabilityRef, &flags);
    return getFlags && (flags & kSCNetworkReachabilityFlagsIsWWAN);
}

- (BOOL)reachWIFI {
    SCNetworkReachabilityFlags flags = 0;
    BOOL getFlags = SCNetworkReachabilityGetFlags(_reachabilityRef, &flags);
    return getFlags && ((flags & kSCNetworkReachabilityFlagsReachable) && !(flags & kSCNetworkReachabilityFlagsIsWWAN));
}

@end

NSString *const STReachabilityDidChangedNotification = @"STReachabilityDidChangedNotification";