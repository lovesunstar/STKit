//
//  UIKit+STKit.m
//  STKit
//
//  Created by SunJiangting on 13-10-5.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import "UIKit+STKit.h"
#import <QuartzCore/QuartzCore.h>
#import <Accelerate/Accelerate.h>
#import <ImageIO/ImageIO.h>
#import <objc/runtime.h>

CGFloat STOnePixel() {
    return 1.0 / [UIScreen mainScreen].scale;
}

CGFloat STGetScreenWidth() {
    return CGRectGetWidth([UIScreen mainScreen].bounds);
}

CGFloat STGetScreenHeight() {
    return CGRectGetHeight([UIScreen mainScreen].bounds);
}


CGAffineTransform STTransformMakeRotation(CGPoint center, CGPoint anchorPoint, CGFloat angle) {
    CGFloat x = anchorPoint.x - center.x;
    CGFloat y = anchorPoint.y - center.y;
    CGAffineTransform  transform = CGAffineTransformMakeTranslation(x, y);
    transform = CGAffineTransformRotate(transform, angle);
    return CGAffineTransformTranslate(transform, -x, -y);
}

CGFloat STGetSystemVersion() {
    return [UIDevice currentDevice].systemVersion.floatValue;
}

NSString *STGetSystemVersionString() {
    return [UIDevice currentDevice].systemVersion;
}

CGPoint STConvertPointBetweenSize(CGPoint point, CGSize fromSize, CGSize toSize) {
    if (fromSize.width * fromSize.height == 0) {
        return CGPointZero;
    }
    return CGPointMake((point.x * toSize.width) / fromSize.width, (point.y * toSize.height) / fromSize.height);
}

CGRect STConvertFrameBetweenSize(CGRect frame, CGSize fromSize, CGSize toSize) {
    if (fromSize.width * fromSize.height == 0) {
        return CGRectZero;
    }
    CGRect targetRect;
    targetRect.origin = STConvertPointBetweenSize(frame.origin, fromSize, toSize);
    targetRect.size.width = CGRectGetWidth(frame) * toSize.width / fromSize.width;
    targetRect.size.height = CGRectGetHeight(frame) * toSize.height / fromSize.height;
    return targetRect;
}


@implementation UIColor (STExtension)
+ (UIColor *)colorWithRGB:(NSInteger)rgb {
    return [self colorWithRGB:rgb alpha:1.0];
}

+ (UIColor *)colorWithRGB:(NSInteger)rgb alpha:(CGFloat)alpha {
    return [self colorWithRed:(CGFloat)((rgb & 0xFF0000) >> 16) / 255.0
                        green:(CGFloat)((rgb & 0x00FF00) >> 8) / 255.0f
                         blue:(CGFloat)(rgb & 0x0000FF) / 255.0
                        alpha:alpha];
}

+ (UIColor *)colorWithHexString:(NSString *)hexString {
    if (![hexString isKindOfClass:[NSString class]] || hexString.length == 0) {
        return nil;
    }
    if ([hexString hasPrefix:@"0x"]) {
        hexString = [hexString substringFromIndex:2];
    }
    if ([hexString hasPrefix:@"#"]) {
        hexString = [hexString substringFromIndex:1];
    }
    static NSPredicate *_predicate;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^(([0-9a-fA-F]{3})|([0-9a-fA-F]{6,8}))$"];
    });
    if (![_predicate evaluateWithObject:hexString]) {
        return nil;
    }
    if (hexString.length == 3) {
        // 处理F12 为 FF1122
        NSString *index0 = [hexString substringWithRange:NSMakeRange(0, 1)];
        NSString *index1 = [hexString substringWithRange:NSMakeRange(1, 1)];
        NSString *index2 = [hexString substringWithRange:NSMakeRange(2, 1)];
        hexString = [NSString stringWithFormat:@"%@%@%@%@%@%@", index0, index0, index1, index1, index2, index2];
    }
    unsigned int alpha = 0xFF;
    NSString *rgbString = [hexString substringToIndex:6];
    NSString *alphaString = [hexString substringFromIndex:6];
    // 存在Alpha
    if (alphaString.length > 0) {
        NSScanner *scanner = [NSScanner scannerWithString:alphaString];
        if (![scanner scanHexInt:&alpha]) {
            alpha = 0xFF;
        }
    }
    
    unsigned int rgb = 0;
    NSScanner *scanner = [NSScanner scannerWithString:rgbString];
    if (![scanner scanHexInt:&rgb]) {
        return nil;
    }
    return [self colorWithRGB:rgb alpha:alpha / 255.0];
}

+ (UIColor *)colorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha {
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    unsigned rgb = 0;
    if ([scanner scanHexInt:&rgb]) {
        return [self colorWithRGB:rgb alpha:alpha];
    }
    return [UIColor clearColor];
}
@end

#pragma mark - UIView Extension
@implementation UIView (STKit)

#pragma mark - UIView Frame Accesser

/**
 * @abstract getter CGRectGetMinY(self.frame) setter frame.origin.y = top;
 */
- (void)setTop:(CGFloat)top {
    CGRect frame = self.frame;
    frame.origin.y = top;
    self.frame = frame;
}
- (CGFloat)top {
    return CGRectGetMinY(self.frame);
}
/**
 * @abstract getter CGRectGetMaxY(self.frame) setter frame.origin.y = bottom - height;
 */
- (void)setBottom:(CGFloat)bottom {
    CGRect frame = self.frame;
    frame.origin.y = bottom - CGRectGetHeight(frame);
    self.frame = frame;
}
- (CGFloat)bottom {
    return CGRectGetMaxY(self.frame);
}
/**
 * @abstract getter CGRectGetMinX(self.frame) setter frame.origin.x = left;
 */
