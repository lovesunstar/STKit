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
}

@end

@implementation STViewController

- (void)dealloc {
    if ([self class] != NSClassFromString(@"_STWrapperViewController")) {
        STImageCachePopContext(_st_imageContextIdentifier);
    }
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        if ([self class] != NSClassFromString(@"_STWrapperViewController")) {
            _st_imageContextIdentifier = STImageCacheBeginContext();
            STImageCachePushContext(_st_imageContextIdentifier);
        }
    }
    return self;
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
    self.view.backgroundColor = [UIColor st_colorWithRGB:0xFFFFFF];
    if (self.st_navigationController.viewControllers.count > 1) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonCustomItem:STBarButtonCustomItemBack
                                                                                              target:self
                                                                                              action:@selector(backViewControllerActionFired:)];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)backViewControllerActionFired:(id)sender {
    [self backViewControllerAnimated:YES];
}

- (void)backViewControllerAnimated:(BOOL)animated {
    if (self.st_navigationController) {
        [self.st_navigationController popViewControllerAnimated:animated];
    } else {
        [self.navigationController popViewControllerAnimated:animated];
    }
}

- (void)setInteractivePopGestureEnabled:(BOOL)interactivePopGestureEnabled {
    UIGestureRecognizer *gestureRecognizer = nil;
    if ([self.st_navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        gestureRecognizer = self.st_navigationController.interactivePopGestureRecognizer;
    } else if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        gestureRecognizer = self.navigationController.interactivePopGestureRecognizer;
    }
    gestureRecognizer.enabled = interactivePopGestureEnabled;
}

- (BOOL)isInteractivePopGestureEnabled {
    UIGestureRecognizer *gestureRecognizer = nil;
    if ([self.st_navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        gestureRecognizer = [self.st_navigationController performSelector:@selector(interactivePopGestureRecognizer)];
    } else if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        gestureRecognizer = self.navigationController.interactivePopGestureRecognizer;
    }
    return gestureRecognizer.enabled;
}

@end
