//
//  STNavigationController.m
//  STKit
//
//  Created by SunJiangting on 14-2-13.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STNavigationController.h"
#import "STNavigationBar.h"

#import "STTabBar.h"
#import "STTabBarController.h"
#import "UIKit+STKit.h"
#import "STResourceManager.h"
#import <objc/runtime.h>

@implementation STNavigationControllerTransitionContext {
    @public
    UIViewController *_st_fromViewController, *_st_toViewController;
    UIView *_st_fromView, *_st_toView;
    CGFloat _st_completion;
    STViewControllerTransitionType _st_transitionType;
    UIView *_st_transitionView;
}

- (UIViewController *)fromViewController {
    return _st_fromViewController;
}

- (UIViewController *)toViewController {
    return _st_toViewController;
}

- (UIView *)fromView {
    return _st_fromView;
}

- (UIView *)toView {
    return _st_toView;
}

- (CGFloat)completion {
    return _st_completion;
}

- (STViewControllerTransitionType)transitionType {
    return _st_transitionType;
}

- (UIView *)transitionView {
    return _st_transitionView;
}

@end

const CGFloat _STAnimationMaskViewMaximumAlpha = 0.2;
#pragma mark - _STAnimationMaskView
@interface _STAnimationMaskView : UIView

@property(nonatomic, strong) UIView *alphaView;
@property(nonatomic, strong) STShadow *shadow;

+ (_STAnimationMaskView *)animationMaskView;

@end

@interface UIScrollView (STFitIOS7)
- (CGFloat)st_contentInsetTopByNavigation;
- (void)st_setContentInsetTopByNavigation:(CGFloat)contentInsetTop;

- (CGFloat)st_contentInsetBottomByNavigation;
- (void)st_setContentInsetBottomByNavigation:(CGFloat)contentInsetBottom;
@end

@interface UINavigationItem (STNavigationChange)
@property (nonatomic, strong) STInvokeHandler   changedHandler;
@end

@implementation UINavigationItem (STNavigationChange)

static char *const STNavigationItemChangedKey = "STNavigationItemChangedKey";

