//
//  STNetwork.m
//  STKit
//
//  Created by SunJiangting on 13-11-13.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import "STNetwork.h"

#import "Foundation+STKit.h"
#import "STAuthorization.h"

#import <CommonCrypto/CommonCrypto.h>
#import <Accelerate/Accelerate.h>
#import "STNetworkOperation.h"

@implementation STPostDataItem

- (NSString *)description {
    NSMutableString *description = [NSMutableString string];
    if (self.name.length > 0) {
        [description appendFormat:@"%@", self.name];
    }
    if (self.path.length > 0) {
        [description appendFormat:@"%@", self.name];
    }
    return description;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[self class]]) {
        NO;
    }
    STPostDataItem *postDataItem = (STPostDataItem *)object;
    BOOL nameEquals = (postDataItem.name == self.name) || ([postDataItem.name isEqualToString:self.name]);
    if (!nameEquals) {
        return NO;
    }
    BOOL pathEquals = (postDataItem.path == self.path) || ([postDataItem.path isEqualToString:self.path]);
    if (!pathEquals) {
        return NO;
    }
    BOOL dataEquals = (postDataItem.data == self.data) || ([postDataItem.data isEqual:self.data]);
    if (!dataEquals) {
        return NO;
    }
    BOOL imageEquals = (postDataItem.image == self.image) || ([postDataItem.image isEqual:self.image]);
    return imageEquals;
}
@end

@interface STNetwork ()

@end

@implementation STNetwork
@synthesize networkQueue = _networkQueue, maxConcurrentRequestCount = _maxConcurrentRequestCount;

static NSThread *_standardNetworkThread;
+ (NSThread *)standardNetworkThread {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _standardNetworkThread = [[NSThread alloc] initWithTarget:self selector:@selector(startNetworkThread) object:nil];
        _standardNetworkThread.name = @"com.suen.STNetworkThread";
        [_standardNetworkThread start];
    });
    return _standardNetworkThread;
}

+ (void)startNetworkThread {
    // Should keep the runloop from exiting
    while (YES) {
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [STAuthorization standardAuthorization];
        self.automaticallyMergeRequest = YES;
        self.timeoutInterval = STRequestTimeoutInterval;
        _maxConcurrentRequestCount = 6;
    }
    return self;
}

- (STNetworkOperation *)sendAsynchronousRequestWithURLString:(NSString *)URLString
                                                  HTTPMethod:(NSString *)HTTPMethod
                                                  parameters:(NSDictionary *)parameters
                                             responseHandler:(STNetworkResponseHandler)responseHandler
                                             progressHandler:(STNetworkProgressHandler)progressHandler
                                             finishedHandler:(STNetworkFinishedHandler)finishedHandler {
    @synchronized(self) {
        __block STNetworkOperation *operation;
        if (self.automaticallyMergeRequest) {
            [self.networkQueue.operations enumerateObjectsUsingBlock:^(STNetworkOperation *opt, NSUInteger idx, BOOL *stop) {
                if ([opt isKindOfClass:[STNetworkOperation class]]) {
                    if ([opt isEqualWithURLString:URLString HTTPMethod:HTTPMethod parameters:parameters] && ![opt isCancelled] && ![opt isFinished]) {
                        operation = opt;
                        *stop = YES;
                    }
                }
            }];
        }
        if (!operation) {
            operation = [[STNetworkOperation alloc] initWithURLString:URLString parameters:parameters HTTPMethod:HTTPMethod];
            operation.timeoutInterval = self.timeoutInterval;
            [self.networkQueue addOperation:operation];
        }

        [operation addResponseHandler:responseHandler];
        [operation addProgressHanlder:progressHandler];
        [operation addFinishedHandler:finishedHandler];
        return operation;
    }
}

- (void)cancelAsynchronousRequestWithURLString:(NSString *)URLString HTTPMethod:(NSString *)HTTPMethod parameters:(NSDictionary *)parameters {
    @synchronized(self) {
        __block STNetworkOperation *operation = nil;
        [self.networkQueue.operations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[STNetworkOperation class]]) {
                STNetworkOperation *opt = (STNetworkOperation *)obj;
                if ([opt isEqualWithURLString:URLString HTTPMethod:HTTPMethod parameters:parameters]) {
                    operation = opt;
                    *stop = YES;
                }
            }
        }];
        [self cancelOperationIfNeeded:operation];
    }
}

