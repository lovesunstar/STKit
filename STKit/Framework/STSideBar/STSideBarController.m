//
//  STSideBarController.m
//  STKit
//
//  Created by SunJiangting on 13-11-19.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import "STSideBarController.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "Foundation+STKit.h"
#import "UIKit+STKit.h"
#import "STTabBarController.h"
#import "STNavigationBar.h"
#import "STNavigationController.h"

typedef enum { STDirectionLeft = 1, STDirectionRight = 2 } STDirection;

typedef enum {
    STSideViewWillAppear,
    STSideViewDidAppear,
    STSideViewTranslation,
    STSideViewWillDisappear,
    STSideViewDidDisappear,
} _STSideViewState;

const CGFloat STMinSideBarInteractionOffset = 10.;

@interface STSideBarController () <UIGestureRecognizerDelegate>

@property(nonatomic, assign) _STSideViewState sideViewState;

@property(nonatomic, strong) UIViewController *rootViewController;
@property(nonatomic, strong) UIView *containerView;
@property(nonatomic, strong) UIView *hitTestView;

@property(nonatomic, assign) CGRect standardViewFrame;

@property(nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property(nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property(nonatomic, assign) CGPoint panGestureStartPoint;
@end

@implementation STSideBarController

- (void)dealloc {
    self.panGestureRecognizer.delegate = nil;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _rootViewController = rootViewController;
        _selectedIndex = 0;
        _maxSideWidth = 260.;
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [self initWithRootViewController:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    BOOL portrait = UIInterfaceOrientationIsPortrait(self.interfaceOrientation);
    CGFloat bWidth = CGRectGetWidth(self.view.frame);
    CGFloat bHeight = CGRectGetHeight(self.view.frame);
    if (portrait) {
        self.standardViewFrame = CGRectMake(0, 0, bWidth, bHeight);
    } else {
        self.standardViewFrame = CGRectMake(0, 0, bHeight, bWidth);
    }

    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(gestureRecognizerDidChanged:)];
    self.panGestureRecognizer.delegate = self;
    self.panGestureRecognizer.cancelsTouchesInView = YES;

    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizerActionFired:)];
    self.tapGestureRecognizer.cancelsTouchesInView = YES;

    if (self.rootViewController) {
        [self addChildViewController:self.rootViewController];
        [self.view addSubview:self.rootViewController.view];
        [self.rootViewController didMoveToParentViewController:self];
        self.rootViewController.view.frame = self.view.bounds;
        SEL selector = NSSelectorFromString(@"setSideBarController:");
        if ([self.rootViewController respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self.rootViewController performSelector:selector withObject:self];
#pragma clang diagnostic pop
        }
    }
    self.sideViewState = STSideViewDidDisappear;

    UIView *containerView = [[UIView alloc] initWithFrame:self.view.bounds];
    containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    containerView.backgroundColor = [UIColor clearColor];
    containerView.clipsToBounds = YES;
    containerView.layer.masksToBounds = NO;
    containerView.layer.shadowColor = [UIColor blackColor].CGColor;
    containerView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    containerView.layer.shadowOpacity = 1.0f;
    containerView.layer.shadowRadius = 2.f;

    CGRect shadowRect = CGRectOffset(self.standardViewFrame, -2.5, -2.5);
    shadowRect.size.width += 5;
    shadowRect.size.height += 5;
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:shadowRect];
    containerView.layer.shadowPath = shadowPath.CGPath;
    [self.view addSubview:containerView];
    self.containerView = containerView;

    self.hitTestView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.hitTestView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    __weak STSideBarController *weakSelf = self;
    self.hitTestView.hitTestBlock = ^(CGPoint point, UIEvent *event, BOOL *returnSuper) {
        if (![weakSelf hintSideInteractiveGestureRecognizer]) {
            return (UIView *)nil;
        }
        CGFloat sideInteractionDistance = CGRectGetWidth(weakSelf.containerView.bounds) - weakSelf.maxSideWidth;
        if (weakSelf.sideViewState == STSideViewDidDisappear) {
            sideInteractionDistance = STMinSideBarInteractionOffset;
        }
        CGPoint touchPoint = [weakSelf.hitTestView convertPoint:point toView:weakSelf.containerView];
        if (!CGRectContainsPoint(weakSelf.containerView.bounds, touchPoint)) {
            return (UIView *)nil;
        }

        UINavigationBar *navigationBar = [weakSelf.selectedViewController topNavigationBar];
        CGPoint navigationPoint = [weakSelf.hitTestView convertPoint:point toView:navigationBar];
        if ([navigationBar pointInside:navigationPoint withEvent:event]) {
            return [weakSelf.selectedViewController.view hitTest:touchPoint withEvent:event];
        }
        BOOL sideEffected = (touchPoint.x <= sideInteractionDistance);
        if (sideEffected) {
            return weakSelf.selectedViewController.view;
        }
        return (UIView *)nil;
    };
    self.hitTestView.pointInsideBlock = ^(CGPoint point, UIEvent *event, BOOL *returnSuper) {
        if (!weakSelf.selectedViewController || (weakSelf.sideViewState != STSideViewDidAppear && weakSelf.sideViewState != STSideViewDidDisappear)) {
            return NO;
        }
        *returnSuper = YES;
        return YES;
    };

    [self.view addSubview:self.hitTestView];

    [self layoutViewControllersAnimated:NO];
}

