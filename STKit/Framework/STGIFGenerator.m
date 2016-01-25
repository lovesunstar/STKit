//
//  STGIFGenerator.m
//  STKit
//
//  Created by SunJiangting on 14-11-8.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STGIFGenerator.h"
#import "Foundation+STKit.h"
#import "UIKit+STKit.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation STGIFProperty
static STGIFProperty *_defaultProperty;
+ (STGIFProperty *)defaultGIFProperty {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultProperty = [[STGIFProperty alloc] init];
        _defaultProperty.hasGlobalColorMap = YES;
        _defaultProperty.colorModel = STGIFPropertyColorModelRGB;
        _defaultProperty.depth = 8;
        _defaultProperty.loopCount = 0;
    });
    return _defaultProperty;
}

- (NSString *)colorModelString {
    CFStringRef colorModelString;
    switch (self.colorModel) {
        case STGIFPropertyColorModelCMYK:
            colorModelString = kCGImagePropertyColorModelCMYK;
            break;
        case STGIFPropertyColorModelGray:
            colorModelString = kCGImagePropertyColorModelGray;
            break;
        case STGIFPropertyColorModelLab:
            colorModelString = kCGImagePropertyColorModelLab;
            break;
        case STGIFPropertyColorModelRGB:
        default:
            colorModelString = kCGImagePropertyColorModelRGB;
            break;
    }
    return (__bridge NSString *)(colorModelString);
}

@end

@interface STGIFGenerator () {
    dispatch_queue_t _privateQueue;
}
@property (nonatomic, assign) STGIFProperty     *property;
@property (nonatomic, strong) NSMutableArray    *images;
@property (nonatomic, strong) NSMutableArray    *durations;
@property (nonatomic, weak)   NSRunLoop         *callbackRunLoop;

@property (nonatomic, strong) void(^completionHandler)(NSString *);

@end

@implementation STGIFGenerator

- (instancetype)initWithProperty:(STGIFProperty *)property {
    self = [super init];
    if (self) {
        self.images = [NSMutableArray arrayWithCapacity:5];
        self.durations = [NSMutableArray arrayWithCapacity:5];
        self.property = property;
        _privateQueue = dispatch_queue_create("com.suen.stkit.GIFGenerator", NULL);
    }
    return self;
}

- (instancetype)init {
    return [self initWithProperty:[STGIFProperty defaultGIFProperty]];
}

- (void)appendImage:(UIImage *)image duration:(NSTimeInterval)duration {
    if (image) {
        [self.images addObject:image];
        if (duration < 0.01) {
            duration = 0.01;
        }
        [self.durations addObject:@(duration)];
    }
}

- (void)startGeneratorWithPath:(NSString *)path
             completionHandler:(void (^)(NSString *))completionHandler {
    self.callbackRunLoop = [NSRunLoop currentRunLoop];
    self.completionHandler = completionHandler;
    if (path.length == 0) {
        NSString *name = [NSString stringWithFormat:@"%lld.gif", (long long)[[NSDate date] timeIntervalSince1970]];
        path = [STLibiaryDirectory() stringByAppendingPathComponent:name];
    }
    NSArray *images = [self.images copy];
    NSArray *durations = [self.durations copy];
    dispatch_async(_privateQueue, ^{
        CFURLRef URLRef = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,(CFStringRef)path,kCFURLPOSIXPathStyle, NO);
        CGImageDestinationRef destination = CGImageDestinationCreateWithURL(URLRef, kUTTypeGIF, images.count, NULL);
        if (URLRef) {
            CFRelease(URLRef);
        }
        NSMutableDictionary *properities = [NSMutableDictionary dictionaryWithCapacity:4];
        [properities setValue:@(self.property.hasGlobalColorMap) forKey:(NSString *)kCGImagePropertyGIFHasGlobalColorMap];
        [properities setValue:@(self.property.depth) forKey:(NSString *)kCGImagePropertyDepth];
        [properities setValue:@(self.property.loopCount) forKey:(NSString *)kCGImagePropertyGIFLoopCount];
        [properities setValue:self.property.colorModelString forKey:(NSString *)kCGImagePropertyColorModel];
        CGImageDestinationSetProperties(destination, (CFDictionaryRef)properities);
        
        for (NSInteger idx = 0; idx < images.count; idx ++) {
            UIImage *image = images[idx];
            NSNumber *duration = durations[idx];
            NSDictionary *GIFProperties = @{(NSString *)kCGImagePropertyGIFDictionary:@{
                                                    (NSString *)kCGImagePropertyGIFDelayTime:duration,
                                                    (NSString *)kCGImagePropertyGIFUnclampedDelayTime:@(100)
                                                    }};
            if (image.CGImage) {
                UIImage *frameImage;
                if (self.preferredImageSize.width == 0 || self.preferredImageSize.height == 0) {
                    frameImage = image;
                } else {
                    frameImage = [image st_imageConstrainedToSize:self.preferredImageSize contentMode:UIViewContentModeScaleAspectFit];
                }
                CGImageDestinationAddImage(destination, frameImage.CGImage, (CFDictionaryRef)GIFProperties);
            }
        }
        BOOL success = CGImageDestinationFinalize(destination);
        CFRelease(destination);
        NSTimer *timer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(callback:) userInfo:@{@"STGIFSavedPath":path, @"STGIFSavedSuccess":@(success)} repeats:NO];
        [self.callbackRunLoop addTimer:timer forMode:NSRunLoopCommonModes];
    });
}

- (void)callback:(NSTimer *)timer {
    NSString *path = [timer.userInfo valueForKey:@"STGIFSavedPath"];
    if (self.completionHandler) {
        self.completionHandler(path);
    }
}

- (void)cancel {
    @synchronized(self) {
        self.completionHandler = nil;
    }
}

@end
