//
//  STImageLoader.m
//  STKit
//
//  Created by SunJiangting on 13-10-29.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import "STImageLoader.h"
#import "UIKit+STKit.h"

#import <ImageIO/ImageIO.h>
#import "STHTTPNetwork.h"
#import "STImageCache.h"
#import "STHTTPOperation.h"

@interface STHTTPImageOperation : STHTTPOperation
@property (nonatomic, copy)NSString *URLString;
@property (nonatomic) BOOL  userCancelled;
@property (nonatomic, weak)STHTTPImageOperation *dependency;
@end

@implementation STHTTPImageOperation
@end

@interface STImageLoader () {
    dispatch_queue_t _cacheQueue;
}

@property(nonatomic, strong) NSOperationQueue *downloadQueue;
@property(nonatomic, strong) dispatch_queue_t  decodeQueue;
@property(nonatomic, strong) STHTTPNetwork    *network;
@property(nonatomic, weak) STHTTPImageOperation *previousOperation;

@end

@implementation STImageLoader {
}

static STImageLoader *_imageLoader;

+ (instancetype)imageLoader {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ _imageLoader = [[STImageLoader alloc] init]; });
    return _imageLoader;
}

- (instancetype)init {
    self = [super init];
    if (self) {

        STHTTPConfiguration *HTTPConfiguration = [[STHTTPConfiguration alloc] init];
        HTTPConfiguration.timeoutInterval = 15.0;
        HTTPConfiguration.decodeResponseData = NO;
        HTTPConfiguration.HTTPMethod = @"GET";
        HTTPConfiguration.cachePolicy = NSURLRequestReloadIgnoringCacheData;
        HTTPConfiguration.supportCachePolicy = NO;
        
        STNetworkConfiguration *configuration = [[STNetworkConfiguration alloc] init];
        configuration.HTTPConfiguration = HTTPConfiguration;
        self.network = [[STHTTPNetwork alloc] initWithConfiguration:configuration];
        
        self.downloadQueue = [[NSOperationQueue alloc] init];
        self.downloadQueue.maxConcurrentOperationCount = 6;
        self.downloadQueue.name = @"com.suen.network.ImageDownloadQueue";
        [self.network setValue:self.downloadQueue forVar:@"_networkQueue"];
        
        _decodeQueue = dispatch_queue_create("com.suen.network.ImageDecodeQueue", DISPATCH_QUEUE_CONCURRENT);
        self.network.callbackQueue = _decodeQueue;
        
        _cacheQueue = dispatch_queue_create("com.suen.network.cacheQueue", NULL);
        
        self.downloadOrder = STImageDownloadOrderForward;
        
    }
    return self;
}

- (NSInteger)loadImageWithURLString:(NSString *)URLString finishedHandler:(STImageLoaderHandler)finishedHandler {
    return [self loadImageWithURLString:URLString progressHandler:nil finishedHandler:finishedHandler];
}

- (NSInteger)loadImageWithURLString:(NSString *)URLString
                    progressHandler:(STImageProgressHandler)progressHandler
                    finishedHandler:(STImageLoaderHandler)finishedHandler {
    
    if ([STImageCache hasCachedImageForKey:URLString]) {
        dispatch_sync(_cacheQueue, ^{
            UIImage *cachedImage = [STImageCache cachedImageForKey:URLString];
            [self secureInvokeProgressHandlerOnMainThread:progressHandler withCompletion:1];
            [self secureInvokeFinishedHandlerOnMainThread:finishedHandler withImage:cachedImage URLString:URLString usingCache:YES error:nil];
        });
        return -1;
    } else {
        STHTTPImageOperation *operation = [STHTTPImageOperation operationWithURLString:URLString parameters:nil];
        operation.URLString = URLString;
        operation.progressHandler = ^(STHTTPOperation *operation, NSData *data, CGFloat completionPercent) {
            [self secureInvokeProgressHandlerOnMainThread:progressHandler withCompletion:completionPercent];
        };
        [self.network sendHTTPOperation:operation completionHandler:^(STHTTPOperation *operation, id response, NSError *error) {
            if (error) {
                [self secureInvokeFinishedHandlerOnMainThread:finishedHandler withImage:nil URLString:URLString usingCache:NO error:error];
            } else {
                UIImage *image = [UIImage imageWithSTData:response];
                dispatch_async(_cacheQueue, ^{ [STImageCache cacheImage:image forKey:URLString]; });
                [self secureInvokeFinishedHandlerOnMainThread:finishedHandler withImage:image URLString:URLString usingCache:NO error:nil];
            }
        }];
        NSString *accept = [NSString stringWithFormat:@"image/webp,image/*;q=0.8;scale=%f", [UIScreen mainScreen].scale];
        [operation setValue:accept forHTTPHeaderField:@"Accept"];
        if (self.downloadOrder == STImageDownloadOrderBackward) {
            [self.previousOperation addDependency:operation];
            self.previousOperation.dependency = operation;
        }
        self.previousOperation = operation;
        return operation.identifier;
    }
}

- (void)cancelLoadImageWithURLString:(NSString *)URLString {
    NSArray *operations = [self.downloadQueue.operations copy];
    [operations enumerateObjectsUsingBlock:^(STHTTPOperation *obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[STHTTPImageOperation class]] && !((STHTTPImageOperation *)obj).userCancelled) {
            STHTTPImageOperation *operation = (STHTTPImageOperation *)obj;
            if ([operation.URLString isEqualToString:URLString]) {
                [self.network cancelHTTPOperation:operation];
                operation.userCancelled = YES;
            }
        }
    }];
}

- (void)cancelLoadImageWithIdentifier:(NSInteger)identifier {
    NSArray *operations = [self.downloadQueue.operations copy];
    [operations enumerateObjectsUsingBlock:^(STHTTPOperation *obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[STHTTPImageOperation class]] && !((STHTTPImageOperation *)obj).userCancelled) {
            STHTTPImageOperation *operation = (STHTTPImageOperation *)obj;
            if (identifier == obj.identifier) {
                [self.network cancelHTTPOperation:operation];
                operation.userCancelled = YES;
            }
        }
    }];
}

- (void)secureInvokeProgressHandlerOnMainThread:(STImageProgressHandler)handler withCompletion:(CGFloat)completion {
    if (!handler) {
        return;
    }
    if ([NSThread isMainThread]) {
        handler(completion);
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{ handler(completion); });
    }
}

- (void)secureInvokeFinishedHandlerOnMainThread:(STImageLoaderHandler)handler
                                      withImage:(UIImage *)response
                                      URLString:(NSString *)URLString
                                     usingCache:(BOOL)usingCache
                                          error:(NSError *)error {
    if (!handler) {
        return;
    }
    if ([NSThread isMainThread]) {
        handler(response, URLString, usingCache, error);
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(response, URLString, usingCache, error);
        });
    }
}

@end