- (void)layoutViewControllersAnimated:(BOOL)animated {
    if (self.viewControllers.count == 0) {
        return;
    }
    if (_selectedIndex >= self.viewControllers.count) {
        _selectedIndex = 0;
    }
    if (self.isViewLoaded) {
        self.selectedIndex = _selectedIndex;
    }
    if (self.sideAppeared) {
        [self concealSideViewControllerAnimated:animated];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    BOOL portrait = UIInterfaceOrientationIsPortrait(self.interfaceOrientation);
    CGFloat bWidth = CGRectGetWidth(self.view.frame);
    CGFloat bHeight = CGRectGetHeight(self.view.frame);
    if (portrait) {
        self.standardViewFrame = CGRectMake(0, 0, bWidth, bHeight);
    } else {
        self.standardViewFrame = CGRectMake(0, 0, bHeight, bWidth);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - SetSideViewControllers

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    if (selectedIndex >= self.viewControllers.count) {
        return;
    }
    UIViewController *childViewController = [self.viewControllers objectAtIndex:selectedIndex];
    childViewController.view.frame = self.containerView.bounds;
    if (childViewController != self.selectedViewController) {
        [self willChangeValueForKey:@"selectedIndex"];
        if (!self.selectedViewController) {
            // 如果没有任何选中的viewController
            [self.containerView addSubview:childViewController.view];
        } else {
            [self removeSidePanGestureRecognizerFromViewController:self.selectedViewController];
            // 将当前要选中的视图移动到顶部
            [self transitionFromViewController:self.selectedViewController
                              toViewController:childViewController
                                      duration:0.0
                                       options:0.0
                                    animations:nil
                                    completion:nil];
        }
        [self addSidePanGestureRecognizerToViewController:childViewController];
        _selectedIndex = selectedIndex;
        _selectedViewController = childViewController;
        [self didChangeValueForKey:@"selectedIndex"];
    }
    [self.containerView bringSubviewToFront:self.selectedViewController.view];
    if (self.sideViewState != STSideViewDidDisappear) {
        [self concealSideViewControllerAnimated:YES];
    }
}

- (void)setViewControllers:(NSArray *)viewControllers {
    [self setViewControllers:viewControllers animated:NO];
}

- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated {
    [self.containerView removeGestureRecognizer:self.tapGestureRecognizer];
    [_viewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[UIViewController class]]) {
            UIViewController *childViewController = (UIViewController *)obj;
            [childViewController willMoveToParentViewController:nil];
            SEL selector = NSSelectorFromString(@"setSideBarController:");
            if ([childViewController respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [childViewController performSelector:selector withObject:nil];
#pragma clang diagnostic pop
            }
            [childViewController.view removeFromSuperview];
            [childViewController removeFromParentViewController];
        }
    }];
    [self willChangeValueForKey:@"viewControllers"];
    // setViewcontrollers;
    [viewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[UIViewController class]]) {
            UIViewController *childViewController = (UIViewController *)obj;
            [self addChildViewController:childViewController];
            SEL selector = NSSelectorFromString(@"setSideBarController:");
            if ([childViewController respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [childViewController performSelector:selector withObject:self];
#pragma clang diagnostic pop
            }
            [childViewController didMoveToParentViewController:self];
        }
    }];
    _viewControllers = [viewControllers copy];
    [self didChangeValueForKey:@"viewControllers"];
    if (self.isViewLoaded) {
        [self layoutViewControllersAnimated:animated];
    }
}

