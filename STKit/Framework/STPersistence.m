//
//  STPersistence.m
//  STKit
//
//  Created by SunJiangting on 13-12-8.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import "STPersistence.h"

NSString *STPersistDocumentDirectory() {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *directory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *persistPath = [directory stringByAppendingPathComponent:@"STPreferences"];
    BOOL direct;
    BOOL exists = [manager fileExistsAtPath:persistPath isDirectory:&direct];
    if (!exists) {
        [manager createDirectoryAtPath:persistPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return persistPath;
}

NSString *STPersistLibiaryDirectory() {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *directory = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
    NSString *persistPath = [directory stringByAppendingPathComponent:@"STPreferences"];
    BOOL direct;
    BOOL exists = [manager fileExistsAtPath:persistPath isDirectory:&direct];
    if (!exists) {
        [manager createDirectoryAtPath:persistPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return persistPath;
}

NSString *STPersistCacheDirectory() {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *directory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    NSString *persistPath = [directory stringByAppendingPathComponent:@"STPreferences"];
    BOOL direct;
    BOOL exists = [manager fileExistsAtPath:persistPath isDirectory:&direct];
    if (!exists) {
        [manager createDirectoryAtPath:persistPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return persistPath;
}

NSString *STPersistTemporyDirectory() {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *persistPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"STPreferences"];
    BOOL direct;
    BOOL exists = [manager fileExistsAtPath:persistPath isDirectory:&direct];
    if (!exists) {
        [manager createDirectoryAtPath:persistPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return persistPath;
}


@interface STPersistence ()

@property(nonatomic, copy) NSString *cacheDirectory;

@end

@interface _STUserDefaults : STPersistence

@property(nonatomic, copy) NSString *filePath;
- (instancetype)initWithName:(NSString *)name;
- (void)resetPersistence;
@end


@implementation STPersistence

+ (BOOL)writeValue:(id)value forKey:(NSString *)key toFile:(NSString *)path {
    if (key.length == 0) {
        return NO;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (!value) {
        return [fileManager removeItemAtPath:path error:nil];
    }
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:2];
    [dictionary setValue:value forKey:@"data"];
    [dictionary setValue:key forKey:@"key"];
    return [dictionary writeToFile:path atomically:YES];
}

+ (id)valueForKey:(NSString *)key inFile:(NSString *)path {
    if (key.length == 0 || path.length == 0) {
        return nil;
    }
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    if ([dictionary[@"key"] isEqualToString:key]) {
        return dictionary[@"data"];
    }
    return nil;
}

- (instancetype)init {
    return [self initWithDirectory:STPersistenceDirectoryLibiary subpath:nil];
}

- (instancetype)initWithDirectory:(STPersistenceDirectory)directory subpath:(NSString *)subpath {
    self = [super init];
    if (self) {
        self.cacheDirectory =[self _persistPath:subpath inDirectory:directory];
        if (!self.cacheDirectory) {
            self = nil;
        }
    }
    return self;
}

- (NSString *)cachedPathForKey:(NSString *)key {
    return [self.cacheDirectory stringByAppendingPathComponent:key.md5String];
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if (key.length == 0) {
        return;
    }
    NSString *path = [self cachedPathForKey:key];
    [[self class] writeValue:value forKey:key toFile:path];
}

- (id)valueForKey:(NSString *)key {
    NSString *path = [self cachedPathForKey:key];
    return [[self class] valueForKey:key inFile:path];
}

- (NSString *)_persistPath:(NSString *)subpath inDirectory:(STPersistenceDirectory)directory {
    NSString *domain = nil;
    switch (directory) {
        case STPersistenceDirectoryDocument:
            domain = STPersistDocumentDirectory();
            break;
        case STPersistenceDirectoryLibiary:
            domain = STPersistLibiaryDirectory();
            break;
        case STPersistenceDirectoryTemporary:
            domain = STPersistTemporyDirectory();
            break;
        case STPersistenceDirectoryCache:
        default:
            domain = STPersistCacheDirectory();
            break;
    }
    if (subpath.length == 0) {
        return domain;
    }
    NSString *path = [domain stringByAppendingPathComponent:subpath];
    BOOL isDirectory = NO;
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    if (isExists) {
        if (!isDirectory) {
            return domain;
        }
        return path;
    }
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
    return path;
}

static _STUserDefaults *_userDefaults;
+ (instancetype)standardPersistence {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _userDefaults = [[_STUserDefaults alloc] init];
    });
    return _userDefaults;
}

+ (void)resetStandardPersistence {
    [_userDefaults performSelector:@selector(resetPersistence) withObjects:nil, nil];
}


static NSMutableDictionary *_persistences;
+ (instancetype)persistenceNamed:(NSString *)name {
    if (name.length == 0) {
        return [self standardPersistence];
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _persistences = [NSMutableDictionary dictionaryWithCapacity:1];
    });
    if (![_persistences valueForKey:name]) {
        @synchronized(_persistences) {
            _STUserDefaults *userDefaults = [[_STUserDefaults alloc] initWithName:name];
            if (![_persistences valueForKey:name]) {
                [_persistences setValue:userDefaults forKey:name];
            }
        }
    }
    return [_persistences valueForKey:name];
}

+ (void)resetPersistenceNamed:(NSString *)name {
    _STUserDefaults *userDefaults = [self persistenceNamed:name];
    [userDefaults resetPersistence];
}

@end

@implementation _STUserDefaults

- (instancetype)initWithName:(NSString *)name {
    self = [super initWithDirectory:STPersistenceDirectoryLibiary subpath:nil];
    if (name.length == 0) {
        name = [[NSBundle mainBundle].bundleIdentifier stringByAppendingString:@".plist"];
    } else {
        if (![name hasSuffix:@".plist"]) {
            name = [name stringByAppendingString:@".plist"];
        }
    }
    if (self) {
        self.filePath = [self.cacheDirectory stringByAppendingPathComponent:name];
    }
    return self;
}

- (instancetype)initWithDirectory:(STPersistenceDirectory)directory subpath:(NSString *)subpath {
    return [self initWithName:nil];
}

- (NSString *)description {
    return @"STPersistence";
}

+ (NSString *)description {
    return @"STPersistence";
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if (key.length == 0) {
        return;
    }
    NSMutableDictionary *dictionary;
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:_filePath];
    if ([defaults isKindOfClass:[NSDictionary class]]) {
        dictionary = [defaults mutableCopy];
    }
    if (!dictionary) {
        dictionary = [NSMutableDictionary dictionaryWithCapacity:2];
    }
    [dictionary setValue:value forKey:key];
    [dictionary writeToFile:_filePath atomically:YES];
}

- (id)valueForKey:(NSString *)key {
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:_filePath];
    return [dictionary valueForKey:key];
}

- (void)resetPersistence {
    NSDictionary *dictionary = @{};
    [dictionary writeToFile:_filePath atomically:YES];
}

+ (Class)superclass {
    return [STPersistence superclass];
}

+ (Class)class {
    return [STPersistence class];
}

@end

@implementation STPersistence (STPersistCreation)

+ (instancetype)documentPersistence {
    return [self documentPersistenceWithSubpath:nil];
}


+ (instancetype)cachePersistence {
    return [self cachePersistenceWithSubpath:nil];
}

+ (instancetype)libiaryPersistence {
    return [self libiaryPersistenceWithSubpath:nil];
}

+ (instancetype)tempoaryPersistence {
    return [self tempoaryPersistenceWithSubpath:nil];
}

+ (instancetype)documentPersistenceWithSubpath:(NSString *)subpath {
    return [[self alloc] initWithDirectory:STPersistenceDirectoryDocument subpath:subpath];
}

+ (instancetype)libiaryPersistenceWithSubpath:(NSString *)subpath {
    return [[self alloc] initWithDirectory:STPersistenceDirectoryLibiary subpath:subpath];
}

+ (instancetype)cachePersistenceWithSubpath:(NSString *)subpath {
    return [[self alloc] initWithDirectory:STPersistenceDirectoryCache subpath:subpath];
}

+ (instancetype)tempoaryPersistenceWithSubpath:(NSString *)subpath {
    return [[self alloc] initWithDirectory:STPersistenceDirectoryTemporary subpath:subpath];
}

@end