//
//  STKeychain.m
//  STKit
//
//  Created by SunJiangting on 15/6/28.
//  Copyright (c) 2015年 SunJiangting. All rights reserved.
//

#import "STKeychain.h"
#import <Security/Security.h>
#import "Foundation+STKit.h"
#import <UIKit/UIKit.h>

@interface STKeychain () {
    NSString *_accessGroup, *_identifier;
}

@property(nonatomic, strong) NSMutableDictionary *query;

@property(nonatomic, strong) NSMutableDictionary *keychainItems;

@end

@implementation STKeychain

- (id)initWithIdentifier:(NSString *)identifier accessGroup:(NSString *)accessGroup {
    if (![identifier isKindOfClass:[NSString class]] || identifier.length == 0) {
        NSString *bundleIdentifier = [NSBundle mainBundle].bundleIdentifier;
//        identifier = [bundleIdentifier md5String];
        identifier = bundleIdentifier;
    }
    self = [super init];
    if (self) {
        _accessGroup = [accessGroup copy];
        _identifier = [identifier copy];
        
        self.query = [NSMutableDictionary dictionaryWithCapacity:10];
        self.query[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
        self.query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
        self.query[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleWhenUnlocked;
        [self.query setValue:identifier forKey:(__bridge id)kSecAttrAccount];
        [self.query setValue:identifier forKey:(__bridge id)kSecAttrGeneric];
        [self.query setObject:identifier forKey:(__bridge id)kSecAttrService];
        if (accessGroup) {
            if (![self isDeviceSimulator]) {
                [self.query setObject:accessGroup forKey:(__bridge id)kSecAttrAccessGroup];
            }
        }
        self.keychainItems = [NSMutableDictionary dictionaryWithCapacity:5];
        
        NSMutableDictionary *tempQuery = [self.query mutableCopy];
        tempQuery[(__bridge id)kSecReturnData] = (__bridge id)kCFBooleanTrue;
        
        CFTypeRef result = nil;
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)tempQuery, &result);
        if (status == noErr) {
            NSData *data = (__bridge_transfer NSData *)result;
            if (data) {
                id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                if ([json isKindOfClass:[NSDictionary class]]) {
                    [self.keychainItems addEntriesFromDictionary:json];
                }
            }
        }
    }
    
    return self;
}

- (NSDictionary *)keyChainItems {
    return nil;
}

- (BOOL)isDeviceSimulator {
    return [[[UIDevice currentDevice].model lowercaseString] st_contains:@"simulator"];
}

- (instancetype)init {
    return [self initWithIdentifier:nil accessGroup:nil];
}


- (void)setValue:(id)value forKey:(id)key {
    if (!key) {
        return;
    }
    id originValue = [self.keychainItems valueForKey:key];
    if ([originValue isEqual:value]) {
        return;
    }
    [self.keychainItems setValue:value forKey:key];
    [self synchronize];
}

- (void)synchronize {
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.keychainItems options:NSJSONWritingPrettyPrinted error:&error];
    if (error || !data) {
        return;
    }
    NSMutableDictionary *tempQuery = [NSMutableDictionary dictionaryWithCapacity:2];
    tempQuery[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    [tempQuery setValue:_identifier forKey:(__bridge id)kSecAttrGeneric];
    [tempQuery setValue:_identifier forKey:(__bridge id)kSecAttrService];
    [tempQuery setValue:_identifier forKey:(__bridge id)kSecAttrAccount];
    
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)tempQuery, NULL);
    if(status == errSecSuccess) {
        NSMutableDictionary *updateItem = [NSMutableDictionary dictionaryWithCapacity:1];
        [updateItem setObject:data forKey:(__bridge id)kSecValueData];
        
        status = SecItemUpdate((__bridge CFDictionaryRef)tempQuery, (__bridge CFDictionaryRef)updateItem);
    }
    else if(status == errSecItemNotFound) {
        NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithCapacity:5];
        [attrs setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
        [attrs setValue:_identifier forKey:(__bridge id)kSecAttrGeneric];
        [attrs setValue:_identifier forKey:(__bridge id)kSecAttrAccount];
        [attrs setValue:_identifier forKey:(__bridge id)kSecAttrService];
        
        if (_accessGroup) {
            if (![self isDeviceSimulator]) {
                attrs[(__bridge id)kSecAttrAccessGroup] = _accessGroup;
            }
        }
        [attrs setValue:data forKey:(__bridge id)kSecValueData];
        status = SecItemAdd((__bridge CFDictionaryRef)attrs, NULL);
    }
}

- (id)valueForKey:(id)key {
    return [self.keychainItems valueForKey:key];
}

- (void)removeAllValues {
    [self.keychainItems removeAllObjects];
    [self synchronize];

}

@end

@interface STKeychainManager ()

@property(nonatomic, strong) STKeychain *keychain;

@end

@implementation STKeychainManager

static STKeychainManager *_sharedManager;
+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    return _sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.keychain = [[STKeychain alloc] init];
    }
    return self;
    
}

- (void)setValue:(id)value forKey:(NSString *)key {
    [self.keychain setValue:value forKey:key];
}

- (id)valueForKey:(NSString *)key {
    return [self.keychain valueForKey:key];
}

@end