#pragma mark - Open/Close SideViewController

- (void)revealSideViewControllerAnimated:(BOOL)animated {
    [self.containerView addGestureRecognizer:self.tapGestureRecognizer];
    CGRect frame = self.standardViewFrame;
    frame.origin.x = self.maxSideWidth;
    [UIView animateWithDuration:0.35
        animations:^{ self.containerView.frame = frame; }
        completion:^(BOOL finished) {
            self.containerView.frame = frame;
            self.sideViewState = STSideViewDidAppear;
            self.sideAppeared = YES;
        }];
}

- (void)concealSideViewControllerAnimated:(BOOL)animated {
    [self.containerView removeGestureRecognizer:self.tapGestureRecognizer];
    [UIView animateWithDuration:0.35
        animations:^{
            // 主界面 view 回归原位
            self.containerView.frame = self.standardViewFrame;
        }
        completion:^(BOOL finished) {
            // 主界面 view 回归原位
            self.containerView.frame = self.standardViewFrame;
            self.sideViewState = STSideViewDidDisappear;
            self.sideAppeared = NO;
        }];
}

#pragma mark - Add/Remove GestureRecognizer
- (void)addSidePanGestureRecognizerToViewController:(UIViewController *)viewController {
    [viewController.view addGestureRecognizer:self.panGestureRecognizer];
}

- (void)removeSidePanGestureRecognizerFromViewController:(UIViewController *)viewController {
    [viewController.view removeGestureRecognizer:self.panGestureRecognizer];
}

#pragma mark - Complete GestureRecognizer
/// 完成一半时,将剩下的动画自动完成
- (void)completeSideViewController:(UIViewController *)sideViewController animated:(BOOL)animated targetDistance:(CGFloat)targetOffset {
    [self.containerView removeGestureRecognizer:self.tapGestureRecognizer];
    targetOffset *= 0.1;
    CGFloat percent = 0.0;
    CGRect frame = self.containerView.frame;
    CGFloat targetX = CGRectGetMinX(frame) + targetOffset;
    if (targetX <= (self.maxSideWidth / 2)) {
        percent = targetX / self.maxSideWidth;
        if (targetX < 0) {
            percent = 0.9;
        }
        frame = self.standardViewFrame;
    } else {
        percent = 1.0 - targetX / self.maxSideWidth;
        if (targetX > self.maxSideWidth) {
            percent = 0.9;
        }
        frame.origin.x = self.maxSideWidth;
    }
    void (^animations)(void) = ^() { self.containerView.frame = frame; };

    void (^completion)(BOOL) = ^(BOOL finished) {
        self.containerView.frame = frame;
        if (CGRectGetMinX(frame) <= 0) {
            self.sideViewState = STSideViewDidDisappear;
            self.sideAppeared = NO;
        } else {
            self.sideViewState = STSideViewDidAppear;
            self.sideAppeared = YES;
            [self.containerView addGestureRecognizer:self.tapGestureRecognizer];
        }
    };
    if (animated) {
        [UIView animateWithDuration:0.25 * percent animations:animations completion:completion];
    } else {
        animations();
        completion(NO);
    }
}

- (void)tapGestureRecognizerActionFired:(UITapGestureRecognizer *)tapGestureRecognizer {
    if (self.sideViewState == STSideViewDidAppear) {
        [self concealSideViewControllerAnimated:YES];
    }
}

