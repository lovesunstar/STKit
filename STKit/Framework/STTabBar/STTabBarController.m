//
//  STTabBarController.m
//  STKit
//
//  Created by SunJiangting on 14-2-13.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STTabBarController.h"
#import "STTabBar.h"
#import "STTabBarItem.h"
#import "STNavigationController.h"
#import <objc/runtime.h>

@interface STTabBarController () <STTabBarDelegate> {
}

@property(nonatomic, strong) UIView *transitionView;
@property(nonatomic, strong) STTabBar *tabBar;
@property(nonatomic, strong) NSArray *tabBarItems;

- (void)updateVisibleChildController;

@end

@implementation STTabBarController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _selectedIndex = -1;
        self.tabBarHeight = STCustomTabBarHeight;
        self.actualTabBarHeight = STCustomTabBarHeight;
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    if (self.isViewLoaded && !self.view.window) {
    }
}

#pragma mark - TabBarViewController
- (void)setViewControllers:(NSArray *)viewControllers {
    [self setViewControllers:viewControllers animated:NO];
}

- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated {
    [self willChangeValueForKey:@"viewControllers"];
    [_viewControllers enumerateObjectsUsingBlock:^(UIViewController *obj, NSUInteger idx, BOOL *stop) {
        SEL selector = NSSelectorFromString(@"setCustomTabBarController:");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if ([obj respondsToSelector:selector]) {
            [obj performSelector:selector withObject:nil];
        }
#pragma clang diagnostic pop
        [obj willMoveToParentViewController:nil];
        [obj removeFromParentViewController];
    }];
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:5];
    [viewControllers enumerateObjectsUsingBlock:^(UIViewController *obj, NSUInteger idx, BOOL *stop) {
        [self addChildViewController:obj];
        [obj didMoveToParentViewController:self];
        SEL selector = NSSelectorFromString(@"setCustomTabBarController:");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if ([obj respondsToSelector:selector]) {
            [obj performSelector:selector withObject:self];
        }
#pragma clang diagnostic pop
        STTabBarItem *tabBarItem = obj.customTabBarItem;
        [items addObject:tabBarItem];
    }];
    _viewControllers = viewControllers;
    self.tabBarItems = items;
    [self updateVisibleChildController];
    [self didChangeValueForKey:@"viewControllers"];
}

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor clearColor];

    self.tabBar.frame = CGRectMake(0, CGRectGetHeight(self.view.bounds) - self.tabBarHeight, CGRectGetWidth(self.view.bounds), self.tabBarHeight);
    [self.view addSubview:self.tabBar];

    self.transitionView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.transitionView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.transitionView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.transitionView];
    [self.view bringSubviewToFront:self.tabBar];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self updateVisibleChildController];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.tabBar.frame = CGRectMake(0, CGRectGetHeight(self.view.bounds) - self.tabBarHeight, CGRectGetWidth(self.view.bounds), self.tabBarHeight);
    self.transitionView.frame = self.view.bounds;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tabBar.frame = CGRectMake(0, CGRectGetHeight(self.view.bounds) - self.tabBarHeight, CGRectGetWidth(self.view.bounds), self.tabBarHeight);
    self.transitionView.frame = self.view.bounds;
}

#pragma mark - SelectedViewController
- (void)setSelectedViewController:(UIViewController *)selectedViewController {
    if ([self.delegate respondsToSelector:@selector(tabBarController:shouldSelectViewController:)] &&
        ![self.delegate tabBarController:self shouldSelectViewController:selectedViewController]) {
        return;
    }

    if (_selectedViewController == selectedViewController) {
        SEL selector = NSSelectorFromString(@"popToRootViewControllerAnimated:");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if ([selectedViewController respondsToSelector:selector]) {
            [(STNavigationController *)selectedViewController popToRootViewControllerAnimated:YES];
        }
#pragma clang diagnostic pop
    } else {
        UIViewController *fromController = self.selectedViewController;
        UIViewController *toController = selectedViewController;
        [self privateSetSelectedController:toController];
        if (![self.view isDescendantOfView:self.tabBar]) {
            [self.tabBar removeFromSuperview];
            [self.view addSubview:self.tabBar];
            [self updateTabBarFrameWithTopViewController:selectedViewController];
        }
        if (self.animatedWhenTransition) {
            [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
            [self transitionFromViewController:fromController
                              toViewController:toController
                                    completion:^(BOOL finished) {
                                        if ([UIApplication sharedApplication].isIgnoringInteractionEvents) {
                                            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                                        }

                                    }];
        } else {
            toController.view.frame = self.transitionView.bounds;
            toController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.transitionView addSubview:toController.view];
            [fromController.view removeFromSuperview];
        }
    }
    if ([self.delegate respondsToSelector:@selector(tabBarController:didSelectViewController:)]) {
        [self.delegate performSelector:@selector(tabBarController:didSelectViewController:) withObject:self withObject:selectedViewController];
    }
}