- (void)setChangedHandler:(STInvokeHandler)changedHandler {
    objc_setAssociatedObject(self, STNavigationItemChangedKey, changedHandler, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (STInvokeHandler)changedHandler {
    return objc_getAssociatedObject(self, STNavigationItemChangedKey);
}

+ (void)load {
    STExchangeSelectors(self, @selector(setTitle:), @selector(st_setTitle:));
    STExchangeSelectors(self, @selector(setTitleView:), @selector(st_setTitleView:));
    STExchangeSelectors(self, @selector(setRightBarButtonItem:), @selector(st_setRightBarButtonItem:));
    STExchangeSelectors(self, @selector(setLeftBarButtonItem:), @selector(st_setLeftBarButtonItem:));
}

- (void)st_setTitle:(NSString *)title {
    [self st_setTitle:title];
    [self st_configChanged];
}

- (void)st_setTitleView:(UIView *)titleView {
    [self st_setTitleView:titleView];
    [self st_configChanged];
}

- (void)st_setRightBarButtonItem:(UIBarButtonItem *)rightBarButtonItem {
    [self st_setRightBarButtonItem:rightBarButtonItem];
    [self st_configChanged];
}

- (void)st_setLeftBarButtonItem:(UIBarButtonItem *)leftBarButtonItem {
    [self st_setLeftBarButtonItem:leftBarButtonItem];
    [self st_configChanged];
}

- (void)st_configChanged {
    if (self.changedHandler) {
        self.changedHandler();
    }
}

@end

@interface UIViewController (STKeyBoard)

@property(nonatomic, weak) UIView *keyboardSnapshotView;
@property(nonatomic, weak) UIView *keyboardView;

@end

@implementation UIViewController (STKeyBoard)

static char *const STViewControllerKeyboardView = "STViewControllerKeyboardView";
- (void)setKeyboardView:(UIView *)keyboardView {
    objc_setAssociatedObject(self, STViewControllerKeyboardView, keyboardView, OBJC_ASSOCIATION_ASSIGN);
}

- (UIView *)keyboardView {
    return objc_getAssociatedObject(self, STViewControllerKeyboardView);
}

static char *const STViewControllerKeyboardSnapshotView = "STViewControllerKeyboardSnapshotView";
- (void)setKeyboardSnapshotView:(UIView *)keyboardSnapshotView {
    objc_setAssociatedObject(self, STViewControllerKeyboardSnapshotView, keyboardSnapshotView, OBJC_ASSOCIATION_ASSIGN);
}

- (UIView *)keyboardSnapshotView {
    return objc_getAssociatedObject(self, STViewControllerKeyboardSnapshotView);
}

@end

#pragma mark - _STToolBarController

@interface _STWrapperViewController : STViewController

@property(nonatomic, readonly) UIViewController *rootViewController;

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController;
/// 以下两个方法非常私有，谨慎使用
- (BOOL)_st_requireCustomTabBar;
- (BOOL)_st_resignCustomTabBar;

@end

@interface UIViewController (_STWrapperControllerAssocity)

@property(nonatomic, assign, setter=st_setWrapperViewController:, getter=st_wrapperViewController) _STWrapperViewController *st_wrapperViewController;

@end

@implementation UIViewController (_STWrapperControllerAssocity)

static char *const STViewControllerWrapperControllerKey = "_STViewControllerWrapperControllerKey";

- (void)st_setWrapperViewController:(_STWrapperViewController *)wrapperViewController {
    objc_setAssociatedObject(self, STViewControllerWrapperControllerKey, wrapperViewController, OBJC_ASSOCIATION_ASSIGN);
}

- (_STWrapperViewController *)st_wrapperViewController {
    return objc_getAssociatedObject(self, STViewControllerWrapperControllerKey);
}

@end


@interface UIViewController (_STViewControllerAppearLifeCycle)

@property(nonatomic, assign, setter=st_setShouldNotifyAppearState:, getter=st_shouldNotifyAppearState) BOOL st_shouldNotifyAppearState;

@end

@implementation UIViewController (_STViewControllerAppearLifeCycle)

static char *const STViewControllerShouldCallbackAppearLifeCycle = "_STViewControllerShouldCallbackAppearLifeCycle";

+ (void)load {
    STExchangeSelectors(self, @selector(viewWillAppear:), @selector(st_viewWillAppear:));
    STExchangeSelectors(self, @selector(viewDidAppear:), @selector(st_viewDidAppear:));
    STExchangeSelectors(self, @selector(viewWillDisappear:), @selector(st_viewWillDisappear:));
    STExchangeSelectors(self, @selector(viewDidDisappear:), @selector(st_viewDidDisappear:));
}

- (void)st_setShouldNotifyAppearState:(BOOL)shouldNotify {
    objc_setAssociatedObject(self, STViewControllerShouldCallbackAppearLifeCycle, @(shouldNotify), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)st_shouldNotifyAppearState {
    NSNumber *shouldValue = objc_getAssociatedObject(self, STViewControllerShouldCallbackAppearLifeCycle);
    if ([shouldValue isKindOfClass:[NSNumber class]]) {
        return shouldValue.boolValue;
    }
    return YES;
}

- (void)st_viewWillAppear:(BOOL)animated {
    if (self.st_shouldNotifyAppearState) {
//        [self st_viewWillAppear:animated];
    }
}

- (void)st_viewDidAppear:(BOOL)animated {
    if (self.st_shouldNotifyAppearState) {
//        [self st_viewDidAppear:animated];
    }
}

- (void)st_viewWillDisappear:(BOOL)animated {
    if (self.st_shouldNotifyAppearState) {
//        [self st_viewWillDisappear:animated];
    }
}

- (void)st_viewDidDisappear:(BOOL)animated {
    if (self.st_shouldNotifyAppearState) {
//        [self st_viewDidDisappear:animated];
    }
}

@end

#pragma mark - STNavigationController

@interface STNavigationController () <UIGestureRecognizerDelegate> {
    CGPoint _panGestureStartPoint;
    BOOL _updatingVisibleController;
    BOOL _panGestureAnimating;
    NSMutableArray *_viewControllers;
    BOOL _panGestureShouldBeginTransite;
}

@property(nonatomic, strong) STNavigationBar *navigationBar;
@property(nonatomic, strong) UIView *transitionView;

@property(nonatomic, strong) _STAnimationMaskView *animationMaskView;

@property(nonatomic, strong) UIGestureRecognizer *interactivePopGestureRecognizer;
@property(nonatomic, strong) NSMutableDictionary *wrapperControllerDictionary;

@property(nonatomic, strong) NSMutableArray *operationQueue;
@property(nonatomic, assign) BOOL animating;

@property(nonatomic, strong) UIViewController *visibleWrapperViewController;

@property(nonatomic, strong) UIViewController *panFromViewController;
@property(nonatomic, strong) UIViewController *panTargetViewController;
@property(nonatomic, strong) UIViewController *popedViewController;

- (UIView *)_wrapperViewForController:(UIViewController *)viewController;

@end

@implementation STNavigationController

- (void)dealloc {
    self.interactivePopGestureRecognizer.delegate = nil;
    [_shadow removeObserver:self forKeyPath:@"shadowOpacity"];
    [_shadow removeObserver:self forKeyPath:@"shadowOffset"];
    [_shadow removeObserver:self forKeyPath:@"shadowRadius"];
    [_shadow removeObserver:self forKeyPath:@"shadowColor"];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [self initWithRootViewController:nil];
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.st_maximumInteractivePopEdgeDistance = 30;
        _viewControllers = [NSMutableArray arrayWithCapacity:1];
        self.wrapperControllerDictionary = [NSMutableDictionary dictionaryWithCapacity:2];
        if (rootViewController) {
            [self pushViewController:rootViewController animated:NO];
        }
        _shadow = [[STShadow alloc] init];
        _shadow.shadowColor = [UIColor blackColor];
        _shadow.shadowOffset = CGSizeMake(- 3, 0);
        _shadow.shadowRadius = 3.0;
        _shadow.shadowOpacity = 0.1;
        
        [_shadow addObserver:self forKeyPath:@"shadowOpacity" options:NSKeyValueObservingOptionNew context:NULL];
        [_shadow addObserver:self forKeyPath:@"shadowOffset" options:NSKeyValueObservingOptionNew context:NULL];
        [_shadow addObserver:self forKeyPath:@"shadowRadius" options:NSKeyValueObservingOptionNew context:NULL];
        [_shadow addObserver:self forKeyPath:@"shadowColor" options:NSKeyValueObservingOptionNew context:NULL];
        
        self.maximumPopAnimationMaskAlpha = _STAnimationMaskViewMaximumAlpha;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.frame = [UIScreen mainScreen].bounds;
    
    self.transitionView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.transitionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.transitionView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.transitionView];

    self.interactivePopGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizerFired:)];
    self.interactivePopGestureRecognizer.delegate = self;
    self.interactivePopGestureRecognizer.delaysTouchesBegan = NO;
    self.interactivePopGestureRecognizer.delaysTouchesEnded = YES;
    [self.transitionView addGestureRecognizer:self.interactivePopGestureRecognizer];

    UIViewController *viewController = [self _wrapperViewController:self.topViewController];
    UIView *view = [self _wrapperViewForController:viewController];
    self.topViewController.st_shouldNotifyAppearState = NO;
    [self.topViewController viewWillAppear:NO];
    [self.transitionView addSubview:view];
    [self.topViewController viewDidAppear:NO];
    
    __weak STNavigationController *weakSelf = self;
    self.transitionView.hitTestBlock = ^(CGPoint point, UIEvent *event, BOOL *returnSuper) {
        /// WebView 需要做特殊处理
        if (!weakSelf.interactivePopGestureRecognizer.enabled || weakSelf.animating || weakSelf.presentedViewController ||
            weakSelf.topViewController.presentedViewController || weakSelf.viewControllers.count <= 1) {
            *returnSuper = YES;
            return (UIView *)nil;
        }
        UIViewController *topVC = [weakSelf.viewControllers lastObject];
        CGFloat maximumDistance = topVC.st_maximumInteractivePopEdgeDistance;

        if (point.x < MIN(15, maximumDistance) && point.y > 64 * !(topVC.st_navigationBarHidden) && point.y > topVC.st_interactivePopTopEdgeOffset) {
            return (UIView *)weakSelf.transitionView;
        }
        *returnSuper = YES;
        return (UIView *)nil;
    };

    self.visibleWrapperViewController = viewController;

    UIView *hitTestView = [[UIView alloc] initWithFrame:self.view.bounds];
    hitTestView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    hitTestView.hitTestBlock = ^(CGPoint point, UIEvent *event, BOOL *returnSuper) {
        if (!weakSelf.interactivePopGestureRecognizer.enabled || weakSelf.animating || weakSelf.presentedViewController ||
            weakSelf.topViewController.presentedViewController || weakSelf.viewControllers.count <= 1) {
            return [weakSelf.transitionView hitTest:point withEvent:event];
        }
        UIViewController *topVC = [weakSelf.viewControllers lastObject];
        CGFloat maximumDistance = topVC.st_maximumInteractivePopEdgeDistance;
        if (point.x < maximumDistance && point.y > 64 * !(topVC.st_navigationBarHidden)) {
            return (UIView *)nil;
        }
        return [weakSelf.transitionView hitTest:point withEvent:event];
    };

    [self.view addSubview:hitTestView];
    [self _updateShadow];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - PushViewController
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (!viewController || [viewController isKindOfClass:[STNavigationController class]] || [_viewControllers containsObject:viewController]) {
        return;
    }
    viewController.st_shouldNotifyAppearState = NO;
    [_viewControllers addObject:viewController];
    [self setCustomNavigationController:self forController:viewController];

    UIViewController *fromWrapperViewController = self.visibleWrapperViewController;
    UIViewController *toWrapperViewController = [self _wrapperViewController:viewController];
    UIViewController *disappearedVC = [self _unwrapViewController:fromWrapperViewController];
    disappearedVC.st_shouldNotifyAppearState = NO;
    if (!self.isViewLoaded) {
        [self addChildViewController:toWrapperViewController];
        [toWrapperViewController didMoveToParentViewController:self];
        return;
    }
    void (^transition)(void) = ^{
        UIView *view = [self _wrapperViewForController:toWrapperViewController];
        [self.transitionView addSubview:view];
        view.frame = self.transitionView.bounds;
        [self addChildViewController:toWrapperViewController];
        [viewController st_viewWillAppear:YES];
        [disappearedVC st_viewWillDisappear:YES];
    };

    void (^completion)(BOOL) = ^(BOOL finished) {
        [toWrapperViewController didMoveToParentViewController:self];
        [viewController st_viewDidAppear:YES];
        [fromWrapperViewController.view removeFromSuperview];
        [disappearedVC st_viewDidDisappear:YES];
    };
    if (self.st_tabBarController) {
        [self _layoutTabBarFromViewController:fromWrapperViewController toViewController:toWrapperViewController];
    }
    if (!animated) {
        transition();
        completion(YES);
        self.visibleWrapperViewController = toWrapperViewController;
    } else {
        NSMutableArray *effectedViewControllers = [NSMutableArray arrayWithCapacity:2];
        [effectedViewControllers addObject:viewController];
        [self _setNeedTransitionToViewController:toWrapperViewController
                                 transitionType:STViewControllerTransitionTypePush
                                     transition:transition
                                     completion:completion];
    }
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    UIViewController *toViewController;
    if (_viewControllers.count > 1) {
        toViewController = [_viewControllers objectAtIndex:_viewControllers.count - 2];
    }
    if (toViewController) {
        NSArray *popedArray = [self popToViewController:toViewController animated:animated];
        if (popedArray.count > 0) {
            return [popedArray lastObject];
        }
    }
    return nil;
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated {
    if ([_viewControllers count] > 0) {
        UIViewController *toViewController = [_viewControllers objectAtIndex:0];
        return [self popToViewController:toViewController animated:animated];
    }
    return nil;
}

- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([_viewControllers count] <= 1 || !viewController) {
        return nil;
    }
    if (![self.viewControllers containsObject:viewController]) {
        return nil;
    }

    NSMutableArray *popedViewControllers = [NSMutableArray arrayWithCapacity:2];
    while (self.topViewController != viewController) {
        UIViewController *topViewController = self.topViewController;
        NSString *key = [NSString stringWithFormat:@"%llu", (unsigned long long)topViewController.hash];
        UIViewController *wrapperViewController = [self.wrapperControllerDictionary valueForKey:key];
        [wrapperViewController willMoveToParentViewController:nil];
        [wrapperViewController removeFromParentViewController];
        [self.wrapperControllerDictionary removeObjectForKey:key];
        [_viewControllers removeObject:topViewController];
        [popedViewControllers addObject:topViewController];
    }

    UIViewController *fromWrapperViewController = self.visibleWrapperViewController;
    UIViewController *toWrapperViewController = [self _wrapperViewController:viewController];

    if (self.st_tabBarController) {
        [self _layoutTabBarFromViewController:fromWrapperViewController toViewController:toWrapperViewController];
    }

    void (^transition)(void) = ^{
        [fromWrapperViewController willMoveToParentViewController:nil];
        UIView *view = [self _wrapperViewForController:toWrapperViewController];
        [self.transitionView insertSubview:view belowSubview:fromWrapperViewController.view];
    };
    void (^completion)(BOOL) = ^(BOOL finished) {
        [fromWrapperViewController.view removeFromSuperview];
        [fromWrapperViewController removeFromParentViewController];
        toWrapperViewController.view.frame = self.transitionView.bounds;
        [self setCustomNavigationController:nil forController:[self _unwrapViewController:fromWrapperViewController]];
        for (UIViewController *viewController in popedViewControllers) {
            if ([viewController respondsToSelector:@selector(st_didPopViewControllerAnimated:)]) {
                [viewController st_didPopViewControllerAnimated: animated];
            }
        }
    };
    if (!animated) {
        transition();
        completion(YES);
    } else {
        [self _setNeedTransitionToViewController:toWrapperViewController
                                  transitionType:STViewControllerTransitionTypePop
                                      transition:transition
                                      completion:completion];
    }

    return popedViewControllers;
}

#pragma mark - topAndVisibleController
- (UIViewController *)topViewController {
    return [_viewControllers lastObject];
}

- (UIViewController *)visibleViewController {
    if (self.topViewController.presentedViewController) {
        return self.topViewController.presentedViewController;
    }
    return self.topViewController;
}

- (void)setCustomNavigationController:(STNavigationController *)navigationController forController:(UIViewController *)viewController {
    SEL selector = NSSelectorFromString(@"st_setNavigationController:");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([viewController respondsToSelector:selector]) {
        [viewController performSelector:selector withObject:navigationController];
    }
#pragma clang diagnostic pop
}