#pragma mark - UIPanGestureRecognizerDelegate
/// 手势移动。
- (void)gestureRecognizerDidChanged:(UIPanGestureRecognizer *)panGestureRecognizer {
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.panGestureStartPoint = self.containerView.frame.origin;
        if (self.sideViewState == STSideViewDidDisappear) {
            self.sideViewState = STSideViewWillAppear;
        } else {
            self.sideViewState = STSideViewWillDisappear;
        }

    } else if (panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        self.sideViewState = STSideViewTranslation;

        CGPoint translation = [panGestureRecognizer translationInView:self.containerView];
        CGRect rect = self.standardViewFrame;
        CGFloat originX = self.panGestureStartPoint.x + translation.x;
        originX = MAX(0, MIN(originX, self.maxSideWidth));
        rect.origin.x = originX;
        self.containerView.frame = rect;
    } else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded || panGestureRecognizer.state == UIGestureRecognizerStateCancelled ||
               panGestureRecognizer.state == UIGestureRecognizerStateFailed) {
        /// 结束
        // 判断如果 到了一定位置，结束之后要归位等等
        CGFloat targetOffset = [panGestureRecognizer velocityInView:self.containerView].x * 1;
        [self completeSideViewController:self.rootViewController animated:YES targetDistance:targetOffset];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        self.panGestureStartPoint = self.containerView.frame.origin;
        if (self.sideViewState == STSideViewDidAppear) {
            return YES;
        }
        CGPoint velocity = [gestureRecognizer velocityInView:self.selectedViewController.view];
        if (fabs(velocity.y) > fabs(velocity.x)) {
            return NO;
        }
        return (self.sideViewState == STSideViewDidDisappear) && (fabs(velocity.x) >= fabs(velocity.y));
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIPanGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer != self.panGestureRecognizer) {
        return YES;
    }
    if (!self.selectedViewController || (self.sideViewState != STSideViewDidAppear && self.sideViewState != STSideViewDidDisappear)) {
        return NO;
    }
    CGFloat sideInteractionDistance = CGRectGetWidth(self.containerView.bounds) - self.maxSideWidth;
    if (self.sideViewState == STSideViewDidDisappear) {
        sideInteractionDistance = STMinSideBarInteractionOffset;
        if (self.selectedViewController.presentedViewController) {
            return NO;
        }
        if ([self.selectedViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navigationController = (UINavigationController *)self.selectedViewController;
            if (navigationController.viewControllers.count > 1) {
                return NO;
            }
        }
        if ([self.selectedViewController isKindOfClass:[STNavigationController class]]) {
            STNavigationController *navigationController = (STNavigationController *)self.selectedViewController;
            if (navigationController.viewControllers.count > 1) {
                return NO;
            }
        }
        if ([self.selectedViewController isKindOfClass:[STTabBarController class]]) {
            UIViewController *vc = ((STTabBarController *)self.selectedViewController).selectedViewController;
            if ([vc isKindOfClass:[UINavigationController class]]) {
                if (((UINavigationController *)vc).viewControllers.count > 1) {
                    return NO;
                }
            } else if ([vc isKindOfClass:[STNavigationController class]]) {
                if (((STNavigationController *)vc).viewControllers.count > 1) {
                    return NO;
                }
            }
        }
        if ([self.selectedViewController isKindOfClass:[UITabBarController class]]) {
            UIViewController *vc = ((UITabBarController *)self.selectedViewController).selectedViewController;
            if ([vc isKindOfClass:[UINavigationController class]]) {
                if (((UINavigationController *)vc).viewControllers.count > 1) {
                    return NO;
                }
            } else if ([vc isKindOfClass:[STNavigationController class]]) {
                if (((STNavigationController *)vc).viewControllers.count > 1) {
                    return NO;
                }
            }
        }
    }
    UIView *view = touch.view;
    UINavigationBar *navigationBar = [self.selectedViewController topNavigationBar];
    CGPoint touchPoint = [touch locationInView:self.selectedViewController.view];
    BOOL sideEffected = (touchPoint.x <= sideInteractionDistance);
    if (sideEffected) {
        return YES;
    }
    if (navigationBar && [view isDescendantOfView:navigationBar]) {
        return STGetBitOffset(self.selectedViewController.sideInteractionArea, 0);
    }
    return STGetBitOffset(self.selectedViewController.sideInteractionArea, 1);
}

