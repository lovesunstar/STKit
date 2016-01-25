//
//  STNavigationTransitionDelegate.m
//  STKit
//
//  Created by SunJiangting on 15/7/6.
//  Copyright (c) 2015年 SunJiangting. All rights reserved.
//

#import "STNavigationTransitionDelegate.h"

@implementation STNavigationTransitionDelegate

/// 是否可以使用自定义的transition切换,如果返回False，则使用默认动画
- (BOOL)navigationController:(STNavigationController *)navigationController
shouldBeginTransitionContext:(STNavigationControllerTransitionContext *)transitionContext {
    return YES;
}

- (void)navigationController:(STNavigationController *)navigationController willBeginTransitionContext:(STNavigationControllerTransitionContext *)transitionContext {
    
}

- (void)navigationController:(STNavigationController *)navigationController transitingWithContext:(STNavigationControllerTransitionContext *)transitionContext {
    
}

- (void)navigationController:(STNavigationController *)navigationController didEndTransitionContext:(STNavigationControllerTransitionContext *)transitionContext {
    
}

@end