- (void)setLeft:(CGFloat)left {
    CGRect frame = self.frame;
    frame.origin.x = left;
    self.frame = frame;
}
- (CGFloat)left {
    return CGRectGetMinX(self.frame);
}
/**
 * @abstract getter CGRectGetMaxX(self.frame) setter frame.origin.x = right - width;
 */
- (void)setRight:(CGFloat)right {
    CGRect frame = self.frame;
    frame.origin.x = right - CGRectGetWidth(frame);
    self.frame = frame;
}
- (CGFloat)right {
    return CGRectGetMaxX(self.frame);
}
/**
 * @abstract getter CGRectGetWidth(self.frame) setter frame.size.width = width;
 */
- (void)setWidth:(CGFloat)width {
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}
- (CGFloat)width {
    return CGRectGetWidth(self.frame);
}
/**
 * @abstract getter CGRectGetHeight(self.frame) setter frame.size.height = height;
 */
- (void)setHeight:(CGFloat)height {
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}
- (CGFloat)height {
    return CGRectGetHeight(self.frame);
}
/**
 * @abstract getter frame.origin setter frame.origin = origin;
 */
- (void)setOrigin:(CGPoint)origin {
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}
- (CGPoint)origin {
    return self.frame.origin;
}
/**
 * @abstract getter frame.size setter frame.size = size;
 */
- (void)setSize:(CGSize)size {
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}
- (CGSize)size {
    return self.frame.size;
}
/**
 * @abstract getter self.center.x setter center.x = centerX;
 */
- (void)setCenterX:(CGFloat)centerX {
    CGPoint center = self.center;
    center.x = centerX;
    self.center = center;
}
- (CGFloat)centerX {
    return self.center.x;
}
/**
 * @abstract getter self.center.y setter center.y = centerY;
 */
- (void)setCenterY:(CGFloat)centerY {
    CGPoint center = self.center;
    center.y = centerY;
    self.center = center;
}
- (CGFloat)centerY {
    return self.center.y;
}
/**
 * @abstract getter CGRectGetWidth(frame) / 2
 */
- (CGFloat)inCenterX {
    return 0.5 * CGRectGetWidth(self.bounds);
}
/**
 * @abstract getter CGRectGetHeight(frame) / 2
 */
- (CGFloat)inCenterY {
    return 0.5 * CGRectGetHeight(self.bounds);
}
/**
 * @abstract getter (inCenterX, inCenterY)
 */
- (CGPoint)inCenter {
    return CGPointMake(0.5 * CGRectGetWidth(self.bounds), 0.5 * CGRectGetHeight(self.bounds));
}
/**
 * @abstract location in screen
 */
- (CGFloat)screenX {
    CGFloat x = 0;
    for (UIView *view = self; view; view = view.superview) {
        x += view.left;
    }
    return x;
}
/**
 * @abstract location in screen
 */
- (CGFloat)screenY {
    CGFloat y = 0;
    for (UIView *view = self; view; view = view.superview) {
        y += view.top;
    }
    return y;
}
/**
 * @abstract removeAllSubviews
 */
- (void)removeAllSubviews {
    while (self.subviews.count >= 1) {
        UIView *subview = self.subviews.lastObject;
        [subview removeFromSuperview];
    }
}
/**
 * @abstract view's viewController if the view has one
 */
- (UIViewController *)viewController {
    return (UIViewController *)[self nextResponderWithClass:UIViewController.class];
}

/**
 * @abstract view的parentview中，是否包含某一类的view
 *
 * @param viewClass  superview 的 class
 * @return           view是否被添加到 类型为viewClass的parentview上面
 */
- (BOOL)isDescendantOfClass : (Class)viewClass {
    if (![viewClass isSubclassOfClass:[UIView class]]) {
        return NO;
    }
    UIView *superview = self;
    while (superview) {
        if ([superview isKindOfClass:viewClass]) {
            return YES;
        }
        superview = superview.superview;
    }
    return NO;
}

/**
 * @abstract    递归查找view的superview，直到找到类型为viewClass的view
 *
 * @param viewClass  superview 的 class
 * @return           第一个满足类型为viewClass的superview
 */
- (UIView *)superviewWithClass:(Class)viewClass {
    UIView *superview = self.superview;
    while (superview) {
        if ([superview isKindOfClass:viewClass]) {
            return superview;
        }
        superview = superview.superview;
    }
    return nil;
}

/**
 * @abstract 递归遍历该view，找到该view中的所有subview类型为class的view
 *
 * @param viewClass  subview 的 class
 * @return           所有类型为class的subview
 */
- (NSArray *)viewWithClass:(Class) class {
    NSMutableArray *subviews = [NSMutableArray arrayWithCapacity:2];
    [self _subviewFromView:self ofClass:class array:subviews];
    return [subviews copy];
}
/// 私有方法，递归查找subvie类型为class的所有subview
- (void)_subviewFromView : (UIView *)view ofClass : (Class) class array : (NSMutableArray *)array {
    NSArray *subviews = view.subviews;
    [subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:class]) {
            [array addObject:obj];
        }
        [self _subviewFromView:obj ofClass:class array:array];
    }];
}

/**
 * @abstract 为该View添加轻拍手势
 *
 * @param target 接受手势通知的对象
 * @param action 回调方法
 */
- (void)addTouchTarget:(id)target action:(SEL)action {
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:target action:action];
    [self addGestureRecognizer:tapGestureRecognizer];
}