- (BOOL)hintSideInteractiveGestureRecognizerWithViewController:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nvc = (UINavigationController *)viewController;
        if (nvc.viewControllers.count == 1 && !nvc.presentingViewController && (nvc.topViewController == nvc.visibleViewController)) {
            return YES;
        } else {
            return NO;
        }
    } else if ([viewController isKindOfClass:[STNavigationController class]]) {
        STNavigationController *nvc = (STNavigationController *)viewController;
        if (nvc.viewControllers.count == 1 && !nvc.presentingViewController && (nvc.topViewController == nvc.visibleViewController)) {
            return YES;
        } else {
            return NO;
        }
    } else if ([self.selectedViewController respondsToSelector:@selector(selectedViewController)]) {
        UIViewController *vc = [self.selectedViewController performSelector:@selector(selectedViewController)];
        return [self hintSideInteractiveGestureRecognizerWithViewController:vc];
    } else {
        return !viewController.presentingViewController;
    }
    return NO;
}

- (BOOL)hintSideInteractiveGestureRecognizer {
    return [self hintSideInteractiveGestureRecognizerWithViewController:self.selectedViewController];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO;
}
#pragma mark - Rotate
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    self.standardViewFrame = self.view.bounds;
    CGRect shadowRect = CGRectOffset(self.standardViewFrame, -2.5, -2.5);
    shadowRect.size.width += 5;
    shadowRect.size.height += 5;
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:shadowRect];
    self.containerView.layer.shadowPath = shadowPath.CGPath;
}

@end

@implementation UIViewController (SideBarController)

static char sideBarControllerKey;
- (void)setSideBarController:(STSideBarController *)sideBarController {
    [super willChangeValueForKey:@"sideBarController"];
    objc_setAssociatedObject(self, &sideBarControllerKey, sideBarController, OBJC_ASSOCIATION_ASSIGN);
    [super didChangeValueForKey:@"sideBarController"];
}

- (STSideBarController *)sideBarController {
    id revealController = objc_getAssociatedObject(self, &sideBarControllerKey);
    if (!revealController && self.navigationController) {
        revealController = self.navigationController.sideBarController;
    } else if (!revealController && self.customNavigationController) {
        revealController = self.customNavigationController.sideBarController;
    }
    return revealController;
}

static char sideInteractionAreaKey;
- (void)setSideInteractionArea:(NSInteger)sideInteractionArea {
    [super willChangeValueForKey:@"sideInteractionArea"];
    objc_setAssociatedObject(self, &sideInteractionAreaKey, @(sideInteractionArea), OBJC_ASSOCIATION_COPY_NONATOMIC);
    [super didChangeValueForKey:@"sideInteractionArea"];
}

- (NSInteger)sideInteractionArea {
    id sideInteractionArea = objc_getAssociatedObject(self, &sideInteractionAreaKey);
    if (!sideInteractionArea) {
        return (STSideInteractiveAreaAll);
    }
    return [sideInteractionArea intValue];
}

- (UINavigationBar *)topNavigationBar {
    if ([self isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)self;
        return navigationController.navigationBar;
    }
    if ([self isKindOfClass:[STNavigationController class]]) {
        STNavigationController *navigationController = (STNavigationController *)self;
        return (UINavigationBar *)navigationController.topViewController.customNavigationBar;
    }
    if ([self isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabbarController = (UITabBarController *)self;
        return [tabbarController.selectedViewController topNavigationBar];
    }
    if ([self isKindOfClass:[STTabBarController class]]) {
        STTabBarController *tabbarController = (STTabBarController *)self;
        return [tabbarController.selectedViewController topNavigationBar];
    }
    return [self.navigationController topNavigationBar];
}
@end
