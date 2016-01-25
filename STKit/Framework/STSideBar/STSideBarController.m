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

@interface UIViewController (STTopNavigationBar)

- (UINavigationBar *)st_topNavigationBar;

@end

typedef NS_ENUM(NSInteger, STDirection) {
    STDirectionLeft = 1,
    STDirectionRight = 2
};

typedef NS_ENUM(NSInteger, _STSideViewState) {
    STSideViewWillAppear,
    STSideViewDidAppear,
    STSideViewTranslation,
    STSideViewWillDisappear,
    STSideViewDidDisappear,
};

const CGFloat STMinSideBarInteractionOffset = 10.;
const CGFloat STSideBarChangeDuration = 0.45;

@interface STSideBarController () <UIGestureRecognizerDelegate>

@property(nonatomic, assign) _STSideViewState sideViewState;

@property(nonatomic, strong) UIViewController *rootViewController;
@property(nonatomic, strong) UIView *containerView;
@property(nonatomic, strong) UIView *hitTestView;

@property(nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property(nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property(nonatomic, assign) CGPoint panGestureStartPoint;

@property(nonatomic, strong) STShadow *shadow;
@end

@implementation STSideBarController

- (void)dealloc {
    self.panGestureRecognizer.delegate = nil;
    [self.shadow removeObserver:self forKeyPath:@"shadowOpacity"];
    [self.shadow removeObserver:self forKeyPath:@"shadowOffset"];
    [self.shadow removeObserver:self forKeyPath:@"shadowRadius"];
    [self.shadow removeObserver:self forKeyPath:@"shadowColor"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithRootViewController:UIViewController.new];
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _rootViewController = rootViewController;
        SEL selector = NSSelectorFromString(@"st_setSideBarController:");
        if ([_rootViewController respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [_rootViewController performSelector:selector withObject:self];
#pragma clang diagnostic pop
        }
        _selectedIndex = 0;
        _maxSideWidth = 260.;
        _supportsEdgeInteractive = YES;
        self.shadow = [[STShadow alloc] init];
        self.shadow.shadowColor = [UIColor blackColor];
        self.shadow.shadowRadius = 3.0f;
        self.shadow.shadowOffset = CGSizeMake(- 3.0f, 0.0f);
        self.shadow.shadowOpacity = 0.2;

        [self.shadow addObserver:self forKeyPath:@"shadowOpacity" options:NSKeyValueObservingOptionNew context:NULL];
        [self.shadow addObserver:self forKeyPath:@"shadowOffset" options:NSKeyValueObservingOptionNew context:NULL];
        [self.shadow addObserver:self forKeyPath:@"shadowRadius" options:NSKeyValueObservingOptionNew context:NULL];
        [self.shadow addObserver:self forKeyPath:@"shadowColor" options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [self initWithRootViewController:UIViewController.new];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

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
        SEL selector = NSSelectorFromString(@"st_setSideBarController:");
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
            sideInteractionDistance = weakSelf.supportsEdgeInteractive? STMinSideBarInteractionOffset : 0;
        }
        CGPoint touchPoint = [weakSelf.hitTestView convertPoint:point toView:weakSelf.containerView];
        if (!CGRectContainsPoint(weakSelf.containerView.bounds, touchPoint)) {
            return (UIView *)nil;
        }

        UINavigationBar *navigationBar = [weakSelf.selectedViewController st_topNavigationBar];
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

    [self _updateShadow];
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
    childViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
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
            SEL selector = NSSelectorFromString(@"st_setSideBarController:");
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
            SEL selector = NSSelectorFromString(@"st_setSideBarController:");
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
    CGRect frame = self.view.bounds;
    frame.origin.x = self.maxSideWidth;
    [UIView animateWithDuration:STSideBarChangeDuration
        animations:^{
            self.containerView.frame = frame;
        }
        completion:^(BOOL finished) {
            self.containerView.frame = frame;
            self.sideViewState = STSideViewDidAppear;
            self.sideAppeared = YES;
        }];
}

- (void)concealSideViewControllerAnimated:(BOOL)animated {
    [self.containerView removeGestureRecognizer:self.tapGestureRecognizer];
    [UIView animateWithDuration:STSideBarChangeDuration
        animations:^{
            // 主界面 view 回归原位
            self.containerView.frame = self.view.bounds;
        }
        completion:^(BOOL finished) {
            // 主界面 view 回归原位
            self.containerView.frame = self.view.bounds;
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
- (void)completeSideViewController:(UIViewController *)sideViewController
                    targetDistance:(CGFloat)targetOffset
                        swipeRight:(BOOL)swipeRight {
    [self.containerView removeGestureRecognizer:self.tapGestureRecognizer];
    CGFloat percent = 0.0;
    CGRect frame = self.containerView.frame;
    /// 如果向右滑动
    if (swipeRight) {
        /// 如果本来是出现的
        if (self.sideAppeared || targetOffset >= (self.maxSideWidth / 3.0)) {
            percent = targetOffset / self.maxSideWidth;
            if (targetOffset > self.maxSideWidth) {
                percent = 0.9;
            }
            frame.origin.x = self.maxSideWidth;
            percent = 1.0 - percent;
            
        } else {
            /// 如果本来没有出现
            percent = targetOffset / self.maxSideWidth;
            if (targetOffset < 0) {
                percent = 0.9;
            }
            frame = self.view.bounds;
        }
    } else {
        if (!self.sideAppeared || targetOffset <= (self.maxSideWidth * 2.0 / 3.0)) {
            /// 如果本来没有出现
            percent = targetOffset / self.maxSideWidth;
            if (targetOffset < 0) {
                percent = 0.9;
            }
            frame = self.view.frame;
        } else {
            percent = targetOffset / self.maxSideWidth;
            if (targetOffset > self.maxSideWidth) {
                percent = 0.9;
            }
            percent = 1.0 - percent;
            frame.origin.x = self.maxSideWidth;
        }
    }
    void (^animations)(void) = ^() {
        self.containerView.frame = frame;
    };

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
    [UIView animateWithDuration:MAX(STSideBarChangeDuration * percent, 0.1) animations:animations completion:completion];
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
        CGRect rect = self.view.bounds;
        CGFloat originX = self.panGestureStartPoint.x + translation.x;
        originX = MAX(0, MIN(originX, self.maxSideWidth));
        rect.origin.x = originX;
        self.containerView.frame = rect;
    } else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded || panGestureRecognizer.state == UIGestureRecognizerStateCancelled ||
               panGestureRecognizer.state == UIGestureRecognizerStateFailed) {
        /// 结束
        // 判断如果 到了一定位置，结束之后要归位等等
        CGFloat velocityX = [panGestureRecognizer velocityInView:self.view].x;
        CGFloat targetOffset = MIN(MAX(self.containerView.left + (velocityX * 0.1), 0), self.maxSideWidth);
        [self completeSideViewController:self.rootViewController  targetDistance:targetOffset swipeRight:(velocityX >= 0)];
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
        sideInteractionDistance = self.supportsEdgeInteractive? STMinSideBarInteractionOffset : 0;
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
    UINavigationBar *navigationBar = [self.selectedViewController st_topNavigationBar];
    CGPoint touchPoint = [touch locationInView:self.selectedViewController.view];
    BOOL sideEffected = (touchPoint.x <= sideInteractionDistance);
    if (sideEffected) {
        return YES;
    }
    if (navigationBar && [view isDescendantOfView:navigationBar]) {
        return STGetBitOffset(self.selectedViewController.st_sideInteractionArea, 0);
    }
    return STGetBitOffset(self.selectedViewController.st_sideInteractionArea, 1);
}

- (BOOL)hintSideInteractiveGestureRecognizerWithViewController:(UIViewController *)viewController {
    if (!viewController.isViewLoaded) {
        return NO;
    }
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.shadow) {
        [self _updateShadow];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)_updateShadow {
    if (self.isViewLoaded) {
        
        CGFloat offset = ABS(_shadow.shadowOffset.width);
        CGRect pathRect = CGRectOffset(self.containerView.bounds, - offset, 0);
        pathRect.size.width += offset;
        
        self.containerView.layer.shadowPath = [UIBezierPath bezierPathWithRect:pathRect].CGPath;
        self.containerView.layer.shadowColor = self.shadow.shadowColor.CGColor;
        self.containerView.layer.shadowOpacity = self.shadow.shadowOpacity;
        self.containerView.layer.shadowRadius = self.shadow.shadowRadius;
    }
}

@end

@implementation UIViewController (SideBarController)

static char sideBarControllerKey;
- (void)st_setSideBarController:(STSideBarController *)sideBarController {
    [super willChangeValueForKey:@"st_sideBarController"];
    objc_setAssociatedObject(self, &sideBarControllerKey, sideBarController, OBJC_ASSOCIATION_ASSIGN);
    [super didChangeValueForKey:@"st_sideBarController"];
}

- (STSideBarController *)st_sideBarController {
    id revealController = objc_getAssociatedObject(self, &sideBarControllerKey);
    if (!revealController && self.navigationController) {
        revealController = self.navigationController.st_sideBarController;
    } else if (!revealController && self.st_navigationController) {
        revealController = self.st_navigationController.st_sideBarController;
    }
    return revealController;
}

static char sideInteractionAreaKey;
- (void)st_setSideInteractionArea:(STSideInteractiveArea)sideInteractionArea {
    [super willChangeValueForKey:@"st_sideInteractionArea"];
    objc_setAssociatedObject(self, &sideInteractionAreaKey, @(sideInteractionArea), OBJC_ASSOCIATION_COPY_NONATOMIC);
    [super didChangeValueForKey:@"st_sideInteractionArea"];
}

- (STSideInteractiveArea)st_sideInteractionArea {
    id sideInteractionArea = objc_getAssociatedObject(self, &sideInteractionAreaKey);
    if (!sideInteractionArea) {
        return (STSideInteractiveAreaAll);
    }
    return (STSideInteractiveArea)[sideInteractionArea intValue];
}


static char sideInteractionEdgeAreaKey;
- (CGFloat)st_maximumInteractiveSideEdgeDistance {
    id value = objc_getAssociatedObject(self, &sideInteractionEdgeAreaKey);
    if (![value isKindOfClass:NSNumber.class]) {
        return STMinSideBarInteractionOffset;
    }
    return [value floatValue];
}

- (void)st_setMaximumInteractiveSideEdgeDistance:(CGFloat)maximumInteractivePopEdgeDistance {
    objc_setAssociatedObject(self, &sideInteractionEdgeAreaKey, @(maximumInteractivePopEdgeDistance),
                             OBJC_ASSOCIATION_COPY);
}

@end

@implementation UIViewController (STTopNavigationBar)

- (UINavigationBar *)st_topNavigationBar {
    if ([self isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)self;
        return navigationController.navigationBar;
    }
    if ([self isKindOfClass:[STNavigationController class]]) {
        STNavigationController *navigationController = (STNavigationController *)self;
        return (UINavigationBar *)navigationController.topViewController.st_navigationBar;
    }
    if ([self isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabbarController = (UITabBarController *)self;
        return [tabbarController.selectedViewController st_topNavigationBar];
    }
    if ([self isKindOfClass:[STTabBarController class]]) {
        STTabBarController *tabbarController = (STTabBarController *)self;
        return [tabbarController.selectedViewController st_topNavigationBar];
    }
    return [self.navigationController st_topNavigationBar];
}

@end