#pragma mark - SetViewControllers
- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated {
    assert([viewControllers count] >= 1);
    if (![self.viewControllers isEqualToArray:viewControllers]) {
        // 把老的controller移掉，也把wrappercontroller移掉
        NSMutableArray *oldControllers = [NSMutableArray arrayWithArray:self.viewControllers];
        for (UIViewController *viewController in [self.wrapperControllerDictionary allValues]) {
            [self setCustomNavigationController:nil forController:viewController];
            [viewController willMoveToParentViewController:nil];
            [viewController removeFromParentViewController];
        }
        [_viewControllers removeAllObjects];
        /// 先添加N-1 个ViewController，然后再添加第N个
        for (int i = 0; i < viewControllers.count - 1; i++) {
            UIViewController *viewController = viewControllers[i];
            [self setCustomNavigationController:self forController:viewController];
            [_viewControllers addObject:viewController];
            UIViewController *wrapperViewController = [self _wrapperViewController:viewController];
            [self addChildViewController:wrapperViewController];
            [wrapperViewController didMoveToParentViewController:self];
        }
        UIViewController *viewController = [viewControllers lastObject];
        [self pushViewController:viewController animated:animated];
        for (UIViewController *viewController in oldControllers) {
            if ([[self viewControllers] indexOfObject:viewController] == NSNotFound) {
                NSString *key = [NSString stringWithFormat:@"%llu", (unsigned long long)viewControllers.hash];
                [self.wrapperControllerDictionary removeObjectForKey:key];
            }
        }
        [oldControllers removeAllObjects];
    }
}

- (void)setViewControllers:(NSMutableArray *)viewControllers {
    [self setViewControllers:viewControllers animated:NO];
}

-(NSMutableArray *)operationQueue {
    if (!_operationQueue) {
        _operationQueue = [[NSMutableArray alloc] init];
    }
    return _operationQueue;
}

#pragma mark - RelayoutTabBar
- (void)layoutTabBar:(STTabBar *)tabBar withViewController:(UIViewController *)viewController {
    CGRect frame = tabBar.frame;
    frame.origin.y = CGRectGetHeight(viewController.view.bounds) - CGRectGetHeight(frame);
    tabBar.frame = frame;
}

/// 该方法为了确保用户体验，把TabBar当作SubView添加到某一个Controller的View上
- (void)_layoutTabBarFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController {
    BOOL fromHidesBottomBar = fromViewController.hidesBottomBarWhenPushed;
    BOOL toHidesBottomBar = toViewController.hidesBottomBarWhenPushed;
    BOOL toRequireTabBar = [[toViewController st_valueForVar:@"_requiredTabBar"] boolValue];

    if (toRequireTabBar && [toViewController isKindOfClass:[_STWrapperViewController class]]) {
        [((_STWrapperViewController *)toViewController)_st_resignCustomTabBar];
    }
    STTabBar *tabBar = self.st_tabBarController.tabBar;
    tabBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    if (fromHidesBottomBar != toHidesBottomBar) {
        UIViewController *needBarViewController = toHidesBottomBar ? fromViewController : toViewController;
        /// 如果上一个VC显示TabBar，下一个VC不显示TabBar，则把TabBar加在上一个VC上，这样看起来比较舒服
        if (![needBarViewController.view isDescendantOfView:tabBar]) {
            [tabBar removeFromSuperview];
            [needBarViewController.view addSubview:tabBar];
            [self layoutTabBar:tabBar withViewController:needBarViewController];
        } else {
            [needBarViewController.view bringSubviewToFront:tabBar];
        }
    } else if (!toHidesBottomBar) {
        /// 如果两个都显示，则加在 tabBar上面
        if (![self.st_tabBarController.view isDescendantOfView:tabBar]) {
            [tabBar removeFromSuperview];
            [self.st_tabBarController.view addSubview:tabBar];
            [self layoutTabBar:tabBar withViewController:self.st_tabBarController];
        } else {
            [self.st_tabBarController.view bringSubviewToFront:tabBar];
        }
    } else {
        /// 如果两个都不显示，则加在 tabBar上面
        if (![self.st_tabBarController.view isDescendantOfView:tabBar]) {
            [tabBar removeFromSuperview];
            [self.st_tabBarController.view addSubview:tabBar];
            [self.st_tabBarController.view sendSubviewToBack:tabBar];
            [self layoutTabBar:tabBar withViewController:self.st_tabBarController];
        } else {
            [self.st_tabBarController.view sendSubviewToBack:tabBar];
        }
        
    }
    if (toRequireTabBar && [toViewController isKindOfClass:[_STWrapperViewController class]]) {
        [((_STWrapperViewController *)toViewController)_st_requireCustomTabBar];
    }
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer == self.interactivePopGestureRecognizer) {
        CGPoint point = [touch locationInView:self.transitionView];
        UIViewController *topVC = [self.viewControllers lastObject];
        CGFloat maximumDistance = topVC.st_maximumInteractivePopEdgeDistance;
        return self.viewControllers.count > 1 && point.x < maximumDistance && point.y > 64 * !(topVC.st_navigationBarHidden);
    }
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    UIPanGestureRecognizer *panGestureRecognizer = (UIPanGestureRecognizer *)self.interactivePopGestureRecognizer;
    CGPoint velocity = [panGestureRecognizer velocityInView:gestureRecognizer.view];
    return (fabs(velocity.x) > fabs(velocity.y)) && velocity.x > -10;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    UIPanGestureRecognizer *panGestureRecognizer = (UIPanGestureRecognizer *)self.interactivePopGestureRecognizer;
    CGPoint velocity = [panGestureRecognizer velocityInView:gestureRecognizer.view];
    return (fabs(velocity.x) < fabs(velocity.y));
}

- (void)panGestureRecognizerFired:(UIPanGestureRecognizer *)sender {
    /// 如果能触发此回调，viewControllers.count 必然>=2
    switch (sender.state) {
    case UIGestureRecognizerStateBegan:
        [self _panGestureRecognizerDidBegin:sender];
        break;
    case UIGestureRecognizerStateChanged:
        [self _panGestureRecognizerDidChange:sender];
        break;
    case UIGestureRecognizerStateEnded:
    case UIGestureRecognizerStateCancelled:
    case UIGestureRecognizerStateFailed:
        [self _panGestureRecoginzerDidFinish:sender];
        break;
    default:
        break;
    }
}

#pragma mark - PanGestureActionPrivate
- (void)_panGestureRecognizerDidBegin:(UIPanGestureRecognizer *)panGestureRecognizer {
    if (self.viewControllers.count < 2) {
        /// 结束这一次手势
        panGestureRecognizer.enabled = NO;
        panGestureRecognizer.enabled = YES;
        return;
    }
    _panGestureStartPoint = [panGestureRecognizer locationInView:self.transitionView];
    _updatingVisibleController = YES;
    self.panFromViewController = self.visibleWrapperViewController;
    self.popedViewController = [self popViewControllerAnimated:YES];

    [self.panFromViewController willMoveToParentViewController:nil];
    self.panTargetViewController = [self _wrapperViewController:self.topViewController];
    
    
    UIView *panFromView = [self _wrapperViewForController:self.panFromViewController];
    UIView *panToView = [self _wrapperViewForController:self.panTargetViewController];
    panFromView.userInteractionEnabled = NO;
    panToView.userInteractionEnabled = NO;
    
    STNavigationControllerTransitionContext *transitionContext = [[STNavigationControllerTransitionContext alloc] init];
    transitionContext->_st_fromViewController = [self _unwrapViewController:self.panFromViewController];
    transitionContext->_st_toViewController = [self _unwrapViewController:self.panTargetViewController];
    transitionContext->_st_fromView = panFromView;
    transitionContext->_st_toView = panToView;
    transitionContext->_st_transitionType = STViewControllerTransitionTypePop;
    transitionContext->_st_completion = 0.0;
    transitionContext->_st_transitionView = self.transitionView;
    
    _panGestureShouldBeginTransite = [self shouldBeginTransitionContext:transitionContext];
    if (_panGestureShouldBeginTransite && [self.delegate respondsToSelector:@selector(navigationController:willBeginTransitionContext:)]) {
        [self.delegate navigationController:self willBeginTransitionContext:transitionContext];
    } else {
        [self _st_navigationController:self willBeginTransitionContext:transitionContext];
    }
    
    [self.transitionView insertSubview:panToView belowSubview:panFromView];
    [self addChildViewController:self.panTargetViewController];
}

- (void)_panGestureRecognizerDidChange:(UIPanGestureRecognizer *)panGestureRecognizer {
    CGPoint currentPoint = [panGestureRecognizer locationInView:self.view];
    if (!self.panFromViewController || !self.panTargetViewController || (self.panTargetViewController == self.panFromViewController)) {
        _panGestureAnimating = NO;
        return;
    }
    UIView *panFromView = [self _wrapperViewForController:self.panFromViewController];
    UIView *panToView = [self _wrapperViewForController:self.panTargetViewController];

    if (!_panGestureAnimating) {
        _panGestureAnimating = YES;
        _panGestureStartPoint.y = currentPoint.y;
        
    }
    CGFloat dX = MAX(currentPoint.x - _panGestureStartPoint.x, 0);
    CGFloat completion = MIN(MAX(dX / CGRectGetWidth(self.transitionView.bounds), 0), 1.0);
    STNavigationControllerTransitionContext *transitionContext = [[STNavigationControllerTransitionContext alloc] init];
    transitionContext->_st_fromViewController = [self _unwrapViewController:self.panTargetViewController];
    transitionContext->_st_toViewController = [self _unwrapViewController:self.panTargetViewController];
    transitionContext->_st_fromView = panFromView;
    transitionContext->_st_toView = panToView;
    transitionContext->_st_transitionType = STViewControllerTransitionTypePop;
    transitionContext->_st_completion = completion;
    transitionContext->_st_transitionView = self.transitionView;
    if (_panGestureShouldBeginTransite && [self.delegate respondsToSelector:@selector(navigationController:transitingWithContext:)]) {
        [self.delegate navigationController:self transitingWithContext:transitionContext];
    } else {
        [self _st_navigationController:self transitingWithContext:transitionContext];
    }
}

