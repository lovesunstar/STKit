//
//  STPayManager.m
//  STKit
//
//  Created by SunJiangting on 14-9-3.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STPayManager.h"
#import "STApplicationContext.h"
#import "STPayViewController.h"

@implementation STPayItem

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        self.name = [dictionary valueForKey:@"name"];
        self.title = [dictionary valueForKey:@"title"];
        self.desc = [dictionary valueForKey:@"description"];
        self.detail = [dictionary valueForKey:@"detail"];

        self.count = [[dictionary valueForKey:@"count"] integerValue];
        self.price = [[dictionary valueForKey:@"price"] floatValue];
        self.amount = [[dictionary valueForKey:@"amount"] floatValue];

        if ([dictionary valueForKey:@"platforms"]) {
            self.supportedPlatforms = [[dictionary valueForKey:@"platforms"] integerValue];
        } else {
            self.supportedPlatforms = STPayPlatformAll;
        }
        id defaultValue = [dictionary valueForKey:@"default"];
        if (defaultValue && ([defaultValue integerValue] & self.supportedPlatforms)) {
            self.defaultPlatform = [defaultValue integerValue];
        } else {
            if (self.supportedPlatforms & STPayPlatformAliPay) {
                self.defaultPlatform = STPayPlatformAliPay;
            } else if (self.supportedPlatforms & STPayPlatformWXPay) {
                self.defaultPlatform = STPayPlatformWXPay;
            } else {
                self.defaultPlatform = 0;
            }
        }
    }
    return self;
}
@end

@interface STPayManager ()

- (BOOL)_handleOpenURL:(NSURL *)URL;

@end

@implementation STPayManager

static STPayManager *_payManger;
+ (instancetype)sharedPayManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ _payManger = [[STPayManager alloc] init]; });
    return _payManger;
}

- (BOOL)payForItem:(STPayItem *)payItem finishHandler:(STPayHandler)handler {
    UIViewController *topmostViewController = [STApplicationContext sharedContext].topmostViewController;
    STPayViewController *payViewController = [[STPayViewController alloc] initWithPayItem:payItem handler:handler];
    if (topmostViewController.st_navigationController) {
        [topmostViewController.st_navigationController pushViewController:payViewController animated:YES];
    } else if (topmostViewController.navigationController) {
        [topmostViewController.navigationController pushViewController:payViewController animated:YES];
    } else {
        STNavigationController *navigationController = [[STNavigationController alloc] initWithRootViewController:payViewController];
        [topmostViewController presentViewController:navigationController animated:YES completion:NULL];
    }
    return YES;
}

- (void)cancelPayForItem:(STPayItem *)payItem {
}

- (BOOL)canOpenURL:(NSURL *)URL {
    NSString *scheme = [URL scheme];
    NSString *host = [URL host];
    return [scheme hasPrefix:@"stkit"] && [host isEqualToString:@"pay"];
}

- (BOOL)openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [self _handleOpenURL:url];
}

#pragma mark - Private Method
- (BOOL)_handleOpenURL:(NSURL *)URL {
    NSString *host = [URL host];
    if (![host isEqualToString:@"pay"]) {
        return NO;
    }
    //    stkit://pay?name=123&title=1234&description=1234&price=4000&count=1&amount=4000&allowsEditing=1&platforms=3#1
    NSString *query = [URL query];
    NSDictionary *parameters = [NSDictionary st_dictionaryWithURLQuery:query];
    STPayItem *payItem = [[STPayItem alloc] initWithDictionary:parameters];
    [self payForItem:payItem finishHandler:^(STPayItem *payItem, STPayResult result, NSError *error) {
        NSLog(@"%@", payItem);
        if (result == STPayResultSuccess) {
            /// 支付成功
        } else {
            if (result == STPayResultCancelled) {
                NSLog(@"用户取消支付");
            } else {
                NSLog(@"%@", error);
            }
        }
    }];

    return YES;
}

@end

BOOL STPayManagerOpenURL(NSURL *URL) {
    return [[STPayManager sharedPayManager] _handleOpenURL:URL];
}

BOOL STPayManagerCanOpenURL(NSURL *URL) {
    return [[STPayManager sharedPayManager] canOpenURL:URL];
}