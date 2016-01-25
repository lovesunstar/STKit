//
//  STApplicationContext.m
//  STKit
//
//  Created by SunJiangting on 14-8-14.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STApplicationContext.h"
#import "STPayManager.h"
#import <objc/runtime.h>
#import "Foundation+STKit.h"

@interface UIAlertView (STApplicationContext)


@end

@implementation UIAlertView (STApplicationContext)

+ (void)load {
    STExchangeSelectors(self, @selector(show), @selector(st_show));
}

- (void)st_show {
    STApplicationContext *context = [STApplicationContext sharedContext];
    NSHashTable *hashTable = [context st_valueForVar:@"_alertViewHashTable"];
    if ([hashTable isKindOfClass:[NSHashTable class]]) {
        [hashTable addObject:self];
    }
    [self st_show];
}

@end

@interface STApplicationContext ()

@property (nonatomic, strong) NSMutableDictionary    *classURLPairs;

@end

@implementation STApplicationContext {
    NSHashTable *_alertViewHashTable;
}

static STApplicationContext *_sharedContext;
+ (STApplicationContext *)sharedContext {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ _sharedContext = [[STApplicationContext alloc] init]; });
    return _sharedContext;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _alertViewHashTable = [NSHashTable weakObjectsHashTable];
        self.classURLPairs = [NSMutableDictionary dictionaryWithCapacity:5];
    }
    return self;
}

- (void)_dismissAllAlertViews {
    if (self.availableAlertViews.count > 0) {
        [self.availableAlertViews enumerateObjectsUsingBlock:^(UIAlertView *obj, NSUInteger idx, BOOL *stop) {
            [obj dismissWithClickedButtonIndex:obj.cancelButtonIndex animated:NO];
        }];
    }
}

- (NSString *)name {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleNameKey];
}

- (NSString *)bundleIdentifier {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleIdentifierKey];
}

- (NSString *)bundleVersion {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleVersionKey];
}

- (NSArray *)availableAlertViews {
    return [[_alertViewHashTable allObjects] copy];
}

- (UIWindow *)mainWindow {
    UIApplication *application = [UIApplication sharedApplication];
    id appDelegate = application.delegate;
    if ([appDelegate respondsToSelector:@selector(window)]) {
        return [appDelegate window];
    }
    if (application.windows.count <= 1) {
        return [application.windows firstObject];
    }
    __block UIWindow *mainWindow;
    __block CGFloat maxAreaSize;
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    [application.windows enumerateObjectsUsingBlock:^(UIWindow *window, NSUInteger idx, BOOL *stop) {
        CGRect frame = window.frame;
        CGFloat effectiveHeight = MIN(screenSize.height, CGRectGetMaxY(frame)) - MAX(0, CGRectGetMinY(frame)),
                effectiveWidth = MIN(screenSize.width, CGRectGetMaxX(frame)) - MAX(0, CGRectGetMinX(frame));
        CGFloat areaSize = effectiveWidth * effectiveHeight;
        if (maxAreaSize < areaSize && ![window isKindOfClass:NSClassFromString(@"_STImagePresentWindow")]) {
            maxAreaSize = areaSize;
            mainWindow = window;
        }
    }];
    return mainWindow;
}

- (UIViewController *)topmostViewController {
    return [self topmostViewControllerExcludeClasses:@[@"UIAlertController"]];
}

- (UIViewController *)topmostViewControllerExcludeClasses:(NSArray<NSString *> *)classes {
    UIViewController *rootViewController = self.mainWindow.rootViewController;
    return [self _visibleViewController:rootViewController excludeClasses:classes];
}

- (UIViewController *)_visibleViewController:(UIViewController *)viewController excludeClasses:(NSArray<NSString *> *)classes {
    if ([viewController respondsToSelector:@selector(selectedViewController)]) {
        UITabBarController *tabbarController = (UITabBarController *)viewController;
        return [self _visibleViewController:tabbarController.selectedViewController excludeClasses:classes];
    }
    if ([viewController respondsToSelector:@selector(visibleViewController)]) {
        UINavigationController *navigationController = (UINavigationController *)viewController;
        UIViewController *visibleVC = navigationController.visibleViewController;
        NSString *visibleClass = NSStringFromClass(visibleVC.class);
        if ([classes containsObject:visibleClass]) {
            visibleVC = navigationController.topViewController;
        }
        return [self _visibleViewController:visibleVC excludeClasses:classes];
    }
    NSString *visibleClass = NSStringFromClass(viewController.class);
    if ([viewController isKindOfClass:[UIViewController class]] && ![classes containsObject:visibleClass]) {
        UIViewController *presentedVC = viewController.presentedViewController;
        NSString *presentedClass = NSStringFromClass(viewController.class);
        if (presentedVC && (![classes containsObject:presentedClass])) {
            return [self _visibleViewController:presentedVC excludeClasses:classes];
        }
        return viewController;
    }
    return nil;
}

- (BOOL)openURL:(NSURL *)URL {
    if (![self canOpenURL:URL]) {
        return NO;
    }
    if (STPayManagerCanOpenURL(URL)) {
        if (self.availableAlertViews.count > 0) {
            [self.availableAlertViews enumerateObjectsUsingBlock:^(UIAlertView *obj, NSUInteger idx, BOOL *stop) {
                [obj dismissWithClickedButtonIndex:obj.cancelButtonIndex animated:NO];
            }];
        }
        return STPayManagerOpenURL(URL);
    } else {
        
    }
    return NO;
}

- (BOOL)canOpenURL:(NSURL *)URL {
    if ([[URL scheme] isEqualToString:@"stkit"]) {
        return YES;
    }
    return NO;
}

- (BOOL)registerClass:(Class)class forURLString:(NSString *)URLString {
    NSString *classString = NSStringFromClass(class);
    if (!classString) {
        return NO;
    }
    [self.classURLPairs setValue:classString forKey:URLString];
    return YES;
}

@end