- (void)_panGestureRecoginzerDidFinish:(UIPanGestureRecognizer *)panGestureRecognizer {
    CGPoint translation = [panGestureRecognizer translationInView:self.transitionView];
    self.animating = YES;
    void (^completion)(BOOL) = ^(BOOL finished) {
        _updatingVisibleController = NO;
        self.panFromViewController = nil;
        self.popedViewController = nil;
        self.panTargetViewController = nil;
        _panGestureAnimating = NO;
        _panGestureStartPoint = CGPointZero;
        self.animating = NO;
    };
    CGFloat velocityX = [panGestureRecognizer velocityInView:self.transitionView].x;
    CGFloat targetX = MIN(MAX(translation.x + (velocityX * 0.2), 0), CGRectGetWidth(self.transitionView.bounds));
    CGFloat gestureTargetX = (targetX + translation.x) / 2;
    if (targetX > CGRectGetWidth(self.transitionView.bounds) * 0.6) {
        [self _commitPopViewControllerAnimated:YES shouldTransite:_panGestureShouldBeginTransite targetOriginX:gestureTargetX completion:completion];
    } else {
        [self _rollbackPopViewControllerAnimated:YES shouldTransite:_panGestureShouldBeginTransite targetOriginX:gestureTargetX completion:completion];
    }
}

#pragma mark -Commit/RollbackAnimation
- (void)_commitPopViewControllerAnimated:(BOOL)animated shouldTransite:(BOOL)shouldTransite targetOriginX:(CGFloat)targetX completion:(void (^)(BOOL finished))completionHandler {
    UIView *panFromView = self.panFromViewController.view;
    UIView *panTargetView = self.panTargetViewController.view;
    // 完成比
    CGFloat completion = targetX / CGRectGetWidth(self.transitionView.bounds);
    CGFloat duration = STTransitionViewControllerAnimationDuration * completion;
    if (duration >= STTransitionViewControllerAnimationDuration) {
        duration = STTransitionViewControllerAnimationDuration - 0.1;
    }

    [UIView animateWithDuration:STTransitionViewControllerAnimationDuration - duration
        delay:0.0
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
            STNavigationControllerTransitionContext *transitionContext = [[STNavigationControllerTransitionContext alloc] init];
            transitionContext->_st_fromViewController = [self _unwrapViewController:self.panFromViewController];
            transitionContext->_st_toViewController = [self _unwrapViewController:self.panTargetViewController];
            transitionContext->_st_fromView = panFromView;
            transitionContext->_st_toView = panTargetView;
            transitionContext->_st_transitionType = STViewControllerTransitionTypePop;
            transitionContext->_st_completion = 1.0;
            transitionContext->_st_transitionView = self.transitionView;
            if (shouldTransite && [self.delegate respondsToSelector:@selector(navigationController:transitingWithContext:)]) {
                [self.delegate navigationController:self transitingWithContext:transitionContext];
            } else {
                [self _st_navigationController:self transitingWithContext:transitionContext];
            }
        }
        completion:^(BOOL finished) {
            STNavigationControllerTransitionContext *transitionContext = [[STNavigationControllerTransitionContext alloc] init];
            transitionContext->_st_fromViewController = [self _unwrapViewController:self.panFromViewController];
            transitionContext->_st_toViewController = [self _unwrapViewController:self.panTargetViewController];
            transitionContext->_st_fromView = panFromView;
            transitionContext->_st_toView = panTargetView;
            transitionContext->_st_transitionType = STViewControllerTransitionTypePop;
            transitionContext->_st_completion = 1.0;
            transitionContext->_st_transitionView = self.transitionView;
            panFromView.userInteractionEnabled = YES;
            panTargetView.userInteractionEnabled = YES;
            if (shouldTransite && [self.delegate respondsToSelector:@selector(navigationController:didEndTransitionContext:)]) {
                [self.delegate navigationController:self didEndTransitionContext:transitionContext];
            } else {
                [self _st_navigationController:self didEndTransitionContext:transitionContext];
            }
            
            [panFromView removeFromSuperview];
            [self.panFromViewController removeFromParentViewController];
            UIViewController *viewController = [self _unwrapViewController:self.panFromViewController];
            if ([viewController respondsToSelector:@selector(st_didPopViewControllerAnimated:)]) {
                [viewController st_didPopViewControllerAnimated:true];
            }
            [self setCustomNavigationController:nil forController:viewController];
            self.visibleWrapperViewController = self.panTargetViewController;
            if (completionHandler) {
                completionHandler(finished);
            }
        }];
}

- (void)_rollbackPopViewControllerAnimated:(BOOL)animated shouldTransite:(BOOL)shouldTransite targetOriginX:(CGFloat)targetX completion:(void (^)(BOOL finished))completionHandler {
    UIView *panFromView = self.panFromViewController.view;
    UIView *panTargetView = self.panTargetViewController.view;

    CGFloat completion = targetX / CGRectGetWidth(self.transitionView.bounds);
    CGFloat duration = STTransitionViewControllerAnimationDuration * (completion);
    if (duration > STTransitionViewControllerAnimationDuration) {
        duration = 0.1;
    }
    [UIView animateWithDuration:duration
        delay:0
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
            STNavigationControllerTransitionContext *transitionContext = [[STNavigationControllerTransitionContext alloc] init];
            transitionContext->_st_fromViewController = [self _unwrapViewController:self.panFromViewController];
            transitionContext->_st_toViewController = [self _unwrapViewController:self.panTargetViewController];
            transitionContext->_st_fromView = panFromView;
            transitionContext->_st_toView = panTargetView;
            transitionContext->_st_transitionType = STViewControllerTransitionTypePop;
            transitionContext->_st_completion = 0.0;
            transitionContext->_st_transitionView = self.transitionView;
            if (shouldTransite && [self.delegate respondsToSelector:@selector(navigationController:transitingWithContext:)]) {
                [self.delegate navigationController:self transitingWithContext:transitionContext];
            } else {
                [self _st_navigationController:self transitingWithContext:transitionContext];
            }

        }
        completion:^(BOOL finished) {
            STNavigationControllerTransitionContext *transitionContext = [[STNavigationControllerTransitionContext alloc] init];
            transitionContext->_st_fromViewController = [self _unwrapViewController:self.panFromViewController];
            transitionContext->_st_toViewController = [self _unwrapViewController:self.panTargetViewController];
            transitionContext->_st_fromView = panFromView;
            transitionContext->_st_toView = panTargetView;
            transitionContext->_st_transitionType = STViewControllerTransitionTypePop;
            transitionContext->_st_completion = 0.0;
            transitionContext->_st_transitionView = self.transitionView;
            panFromView.userInteractionEnabled = YES;
            panTargetView.userInteractionEnabled = YES;
            if (shouldTransite && [self.delegate respondsToSelector:@selector(navigationController:didEndTransitionContext:)]) {
                [self.delegate navigationController:self didEndTransitionContext:transitionContext];
            } else {
                [self _st_navigationController:self didEndTransitionContext:transitionContext];
            }

            [panTargetView removeFromSuperview];
            [_viewControllers addObject:self.popedViewController];
            [self setCustomNavigationController:self forController:self.popedViewController];
            [self.panFromViewController removeFromParentViewController];
            [self addChildViewController:self.panFromViewController];
            [self.panFromViewController didMoveToParentViewController:self];

            UIViewController *toViewController = self.popedViewController;
            NSString *key = [NSString stringWithFormat:@"%llu", (unsigned long long)toViewController.hash];
            [self.wrapperControllerDictionary setObject:self.panFromViewController forKey:key];

            self.visibleWrapperViewController = self.panFromViewController;

            if (completionHandler) {
                completionHandler(finished);
            }
        }];
}

#pragma mark -STDefaultNavigationControllerAnimation

- (BOOL)shouldBeginTransitionContext:(STNavigationControllerTransitionContext *)context {
    if ([self.delegate respondsToSelector:@selector(navigationController:shouldBeginTransitionContext:)]) {
        return [self.delegate navigationController:self shouldBeginTransitionContext:context];
    }
    return YES;
}