- (void)removeTouchTarget:(id)target action:(SEL)action {
    for (UIGestureRecognizer *gestureRecognizer in self.gestureRecognizers) {
        if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
            UITapGestureRecognizer *tapGestureRecognizer = (UITapGestureRecognizer *)gestureRecognizer;
            [tapGestureRecognizer removeTarget:target action:action];
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)screenViewX {
    CGFloat x = 0;
    for (UIView *view = self; view; view = view.superview) {
        x += view.left;

        if ([view isKindOfClass:[UIScrollView class]]) {
            UIScrollView *scrollView = (UIScrollView *)view;
            x -= scrollView.contentOffset.x;
        }
    }

    return x;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)screenViewY {
    CGFloat y = 0;
    for (UIView *view = self; view; view = view.superview) {
        y += view.top;

        if ([view isKindOfClass:[UIScrollView class]]) {
            UIScrollView *scrollView = (UIScrollView *)view;
            y -= scrollView.contentOffset.y;
        }
    }
    return y;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGRect)screenFrame {
    return CGRectMake(self.screenViewX, self.screenViewY, self.width, self.height);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)orientationWidth {
    return UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) ? self.height : self.width;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)orientationHeight {
    return UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) ? self.width : self.height;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGPoint)offsetFromView:(UIView *)otherView {
    CGFloat x = 0, y = 0;
    for (UIView *view = self; view && view != otherView; view = view.superview) {
        x += view.left;
        y += view.top;
    }
    return CGPointMake(x, y);
}

-(void)setAnchorPoint:(CGPoint)anchorPoint {
    CGPoint newPoint = CGPointMake(self.bounds.size.width * anchorPoint.x,
                                   self.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(self.bounds.size.width * self.layer.anchorPoint.x,
                                   self.bounds.size.height * self.layer.anchorPoint.y);
    
    newPoint = CGPointApplyAffineTransform(newPoint, self.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, self.transform);
    
    CGPoint position = self.layer.position;
    
    position.x -= oldPoint.x;
    position.x += newPoint.x;
    
    position.y -= oldPoint.y;
    position.y += newPoint.y;
    
    self.layer.position = position;
    self.layer.anchorPoint = anchorPoint;
}

- (CGPoint)anchorPoint {
    return self.layer.anchorPoint;
}

@end

@implementation UIScrollView (STKit)

- (void)setContentOffsetX:(CGFloat)contentOffsetX {
    CGPoint contentOffset = self.contentOffset;
    contentOffset.x = contentOffsetX;
    self.contentOffset = contentOffset;
}

- (CGFloat)contentOffsetX {
    return self.contentOffset.x;
}

- (void)setContentOffsetY:(CGFloat)contentOffsetY {
    CGPoint contentOffset = self.contentOffset;
    contentOffset.y = contentOffsetY;
    self.contentOffset = contentOffset;
}

- (CGFloat)contentOffsetY {
    return self.contentOffset.y;
}

- (void)setContentWidth:(CGFloat)contentWidth {
    CGSize contentSize = self.contentSize;
    contentSize.width = contentWidth;
    self.contentSize = contentSize;
}

- (CGFloat)contentWidth {
    return self.contentSize.width;
}

- (void)setContentHeight:(CGFloat)contentHeight {
    CGSize contentSize = self.contentSize;
    contentSize.height = contentHeight;
    self.contentSize = contentSize;
}

- (CGFloat)contentHeight {
    return self.contentSize.height;
}

@end

@implementation UIResponder (STResponder)


/**
 * @abstract 递归查找view的nextResponder，直到找到类型为class的Responder
 *
 * @param class  nextResponder 的 class
 * @return       第一个满足类型为class的UIResponder
 */
- (UIResponder *)nextResponderWithClass:(Class) class {
    UIResponder *nextResponder = self;
    while (nextResponder) {
        nextResponder = nextResponder.nextResponder;
        if ([nextResponder isKindOfClass:class]) {
            return nextResponder;
        }
    }
    return nil;
}

- (UIResponder *)findFirstResponder {
    if (self.isFirstResponder) {
        return self;
    }
    if ([self isKindOfClass:[UIView class]]) {
        for (UIView *subView in ((UIView *)self).subviews) {
            id responder = [subView findFirstResponder];
            if (responder) {
                return responder;
            }
        }
    }
    return nil;
}

@end

@implementation UIView (STHitTest)

const static NSString *STHitTestViewBlockKey = @"STHitTestViewBlockKey";
const static NSString *STPointInsideBlockKey = @"STPointInsideBlockKey";

+ (void)load {
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(hitTest:withEvent:)),
                                   class_getInstanceMethod(self, @selector(st_hitTest:withEvent:)));
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(pointInside:withEvent:)),
                                   class_getInstanceMethod(self, @selector(st_pointInside:withEvent:)));
}

- (UIView *)st_hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    NSMutableString *spaces = [NSMutableString stringWithCapacity:20];
    UIView *superView = self.superview;
    while (superView) {
        [spaces appendString:@"----"];
        superView = superView.superview;
    }
//    NSLog(@"%@%@:[hitTest:withEvent:]", spaces, NSStringFromClass(self.class));
    UIView *deliveredView = nil;
    // 如果有hitTestBlock的实现，则调用block
    if (self.hitTestBlock) {
        BOOL returnSuper = NO;
        deliveredView = self.hitTestBlock(point, event, &returnSuper);
        if (returnSuper) {
            deliveredView = [self st_hitTest:point withEvent:event];
        }
    } else {
        deliveredView = [self st_hitTest:point withEvent:event];
    }
//    NSLog(@"%@%@:[hitTest:withEvent:] Result:%@", spaces, NSStringFromClass(self.class), NSStringFromClass(deliveredView.class));
    return deliveredView;
}

- (BOOL)st_pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    NSMutableString *spaces = [NSMutableString stringWithCapacity:20];
    UIView *superView = self.superview;
    while (superView) {
        [spaces appendString:@"----"];
        superView = superView.superview;
    }
