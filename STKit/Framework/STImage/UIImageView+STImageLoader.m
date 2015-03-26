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
- (void)setState:(STImageState)state {
    objc_setAssociatedObject(self, (__bridge const void *)(STImageStateKey), @(state), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (STImageState)state {
    NSNumber *number = objc_getAssociatedObject(self, (__bridge const void *)(STImageStateKey));
    return (STImageState)[number integerValue];
}

NSString *const STPlaceholderImageKey = @"STPlaceholderImageKey";
- (void)setPlaceholderImage:(UIImage *)placeholderImage {
    objc_setAssociatedObject(self, (__bridge const void *)(STPlaceholderImageKey), placeholderImage, OBJC_ASSOCIATION_RETAIN);
}

- (UIImage *)placeholderImage {
    return objc_getAssociatedObject(self, (__bridge const void *)(STPlaceholderImageKey));
}

- (BOOL)isFinished {
    return self.state == STImageStateDownloadFinished;
}

- (void)setImageWithURLString:(NSString *)URLString {
    [self setImageWithURLString:URLString finishedHandler:nil];
}

- (void)setImageWithURLString:(NSString *)URLString finishedHandler:(STImageLoaderHandler)finishedHandler {
    [self setImageWithURLString:URLString progressHandler:nil finishedHandler:finishedHandler];
}

- (void)setImageWithURLString:(NSString *)URLString
              progressHandler:(STImageProgressHandler)progressHandler
              finishedHandler:(STImageLoaderHandler)finishedHandler {
    if ([[self imageRequestURLString] isEqualToString:URLString] &&
        (self.state == STImageStateDownloading || (self.state == STImageStateDownloadFinished && self.image))) {
        return;
    }
    self.image = self.placeholderImage;
    [[STImageLoader imageLoader] cancelLoadImageWithIdentifier:self.imageRequestIdentifier];
    [self setImageRequestURLString:URLString];
    self.state = STImageStateDownloading;
    __weak UIImageView *weakSelf = self;
    self.imageRequestIdentifier = [[STImageLoader imageLoader] loadImageWithURLString:URLString
                                        progressHandler:progressHandler
                                        finishedHandler:^(UIImage *image, NSString *_URLString, BOOL usingCache, NSError *error) {
                                            if (![_URLString isEqualToString:[weakSelf imageRequestURLString]]) {
                                                //            有一些下载没有取消成功，已经进入队列了，则不回调，以后一次为准
                                                return;
                                            }
                                            if (!error) {
                                                weakSelf.state = STImageStateDownloadFinished;
                                                weakSelf.image = image;
                                            } else if (error.code != STNetworkErrorCodeUserCancelled && error.code != 0) {
                                                weakSelf.state = STImageStateDownloadFailed;
                                                weakSelf.image = weakSelf.placeholderImage;
                                            }
                                            // cancel 的不回调
                                            if (!error || error.code != STNetworkErrorCodeUserCancelled) {
                                                if (finishedHandler) {
                                                    finishedHandler(image, _URLString, usingCache, error);
                                                }
                                            }
                                        }];
}

- (void)cancelLoadImageWithURLString:(NSString *)URLString {
    if (URLString.length == 0) {
        return;
    }
    [[STImageLoader imageLoader] cancelLoadImageWithURLString:URLString];
}

@end