- (void)_st_transitionWithContext:(STNavigationControllerTransitionContext *)transitionContext {
    STViewControllerTransitionType type = transitionContext.transitionType;
    CGFloat completion = transitionContext.completion;
    UIViewController *fromViewController = transitionContext.fromViewController, *targetViewController = transitionContext.toViewController;
    UIView *fromView = transitionContext.fromView, *targetView = transitionContext.toView;
    CGRect fromViewFrame = fromView.frame, toViewFrame = targetView.frame, maskViewFrame = self.animationMaskView.frame;
    CGFloat maskViewAlpha = 0.0;
    if (type == STViewControllerTransitionTypePop) {
        CGFloat panOffset = MAX(MIN(fromViewController.st_interactivePopTransitionOffset, CGRectGetWidth(self.transitionView.bounds)), 0);
        fromViewFrame.origin.x = completion * CGRectGetWidth(self.transitionView.bounds);
        toViewFrame.origin.x = -panOffset + completion * panOffset;
        maskViewFrame.origin.x = CGRectGetMinX(fromViewFrame) - CGRectGetWidth(maskViewFrame);
        maskViewAlpha = self.maximumPopAnimationMaskAlpha - self.maximumPopAnimationMaskAlpha * completion;
    } else {
        CGFloat panOffset = MAX(MIN(targetViewController.st_interactivePopTransitionOffset, CGRectGetWidth(self.transitionView.bounds)), 0);
        fromViewFrame.origin.x = -panOffset + (1.0 - completion) *panOffset;
        
        toViewFrame.origin.x = (1.0-completion) *CGRectGetWidth(self.transitionView.bounds);
        maskViewFrame.origin.x = CGRectGetMinX(toViewFrame) - CGRectGetWidth(maskViewFrame);
        maskViewAlpha = self.maximumPopAnimationMaskAlpha - self.maximumPopAnimationMaskAlpha * (1.0 - completion);
    }
    
    fromView.frame = fromViewFrame;
    targetView.frame = toViewFrame;
    self.animationMaskView.frame = maskViewFrame;
    self.animationMaskView.height = self.transitionView.height;
    self.animationMaskView.alphaView.alpha = maskViewAlpha;
}

- (void)_st_navigationController:(STNavigationController *)navigationController willBeginTransitionContext:(STNavigationControllerTransitionContext *)transitionContext {
    [self.animationMaskView removeFromSuperview];
    [self.view insertSubview:self.animationMaskView aboveSubview:self.transitionView];
    self.animationMaskView.alphaView.alpha = 0.0;
    transitionContext->_st_completion = 0;
    transitionContext->_st_transitionView = self.transitionView;
    [self _st_transitionWithContext:transitionContext];
}

- (void)_st_navigationController:(STNavigationController *)navigationController transitingWithContext:(STNavigationControllerTransitionContext *)transitionContext {
    [self _st_transitionWithContext:transitionContext];
   
}

- (void)_st_navigationController:(STNavigationController *)navigationController didEndTransitionContext:(STNavigationControllerTransitionContext *)transitionContext {
    [self _st_transitionWithContext:transitionContext];
    [self.animationMaskView removeFromSuperview];
    self.animationMaskView.alphaView.alpha = 0.0;
}

#pragma mark - Private Method

#pragma mark - PushAndPopLayoutUpdate
- (void)_setNeedTransitionToViewController:(UIViewController *)toViewController
                            transitionType:(STViewControllerTransitionType)transitionType
                                transition:(void (^)(void))transition
                                completion:(void (^)(BOOL))completion {
    
    if (!_updatingVisibleController) {
        __weak STNavigationController *weakSelf = self;
        if (self.animating || self.operationQueue.count > 0) {
            [self.operationQueue addObject:[NSBlockOperation blockOperationWithBlock:^{
                [weakSelf _transitionToViewController:toViewController
                                             duration:STTransitionViewControllerAnimationDuration
                                       transitionType:transitionType
                                           transition:transition
                                           completion:completion];
            }]];
        } else {
            [weakSelf _transitionToViewController:toViewController
                                         duration:STTransitionViewControllerAnimationDuration
                                   transitionType:transitionType
                                       transition:transition
                                       completion:completion];
        }
    }
}

- (void)_transitionToViewController:(UIViewController *)toWrapperViewController
                           duration:(NSTimeInterval)duration
                     transitionType:(STViewControllerTransitionType)transitionType
                         transition:(void (^)(void))transition
                         completion:(void (^)(BOOL))completion {
    
    _updatingVisibleController = NO;
    if (self.visibleWrapperViewController == toWrapperViewController) {
        return;
    }
    if (transition) {
        transition();
    }
    self.animating = YES;
    
    UIViewController *fromWrapperViewController = self.visibleWrapperViewController;
    UIViewController *fromViewController = [self _unwrapViewController:fromWrapperViewController], *toViewController = [self _unwrapViewController:toWrapperViewController];
    UIView *fromView = [self _wrapperViewForController:fromWrapperViewController], *toView = [self _wrapperViewForController:toWrapperViewController];
    
    STNavigationControllerTransitionContext *transitionContext = [[STNavigationControllerTransitionContext alloc] init];
    transitionContext->_st_fromViewController = fromViewController;
    transitionContext->_st_toViewController = toViewController;
    transitionContext->_st_fromView = fromView;
    transitionContext->_st_toView = toView;
    transitionContext->_st_transitionType = transitionType;
    transitionContext->_st_completion = 0.0;
    transitionContext->_st_transitionView = self.transitionView;
    BOOL shouldBeginTransite = [self shouldBeginTransitionContext:transitionContext];
    if (shouldBeginTransite && [self.delegate respondsToSelector:@selector(navigationController:willBeginTransitionContext:)]) {
        [self.delegate navigationController:self willBeginTransitionContext:transitionContext];
    } else {
        [self _st_navigationController:self willBeginTransitionContext:transitionContext];
    }
    
    void (^animations)(void) = ^{
        STNavigationControllerTransitionContext *transitionContext = [[STNavigationControllerTransitionContext alloc] init];
        transitionContext->_st_fromViewController = fromViewController;
        transitionContext->_st_toViewController = toViewController;
        transitionContext->_st_fromView = fromView;
        transitionContext->_st_toView = toView;
        transitionContext->_st_transitionType = transitionType;
        transitionContext->_st_completion = 1.0;
        transitionContext->_st_transitionView = self.transitionView;
        if (shouldBeginTransite && [self.delegate respondsToSelector:@selector(navigationController:transitingWithContext:)]) {
            [self.delegate navigationController:self transitingWithContext:transitionContext];
        } else {
            [self _st_navigationController:self transitingWithContext:transitionContext];
        }
    };
    
    void (^animationCompletion)(BOOL) = ^(BOOL finished) {
        self.animating = NO;
        STNavigationControllerTransitionContext *transitionContext = [[STNavigationControllerTransitionContext alloc] init];
        transitionContext->_st_fromViewController = fromViewController;
        transitionContext->_st_toViewController = toViewController;
        transitionContext->_st_fromView = fromView;
        transitionContext->_st_toView = toView;
        transitionContext->_st_transitionType = transitionType;
        transitionContext->_st_completion = 1.0;
        transitionContext->_st_transitionView = self.transitionView;
        if (shouldBeginTransite && [self.delegate respondsToSelector:@selector(navigationController:didEndTransitionContext:)]) {
            [self.delegate navigationController:self didEndTransitionContext:transitionContext];
        } else {
            [self _st_navigationController:self didEndTransitionContext:transitionContext];
        }
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        self.visibleWrapperViewController = toWrapperViewController;
        if (completion) {
            completion(finished);
        }
        if (self.operationQueue.count > 0) {
            NSBlockOperation *operation = [self.operationQueue objectAtIndex:0];
            [self.operationQueue removeObjectAtIndex:0];
            [operation start];
        }
    };
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:animations completion:animationCompletion];
}


- (_STAnimationMaskView *)animationMaskView {
    if (!_animationMaskView) {
        _animationMaskView = [_STAnimationMaskView animationMaskView];
        _animationMaskView.shadow = self.shadow;
    }
    return _animationMaskView;
}

- (STNavigationBar *)navigationBar {
    if (!_navigationBar) {
        _navigationBar = [[STNavigationBar alloc] init];
    }
    return _navigationBar;
}


- (UIView *)_wrapperViewForController:(UIViewController *)viewController {
    UIView *view = viewController.view;
    view.frame = self.transitionView.bounds;
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.clipsToBounds = YES;
    return view;
}

- (BOOL)_shouldWrapViewController:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[_STWrapperViewController class]]) {
        return NO;
    }
    return YES;
}

- (UIViewController *)_wrapperViewController:(UIViewController *)viewController {
    if (!viewController) {
        return nil;
    }
    UIViewController *wrapperViewController = viewController;
    NSString *key = [NSString stringWithFormat:@"%llu", (unsigned long long)viewController.hash];
    if (![viewController isKindOfClass:[_STWrapperViewController class]]) {
        if ([self.wrapperControllerDictionary objectForKey:key]) {
            wrapperViewController = [self.wrapperControllerDictionary objectForKey:key];
        } else {
            if ([self _shouldWrapViewController:viewController]) {
                _STWrapperViewController *toolBarController = [[_STWrapperViewController alloc] initWithRootViewController:viewController];
                [self.wrapperControllerDictionary setObject:toolBarController forKey:key];
                wrapperViewController = toolBarController;
            }
        }
    }
    return wrapperViewController;
}

- (UIViewController *)_unwrapViewController:(UIViewController *)viewController {
    if (!viewController) {
        return nil;
    }
    if ([viewController isKindOfClass:[_STWrapperViewController class]]) {
        return ((_STWrapperViewController *)viewController).rootViewController;
    }
    return viewController;
}

#pragma mark - AutoRotate
- (BOOL)shouldAutorotate {
    return self.topViewController.shouldAutorotate;
}

- (UIView *)_keyboardFromViewController:(UIViewController *)viewController {
    UIResponder *firstResponder = viewController.view.st_findFirstResponder;
    if ([firstResponder respondsToSelector:@selector(setInputAccessoryView:)] && !firstResponder.inputAccessoryView) {
        [firstResponder performSelector:@selector(setInputAccessoryView:) withObject:UIView.new];
        [firstResponder reloadInputViews];
    }
    UIView *keyboard = firstResponder.inputAccessoryView.superview;
    return keyboard;
}

