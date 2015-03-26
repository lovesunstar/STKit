//
//  STTabBarItem.m
//  STKit
//
//  Created by SunJiangting on 14-2-13.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STTabBarItem.h"
#import "STTabBar.h"

@implementation STTabBarItem

- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image selectedImage:(UIImage *)selectedImage {
    self = [super init];
    if (self) {
        self.title = title;
        self.image = image;
        self.selectedImage = selectedImage;
    }
    return self;
}

- (void)setBadgeValue:(NSString *)badgeValue {
    _badgeValue = badgeValue;
    if ([self.itemView respondsToSelector:@selector(setBadgeValue:)]) {
        [self.itemView performSelector:@selector(setBadgeValue:) withObject:badgeValue];
    }
}

@end