//    NSLog(@"%@%@:[pointInside:withEvent:]", spaces, NSStringFromClass(self.class));
    BOOL pointInside = NO;
    if (self.pointInsideBlock) {
        BOOL returnSuper = NO;
        pointInside =  self.pointInsideBlock(point, event, &returnSuper);
        if (returnSuper) {
            pointInside = [self st_pointInside:point withEvent:event];
        }
    } else {
        pointInside = [self st_pointInside:point withEvent:event];
    }
    return pointInside;
}

- (void)setHitTestBlock:(STHitTestViewBlock)hitTestBlock {
    objc_setAssociatedObject(self, (__bridge const void *)(STHitTestViewBlockKey), hitTestBlock, OBJC_ASSOCIATION_COPY);
}

- (STHitTestViewBlock)hitTestBlock {
    return objc_getAssociatedObject(self, (__bridge const void *)(STHitTestViewBlockKey));
}

- (void)setPointInsideBlock:(STPointInsideBlock)pointInsideBlock {
    objc_setAssociatedObject(self, (__bridge const void *)(STPointInsideBlockKey), pointInsideBlock, OBJC_ASSOCIATION_COPY);
}

- (STPointInsideBlock)pointInsideBlock {
    return objc_getAssociatedObject(self, (__bridge const void *)(STPointInsideBlockKey));
}

@end

const static NSString *STTextContainerMenuEnabled = @"STTextContainerMenuEnabled";

@implementation UITextField (STMenuController)

+ (void)load {
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(canPerformAction:withSender:)),
                                   class_getInstanceMethod(self, @selector(st_canPerformAction:withSender:)));
}

- (BOOL)st_canPerformAction:(SEL)action withSender:(id)sender {
    if (self.menuEnabled) {
        return [self st_canPerformAction:action withSender:sender];
    }
    return NO;
}

- (void)setMenuEnabled:(BOOL)menuEnabled {
    objc_setAssociatedObject(self, (__bridge const void *)(STTextContainerMenuEnabled), @(menuEnabled), OBJC_ASSOCIATION_COPY);
}

- (BOOL)isMenuEnabled {
    NSNumber *menuNumber = objc_getAssociatedObject(self, (__bridge const void *)(STTextContainerMenuEnabled));
    if (!menuNumber) {
        return YES;
    }
    return menuNumber.boolValue;
}

@end

@implementation UITextView (STMenuController)

+ (void)load {
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(canPerformAction:withSender:)),
                                   class_getInstanceMethod(self, @selector(st_canPerformAction:withSender:)));
}

- (BOOL)st_canPerformAction:(SEL)action withSender:(id)sender {
    if (self.menuEnabled) {
        return [self st_canPerformAction:action withSender:sender];
    }
    return NO;
}

- (void)setMenuEnabled:(BOOL)menuEnabled {
    objc_setAssociatedObject(self, (__bridge const void *)(STTextContainerMenuEnabled), @(menuEnabled), OBJC_ASSOCIATION_COPY);
}

- (BOOL)isMenuEnabled {
    NSNumber *menuNumber = objc_getAssociatedObject(self, (__bridge const void *)(STTextContainerMenuEnabled));
    if (!menuNumber) {
        return YES;
    }
    return menuNumber.boolValue;
}

@end

@implementation UIView (STSnapshot)

- (UIImage *)snapshotImage {
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, [UIScreen mainScreen].scale);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIGraphicsPopContext();
    return image;
}

- (UIImage *)snapshotImageInRect:(CGRect)rect {
    return [[self snapshotImage] subimageInRect:rect];
}

- (UIImage *)transformedSnapshotImage {
    CGAffineTransform transform = self.transform;
    UIImage *image = self.snapshotImage;
    if (CGAffineTransformIsIdentity(transform)) {
        return image;
    }
    return [image imageWithTransform:transform];
}

@end

@implementation UIView (STBlur)

- (UIImage *)blurImage {
    return [self.snapshotImage blurImageWithStyle:STBlurEffectStyleLight];
}

- (UIView *)statusBarWindow {
    UIView *statusBar = nil;
    NSData *data = [NSData dataWithBytes:(unsigned char[]) { 0x73, 0x74, 0x61, 0x74, 0x75, 0x73, 0x42, 0x61, 0x72 } length:9];
    NSString *key = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    id object = [UIApplication sharedApplication];
    if ([object respondsToSelector:NSSelectorFromString(key)]) {
        statusBar = [object valueForKey:key];
    }
    return statusBar;
}

@end

static char *const STCollectionViewWillReloadInvokeBlockKey = "STCollectionViewWillReloadInvokeBlockKey";
static char *const STCollectionViewDidReloadInvokeBlockKey = "STCollectionViewDidReloadInvokeBlockKey";

@implementation UICollectionView (STReloadData)

+ (void)load {
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(reloadData)), class_getInstanceMethod(self, @selector(st_ReloadData)));
}

- (void)setWillReloadData:(STInvokeHandler)willReloadData {
    objc_setAssociatedObject(self, STCollectionViewWillReloadInvokeBlockKey, willReloadData, OBJC_ASSOCIATION_COPY);
}

- (STInvokeHandler)willReloadData {
    return objc_getAssociatedObject(self, STCollectionViewWillReloadInvokeBlockKey);
}

- (void)setDidReloadData:(STInvokeHandler)didReloadData {
    objc_setAssociatedObject(self, STCollectionViewDidReloadInvokeBlockKey, didReloadData, OBJC_ASSOCIATION_COPY);
}

- (STInvokeHandler)didReloadData {
    return objc_getAssociatedObject(self, STCollectionViewDidReloadInvokeBlockKey);
}

- (void)st_ReloadData {
    if (self.willReloadData) {
        self.willReloadData();
    }
    [self st_ReloadData];
    if (self.didReloadData) {
        self.didReloadData();
    }
}

@end


static char *const STTableViewWillReloadInvokeBlockKey = "STCollectionViewWillReloadInvokeBlockKey";
static char *const STTableViewDidReloadInvokeBlockKey = "STCollectionViewDidReloadInvokeBlockKey";