- (void)_addKeyboardViewToController:(UIViewController *)viewController {
    /// 如果已经有了keyboardview
    if (![UIView instancesRespondToSelector:@selector(snapshotViewAfterScreenUpdates:)] || viewController.keyboardView) {
        return;
    }
    UIView *keyboard = [self _keyboardFromViewController:viewController];
    UIView *keyboardView = [keyboard snapshotViewAfterScreenUpdates:NO];
    keyboardView.userInteractionEnabled = NO;
    keyboardView.frame = keyboard.frame;
    [viewController.view addSubview:keyboardView];
    viewController.keyboardSnapshotView = keyboardView;
    viewController.keyboardView = keyboard;
    keyboard.hidden = YES;
}

- (void)_removeKeyboardViewFromController:(UIViewController *)viewController {
    [viewController.keyboardSnapshotView removeFromSuperview];
    viewController.keyboardSnapshotView = nil;
    viewController.keyboardView.hidden = NO;
    viewController.keyboardView = nil;
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
        _animationMaskView.shadow = self.shadow;
    }
}

@end

CGFloat const STTransitionViewControllerAnimationDuration = 0.35;

static NSString *const STNavigationBarKey = @"STNavigationBarKey";
static NSString *const STNavigationBarHiddenKey = @"STNavigationBarHiddenKey";
static NSString *const STNavigationControllerKey = @"STNavigationControllerKey";

static NSString *const STNavigationControllerSideOffsetKey = @"STNavigationControllerSideOffsetKey";
static NSString *const STNavigationControllerTransitionOffsetKey = @"STNavigationControllerTransitionOffsetKey";
static NSString *const STNavigationControllerTransitionTopOffsetKey = @"STNavigationControllerTransitionTopOffsetKey";

@implementation UIViewController (STNavigationController)

- (void)st_setNavigationBar:(STNavigationBar *)navigationBar {
    objc_setAssociatedObject(self, (__bridge const void *)(STNavigationBarKey), navigationBar, OBJC_ASSOCIATION_ASSIGN);
}

- (STNavigationBar *)st_navigationBar {
    return objc_getAssociatedObject(self, (__bridge const void *)(STNavigationBarKey));
}

- (BOOL)st_navigationBarHidden {
    NSNumber *hidden = objc_getAssociatedObject(self, (__bridge const void *)(STNavigationBarHiddenKey));
    return hidden.boolValue;
}


- (void)st_setNavigationBarHidden:(BOOL)navigationBarHidden {
    objc_setAssociatedObject(self, (__bridge const void *)(STNavigationBarHiddenKey), @(navigationBarHidden), OBJC_ASSOCIATION_COPY);
}

- (STNavigationController *)st_navigationController {
    return objc_getAssociatedObject(self, (__bridge const void *)(STNavigationControllerKey));
}


- (void)st_setNavigationController:(STNavigationController *)navigationController {
    objc_setAssociatedObject(self, (__bridge const void *)(STNavigationControllerKey), navigationController, OBJC_ASSOCIATION_ASSIGN);
}


- (void)st_setMaximumInteractivePopEdgeDistance:(CGFloat)maximumInteractivePopEdgeDistance {
    objc_setAssociatedObject(self, (__bridge const void *)(STNavigationControllerSideOffsetKey), @(maximumInteractivePopEdgeDistance),
                             OBJC_ASSOCIATION_COPY);
}

- (CGFloat)st_maximumInteractivePopEdgeDistance {
    NSNumber *maxNumber = objc_getAssociatedObject(self, (__bridge const void *)(STNavigationControllerSideOffsetKey));
    if (![maxNumber isKindOfClass:[NSNumber class]]) {
        return STMaximumInteractivePopEdgeDistance;
    }
    return maxNumber.floatValue;
}

- (void)st_setInteractivePopTopEdgeDistance:(CGFloat)interactivePopTopEdgeDistance {
    objc_setAssociatedObject(self, (__bridge const void *)(STNavigationControllerTransitionTopOffsetKey), @(interactivePopTopEdgeDistance),
                             OBJC_ASSOCIATION_COPY);
}

- (CGFloat)st_interactivePopTopEdgeOffset {
    NSNumber *maxNumber = objc_getAssociatedObject(self, (__bridge const void *)(STNavigationControllerTransitionTopOffsetKey));
    if (![maxNumber isKindOfClass:[NSNumber class]]) {
        return 0;
    }
    return maxNumber.floatValue;
}

- (void)st_setInteractivePopTransitionOffset:(CGFloat)interactivePopTransitionOffset {
    objc_setAssociatedObject(self, (__bridge const void *)(STNavigationControllerTransitionOffsetKey), @(ABS(interactivePopTransitionOffset)),
                             OBJC_ASSOCIATION_COPY);
}

- (CGFloat)st_interactivePopTransitionOffset {
    NSNumber *maxNumber = objc_getAssociatedObject(self, (__bridge const void *)(STNavigationControllerTransitionOffsetKey));
    if (![maxNumber isKindOfClass:[NSNumber class]]) {
        return STInteractivePopTransitionOffset;
    }
    return maxNumber.floatValue;
}
@end

CGFloat const STMaximumInteractivePopEdgeDistance = 30;
CGFloat const STInteractivePopTransitionOffset = 80;

#pragma mark - Private Implements

@implementation _STAnimationMaskView {
    UIView *_shadowView;
}

+ (_STAnimationMaskView *)animationMaskView {
    CGRect frame = [UIScreen mainScreen].bounds;
    CGFloat width = MAX(CGRectGetWidth(frame), CGRectGetHeight(frame));
    frame.size.width = width;
    frame.size.height = width;
    _STAnimationMaskView *animationView = [[_STAnimationMaskView alloc] initWithFrame:frame];
    animationView.userInteractionEnabled = NO;
    return animationView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.alphaView = [[UIView alloc] initWithFrame:self.bounds];
        self.alphaView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.alphaView.backgroundColor = [UIColor blackColor];
        [self addSubview:self.alphaView];

        CGRect frame = self.bounds;
        frame.origin.x = CGRectGetWidth(frame);
        frame.size.width = STOnePixel();
        
        UIView *shadowView = [[UIView alloc] initWithFrame:frame];
        shadowView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
        
        [self addSubview:shadowView];
        _shadowView = shadowView;
    }
    return self;
}

- (void)setShadow:(STShadow *)shadow {
    CGFloat offset = ABS(shadow.shadowOffset.width);
    CGRect pathRect = CGRectOffset(_shadowView.bounds, - offset, 0);
    pathRect.size.width += offset;
    _shadowView.layer.shadowPath = [UIBezierPath bezierPathWithRect:pathRect].CGPath;
    _shadowView.layer.shadowOpacity = shadow.shadowOpacity;
    _shadowView.layer.shadowColor = shadow.shadowColor.CGColor;
    _shadowView.layer.shadowRadius = shadow.shadowRadius;
    
    _shadow = shadow;
    
}

@end

#pragma mark - ScrollContentInset

@implementation UIScrollView (STFitIOS7)

static NSString *const STScrollViewContentInsetTop = @"com.suen.STScrollViewContentInsetTop";
static NSString *const STScrollViewContentInsetBottom = @"com.suen.STScrollViewContentInsetBottom";

- (CGFloat)st_contentInsetTopByNavigation {
    NSNumber *contentInsetTop = objc_getAssociatedObject(self, (__bridge const void *)(STScrollViewContentInsetTop));
    return contentInsetTop.floatValue;
}

- (void)st_setContentInsetTopByNavigation:(CGFloat)contentInsetTop {
    objc_setAssociatedObject(self, (__bridge const void *)(STScrollViewContentInsetTop), @(contentInsetTop), OBJC_ASSOCIATION_RETAIN);
}

- (CGFloat)st_contentInsetBottomByNavigation {
    NSNumber *contentInsetTop = objc_getAssociatedObject(self, (__bridge const void *)(STScrollViewContentInsetBottom));
    return contentInsetTop.floatValue;
}

- (void)st_setContentInsetBottomByNavigation:(CGFloat)contentInsetBottom {
    objc_setAssociatedObject(self, (__bridge const void *)(STScrollViewContentInsetBottom), @(contentInsetBottom), OBJC_ASSOCIATION_RETAIN);
}

@end

@interface _STWrapperViewController () {
    BOOL _navigationAnimating;
    UIView *_st_previousTabBarSuperview;
    BOOL _requiredTabBar;
}

@property(nonatomic, strong) STNavigationBar *navigationBar;
@property(nonatomic, strong) UIViewController *rootViewController;

- (CGRect)navigationViewFrameForController:(UIViewController *)viewController;

@property(nonatomic, strong) UIView *rootView;

@end

@implementation _STWrapperViewController