- (void)transitionFromViewController:(UIViewController *)fromViewController
                    toViewController:(UIViewController *)toViewController
                          completion:(void (^)(BOOL))finishCompletion {

    toViewController.view.frame = self.transitionView.bounds;
    [self.transitionView addSubview:toViewController.view];
    UIViewController *toVisibleController = ([toViewController respondsToSelector:@selector(visibleViewController)])
                                                ? [toViewController performSelector:@selector(visibleViewController)]
                                                : toViewController;
    UITableView *toTableView =
        ([toVisibleController respondsToSelector:@selector(tableView)]) ? [toVisibleController performSelector:@selector(tableView)] : nil;
    /// 获取列表中可见的cell
    NSMutableArray *visibleView = [NSMutableArray arrayWithCapacity:5];
    NSArray *visibleRows = [toTableView indexPathsForVisibleRows];
    [visibleRows enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
        UIView *headerView = [toTableView headerViewForSection:indexPath.section];
        if (indexPath.row == 0 && headerView && ![visibleView containsObject:headerView]) {
            [visibleView addObject:headerView];
        }
        UITableViewCell *tableViewCell = [toTableView cellForRowAtIndexPath:indexPath];
        if (tableViewCell) {
            [visibleView addObject:tableViewCell];
        }
        UIView *footerView = [toTableView footerViewForSection:indexPath.section];
        if ((indexPath.row == ([toTableView numberOfRowsInSection:indexPath.section] - 1)) && ![visibleView containsObject:footerView] &&
            footerView) {
            [visibleView addObject:footerView];
        }
    }];

    NSInteger fromIndex = [self.viewControllers indexOfObject:fromViewController];
    NSInteger toIndex = [self.viewControllers indexOfObject:toViewController];

    CGFloat transitionWidth = CGRectGetWidth(self.transitionView.bounds);
    BOOL leftToRight = (fromIndex < toIndex);

    CGFloat delta = leftToRight ? transitionWidth : -transitionWidth;

    fromViewController.view.transform = CGAffineTransformIdentity;
    toViewController.view.transform = CGAffineTransformMakeTranslation(delta, 0);

    [UIView animateWithDuration:0.0
                     animations:NULL
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0
                                               delay:0
                                             options:0
                                          animations:NULL
                                          completion:^(BOOL finished) {
                                              [UIView animateWithDuration:0.15
                                                  delay:0
                                                  options:UIViewAnimationOptionCurveEaseIn
                                                  animations:^{
                                                      fromViewController.view.transform = CGAffineTransformMakeTranslation(-delta, 0);
                                                      toViewController.view.transform = CGAffineTransformIdentity;
                                                  }
                                                  completion:^(BOOL finished) {
                                                      fromViewController.view.transform = CGAffineTransformIdentity;
                                                      [fromViewController.view removeFromSuperview];
                                                  }];
                                              [visibleView enumerateObjectsWithOptions:NSEnumerationReverse
                                                                            usingBlock:^(UIView *tableSubview, NSUInteger idx, BOOL *stop) {
                                                                                NSTimeInterval delay = ((float)idx / (float)visibleView.count) * 0.15;
                                                                                tableSubview.transform = CGAffineTransformMakeTranslation(delta, 0);
                                                                                void (^animation)() =
                                                                                    ^{ tableSubview.transform = CGAffineTransformIdentity; };
                                                                                void (^completion)(BOOL) = ^(BOOL finished) {
                                                                                    tableSubview.transform = CGAffineTransformIdentity;
                                                                                };
                                                                                if (STGetSystemVersion() >= 7) {
                                                                                    [UIView animateWithDuration:0.55
                                                                                                          delay:0.15 + delay
                                                                                         usingSpringWithDamping:0.75
                                                                                          initialSpringVelocity:1
                                                                                                        options:UIViewAnimationOptionCurveEaseInOut
                                                                                                     animations:animation
                                                                                                     completion:completion];
                                                                                } else {
                                                                                    [UIView animateWithDuration:0.55
                                                                                                          delay:0.15 + delay
                                                                                                        options:UIViewAnimationOptionCurveEaseInOut
                                                                                                     animations:animation
                                                                                                     completion:completion];
                                                                                }
                                                                            }];
                                              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)),
                                                             dispatch_get_main_queue(), ^{
                                                  if (finishCompletion) {
                                                      finishCompletion(YES);
                                                  }
                                              });

                                          }];
                     }];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    if (selectedIndex >= self.viewControllers.count) {
        return;
    }
    self.selectedViewController = [self.viewControllers objectAtIndex:selectedIndex];
}

