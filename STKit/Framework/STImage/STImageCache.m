//
//  STImageCache.m
//  STKit
//
//  Created by SunJiangting on 13-12-17.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import "STImageCache.h"
#import "Foundation+STKit.h"

NSInteger const STMaximumCacheAge = 3600*24*7;

NSString *STImageCacheDirectory() {
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = cachePaths[0];
    NSString *cacheDirectory = [cachePath stringByAppendingPathComponent:@"STImageCache"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cacheDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    }

    return cacheDirectory;
}

extern void STImageCacheResetContextIdentifier(STIdentifier _identifier);

static NSCache *_imageCache;

@interface STImageContext : NSObject

@property(nonatomic, assign, readonly) STIdentifier identifier;

- (instancetype)initWithIdentifier:(STIdentifier)identifier;

@property(nonatomic, strong) UIImage *image;

- (void)saveKey:(NSString *)key forIdentifier:(STIdentifier)identifier;
- (STIdentifier)currentIdentifier;

@end

@implementation STImageContext {
    STIdentifier _currentIdentifier;
  @public
    NSMutableDictionary *_dictionary;
}

- (void)dealloc {
    [_dictionary removeAllObjects];
}

- (instancetype)initWithIdentifier:(STIdentifier)identifier {
    self = [super init];
    if (self) {
        _identifier = identifier;
        _currentIdentifier = identifier;
        _dictionary = [NSMutableDictionary dictionaryWithCapacity:2];
    }
    return self;
}

- (STIdentifier)currentIdentifier {
    @synchronized(self) {
        STIdentifier temp = _currentIdentifier;
        _currentIdentifier++;
        return temp;
    }
}

- (void)saveKey:(NSString *)key forIdentifier:(STIdentifier)identifier {
    @synchronized(self) {
        if (identifier == 0) {
            [_dictionary removeObjectForKey:key];
        } else {
            [_dictionary setValue:@(identifier) forKey:key];
        }
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@:%lld", self.class, self.identifier];
}

@end

@interface STImageCache ()

@property(nonatomic, strong) NSMutableArray *imageContexts;
@property(nonatomic, strong) dispatch_queue_t ioQueue;
@property(nonatomic, strong) NSCache        *memoryCache;

@end

@implementation STImageCache

static STImageCache *_sharedCache;
+ (instancetype)sharedImageCache {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedCache = [[self alloc] init];
    });
    return _sharedCache;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _imageContexts = [NSMutableArray arrayWithCapacity:5];
        _ioQueue = dispatch_queue_create("com.suen.image.cacheQueue", DISPATCH_QUEUE_SERIAL);
        _memoryCache = [[NSCache alloc] init];
        _memoryCache.name = @"STImageMemoryCache";
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMemoryWarning)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    @synchronized(self) {
        [self.memoryCache removeAllObjects];
    }
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    @synchronized(self) {
        [self.memoryCache removeAllObjects];
    }
    
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    /// 删除7天以前的图片
    [self removeCachedImagesBeforeDate:[[NSDate date] dateByAddingTimeInterval:-STMaximumCacheAge] completionHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
}

+ (void)pushImageContext:(STIdentifier)contextID {
    [[self sharedImageCache] pushImageContext:contextID];
}

- (void)pushImageContext:(STIdentifier)contextID {
    __block STImageContext *imageContext;
    [self.imageContexts enumerateObjectsUsingBlock:^(STImageContext *obj, NSUInteger idx, BOOL *stop) {
        if (contextID == obj.identifier) {
            imageContext = obj;
            *stop = YES;
        }
    }];
    if (imageContext) {
        [self.imageContexts removeObject:imageContext];
    } else {
        imageContext = [[STImageContext alloc] initWithIdentifier:contextID];
    }
    [self.imageContexts addObject:imageContext];
}

+ (void)popImageContext:(STIdentifier)contextID {
    [[self sharedImageCache] popImageContext:contextID];
}

- (void)popImageContext:(STIdentifier)contextID {
    __block STImageContext *imageContext;
    [self.imageContexts enumerateObjectsUsingBlock:^(STImageContext *obj, NSUInteger idx, BOOL *stop) {
        if (contextID == obj.identifier) {
            imageContext = obj;
            *stop = YES;
        }
    }];
    NSCache *memoryCache = [self memoryCache];
    [imageContext->_dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) { [memoryCache removeObjectForKey:key]; }];
    [self.imageContexts removeObject:imageContext];
}