- (void)dealloc {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL selector = NSSelectorFromString(@"st_setSuperView:");
    [self.rootViewController st_performSelector:selector withObjects:nil, nil];
#pragma clang diagnostic pop
    self.rootViewController.st_wrapperViewController = nil;
    self.rootViewController.navigationItem.changedHandler = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.rootViewController = rootViewController;
        self.st_navigationBarHidden = rootViewController.st_navigationBarHidden;
        self.rootViewController.st_wrapperViewController = self;
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [self initWithRootViewController:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL selector = NSSelectorFromString(@"st_setNavigationBar:");
    if ([self.rootViewController respondsToSelector:selector]) {
        [self.rootViewController performSelector:selector withObject:self.navigationBar];
    }
    SEL selector1 = NSSelectorFromString(@"st_setSuperView:");
    [self.rootViewController st_performSelector:selector1 withObjects:self.view, nil];
#pragma clang diagnostic pop
    self.navigationBar.barTintColor = self.rootViewController.st_navigationController.navigationBar.barTintColor;
    
    self.view.backgroundColor = [UIColor clearColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.rootView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.rootView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.rootView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.rootView];
    
    if (self.rootViewController.view) {
        [self addChildViewController:self.rootViewController];
        self.rootViewController.view.frame = self.rootView.bounds;
        self.rootViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.rootView addSubview:self.rootViewController.view];
        [self.rootViewController didMoveToParentViewController:self];
    }
    [self.view bringSubviewToFront:self.navigationBar];
    
    {
        STNavigationController *navigationController = self.rootViewController.st_navigationController;
        UINavigationItem *navigationItem = self.rootViewController.navigationItem;
        UIBarButtonItem *leftBarButtonItem = navigationItem.leftBarButtonItem;
        if (navigationController.viewControllers.count > 1 && !leftBarButtonItem &&
            (navigationController.viewControllers[0] != self.rootViewController) && ![self.rootViewController isKindOfClass:[STViewController class]] && !navigationItem.hidesBackButton) {
            navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonCustomItem:STBarButtonCustomItemBack
                                                                                             target:self
                                                                                             action:@selector(backRootViewControllerAnimated:)];
        }
        
        NSDictionary *titleTextAttributes = self.navigationBar.titleTextAttributes;
        if (!titleTextAttributes) {
            titleTextAttributes = navigationController.navigationBar.titleTextAttributes;
        }
        self.navigationBar.titleTextAttributes = titleTextAttributes;
        
        UIImage *backgroundImage = self.navigationBar.backgroundImage;
        if (!backgroundImage) {
            backgroundImage = navigationController.navigationBar.backgroundImage;
        }
        self.navigationBar.backgroundImage = backgroundImage;
        self.navigationBar.hidden = self.rootViewController.st_navigationBarHidden;
    }
    
    [self updateNavigationViewIfNeeded];
    UIViewController *basedViewController = self.rootViewController.st_navigationController;
    if (!basedViewController) {
        basedViewController = self.rootViewController.st_tabBarController;
    }
    if ([UIViewController instancesRespondToSelector:@selector(traitCollection)]) {
        [self customLayoutSubviewsWithTraitCollection:basedViewController.traitCollection];
    } else {
        [self customLayoutSubviewsWithTraitCollection:nil];
    }
    
    __weak _STWrapperViewController *weakSelf = self;
    self.rootViewController.navigationItem.changedHandler = ^() {
        [weakSelf updateNavigationViewIfNeeded];
    };
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarDidChangeNotification) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
}

- (STNavigationBar *)navigationBar {
    if (!self.rootViewController.st_navigationController) {
        return nil;
    }
    if (!_navigationBar) {
        _navigationBar = [[STNavigationBar alloc] initWithFrame:[self navigationViewFrameForController:self.rootViewController]];
        [self.view addSubview:_navigationBar];
    }
    return _navigationBar;
}

- (void)statusBarDidChangeNotification {
    [self.view setNeedsLayout];
    if ([UIViewController instancesRespondToSelector:@selector(traitCollection)]) {
        [self customLayoutSubviewsWithTraitCollection:self.traitCollection];
    } else {
        [self customLayoutSubviewsWithTraitCollection:nil];
    }
}