@implementation UITableView (STReloadData)

+ (void)load {
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(reloadData)), class_getInstanceMethod(self, @selector(st_reloadData)));
}

- (void)setWillReloadData:(STInvokeHandler)willReloadData {
    objc_setAssociatedObject(self, STTableViewWillReloadInvokeBlockKey, willReloadData, OBJC_ASSOCIATION_COPY);
}

- (STInvokeHandler)willReloadData {
    return objc_getAssociatedObject(self, STTableViewWillReloadInvokeBlockKey);
}

- (void)setDidReloadData:(STInvokeHandler)didReloadData {
    objc_setAssociatedObject(self, STTableViewDidReloadInvokeBlockKey, didReloadData, OBJC_ASSOCIATION_COPY);
}

- (STInvokeHandler)didReloadData {
    return objc_getAssociatedObject(self, STTableViewDidReloadInvokeBlockKey);
}

- (void)st_reloadData {
    if (self.willReloadData) {
        self.willReloadData();
    }
    [self st_reloadData];
    if (self.didReloadData) {
        self.didReloadData();
    }
}

@end


@implementation UIActionSheet (STKit)

- (instancetype)initWithTitle:(NSString *)title
                     delegate:(id<UIActionSheetDelegate>)delegate
            cancelButtonTitle:(NSString *)cancelButtonTitle
       destructiveButtonTitle:(NSString *)destructiveButtonTitle
        otherButtonTitleArray:(NSArray *)otherButtonTitleArray {
    self = [self initWithTitle:title
                      delegate:delegate
             cancelButtonTitle:cancelButtonTitle
        destructiveButtonTitle:destructiveButtonTitle
             otherButtonTitles:nil, nil];
    [otherButtonTitleArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            [self addButtonWithTitle:obj];
        }
    }];
    return self;
}

@end

@implementation UIImage (STSubimage)

- (UIImage *)imageRotatedByRadians:(CGFloat)radians {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.size.width, self.size.height)];
    CGAffineTransform transform = CGAffineTransformMakeRotation(radians);
    view.transform = transform;
    CGSize rotatedSize = view.size;
    UIGraphicsBeginImageContextWithOptions(rotatedSize, NO, self.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, rotatedSize.width/2, rotatedSize.height/2);
    CGContextRotateCTM(context, radians);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context, CGRectMake(-self.size.width / 2, -self.size.height / 2, self.size.width, self.size.height), self.CGImage);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees {
    return [self imageRotatedByRadians:STDegreeToRadian(degrees)];
}

- (UIImage *)subimageInRect:(CGRect)rect {
    CGFloat scale = MAX(self.scale, 1);
    rect = CGRectMake(rect.origin.x * scale, rect.origin.y * scale, rect.size.width * scale, rect.size.height * scale);
    CGImageRef subimageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
    CGRect smallBounds = CGRectMake(0, 0, CGImageGetWidth(subimageRef), CGImageGetHeight(subimageRef));
    UIGraphicsBeginImageContext(smallBounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, smallBounds, subimageRef);
    UIImage *smallImage = [UIImage imageWithCGImage:subimageRef scale:self.scale orientation:self.imageOrientation];
    UIGraphicsEndImageContext();
    CGImageRelease(subimageRef);
    return smallImage;
}