+ (void)cacheImage:(UIImage *)image forKey:(NSString *)key {
    [[self sharedImageCache] cacheImage:image forKey:key];
}

- (void)cacheImage:(UIImage *)image forKey:(NSString *)key {
    if (key.length == 0) {
        return;
    }
    if (!image) {
        [self removeCacheImageForKey:key];
        return;
    }
    @synchronized(self) {
        STIdentifier identifier = [[[self imageContexts] lastObject] currentIdentifier];
        @synchronized(self) {
            [self.memoryCache setObject:image forKey:key];
        }
        [[self.imageContexts lastObject] saveKey:key forIdentifier:identifier];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager createFileAtPath:[self cachedPathForKey:key] contents:UIImageJPEGRepresentation(image, 1.0) attributes:nil];
    }
}

+ (void)removeCacheImageForKey:(NSString *)key {
    [[self sharedImageCache] removeCacheImageForKey:key];
}

- (void)removeCacheImageForKey:(NSString *)key {
    @synchronized(self) {
        @synchronized(self) {
            [self.memoryCache removeObjectForKey:key];
        }
        [[self.imageContexts lastObject] saveKey:key forIdentifier:0];
        if ([self hasCachedImageForKey:key]) {
            NSString *path = [self cachedPathForKey:key];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            BOOL exist = [fileManager fileExistsAtPath:path isDirectory:NULL];
            if (exist) {
                [fileManager removeItemAtPath:path error:nil];
            }
        }
    }
}

+ (BOOL)hasCachedImageForKey:(NSString *)key {
    return [[self sharedImageCache] hasCachedImageForKey:key];
}

- (BOOL)hasCachedImageForKey:(NSString *)key {
    if (key.length == 0) {
        return NO;
    }
    @synchronized(self) {
        NSString *path = [self cachedPathForKey:key];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL directory;
        BOOL exist = [fileManager fileExistsAtPath:path isDirectory:&directory];
        return exist && (!directory);
    }
}

+ (UIImage *)cachedImageForKey:(NSString *)key {
    return [[self sharedImageCache] cachedImageForKey:key];
}

- (UIImage *)cachedImageForKey:(NSString *)key {
    if (key.length == 0) {
        return nil;
    }
    @synchronized(self) {
        @synchronized(self) {
            id cachedValue = [self.memoryCache objectForKey:key];
            if (cachedValue) {
                return cachedValue;
            }
        }
        NSString *path = [self cachedPathForKey:key];
        UIImage *image = [UIImage imageWithContentsOfFile:path];
        if (!image) {
            return nil;
        }
        if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
            CGFloat scale = 1.0;
            if (path.length >= 8) {
                NSRange range = [path rangeOfString:@"@2x." options:0 range:NSMakeRange(path.length - 8, 5)];
                if (range.location != NSNotFound) {
                    scale = 2.0;
                }
            }
            UIImage *scaledImage = [[UIImage alloc] initWithCGImage:image.CGImage scale:scale orientation:image.imageOrientation];
            image = scaledImage;
        }

        STIdentifier identifier = [[[self imageContexts] lastObject] currentIdentifier];
        @synchronized(self) {
            [self.memoryCache setObject:image forKey:key];
        }
        [[self.imageContexts lastObject] saveKey:key forIdentifier:identifier];
        return image;
    }
}

+ (void)removeMemoryCacheForKey:(NSString *)key {
    [[self sharedImageCache] removeMemoryCacheForKey:key];
}

- (void)removeMemoryCacheForKey:(NSString *)key {
    @synchronized(self) {
        [self.memoryCache removeObjectForKey:key];
    }
}

+ (BOOL)hasMemoryCacheForKey:(NSString *)key {
    return [[self sharedImageCache] hasMemoryCacheForKey:key];
}

- (BOOL)hasMemoryCacheForKey:(NSString *)key {
    @synchronized(self) {
        return !!([self.memoryCache objectForKey:key]);
    }
}

+ (void)cacheData:(NSData *)data forKey:(NSString *)key {
    if (key.length == 0) {
        return;
    }
    if (!data) {
        [self removeCacheImageForKey:key];
        return;
    }
    @synchronized(self) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager createFileAtPath:[self cachedPathForKey:key] contents:data attributes:nil];
    }
}

+ (NSData *)cachedDataForKey:(NSString *)key {
    if (key.length == 0) {
        return nil;
    }
    @synchronized(self) {
        NSString *path = [self cachedPathForKey:key];
        return [NSData dataWithContentsOfFile:path];
    }
}