- (void)cancelOperationIfNeeded:(STNetworkOperation *)operation {
    BOOL willBeCancelled = NO;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL selector = NSSelectorFromString(@"__willBeCancelled");
    if ([operation respondsToSelector:selector]) {
        willBeCancelled = [[operation performSelector:selector] boolValue];
    }
#pragma clang diagnostic pop
    BOOL statusCancel = (willBeCancelled || [operation isCancelled] || [operation isFinished]);
    if ([self canCancelNetworkOperation:operation] && !statusCancel) {
        [operation cancel];
    }
}

- (void)cancelAsynchronousRequestWithIdentifier:(NSInteger)identifier {
    @synchronized(self) {
        __block STNetworkOperation *operation = nil;
        [self.networkQueue.operations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[STNetworkOperation class]]) {
                STNetworkOperation *opt = (STNetworkOperation *)obj;
                if (opt.identifier == identifier && identifier != 0) {
                    operation = opt;
                    *stop = YES;
                }
            }
        }];
        [self cancelOperationIfNeeded:operation];
    }
}

- (BOOL)canCancelNetworkOperation:(STNetworkOperation *)operation {
    if (!operation) {
        return NO;
    }
    NSArray *responseHandlers = [operation valueForVar:@"_responseHandlerArray"];
    NSArray *progressHandlers = [operation valueForVar:@"_progressHandlerArray"];
    NSArray *finishedHandlers = [operation valueForVar:@"_finishedHandlerArray"];
    return (finishedHandlers.count <= 1 && responseHandlers.count <= 1 && progressHandlers.count <= 1);
}

- (NSOperationQueue *)networkQueue {
    if (!_networkQueue) {
        _networkQueue = [[NSOperationQueue alloc] init];
        _networkQueue.maxConcurrentOperationCount = (_maxConcurrentRequestCount > 0) ? _maxConcurrentRequestCount:6;
        _networkQueue.name = @"com.suen.network.DefaultQueue";
    }
    return _networkQueue;
}

- (void)setMaxConcurrentRequestCount:(NSInteger)maxConcurrentRequestCount {
    _networkQueue.maxConcurrentOperationCount=  maxConcurrentRequestCount;
    _maxConcurrentRequestCount = maxConcurrentRequestCount;
}

- (NSInteger)maxConcurrentRequestCount {
    return _networkQueue.maxConcurrentOperationCount;
}

@end

@implementation STNetwork (STSynchronousRequest)

- (NSData *)sendSynchronousRequestWithURLString:(NSString *)URLString
                                     HTTPMethod:(NSString *)HTTPMethod
                                     parameters:(NSDictionary *)parameters
                                          error:(NSError **)error {
    return [self sendSynchronousRequestWithURLString:URLString HTTPMethod:HTTPMethod parameters:parameters response:nil error:error];
}

- (NSData *)sendSynchronousRequestWithURLString:(NSString *)URLString
                                     HTTPMethod:(NSString *)HTTPMethod
                                     parameters:(NSDictionary *)parameters
                                       response:(NSURLResponse **)response
                                          error:(NSError **)error {
    STNetworkOperation *operation = [[STNetworkOperation alloc] initWithURLString:URLString parameters:parameters HTTPMethod:HTTPMethod];
    [operation prepareToRequest];
    return [NSURLConnection sendSynchronousRequest:operation.URLRequest returningResponse:response error:error];
}

@end

@implementation NSDictionary (STNetwork)
- (NSString *)componentsJoinedUsingURLEncode {
    NSMutableString *mutableString = [NSMutableString string];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            [mutableString appendFormat:@"%@=%@&", [key stringByURLEncoded], [obj stringByURLEncoded]];
        } else {
            [mutableString appendFormat:@"%@=%@&", [key stringByURLEncoded], obj];
        }
    }];
    if (mutableString.length > 0) {
        [mutableString deleteCharactersInRange:NSMakeRange(mutableString.length - 1, 1)];
    }
    return [mutableString copy];
}

@end

NSTimeInterval const STRequestTimeoutInterval = 60;