- (void)updateNavigationViewIfNeeded {
    if (!_navigationBar) {
        return;
    }
    UINavigationItem *navigationItem = self.rootViewController.navigationItem;
    UIBarButtonItem *leftBarButtonItem = navigationItem.leftBarButtonItem;
    self.navigationBar.translucent = (self.rootViewController.edgesForExtendedLayout & UIRectEdgeTop);
    UIView *leftBarView = [leftBarButtonItem st_customView];
    self.navigationBar.leftBarView = leftBarView;
    self.navigationBar.title = navigationItem.title;
    if (navigationItem.titleView) {
        self.navigationBar.titleView = navigationItem.titleView;
    }
    UIView *rightBarView = [navigationItem.rightBarButtonItem st_customView];
    self.navigationBar.rightBarView = rightBarView;
    BOOL leftConstructUsingSTKit = NO, rightConstructUsingSTKit = NO;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL selector = NSSelectorFromString(@"st_constructUsingSTKit");
    id returnValue0 = [navigationItem.leftBarButtonItem st_performSelector:selector withObjects:nil, nil] ;
    if ([returnValue0 respondsToSelector:@selector(boolValue)]) {
        leftConstructUsingSTKit = [returnValue0 boolValue];
    }
    id returnValue1 = [navigationItem.rightBarButtonItem st_performSelector:selector withObjects:nil, nil];
    if ([returnValue1 respondsToSelector:@selector(boolValue)]) {
        rightConstructUsingSTKit = [returnValue1 boolValue];
    }
#pragma clang diagnostic pop
    NSInteger flags = 0;
    if (leftConstructUsingSTKit) {
        flags |= 1;
    }
    if (rightConstructUsingSTKit) {
        flags |= (1 << 1);
    }
    [self.navigationBar st_setValue:@(flags) forVar:@"_tintFlags"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL selector1 = NSSelectorFromString(@"_retintItems");
    [self.navigationBar st_performSelector:selector1 withObjects:nil, nil];
#pragma clang diagnostic pop
    
}

- (void)backRootViewControllerAnimated:(id)sender {
    [self.rootViewController.st_navigationController popViewControllerAnimated:YES];
}

- (CGRect)navigationViewFrameForTraitCollection:(UITraitCollection *)traitCollection {
    CGRect rect = CGRectZero;
    rect.size.width = CGRectGetWidth(self.view.frame);
    CGFloat height = 64 - 20 *[UIApplication sharedApplication].statusBarHidden;
    if (STGetSystemVersion() >= 8) {
        if (traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
            height = 44;
        }
    } else {
        height = 64;
    }
    rect.origin.y = self.rootViewController.st_navigationBarOffset;
    rect.size.height = height - (height * self.st_navigationBarHidden);
    return rect;
}

- (CGRect)navigationViewFrameForController:(UIViewController *)viewController {
    CGRect rect = CGRectZero;
    rect.size.width = CGRectGetWidth(self.view.frame);
    CGFloat height = 64;
    rect.origin.y = self.rootViewController.st_navigationBarOffset;
    rect.size.height = height - (height * self.st_navigationBarHidden);
    return rect;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect frame = self.view.frame;
    frame.origin.y = 0;
    self.view.frame = frame;
    if ([UIViewController instancesRespondToSelector:@selector(traitCollection)]) {
        [self customLayoutSubviewsWithTraitCollection:self.traitCollection];
    } else {
        [self customLayoutSubviewsWithTraitCollection:nil];
    }
}

- (void)customLayoutSubviewsWithTraitCollection:(UITraitCollection *)traitCollection {
    if (STGetSystemVersion() >= 8) {
        self.navigationBar.frame = [self navigationViewFrameForTraitCollection:traitCollection];
    } else {
        self.navigationBar.frame = [self navigationViewFrameForController:self.rootViewController];
    }
    [self fitsIOS7EdgeExtendedLayout];
}

- (void)fitsIOS7EdgeExtendedLayout {
    UIRectEdge edge = self.rootViewController.edgesForExtendedLayout;
    BOOL topExtended = !!(edge & UIRectEdgeTop);
    /// TODO:待优化。 navigationBar不透明会出发off-screen渲染，这里可以优化以减少off-screen渲染。
//    if (!topExtended && !self.navigationBar.translucent) {
//        self.navigationBar.translucent = NO;
//    }
    BOOL bottomExtended = !!(edge & UIRectEdgeBottom);
    CGFloat top = 0, height = CGRectGetHeight(self.view.bounds);
    top = (!topExtended) * (!self.st_navigationBarHidden) * CGRectGetMaxY(self.navigationBar.frame);
    height -= top;
    if ((self.rootViewController.tabBarController || self.rootViewController.st_tabBarController) &&
        !self.rootViewController.hidesBottomBarWhenPushed) {
        height -= self.rootViewController.st_tabBarController.actualTabBarHeight * (!bottomExtended);
    }
    CGRect frame = self.rootViewController.view.frame;
    frame.origin.y = top;
    frame.size.height = height;
    self.rootView.frame = frame;

    BOOL adjustScrollView = NO;
    if ([self.rootViewController respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
        adjustScrollView = self.rootViewController.automaticallyAdjustsScrollViewInsets;
    }
    if (!adjustScrollView) {
        return;
    }
    if (topExtended) {
         [self fitTopChildScrollViewEdgeInsets];
    }
    if (bottomExtended && (self.rootViewController.tabBarController || self.rootViewController.st_tabBarController) &&
        !self.rootViewController.hidesBottomBarWhenPushed) {
         [self fitBottomChildScrollViewEdgeInsets];
    }
}

- (void)fitTopChildScrollViewEdgeInsets {
    UIView *navigationBar = self.navigationBar;
    if (self.st_navigationBarHidden) {
        navigationBar = nil;
    }
    NSArray *array = [self intersectChildScrollViewWithView:navigationBar];
    for (UIScrollView *scrollView in array) {
        UIEdgeInsets contentInset = scrollView.contentInset;
        CGFloat topInset = CGRectGetHeight(self.navigationBar.frame);
        if (STGetSystemVersion() >= 7) {
            BOOL includesQpaqueBar = self.rootViewController.extendedLayoutIncludesOpaqueBars;
            if (includesQpaqueBar) {
                topInset -= 20;
            }
        }
        if (!CGRectIsEmpty(scrollView.frame)) {
            contentInset.top = (contentInset.top - [scrollView st_contentInsetTopByNavigation] + topInset);
            scrollView.contentInset = contentInset;
            scrollView.scrollIndicatorInsets = contentInset;
            if ([scrollView st_contentInsetTopByNavigation] == 0 && topInset != 0) {
                if (scrollView.contentOffset.y <= -contentInset.top) {
                    scrollView.contentOffset = CGPointMake(0, -contentInset.top);
                }
            }
            [scrollView st_setContentInsetTopByNavigation:topInset];
        }
    }
}

- (void)fitBottomChildScrollViewEdgeInsets {
    if (!(self.rootViewController.st_tabBarController || self.rootViewController.tabBarController)) {
        return;
    }
    UIView *tabBar = self.rootViewController.st_tabBarController.tabBar;
    NSArray *array = [self intersectChildScrollViewWithView:tabBar];
    for (UIScrollView *scrollView in array) {
        UIEdgeInsets insets = scrollView.contentInset;
        insets.bottom = (insets.bottom - [scrollView st_contentInsetBottomByNavigation] + self.rootViewController.st_tabBarController.actualTabBarHeight);
        scrollView.contentInset = insets;
        scrollView.scrollIndicatorInsets = insets;
        [scrollView st_setContentInsetBottomByNavigation:self.rootViewController.st_tabBarController.actualTabBarHeight];
    }
}

- (void)addChildScrollViewFromView:(UIView *)view intersectView:(UIView *)intersectView toArray:(NSMutableArray *)array {
    CGRect viewFrame = [intersectView.superview convertRect:intersectView.frame toView:nil];
    viewFrame.origin.x = 0;
    for (UIView *subview in view.subviews) {
        CGRect frame = [view convertRect:subview.frame toView:nil];
        frame.origin.x = 0;
        if (CGRectIntersectsRect(viewFrame, frame)) {
            if ([subview isKindOfClass:[UIScrollView class]]) {
                [array addObject:subview];
            } else {
                [self addChildScrollViewFromView:subview intersectView:intersectView toArray:array];
            }
        } else {
            [self resetUnsedContentInsetInView:subview];
        }
    }
}

- (void)resetUnsedContentInsetInView:(UIView *)view {
    if ([view isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)view;
        UIEdgeInsets contentInset = scrollView.contentInset;
        contentInset.top -= [scrollView st_contentInsetTopByNavigation];
        contentInset.bottom -= [scrollView st_contentInsetBottomByNavigation];
        scrollView.contentInset = contentInset;
        scrollView.scrollIndicatorInsets = scrollView.contentInset;
        [scrollView st_setContentInsetTopByNavigation:0];
        [scrollView st_setContentInsetBottomByNavigation:0];
    } else {
        for (UIView *subview in view.subviews) {
            [self resetUnsedContentInsetInView:subview];
        }
    }
}

- (NSArray *)intersectChildScrollViewWithView:(UIView *)view {
    NSMutableArray *scrollViews = [NSMutableArray arrayWithCapacity:1];
    UIView *containerView = self.rootView;
    if ([containerView isKindOfClass:[UIScrollView class]]) {
        CGRect frame = [view.superview convertRect:view.frame toView:nil];
        CGRect viewFrame = [containerView.superview convertRect:containerView.frame toView:nil];
        if (CGRectIntersectsRect(viewFrame, frame)) {
            [scrollViews addObject:containerView];
        } else {
            UIScrollView *scrollView = (UIScrollView *)containerView;
            UIEdgeInsets contentInset = scrollView.contentInset;
            contentInset.top -= [scrollView st_contentInsetTopByNavigation];
            contentInset.bottom -= [scrollView st_contentInsetBottomByNavigation];
            scrollView.contentInset = contentInset;
            scrollView.scrollIndicatorInsets = contentInset;
            [scrollView st_setContentInsetTopByNavigation:0];
            [scrollView st_setContentInsetBottomByNavigation:0];
        }
    } else {
        [self addChildScrollViewFromView:containerView intersectView:view toArray:scrollViews];
    }
    return scrollViews;
}

- (void)setNavigationBarHidden:(BOOL)navigationBarHidden animated:(BOOL)animated customAnimations:(void (^)(void))customAnimations {
    UIView *navigationBar = self.navigationBar;
    if (_navigationAnimating || !navigationBar) {
        return;
    }
    _navigationAnimating = YES;
    self.st_navigationBarHidden = navigationBarHidden;
    if (!navigationBarHidden) {
        self.navigationBar.hidden = NO;
    }

    void (^animations)(void) = ^{
        if (navigationBarHidden && customAnimations) {
            customAnimations();
        }
        if ([UIViewController instancesRespondToSelector:@selector(traitCollection)]) {
            [self customLayoutSubviewsWithTraitCollection:self.traitCollection];
        } else {
            [self customLayoutSubviewsWithTraitCollection:nil];
        }
        if (!navigationBarHidden && customAnimations) {
            customAnimations();
        }
    };

    void (^completion)(BOOL) = ^(BOOL finished) {
        _navigationAnimating = NO;
        self.navigationBar.hidden = navigationBarHidden;
        self.rootViewController.st_navigationBarHidden = navigationBarHidden;
    };
    if (animated) {
        [UIView animateWithDuration:0.25 animations:animations completion:completion];
    } else {
        animations();
        completion(YES);
    }
}

- (BOOL)prefersStatusBarHidden {
    return self.rootViewController.prefersStatusBarHidden;
}

- (CGFloat)interactivePopTransitionOffset {
    return self.rootViewController.st_interactivePopTransitionOffset;
}

- (BOOL)hidesBottomBarWhenPushed {
    return self.rootViewController.hidesBottomBarWhenPushed;
}

/// 以下两个方法非常私有，谨慎使用
- (BOOL)_st_requireCustomTabBar {
    if (self.rootViewController.st_tabBarController) {
        if (self.rootViewController.hidesBottomBarWhenPushed) {
            return NO;
        }
        _requiredTabBar = YES;
        UIView *tabBar = (UIView *)self.rootViewController.st_tabBarController.tabBar;
        _st_previousTabBarSuperview = tabBar.superview;
        [tabBar removeFromSuperview];
        [self.view insertSubview:tabBar aboveSubview:self.rootView];

        CGRect frame = tabBar.frame;
        frame.origin.y = CGRectGetHeight(self.view.bounds) - CGRectGetHeight(frame);
        tabBar.frame = frame;
        return YES;
    }
    return NO;
}

- (BOOL)_st_resignCustomTabBar {
    _requiredTabBar = NO;
    if (self.rootViewController.st_tabBarController && _st_previousTabBarSuperview) {
        if (self.rootViewController.hidesBottomBarWhenPushed) {
            return NO;
        }
        UIView *tabBar = (UIView *)self.rootViewController.st_tabBarController.tabBar;
        if (tabBar.superview == _st_previousTabBarSuperview) {
            return YES;
        }
        [tabBar removeFromSuperview];
        [_st_previousTabBarSuperview addSubview:tabBar];
        CGRect frame = tabBar.frame;
        frame.origin.y = CGRectGetHeight(_st_previousTabBarSuperview.bounds) - CGRectGetHeight(frame);
        tabBar.frame = frame;
        return YES;
    }
    return NO;
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    self.rootViewController.st_navigationBarOffset = 0;
    [self customLayoutSubviewsWithTraitCollection:newCollection];
}

@end

@implementation UIViewController (STNavigationCallback)

- (void)st_didPopViewControllerAnimated:(BOOL)animated {
    
}

@end

@implementation UIViewController (STNavigationScreenView)

static char *const STViewControllerSuperview = "STViewControllerSuperview";

- (UIView *)st_superview {
    if (!self.isViewLoaded) {
        return nil;
    }
    UIView *associatedView = objc_getAssociatedObject(self, STViewControllerSuperview);
    if (!associatedView) {
        return self.view.superview;
    }
    return associatedView;
}

- (void)st_setSuperView:(UIView *)superview {
    objc_setAssociatedObject(self, STViewControllerSuperview, superview, OBJC_ASSOCIATION_ASSIGN);
}

@end

@implementation UIViewController (STNavigationBarVisiblity)

- (void)st_setNavigationBarHidden:(BOOL)st_navigationBarHidden animated:(BOOL)animated {
    if ([self.st_wrapperViewController isKindOfClass:[_STWrapperViewController class]]) {
        [self.st_wrapperViewController setNavigationBarHidden:st_navigationBarHidden animated:animated customAnimations:nil];
    }
}

- (void)st_setNavigationBarHidden:(BOOL)st_navigationBarHidden animated:(BOOL)animated alongWithAnimations:(void(^)(void))animations {
    if ([self.st_wrapperViewController isKindOfClass:[_STWrapperViewController class]]) {
        [self.st_wrapperViewController setNavigationBarHidden:st_navigationBarHidden animated:animated customAnimations:animations];
    }
}

- (void)st_updateDisplayContext {
    [self.st_wrapperViewController fitsIOS7EdgeExtendedLayout];
}


static char *const STNavigationBarOffset = "STNavigationBarOffset";

- (CGFloat)st_navigationBarOffset {
    NSNumber *offsetValue = objc_getAssociatedObject(self, STNavigationBarOffset);
    if (![offsetValue isKindOfClass:[NSNumber class]]) {
        return 0;
    }
    return offsetValue.floatValue;
}

- (void)st_setNavigationBarOffset:(CGFloat)offset {
    objc_setAssociatedObject(self, STNavigationBarOffset, @(offset), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end