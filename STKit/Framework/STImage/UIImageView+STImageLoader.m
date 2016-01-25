//
//  UIImageView+STImageLoader.m
//  STKit
//
//  Created by SunJiangting on 13-11-26.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import "UIImageView+STImageLoader.h"

#import "STImageLoader.h"
#import "STHTTPOperation.h"
#import "STHTTPNetwork.h"
#import "STImageCache.h"
#import <objc/runtime.h>

@implementation UIImageView (STImageLoader)

NSString *const STImageRequestURLStringKey = @"STImageRequestURLStringKey";
- (void)setImageRequestURLString:(NSString *)URLString {
    objc_setAssociatedObject(self, (__bridge const void *)(STImageRequestURLStringKey), [URLString copy], OBJC_ASSOCIATION_RETAIN);
}

- (NSString *)imageRequestURLString {
    return objc_getAssociatedObject(self, (__bridge const void *)(STImageRequestURLStringKey));
}

NSString *const STImageRequestIdentifierKey = @"STImageRequestIdentifierKey";
- (void)setImageRequestIdentifier:(NSInteger)identifier {
    objc_setAssociatedObject(self, (__bridge const void *)(STImageRequestIdentifierKey), @(identifier), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSInteger)imageRequestIdentifier {
     NSNumber *number = objc_getAssociatedObject(self, (__bridge const void *)(STImageRequestIdentifierKey));
    return number.integerValue;
}

NSString *const STImageStateKey = @"STImageStateKey";
- (void)st_setState:(STImageState)state {
    objc_setAssociatedObject(self, (__bridge const void *)(STImageStateKey), @(state), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (STImageState)st_state {
    NSNumber *number = objc_getAssociatedObject(self, (__bridge const void *)(STImageStateKey));
    return (STImageState)[number integerValue];
}

NSString *const STPlaceholderImageKey = @"STPlaceholderImageKey";
- (void)st_setPlaceholderImage:(UIImage *)placeholderImage {
    objc_setAssociatedObject(self, (__bridge const void *)(STPlaceholderImageKey), placeholderImage, OBJC_ASSOCIATION_RETAIN);
}

- (UIImage *)st_placeholderImage {
    return objc_getAssociatedObject(self, (__bridge const void *)(STPlaceholderImageKey));
}

- (BOOL)st_isFinished {
    return self.st_state == STImageStateDownloadFinished;
}

- (void)st_setImageWithURLString:(NSString *)URLString {
    [self st_setImageWithURLString:URLString finishedHandler:nil];
}

- (void)st_setImageWithURLString:(NSString *)URLString finishedHandler:(STImageLoaderHandler)finishedHandler {
    [self st_setImageWithURLString:URLString progressHandler:nil finishedHandler:finishedHandler];
}

- (void)st_setImageWithURLString:(NSString *)URLString
                 progressHandler:(STImageProgressHandler)progressHandler
                 finishedHandler:(STImageLoaderHandler)finishedHandler {
    if ([[self imageRequestURLString] isEqualToString:URLString] &&
        (self.st_state == STImageStateDownloading || (self.st_state == STImageStateDownloadFinished && self.image)) && [STImageCache hasCachedImageForKey:URLString]) {
        return;
    }
    self.image = self.st_placeholderImage;
    [[STImageLoader imageLoader] cancelLoadImageWithIdentifier:self.imageRequestIdentifier];
    [self setImageRequestURLString:URLString];
    [self st_setState:STImageStateDownloading];
    __weak UIImageView *weakSelf = self;
    self.imageRequestIdentifier = [[STImageLoader imageLoader] loadImageWithURLString:URLString
                                        progressHandler:progressHandler
                                        finishedHandler:^(UIImage *image, NSString *_URLString, BOOL usingCache, NSError *error) {
                                            if (![_URLString isEqualToString:[weakSelf imageRequestURLString]]) {
                                                //            有一些下载没有取消成功，已经进入队列了，则不回调，以后一次为准
                                                return;
                                            }
                                            if (!error) {
                                                [self st_setState:STImageStateDownloadFinished];
                                                weakSelf.image = image;
                                            } else if (error.code != STHTTPNetworkErrorCodeUserCancelled && error.code != 0) {
                                                [self st_setState:STImageStateDownloadFailed];
                                                weakSelf.image = weakSelf.st_placeholderImage;
                                            }
                                            // cancel 的不回调
                                            if (!error || error.code != STHTTPNetworkErrorCodeUserCancelled) {
                                                if (finishedHandler) {
                                                    finishedHandler(image, _URLString, usingCache, error);
                                                }
                                            }
                                        }];
}

- (void)st_cancelLoadImageWithURLString:(NSString *)URLString {
    if (URLString.length == 0) {
        return;
    }
    [[STImageLoader imageLoader] cancelLoadImageWithURLString:URLString];
}

@end
