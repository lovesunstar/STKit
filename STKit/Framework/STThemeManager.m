//
//  STThemeManager.m
//  STKit
//
//  Created by SunJiangting on 13-12-19.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import "STThemeManager.h"
#import "STTheme.h"

#import <UIKit/UIKit.h>

@interface STThemeManager ()

@property(nonatomic, strong) STTheme *currentTheme;

@end

@implementation STThemeManager

static STThemeManager *_themeManager;
+ (instancetype)sharedThemeManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ _themeManager = STThemeManager.new; });
    return _themeManager;
}

+ (STTheme *)currentTheme {
    return [STThemeManager sharedThemeManager].currentTheme;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        STTheme *theme = [[STTheme alloc] init];
        UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18.];
        [theme setThemeValue:font forKey:@"STDChatViewFont" whenContainedIn:NSClassFromString(@"STDTextChatCell")];

        UIFont *sendButtonFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:13.];
        [theme setThemeValue:sendButtonFont forKey:@"STDInputSendButton" whenContainedIn:NSClassFromString(@"STDChatInputView")];
        self.currentTheme = theme;
    }
    return self;
}
@end
