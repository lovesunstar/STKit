//
//  STImage.m
//  STKit
//
//  Created by SunJiangting on 14-11-8.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STImage.h"
#import "UIKit+STKit.h"
#import <ImageIO/ImageIO.h>

@interface STImage () {
    NSData             *_imageData;
    CGImageSourceRef    _imageSource;
}

@property (nonatomic, assign, getter=isGIFImage) BOOL  GIFImage;
@property (nonatomic, assign) NSInteger numberOfImages;


@end

@implementation STImage

- (void)dealloc {
    if (_imageSource) {
        CFRelease(_imageSource);
    }
}
- (instancetype)initWithData:(NSData *)data scale:(CGFloat)scale {
    STImageDataType imageType = [data imageType];
    if (imageType != STImageDataTypeGIF) {
        return [super initWithData:data scale:scale];
    }
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    NSInteger imageCount = CGImageSourceGetCount(imageSource);
    CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    self = [super initWithCGImage:image scale:scale orientation:UIImageOrientationUp];
    if (image) {
        CFRelease(image);
    }
    if (self) {
        _imageData = data;
        _imageSource = imageSource;
        self.numberOfImages = imageCount;
        self.GIFImage = YES;
    } else {
        CFRelease(imageSource);
    }
    return self;
}

- (instancetype)initWithContentsOfFile:(NSString *)path {
    NSData *data = [NSData dataWithContentsOfFile:path];
    STImageDataType imageType = [data imageType];
    if (imageType != STImageDataTypeGIF) {
        return [super initWithContentsOfFile:path];
    }
    return [self initWithData:data scale:[UIScreen mainScreen].scale];
}

- (UIImage *) imageAtIndex:(NSInteger)index duration:(NSTimeInterval *)duration {
    if (index >= self.numberOfImages) {
        if (duration) {
            *duration = 0.0;
        }
        return nil;
    }
    if (!self.isGIFImage) {
        return self;
    }
    if (!_imageData) {
        return nil;
    }
    CGImageRef image = CGImageSourceCreateImageAtIndex(_imageSource, index, NULL);
    UIImage *result = [UIImage imageWithCGImage:image scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
    
    if (duration) {
        *duration = [self _frameDurationAtIndex:index];
    }
    
    CGImageRelease(image);
    return result;
}

- (NSTimeInterval)_frameDurationAtIndex:(NSInteger)index {
    NSTimeInterval frameDuration = 0.1f;
    NSDictionary *frameProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(_imageSource, index, nil);
    NSDictionary *GIFProperties = frameProperties[(NSString *)kCGImagePropertyGIFDictionary];
    NSNumber *delayTimeUnclampedProp = GIFProperties[(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (delayTimeUnclampedProp) {
        frameDuration = [delayTimeUnclampedProp floatValue];
    } else {
        NSNumber *delayTimeProp = GIFProperties[(NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTimeProp) {
            frameDuration = [delayTimeProp floatValue];
        }
    }
    
    if (frameDuration < 0.011f) {
        frameDuration = 0.100f;
    }
    return frameDuration;
}

@end

@interface UIImage (STGIFImage)

@end

@implementation UIImage (STGIFImage)

- (UIImage *) imageAtIndex:(NSInteger)index duration:(NSTimeInterval *)duration {
    if (duration) {
        *duration = 0.0;
    }
    return nil;
}

- (NSInteger)numberOfImages {
    return 1;
}

- (BOOL)isGIFImage {
    return NO;
}

@end