+ (NSString *)cachedPathForKey:(NSString *)key {
    return [[self sharedImageCache] cachedPathForKey:key];
}

- (NSString *)cachedPathForKey:(NSString *)key {
    return [STImageCacheDirectory() stringByAppendingPathComponent:[key st_md5String]];
}

+ (unsigned long long)cacheSize {
    NSString *cacheDirectory = STImageCacheDirectory();
    unsigned long long result = 0;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *fileEnumerator = [fileManager enumeratorAtPath:cacheDirectory];
    for (NSString *fileName in fileEnumerator) {
        @autoreleasepool {
            NSString *filePath = [cacheDirectory stringByAppendingPathComponent:fileName];
            NSDictionary *attrs = [fileManager attributesOfItemAtPath:filePath error:nil];
            result += [attrs fileSize];
        }
    }
    return result;
}

+ (void)calculateCacheSizeWithCompletionHandler:(void(^)(CGFloat))completionHandler {
    [self calculateCacheSizeInQueue:nil completionHandler:completionHandler];
}

+ (void)calculateCacheSizeInQueue:(dispatch_queue_t)backgroundQueue completionHandler:(void(^)(CGFloat))completionHandler {
    if (!backgroundQueue) {
        backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    }
    dispatch_async(backgroundQueue, ^{
        NSString *cacheDirectory = STImageCacheDirectory();
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        CGFloat result = .0f;
        NSUInteger fileCount = 0;
        NSDirectoryEnumerator *fileEnumerator = [fileManager enumeratorAtPath:cacheDirectory];
        for (NSString *fileName in fileEnumerator) {
            @autoreleasepool {
                NSString *filePath = [cacheDirectory stringByAppendingPathComponent:fileName];
                NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
                result += [attrs fileSize];
                fileCount += 1;
            }
        }
        if (completionHandler) {
            completionHandler(result);
        }
    });
}


+ (void)removeCachedImagesBeforeDate:(NSDate *)date
                   completionHandler:(void(^)())completionHandler {
    [[self sharedImageCache] removeCachedImagesBeforeDate:date completionHandler:completionHandler];
}

- (void)removeCachedImagesBeforeDate:(NSDate *)date
                   completionHandler:(void(^)())completionHandler {
    dispatch_async(self.ioQueue, ^{
        NSURL *diskCacheURL = [NSURL fileURLWithPath:STImageCacheDirectory() isDirectory:YES];
        NSArray *resourceKeys = @[NSURLIsDirectoryKey, NSURLContentModificationDateKey, NSURLTotalFileAllocatedSizeKey];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSDirectoryEnumerator *fileEnumerator = [fileManager enumeratorAtURL:diskCacheURL
                                                   includingPropertiesForKeys:resourceKeys
                                                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                 errorHandler:NULL];
        NSMutableArray *urlsToDelete = [[NSMutableArray alloc] init];
        for (NSURL *fileURL in fileEnumerator) {
            NSDictionary *resourceValues = [fileURL resourceValuesForKeys:resourceKeys error:NULL];
            if ([resourceValues[NSURLIsDirectoryKey] boolValue]) {
                continue;
            }
            // Remove files that are older than the expiration date;
            NSDate *modificationDate = resourceValues[NSURLContentModificationDateKey];
            if ([[modificationDate laterDate:date] isEqualToDate:date]) {
                [urlsToDelete addObject:fileURL];
                continue;
            }
        }
        
        for (NSURL *fileURL in urlsToDelete) {
            [fileManager removeItemAtURL:fileURL error:nil];
        }
        if (completionHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler();
            });
        }
    });
}

@end

static STIdentifier identifier = 1000000000;

static NSMutableArray *_reuseIdentifiers;

NSMutableArray *STReuseIdentifiers() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ _reuseIdentifiers = [NSMutableArray arrayWithCapacity:2]; });
    return _reuseIdentifiers;
}

STIdentifier STImageCacheBeginContext() {
    @synchronized([STImageCache class]) {
        STIdentifier _identifier = [[STReuseIdentifiers() firstObject] longLongValue];
        if (_identifier <= 10000) {
            identifier += 1000000;
            _identifier = identifier;
        } else {
            [STReuseIdentifiers() removeObjectAtIndex:0];
        }
        return _identifier;
    }
}

void STImageCachePushContext(STIdentifier contextId) { [STImageCache pushImageContext:contextId]; }

void STImageCachePopContext(STIdentifier contextId) {
    [STImageCache popImageContext:contextId];
    [STReuseIdentifiers() addObject:@(contextId)];
}
