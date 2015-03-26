//
//  STTheme.m
//  STKit
//
//  Created by SunJiangting on 13-12-19.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import "STTheme.h"

@interface STTheme ()

@property(nonatomic, retain) NSMutableDictionary *elementDictionary;

@end

@implementation STTheme

- (instancetype)init {
    self = [super init];
    if (self) {
        self.elementDictionary = [NSMutableDictionary dictionaryWithCapacity:5];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.elementDictionary = [aDecoder decodeObjectForKey:@"elementDictionary"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.elementDictionary forKey:@"elementDictionary"];
}

- (void)setThemeValue:(id)value forKey:(NSString *)key whenContainedIn:(Class)containerClass {
    NSString *className = NSStringFromClass(containerClass);
    NSMutableDictionary *themeElement = [NSMutableDictionary dictionaryWithCapacity:2];
    [themeElement setValue:value forKey:key];
    [self.elementDictionary setValue:themeElement forKey:className];
}

- (id)themeValueForKey:(NSString *)key whenContainedIn:(Class)containerClass {
    NSString *className = NSStringFromClass(containerClass);
    NSDictionary *theme = [self.elementDictionary valueForKey:className];
    return [theme valueForKey:key];
}

@end
