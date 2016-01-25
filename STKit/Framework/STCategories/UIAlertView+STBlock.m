//
//  UIAlertView+STBlock.m
//  STKit
//
//  Created by SunJiangting on 14-10-31.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "UIAlertView+STBlock.h"
#import "Foundation+STKit.h"
#import <objc/runtime.h>

static NSString *const STAlertViewDismissBlockKey = @"STAlertViewDismissBlockKey";
static NSString *const STAlertViewDelegateKey = @"STAlertViewDelegateKey";

@implementation UIAlertView (STBlock)

+ (void)load {
    STExchangeSelectors(self, @selector(setDelegate:), @selector(st_setDelegate:));
}

- (void)st_showWithDismissBlock:(STAlertViewDismissBlock)block {
    self.dismissBlock = block;
    if (!self.delegate) {
        self.delegate = self;
    }
    [self show];
}

- (void)setDismissBlock:(STAlertViewDismissBlock)block {
    objc_setAssociatedObject(self, (__bridge const void *)(STAlertViewDismissBlockKey), block, OBJC_ASSOCIATION_COPY);
}

- (STAlertViewDismissBlock)dismissBlock {
    return objc_getAssociatedObject(self, (__bridge const void *)(STAlertViewDismissBlockKey));
}

- (void)st_setDelegate:(id<UIAlertViewDelegate>)delegate {
    if (![self isEqual:delegate]) {
        [self st_setDelegate:(id<UIAlertViewDelegate>)self];
        [self st_setCustomDelegate:delegate];
    } else {
        [self st_setDelegate:delegate];
        [self st_setCustomDelegate:nil];
    }
}

static char *const STCustomDelegate = "STCustomDelegate";
- (void)st_setCustomDelegate:(id<UIAlertViewDelegate>)delegate {
    objc_setAssociatedObject(self, STCustomDelegate, delegate, OBJC_ASSOCIATION_ASSIGN);
}

- (id<UIAlertViewDelegate>)st_customDelegate {
    return objc_getAssociatedObject(self, STCustomDelegate);
}

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    id<UIAlertViewDelegate> delegate = [self st_customDelegate];
    if ([delegate respondsToSelector:@selector(alertView:clickedButtonAtIndex:)]) {
        [delegate alertView:alertView clickedButtonAtIndex:buttonIndex];
    }
}

// Called when we cancel a view (eg. the user clicks the Home button). This is not called when the user clicks the cancel button.
// If not defined in the delegate, we simulate a click in the cancel button
- (void)alertViewCancel:(UIAlertView *)alertView {
    id<UIAlertViewDelegate> delegate = [self st_customDelegate];
    if ([delegate respondsToSelector:@selector(alertViewCancel:)]) {
        [delegate alertViewCancel:alertView];
    }
}

- (void)willPresentAlertView:(UIAlertView *)alertView {
    id<UIAlertViewDelegate> delegate = [self st_customDelegate];
    if ([delegate respondsToSelector:@selector(willPresentActionSheet:)]) {
        [delegate willPresentAlertView:alertView];
    }
    
} // before animation and showing view

- (void)didPresentAlertView:(UIAlertView *)alertView {
    id<UIAlertViewDelegate> delegate = [self st_customDelegate];
    if ([delegate respondsToSelector:@selector(didPresentAlertView:)]) {
        [delegate didPresentAlertView:alertView];
    }
} // after animation

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    id<UIAlertViewDelegate> delegate = [self st_customDelegate];
    if ([delegate respondsToSelector:@selector(alertView:willDismissWithButtonIndex:)]) {
        [delegate alertView:alertView willDismissWithButtonIndex:buttonIndex];
    }
} // before animation and hiding view

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    STAlertViewDismissBlock block = self.dismissBlock;
    if (block) {
        block(alertView, buttonIndex);
    }
    id<UIAlertViewDelegate> delegate = [self st_customDelegate];
    if ([delegate respondsToSelector:@selector(alertView:didDismissWithButtonIndex:)]) {
        [delegate alertView:alertView didDismissWithButtonIndex:buttonIndex];
    }
} // after animation

// Called after edits in any of the default fields added by the style
- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    id<UIAlertViewDelegate> delegate = [self st_customDelegate];
    BOOL should = YES;
    if ([delegate respondsToSelector:@selector(alertViewShouldEnableFirstOtherButton:)]) {
        should = [delegate alertViewShouldEnableFirstOtherButton:alertView];
    }
    return should;
}

@end
