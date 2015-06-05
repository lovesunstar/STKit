//
//  STViewController.m
//  STKit
//
//  Created by SunJiangting on 13-10-5.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import "STViewController.h"
#import "STNavigation/STNavigationBar.h"
#import "STTabBar/STTabBarController.h"
#import "UIKit+STKit.h"
#import "STImage/STImageCache.h"
#import <objc/runtime.h>

@interface STViewController () {
  @private
    STIdentifier             _st_imageContextIdentifier;
    UIStatusBarStyle         _st_previousStatusBarStyle;
    __weak STViewController *_st_toolBarController;
}

- (void)setNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated customAnimations:(void (^)(void))animations;

@end

@implementation STViewController

- (void)dealloc {
    if ([self class] != NSClassFromString(@"_STWrapperViewController")) {
        STImageCachePopContext(_st_imageContextIdentifier);
        [UIApplication sharedApplication].statusBarStyle = _st_previousStatusBarStyle;
    }
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ([self class] != NSClassFromString(@"_STWrapperViewController") && nibNameOrNil.length == 0) {
        NSString *xibName = NSStringFromClass([self class]);
        if ([[NSBundle mainBundle] pathForResource:xibName ofType:@"nib"]) {
            nibNameOrNil = xibName;
        }
    }
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        if ([self class] != NSClassFromString(@"_STWrapperViewController")) {
            _st_imageContextIdentifier = STImageCacheBeginContext();
            STImageCachePushContext(_st_imageContextIdentifier);
            self.statusBarStyle = UIStatusBarStyleDefault;
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    CGRect frame = CGRectZero;
    if (STGetSystemVersion() >= 7) {
        frame = [UIScreen mainScreen].bounds;
    } else {
        frame.size = [UIScreen mainScreen].applicationFrame.size;
    }
    self.view.frame = frame;
    self.view.backgroundColor = [UIColor colorWithRGB:0xFFFFFF];
    if (self.customNavigationController.viewControllers.count > 1) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonCustomItem:STBarButtonCustomItemBack
                                                                                              target:self
                                                                                              action:@selector(backViewControllerActionFired:)];
    }
    _st_previousStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.class != NSClassFromString(@"_STWrapperViewController")) {
        [UIApplication sharedApplication].statusBarStyle = self.statusBarStyle;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)backViewControllerActionFired:(id)sender {
    [self backViewControllerAnimated:YES];
}

- (void)backViewControllerAnimated:(BOOL)animated {
    if (self.customNavigationController) {
        [self.customNavigationController popViewControllerAnimated:animated];
    } else {
        [self.navigationController popViewControllerAnimated:animated];
    }
}

- (void)setInteractivePopGestureEnabled:(BOOL)interactivePopGestureEnabled {
    UIGestureRecognizer *gestureRecognizer = nil;
    if ([self.customNavigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        gestureRecognizer = self.customNavigationController.interactivePopGestureRecognizer;
    } else if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        gestureRecognizer = self.navigationController.interactivePopGestureRecognizer;
    }
    gestureRecognizer.enabled = interactivePopGestureEnabled;
}

- (BOOL)isInteractivePopGestureEnabled {
    UIGestureRecognizer *gestureRecognizer = nil;
    if ([self.customNavigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        gestureRecognizer = [self.customNavigationController performSelector:@selector(interactivePopGestureRecognizer)];
    } else if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        gestureRecognizer = self.navigationController.interactivePopGestureRecognizer;
    }
    return gestureRecognizer.enabled;
}

- (UIViewController *)_st_toolBarController {
    return nil;
}

- (void)setNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated {
    [_st_toolBarController setNavigationBarHidden:hidden animated:animated customAnimations:NULL];
}

- (void)setNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated customAnimations:(void (^)(void))animations {
    [_st_toolBarController setNavigationBarHidden:hidden animated:YES customAnimations:animations];
}

- (void)setNavigationBarHidden:(BOOL)hidden animations:(void (^)(void))animations {
    [_st_toolBarController setNavigationBarHidden:hidden animated:YES customAnimations:animations];
}

@end
