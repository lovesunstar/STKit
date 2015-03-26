//
//  STHTTPConfiguration.m
//  STKit
//
//  Created by SunJiangting on 15-2-6.
//  Copyright (c) 2015年 SunJiangting. All rights reserved.
//

#import "STHTTPConfiguration.h"

@implementation STHTTPConfiguration
static STHTTPConfiguration *_defaultConfiguraiton;
+ (instancetype)defaultConfiguration {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultConfiguraiton = [[self alloc] init];
    });
    return _defaultConfiguraiton;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.timeoutInterval = 60;
        self.decodeResponseData = YES;
        self.enctype = STHTTPRequestFormEnctypeURLEncoded;
        self.dataEncoding = NSUTF8StringEncoding;
        self.JSONReadingOptions = NSJSONReadingAllowFragments;
        self.dataType = STHTTPResponseDataTypeTextJSON;
        self.HTTPMethod = @"GET";
        self.supportCachePolicy = YES;
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    STHTTPConfiguration *configuration = [[self class] allocWithZone:zone];
    configuration.timeoutInterval = self.timeoutInterval;
    configuration.decodeResponseData = self.decodeResponseData;
    configuration.enctype = self.enctype;
    configuration.JSONReadingOptions = self.JSONReadingOptions;
    configuration.dataType = self.dataType;
    configuration.HTTPMethod = self.HTTPMethod;
    configuration.compressionOptions = self.compressionOptions;
    configuration.dataEncoding = self.dataEncoding;
    configuration.XMLElementContextKey = self.XMLElementContextKey;
    configuration.XMLParseOptions = self.XMLParseOptions;
    configuration.cachePolicy = self.cachePolicy;
    configuration.supportCachePolicy = self.supportCachePolicy;
    return configuration;
}
@end