- (UIImage *)imageWithTransform:(CGAffineTransform)transform {
    if (self.size.width == 0 || self.size.height == 0) {
        return nil;
    }

    CGSize imageSize = CGSizeMake(self.size.width, self.size.height);

    UIGraphicsBeginImageContextWithOptions(imageSize, YES, self.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextConcatCTM(context, transform);
    CGContextDrawImage(context, CGRectMake(0, 0, imageSize.width, imageSize.height), self.CGImage);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

// imageSize {100,100} size{200, 50} widthRate = 0.5, heightRate = 2
// imageSize {100,100} size{200, 100} widthRate = 0.5 heightRate = 1
- (UIImage *)imageConstrainedToSize:(CGSize)size {
    return [self imageConstrainedToSize:size contentMode:UIViewContentModeScaleAspectFit];
}

- (UIImage *)imageConstrainedToSize:(CGSize)size contentMode:(UIViewContentMode)contentMode {
    CGImageRef imageRef = self.CGImage;
    CGSize imageSize = self.size;
    if (!imageRef || (size.width == 0 && size.height == 0) || imageSize.height == 0) {
        return nil;
    }
    // 首先确定实际的image的大小, 先保证比例，然后找到和constrained比较接近的，计算出实际需要的imageSize。
    CGFloat width, height;
    CGFloat widthRate = imageSize.width / size.width, heightRate = imageSize.height / size.height;
    if (widthRate < heightRate) {
        height = size.height;
        width = imageSize.width / heightRate;
    } else {
        width = size.width;
        height = imageSize.height / widthRate;
    }
    CGSize newSize = CGSizeMake(width, height);
    CGAffineTransform transform = CGAffineTransformIdentity;
    UIImageOrientation orient = self.imageOrientation;
    switch (orient) {
        case UIImageOrientationUp: // EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored: // EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown: // EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored: // EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored: // EXIF = 5
            newSize.width = height;
            newSize.height = width;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeft: // EXIF = 6
            newSize.width = height;
            newSize.height = width;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored: // EXIF = 7
            newSize.width = height;
            newSize.height = width;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        case UIImageOrientationRight: // EXIF = 8
            newSize.width = height;
            newSize.height = width;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
        default:
            break;
    }
    CGFloat scale = MAX(self.scale, 1);
    UIGraphicsBeginImageContextWithOptions(newSize, YES, scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -1, 1);
        CGContextTranslateCTM(context, -height, 0);
    } else {
        CGContextScaleCTM(context, 1, -1);
        CGContextTranslateCTM(context, 0, -height);
    }
    CGContextConcatCTM(context, transform);
    CGContextDrawImage(context, CGRectMake(0, 0, newSize.width, newSize.height), imageRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return imageCopy;
}

+ (UIImage *)imageWithColor:(UIColor *)color {
    if (!color.CGColor) {
        return nil;
    }
    return [[self imageWithColor:color size:CGSizeMake(2, 2)] resizableImageWithCapInsets:UIEdgeInsetsMake(1, 1, 1, 1)
                                                                             resizingMode:UIImageResizingModeStretch];
}

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size {
    if (size.width == 0 || size.height == 0) {
        return nil;
    }
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIGraphicsPopContext();
    return image;
}
@end

@implementation NSData (STImage)

- (STImageDataType)imageType {
    if (self.length <= 8) {
        return STImageDataTypeUnknown;
    }
    const uint8_t PNGHeader[8] = {0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a};
    uint8_t header0[8];
    [self getBytes:&header0 length:8];
    if (header0[0] == 0x0A) {
        return STImageDataTypePCX;
    }
    if (header0[0] == 0x42 && header0[1] == 0x4d) {
        return STImageDataTypeBMP;
    }
    if (header0[0] == 0xff && header0[1] == 0xd8) {
        return STImageDataTypeJPEG;
    }
    // R as RIFF for WEBP
    if (self.length >= 12 && header0[0] == 0x52) {
        NSString *testString = [[NSString alloc] initWithData:[self subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
        if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
            return STImageDataTypeWebP;
        }
    }
    
    
    // 47 49 46 38 39(37) 61
    if (header0[0] == 0x47 && header0[1] == 0x49 && header0[2] == 0x46 && header0[3] == 0x38 && (header0[4] == 0x39 || header0[4] == 0x37) &&
        header0[5] == 0x61) {
        return STImageDataTypeGIF;
    }
    BOOL png = YES;
    for (int i = 0; i < 8; i++) {
        if (PNGHeader[i] != header0[i]) {
            png = NO;
            break;
        }
    }
    if (png) {
        return STImageDataTypePNG;
    }
    return STImageDataTypeUnknown;
}

@end

@implementation UIImage (STImage)

+ (UIImage *)imageWithSTData:(NSData *)data {
    if (!data) {
        return nil;
    }
    STImageDataType imageType = [data imageType];
    if (imageType != STImageDataTypeGIF) {
        return [self imageWithData:data];
    }

    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    size_t count = CGImageSourceGetCount(source);
    UIImage *animatedImage;

    if (count <= 1) {
        animatedImage = [[UIImage alloc] initWithData:data scale:[UIScreen mainScreen].scale];
    } else {
        NSMutableArray *images = [NSMutableArray array];
        NSTimeInterval duration = 0.0f;
        for (size_t i = 0; i < count; i++) {
            CGImageRef image = CGImageSourceCreateImageAtIndex(source, i, NULL);

            NSDictionary *frameProperties = CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, i, NULL));
            duration += [[[frameProperties objectForKey:(NSString *)kCGImagePropertyGIFDictionary]
                objectForKey:(NSString *)kCGImagePropertyGIFDelayTime] doubleValue];
            [images addObject:[UIImage imageWithCGImage:image scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp]];
            CGImageRelease(image);
        }

        if (!duration) {
            duration = (1.0f / 10.0f) * count;
        }
        animatedImage = [UIImage animatedImageWithImages:images duration:duration];
    }
    CFRelease(source);
    return animatedImage;
}

@end

@implementation UIImage (STImageNamed)

+ (void)load {
    // Exchange XIB loading implementation
    Method m1 = class_getInstanceMethod(NSClassFromString(@"UIImageNibPlaceholder"), @selector(initWithCoder:));
    Method m2 = class_getInstanceMethod(self, @selector(initWithCoderH568:));
    method_exchangeImplementations(m1, m2);
    // Exchange imageNamed: implementation
    method_exchangeImplementations(class_getClassMethod(self, @selector(imageNamed:)), class_getClassMethod(self, @selector(imageNamedH568:)));
}

/// 加载gif 图片
+ (UIImage *)gifImageNamed:(NSString *)imageName {
    NSString *prefix = [self prefixWithName:imageName];
    NSString *extension = [self extensionWithName:imageName];

    NSString *retinaName = [NSString stringWithFormat:@"%@@2x", prefix];
    NSString *highImage = [NSString stringWithFormat:@"%@-568h", prefix];
    NSString *highRetinaImage = [NSString stringWithFormat:@"%@-568h@2x", prefix];

    BOOL retina = [UIScreen mainScreen].scale >= 2.0;
    BOOL high = [UIScreen mainScreen].bounds.size.height > 480;

    NSString *preferredName;
    NSBundle *mainBundle = [NSBundle mainBundle];
    if (!high) {
        if (retina) {
            preferredName = retinaName;
            if (![mainBundle pathForResource:preferredName ofType:extension]) {
                preferredName = prefix;
            }
        } else {
            preferredName = prefix;
            if (![mainBundle pathForResource:preferredName ofType:extension]) {
                preferredName = retinaName;
            }
        }
    } else {
        if ([mainBundle pathForResource:highRetinaImage ofType:extension]) {
            preferredName = highRetinaImage;
        } else if ([mainBundle pathForResource:highImage ofType:extension]) {
            preferredName = highImage;
        } else if ([mainBundle pathForResource:retinaName ofType:extension]) {
            preferredName = retinaName;
        }
    }

    NSString *path = [[NSBundle mainBundle] pathForResource:preferredName ofType:extension];
    NSData *data = [NSData dataWithContentsOfFile:path];
    return [self imageWithSTData:data];
}

/// 如果为4.0屏幕，如果存在 imageName-568h@2x.xxx 则优先使用imageName-568h@2x.png -> imageName-568.png。
/// 如果位3.5寸屏幕，则根据当前情况自动加载合适的图片
/// 如果imageName为gif，则去加载gifimage  /// .gif
/// UIImage * image = [UIImage imageNamed:xxx.gif];
+ (UIImage *)imageNamedH568:(NSString *)imageName {

    NSString *prefix = [self prefixWithName:imageName];
    NSString *extension = [self extensionWithName:imageName];
    NSString *preferredPrefix = [self preferredImageNameWithPrefix:prefix extension:extension];
    if ([imageName hasSuffix:@".gif"]) {
        return [self gifImageNamed:imageName];
    } else if ([[extension lowercaseString] hasSuffix:@"jpg"] || [[extension lowercaseString] hasSuffix:@"jpeg"]) {
        return [self imageNamedH568:[NSString stringWithFormat:@"%@.%@", preferredPrefix, extension]];
    }
    return [self imageNamedH568:preferredPrefix];
}

+ (NSString *)preferredImageNameWithPrefix:(NSString *)prefix extension:(NSString *)extension {
    if (![UIScreen mainScreen].bounds.size.height <= 480) {
        return prefix;
    }
    NSDictionary *highRetinaImages = @{@"568":@"-568@2x", @"667":@"-667h@2x", @"736":@"-736h@3x"};
    NSString * key = [NSString stringWithFormat:@"%ld", (long)CGRectGetHeight([UIScreen mainScreen].bounds)];
    NSString *highRetinaImage = [NSString stringWithFormat:@"%@%@", prefix, [highRetinaImages valueForKey:key]];
    if ([[NSBundle mainBundle] pathForResource:highRetinaImage ofType:extension]) {
        return highRetinaImage;
    }
    return prefix;
}

- (id)initWithCoderH568:(NSCoder *)aDecoder {

    NSString *imageName = [aDecoder decodeObjectForKey:@"UIResourceName"];

    NSString *prefix = [[self class] prefixWithName:imageName];
    NSString *extension = [[self class] extensionWithName:imageName];

    NSString *preferredPrefix = [[self class] preferredImageNameWithPrefix:prefix extension:extension];

    if ([imageName hasSuffix:@".gif"]) {
        /// gif
        return [[self class] gifImageNamed:imageName];
    } else {
        return [[self class] imageNamedH568:preferredPrefix];
    }
}

+ (NSString *)prefixWithName:(NSString *)name {
    NSString *prefix = name;
    NSRange dotRange = [name rangeOfString:@"." options:NSBackwardsSearch];
    if (dotRange.location != NSNotFound) {
        NSRange prefixRange = NSMakeRange(0, dotRange.location);
        prefix = [name substringWithRange:prefixRange];
    }
    return [[prefix stringByReplacingOccurrencesOfString:@"@2x" withString:@""] stringByReplacingOccurrencesOfString:@"-568h" withString:@""];
}

+ (NSString *)extensionWithName:(NSString *)name {
    NSString *extension;
    /// 去除后缀
    NSRange dotRange = [name rangeOfString:@"." options:NSBackwardsSearch];
    if (dotRange.location != NSNotFound) {
        NSRange extensionRange = NSMakeRange(dotRange.location + 1, name.length - dotRange.location - 1);
        extension = [name substringWithRange:extensionRange];
    } else {
        extension = @".png";
    }
    return extension;
}

@end

@implementation UIImage (STBlurImage)

- (UIImage *)blurImageWithStyle:(STBlurEffectStyle)style {
    UIColor *tintColor;
    CGFloat radius = 20;
    switch (style) {
    case STBlurEffectStyleExtraLight:
        tintColor = [UIColor colorWithWhite:0.97 alpha:0.82];
        break;
    case STBlurEffectStyleLight:
        radius = 30;
        tintColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        break;
    case STBlurEffectStyleDark:
        tintColor = [UIColor colorWithWhite:0.11 alpha:0.73];
        break;
    case STBlurEffectStyleNone:
    default:
        return self;
    }
    return [self blurImageWithRadius:radius tintColor:tintColor saturationDeltaFactor:1.8 maskImage:nil];
}

- (UIImage *)blurImageWithTintColor:(UIColor *)tintColor {
    const CGFloat EffectColorAlpha = 0.6;
    UIColor *effectColor = tintColor;
    NSInteger componentCount = CGColorGetNumberOfComponents(tintColor.CGColor);
    if (componentCount == 2) {
        CGFloat b;
        if ([tintColor getWhite:&b alpha:NULL]) {
            effectColor = [UIColor colorWithWhite:b alpha:EffectColorAlpha];
        }
    } else {
        CGFloat r, g, b;
        if ([tintColor getRed:&r green:&g blue:&b alpha:NULL]) {
            effectColor = [UIColor colorWithRed:r green:g blue:b alpha:EffectColorAlpha];
        }
    }
    return [self blurImageWithRadius:10 tintColor:effectColor saturationDeltaFactor:-1.0 maskImage:nil];
}

- (UIImage *)blurImageWithRadius:(CGFloat)blurRadius tintColor:(UIColor *)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor {
    return [self blurImageWithRadius:blurRadius tintColor:tintColor saturationDeltaFactor:saturationDeltaFactor maskImage:nil];
}

- (UIImage *)blurImageWithRadius:(CGFloat)blurRadius
                       tintColor:(UIColor *)tintColor
           saturationDeltaFactor:(CGFloat)saturationDeltaFactor
                       maskImage:(UIImage *)maskImage {
    return [self applyBlurWithRadius:blurRadius tintColor:tintColor saturationDeltaFactor:saturationDeltaFactor maskImage:maskImage];
}

- (UIImage *)applyBlurWithRadius:(CGFloat)blurRadius
                       tintColor:(UIColor *)tintColor
           saturationDeltaFactor:(CGFloat)saturationDeltaFactor
                       maskImage:(UIImage *)maskImage {
    if (self.size.width < 1 || self.size.height < 1 || !self.CGImage) {
        return nil;
    }
    CGRect imageRect = {CGPointZero, self.size};
    UIImage *effectImage = self;
    CGContextRef mainContext = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(mainContext);

    BOOL hasBlur = blurRadius > __FLT_EPSILON__;
    BOOL hasSaturationChange = fabs(saturationDeltaFactor - 1.) > __FLT_EPSILON__;
    if (hasBlur || hasSaturationChange) {
        UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectInContext = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(effectInContext, 1.0, -1.0);
        CGContextTranslateCTM(effectInContext, 0, -self.size.height);
        CGContextDrawImage(effectInContext, imageRect, self.CGImage);

        vImage_Buffer effectInBuffer;
        effectInBuffer.data = CGBitmapContextGetData(effectInContext);
        effectInBuffer.width = CGBitmapContextGetWidth(effectInContext);
        effectInBuffer.height = CGBitmapContextGetHeight(effectInContext);
        effectInBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectInContext);

        UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectOutContext = UIGraphicsGetCurrentContext();
        vImage_Buffer effectOutBuffer;
        effectOutBuffer.data = CGBitmapContextGetData(effectOutContext);
        effectOutBuffer.width = CGBitmapContextGetWidth(effectOutContext);
        effectOutBuffer.height = CGBitmapContextGetHeight(effectOutContext);
        effectOutBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectOutContext);

        if (hasBlur) {
            // A description of how to compute the box kernel width from the Gaussian
            // radius (aka standard deviation) appears in the SVG spec:
            // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
            //
            // For larger values of 's' (s >= 2.0), an approximation can be used: Three
            // successive box-blurs build a piece-wise quadratic convolution kernel, which
            // approximates the Gaussian kernel to within roughly 3%.
            //
            // let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
            //
            // ... if d is odd, use three box-blurs of size 'd', centered on the output pixel.
            //
            CGFloat inputRadius = blurRadius * [[UIScreen mainScreen] scale];
            uint32_t radius = floor(inputRadius * 3. * sqrt(2 * M_PI) / 4 + 0.5);
            if (radius % 2 != 1) {
                radius += 1; // force radius to be odd so that the three box-blur methodology works.
            }
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
        }
        BOOL effectImageBuffersAreSwapped = NO;
        if (hasSaturationChange) {
            CGFloat s = saturationDeltaFactor;
            CGFloat floatingPointSaturationMatrix[] = {
                0.0722 + 0.9278 * s, 0.0722 - 0.0722 * s, 0.0722 - 0.0722 * s, 0, 0.7152 - 0.7152 * s, 0.7152 + 0.2848 * s, 0.7152 - 0.7152 * s, 0,
                0.2126 - 0.2126 * s, 0.2126 - 0.2126 * s, 0.2126 + 0.7873 * s, 0, 0, 0, 0, 1,
            };
            const int32_t divisor = 256;
            NSUInteger matrixSize = sizeof(floatingPointSaturationMatrix) / sizeof(floatingPointSaturationMatrix[0]);
            int16_t saturationMatrix[matrixSize];
            for (NSUInteger i = 0; i < matrixSize; ++i) {
                saturationMatrix[i] = (int16_t)roundf(floatingPointSaturationMatrix[i] * divisor);
            }
            if (hasBlur) {
                vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
                effectImageBuffersAreSwapped = YES;
            } else {
                vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
            }
        }
        if (!effectImageBuffersAreSwapped) {
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        }
        UIGraphicsEndImageContext();
        if (effectImageBuffersAreSwapped) {
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        }
        UIGraphicsEndImageContext();
    }

    // Set up output context.
    UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(outputContext, 1.0, -1.0);
    CGContextTranslateCTM(outputContext, 0, -self.size.height);
    // Draw base image.
    CGContextDrawImage(outputContext, imageRect, self.CGImage);

    // Draw effect image.
    if (hasBlur) {
        CGContextSaveGState(outputContext);
        if (maskImage && maskImage.CGImage) {
            CGContextClipToMask(outputContext, imageRect, maskImage.CGImage);
        }
        CGContextDrawImage(outputContext, imageRect, effectImage.CGImage);
        CGContextRestoreGState(outputContext);
    }

    // Add in color tint.
    if (tintColor) {
        CGContextSaveGState(outputContext);
        CGContextSetFillColorWithColor(outputContext, tintColor.CGColor);
        CGContextFillRect(outputContext, imageRect);
        CGContextRestoreGState(outputContext);
    }

    // Output image is ready.
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIGraphicsPopContext();
    return outputImage;
}

@end


@interface UINavigationController (STTest)

@end

@implementation UINavigationController (STTest)

+ (void)load {
    
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(popViewControllerAnimated:)), class_getInstanceMethod(self, @selector(st_popViewControllerAnimated:)));
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(popToViewController:animated:)), class_getInstanceMethod(self, @selector(st_popToViewController:animated:)));
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(popToRootViewControllerAnimated:)), class_getInstanceMethod(self, @selector(st_popToRootViewControllerAnimated:)));
}

- (UIViewController *)st_popViewControllerAnimated:(BOOL)animated {
    return [self st_popViewControllerAnimated:animated];
}
// Returns the popped controller.
- (NSArray *)st_popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    return [self st_popToViewController:viewController animated:animated];
}// Pops view controllers until the one specified is on top. Returns the popped controllers.
- (NSArray *)st_popToRootViewControllerAnimated:(BOOL)animated {
    return [self st_popToRootViewControllerAnimated:animated];
}

@end