#pragma mark - AMTabBarDelegate
- (void)tabBar:(STTabBar *)tabbar didSelectItem:(STTabBarItem *)item {
    self.selectedIndex = [self.tabBarItems indexOfObject:item];
}

#pragma mark - Private Method
- (void)privateSetSelectedController:(UIViewController *)controller {
    _selectedViewController = controller;
    _selectedIndex = [self.viewControllers indexOfObject:_selectedViewController];
    self.tabBar.selectedItem = _selectedViewController.customTabBarItem;
}

- (void)updateTabBarFrameWithTopViewController:(UIViewController *)topViewController {
    if (!topViewController.hidesBottomBarWhenPushed) {
        self.tabBar.frame = CGRectMake(0, CGRectGetHeight(self.view.bounds) - self.tabBarHeight, CGRectGetWidth(self.view.bounds), self.tabBarHeight);
    } else {
        self.tabBar.frame = CGRectMake(-CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - self.tabBarHeight,
                                       CGRectGetWidth(self.view.bounds), self.tabBarHeight);
    }
}

- (void)updateVisibleChildController {
    if (self.viewControllers.count <= 0) {
        return;
    }
    if (!_selectedViewController) {
        _selectedViewController = [self.viewControllers objectAtIndex:0];
    }
    /// 如果view没有加载先不用管，view加载了以后迟早还会掉用这个方法
    if (!self.isViewLoaded) {
        return;
    }
    if (![self.transitionView isDescendantOfView:self.selectedViewController.view]) {
        [self.transitionView removeAllSubviews];
        [self.selectedViewController.view removeFromSuperview];
        UIView *view = self.selectedViewController.view;
        view.frame = self.transitionView.bounds;
        [self.transitionView addSubview:view];
    }
    if (self.tabBarItems) {
        [self.tabBar setItems:self.tabBarItems];
    }
    self.tabBar.selectedItem = self.selectedViewController.customTabBarItem;
    [self updateTabBarFrameWithTopViewController:self.selectedViewController];
}

- (STTabBar *)tabBar {
    if (!_tabBar) {
        CGSize screenSize = [UIScreen mainScreen].applicationFrame.size;
        if (STGetSystemVersion() >= 7) {
            screenSize = [UIScreen mainScreen].bounds.size;
        }
        _tabBar = [[STTabBar alloc] initWithFrame:CGRectMake(0, screenSize.height - self.tabBarHeight, screenSize.width, self.tabBarHeight)];
        _tabBar.delegate = self;
        [_tabBar setValue:@(self.actualTabBarHeight) forVar:@"_actualHeight"];
    }
    return _tabBar;
}

- (void)setBadgeValue:(NSString *)badgeValue forIndex:(NSInteger)index {
    [_tabBar setBadgeValue:badgeValue forIndex:index];
}
- (NSString *)badgeValueForIndex:(NSInteger)index {
    return [_tabBar badgeValueForIndex:index];
}

- (void)setActualTabBarHeight:(CGFloat)actualTabBarHeight {
    _actualTabBarHeight = actualTabBarHeight;
    if (_tabBar) {
        [_tabBar setValue:@(actualTabBarHeight) forVar:@"_actualHeight"];
    }
}

#pragma mark - Rotate
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.selectedViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self.selectedViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

@end

static NSString *const STCustomTabBarItemKey = @"STCustomTabBarItemKey";
static NSString *const STCustomTabBarControllerKey = @"STCustomTabBarControllerKey";
@implementation UIViewController (STTabBarControllerItem)

- (STTabBarItem *)customTabBarItem {
    STTabBarItem *tabBarItem = objc_getAssociatedObject(self, (__bridge const void *)(STCustomTabBarItemKey));
    if (!tabBarItem) {
        tabBarItem = [[STTabBarItem alloc] initWithTitle:nil image:nil selectedImage:nil];
        [self setCustomTabBarItem:tabBarItem];
    }
    return tabBarItem;
}

- (void)setCustomTabBarItem:(STTabBarItem *)customTabBarItem {
    objc_setAssociatedObject(self, (__bridge const void *)(STCustomTabBarItemKey), customTabBarItem, OBJC_ASSOCIATION_RETAIN);
}

- (STTabBarController *)customTabBarController {
    STTabBarController *tabBarController = objc_getAssociatedObject(self, (__bridge const void *)(STCustomTabBarControllerKey));
    if (!tabBarController) {
        if (self.navigationController) {
            return self.navigationController.customTabBarController;
        } else {
            return self.customNavigationController.customTabBarController;
        }
    }
    return tabBarController;
}

- (void)setCustomTabBarController:(STTabBarController *)customTabBarController {
    objc_setAssociatedObject(self, (__bridge const void *)(STCustomTabBarControllerKey), customTabBarController, OBJC_ASSOCIATION_ASSIGN);
}

@end

const CGFloat STCustomTabBarHeight = 49;