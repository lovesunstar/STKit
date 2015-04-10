//
//  STJavaScriptBridge.m
//  STKit
//
//  Created by SunJiangting on 14-10-16.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STJavaScriptBridge.h"
#import <objc/runtime.h>
#import "Foundation+STKit.h"

@implementation STJavaScriptBridgeItem

@end

@interface STJavaScriptBridge ()

@property(nonatomic, weak) UIWebView *webview;

@end

@implementation STJavaScriptBridge

- (void)registerBridgeHandler:(STBridgeHandler)bridgeHandler forJSMethod:(NSString *)JSMethod {
}

- (void)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *URL = request.URL;
    if ([URL.host isEqualToString:self.host] && [URL.host isEqualToString:self.scheme]) {
        // TODO: jsbridge
        [self fetchMessagesWithWebView:webView];
    }
}

- (void)fetchMessagesWithWebView:(UIWebView *)webview {
    NSString *queueString = [webview stringByEvaluatingJavaScriptFromString:@"STBridge.fetchQueue()"];
    NSArray *messages = [queueString JSONValue];
    for (__unused NSDictionary *message in messages) {
        STLog(@"%@", message);
    }
}

@end

@implementation UIWebView (STJavaScriptBridge)

+ (void)load {
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(setDelegate:)), class_getInstanceMethod(self, @selector(st_setDelegate:)));
}

- (void)st_setDelegate:(id<UIWebViewDelegate>)delegate {
    if (![self isEqual:delegate]) {
        [self st_setDelegate:(id<UIWebViewDelegate>)self];
        [self st_setCustomDelegate:delegate];
    } else {
        [self st_setDelegate:delegate];
        [self st_setCustomDelegate:nil];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    [self.JSBridge webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];

    id<UIWebViewDelegate> delegate = [self st_customDelegate];
    BOOL should = YES;
    if ([delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        should = [delegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    }
    return should;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    id<UIWebViewDelegate> delegate = [self st_customDelegate];
    if ([delegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [delegate webViewDidStartLoad:webView];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    id<UIWebViewDelegate> delegate = [self st_customDelegate];
    if ([delegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [delegate webViewDidFinishLoad:webView];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    id<UIWebViewDelegate> delegate = [self st_customDelegate];
    if ([delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [delegate webView:webView didFailLoadWithError:error];
    }
}

static char *const STJSBridgeKey = "STJSBridgeKey";
- (STJavaScriptBridge *)JSBridge {
    STJavaScriptBridge *JSBridge = objc_getAssociatedObject(self, STJSBridgeKey);
    if (!JSBridge) {
        JSBridge = [[STJavaScriptBridge alloc] init];
        JSBridge.webview = self;
        objc_setAssociatedObject(self, STJSBridgeKey, JSBridge, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (!self.allowsJavaScriptBridge) {
        return nil;
    } else {
        if (!self.delegate) {
            self.delegate = (id<UIWebViewDelegate>)self;
        }
    }
    return JSBridge;
}

static char *const STCustomDelegate = "STCustomDelegate";
- (void)st_setCustomDelegate:(id<UIWebViewDelegate>)delegate {
    objc_setAssociatedObject(self, STCustomDelegate, delegate, OBJC_ASSOCIATION_ASSIGN);
}

- (id<UIWebViewDelegate>)st_customDelegate {
    return objc_getAssociatedObject(self, STCustomDelegate);
}

static char *const STAllowsJSBridgeKey = "STAllowsJSBridgeKey";
- (void)setAllowsJavaScriptBridge:(BOOL)allowsJavaScriptBridge {
    objc_setAssociatedObject(self, STAllowsJSBridgeKey, @(allowsJavaScriptBridge), OBJC_ASSOCIATION_COPY);
}

- (BOOL)allowsJavaScriptBridge {
    NSNumber *allows = objc_getAssociatedObject(self, STAllowsJSBridgeKey);
    if (!allows) {
        return YES;
    }
    return allows.boolValue;
}

@end