//
//  STAlbumManager.m
//  STKit
//
//  Created by SunJiangting on 14-9-28.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STAlbumManager.h"
#import <UIKit/UIKit.h>

void STImageWriteToPhotosAlbum(UIImage *image, NSString *album, STAlbumSaveHandler completionHandler) {
    [[STAlbumManager sharedManager] saveImage:image toAlbum:album completionHandler:completionHandler];
}

@interface STAlbumManager ()

@property(nonatomic, strong) ALAssetsLibrary *assetsLibrary;

@end

@implementation STAlbumManager

static STAlbumManager *_sharedManager;
+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ _sharedManager = [[self alloc] init]; });
    return _sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (ALAssetsLibrary *)assetsLibrary {
    if (!_assetsLibrary) {
        _assetsLibrary = [[ALAssetsLibrary alloc] init];
    }
    return _assetsLibrary;
}

- (void)saveImage:(UIImage *)image toAlbum:(NSString *)album completionHandler:(STAlbumSaveHandler)completionHandler {
    [self.assetsLibrary writeImage:image
                           toAlbum:album
                 completionHandler:^(UIImage *image, NSError *error) {
                     if (completionHandler) {
                         completionHandler(image, error);
                     }
                     /// 注意，这里每次都置空是因为期间如果操作相册了，下次保存之前希望能取到最新状态。
                     self.assetsLibrary = nil;
                 }];
}
@end

@implementation ALAssetsLibrary (STAssetsLibrary)

- (void)writeImage:(UIImage *)image toAlbum:(NSString *)album completionHandler:(STAlbumSaveHandler)completionHandler {
    [self writeImageToSavedPhotosAlbum:image.CGImage
                           orientation:(ALAssetOrientation)image.imageOrientation
                       completionBlock:^(NSURL *assetURL, NSError *error) {
                           if (error) {
                               if (completionHandler) {
                                   completionHandler(image, error);
                               }
                           } else {
                               [self addAssetURL:assetURL
                                             toAlbum:album
                                   completionHandler:^(NSError *error) {
                                       if (completionHandler) {
                                           completionHandler(image, error);
                                       }
                                   }];
                           }
                       }];
}

- (void)addAssetURL:(NSURL *)assetURL toAlbum:(NSString *)album completionHandler:(ALAssetsLibraryAccessFailureBlock)completionHandler {
    void (^assetForURLBlock)(NSURL *, ALAssetsGroup *) = ^(NSURL *URL, ALAssetsGroup *group) {
        [self assetForURL:assetURL
            resultBlock:^(ALAsset *asset) {
                [group addAsset:asset];
                completionHandler(nil);
            }
            failureBlock:^(NSError *error) { completionHandler(error); }];
    };
    __block ALAssetsGroup *group;
    [self enumerateGroupsWithTypes:ALAssetsGroupAlbum
                        usingBlock:^(ALAssetsGroup *_group, BOOL *stop) {
                            if ([album isEqualToString:[_group valueForProperty:ALAssetsGroupPropertyName]]) {
                                group = _group;
                            }
                            if (!_group) {
                                /// 循环结束
                                if (group) {
                                    assetForURLBlock(assetURL, group);
                                } else {
                                    [self addAssetsGroupAlbumWithName:album
                                                          resultBlock:^(ALAssetsGroup *group) { assetForURLBlock(assetURL, group); }
                                                         failureBlock:completionHandler];
                                }
                            }
                        }
                      failureBlock:completionHandler];
}

@end