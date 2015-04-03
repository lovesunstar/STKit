//
//  STWebViewController.m
//  STKit
//
//  Created by SunJiangting on 13-11-21.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import "STWebViewController.h"
#import "STIndicatorView.h"
#import "Foundation+STKit.h"
#import "UIKit+STKit.h"
#import "STResourceManager.h"

@interface STWebViewToolbar : UIView


@property(nonatomic, weak) UIButton *backButton;
@property(nonatomic, weak) UIButton *forwardButton;
@property(nonatomic, weak) UIButton *refreshButton;

@property(nonatomic, weak) UIActivityIndicatorView *indicatorView;

@end

@implementation STWebViewToolbar

- (instancetype)initWithFrame:(CGRect)frame {
    frame.size = CGSizeMake(CGRectGetWidth([UIScreen mainScreen].bounds), 49);
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat width = CGRectGetWidth(frame);
        
        UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        backButton.frame = CGRectMake(10, 4.5, 40, 40);
        backButton.imageEdgeInsets = UIEdgeInsetsMake(8, 3, 8, 13);
        [backButton setImage:[STResourceManager imageWithResourceID:STImageResourceWebViewBackNormalID] forState:UIControlStateNormal];
        [backButton setImage:[STResourceManager imageWithResourceID:STImageResourceWebViewBackHighlightedID] forState:UIControlStateHighlighted];
        [backButton setImage:[STResourceManager imageWithResourceID:STImageResourceWebViewBackDisabledID] forState:UIControlStateDisabled];
        backButton.enabled = NO;
        [self addSubview:backButton];
        self.backButton = backButton;
        
        UIButton *forwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
        forwardButton.frame = CGRectMake(60, 4.5, 40, 40);
        forwardButton.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
        [forwardButton setImage:[STResourceManager imageWithResourceID:STImageResourceWebViewForwardNormalID] forState:UIControlStateNormal];
        [forwardButton setImage:[STResourceManager imageWithResourceID:STImageResourceWebViewForwardHighlightedID] forState:UIControlStateHighlighted];
        [forwardButton setImage:[STResourceManager imageWithResourceID:STImageResourceWebViewForwardDisabledID] forState:UIControlStateDisabled];
        forwardButton.enabled = NO;
        [self addSubview:forwardButton];
        self.forwardButton = forwardButton;
        
        UIButton *refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
        refreshButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        refreshButton.frame = CGRectMake(width - 50, 4.5, 40, 40);
        refreshButton.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
        [refreshButton setImage:[STResourceManager imageWithResourceID:STImageResourceWebViewRefreshNormalID] forState:UIControlStateNormal];
        [refreshButton setImage:[STResourceManager imageWithResourceID:STImageResourceWebViewRefreshHighlightedID] forState:UIControlStateHighlighted];
        [refreshButton setImage:[STResourceManager imageWithResourceID:STImageResourceWebViewRefreshDisabledID] forState:UIControlStateDisabled];
        refreshButton.hidden = YES;
        [self addSubview:refreshButton];
        self.refreshButton = refreshButton;
        
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        indicatorView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        indicatorView.frame = refreshButton.frame;
        indicatorView.hidesWhenStopped = YES;
        [self addSubview:indicatorView];
        self.indicatorView = indicatorView;
    }
    return self;
}

@end

@interface STWebViewController () <UIWebViewDelegate>

@property(nonatomic, strong) UIWebView *webView;

@property(nonatomic, strong) STWebViewToolbar *toolbar;
@property(nonatomic, strong) NSURL    *URL;

@property(nonatomic, strong) UILabel  *titleLabel;
@property(nonatomic, copy)   NSString *contentsOfFile;
@end

@implementation STWebViewController

- (void)dealloc {
    [STIndicatorView hideInView:self.view animated:NO];
}

- (instancetype)initWithURL:(NSURL *)URL {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.URL = URL;
        self.showIndicatorWhenLoading = YES;
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (instancetype)initWithURLString:(NSString *)URLString {
    return [self initWithURL:[NSURL URLWithString:URLString]];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [self initWithURL:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = [UIFont systemFontOfSize:14.];
    titleLabel.textColor = [UIColor colorWithRGB:0xFF7300];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    self.navigationItem.titleView = titleLabel;
    self.titleLabel = titleLabel;

    self.edgesForExtendedLayout = (UIRectEdgeLeft | UIRectEdgeRight);
    // Do any additional setup after loading the view.
    CGRect frame = self.view.bounds;
    CGFloat width = CGRectGetWidth(frame);
    CGFloat height = CGRectGetHeight(frame);
    CGFloat barHeight = 49 * !self.webViewBarHidden;
    frame.size.height = height - barHeight;
    

//    BOOL hasWKWebView = NSClassFromString(@"WKWebView");
//    if (hasWKWebView) {
//        WKWebViewConfiguration * configuration = [[WKWebViewConfiguration alloc] init];
//        configuration.suppressesIncrementalRendering = YES;
//        WKWebView * webView = [[WKWebView alloc] initWithFrame:frame configuration:configuration];
//        webView.UIDelegate = self;
//        [webView loadRequest:URLRequest];
//        self.webView = webView;
//    } else {
        UIWebView *webView = [[UIWebView alloc] initWithFrame:frame];
        webView.delegate = self;
        self.webView = webView;
//    }
    self.webView.frame = frame;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.webView];

    self.toolbar = [[STWebViewToolbar alloc] initWithFrame:CGRectMake(0, height - barHeight, width, 49)];
    self.toolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    self.toolbar.backgroundColor = [UIColor grayColor];
    [self.view addSubview:self.toolbar];

    [self.toolbar.refreshButton addTarget:self action:@selector(goRefreshActionFired) forControlEvents:UIControlEventTouchUpInside];
    [self.toolbar.backButton addTarget:self action:@selector(goBackActionFired) forControlEvents:UIControlEventTouchUpInside];
    [self.toolbar.forwardButton addTarget:self action:@selector(goForwardActionFired) forControlEvents:UIControlEventTouchUpInside];
    
    self.toolbar.hidden = self.webViewBarHidden;
    
    [self _loadRequest];
    [self _loadWebViewContent];
}

- (void)_loadRequest {
    if (!self.isViewLoaded) {
        return;
    }
    if (self.URL) {
        NSURLRequest *URLRequest = [NSURLRequest requestWithURL:self.URL];
        [self.webView loadRequest:URLRequest];
    }
}

- (void)_loadWebViewContent {
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setter
- (void)setWebViewBarHidden:(BOOL)webViewBarHidden {
    [self setWebViewBarHidden:webViewBarHidden animated:NO];
}

- (void)setWebViewBarHidden:(BOOL)webViewBarHidden animated:(BOOL)animated {
    if (!self.isViewLoaded) {
        _webViewBarHidden = webViewBarHidden;
        return;
    }
    CGFloat height = CGRectGetHeight(self.view.bounds);
    CGFloat barHeight = 49 * !webViewBarHidden;
    CGRect webviewFrame = self.webView.frame;
    webviewFrame.size.height = height - barHeight;
    CGRect barFrame = self.toolbar.frame;
    barFrame.origin.y = height - barHeight;

    void (^completion)(BOOL) = ^(BOOL finished) {
        self.webView.frame = webviewFrame;
        self.toolbar.frame = barFrame;
        self.toolbar.hidden = webViewBarHidden;
        _webViewBarHidden = webViewBarHidden;
    };
    self.toolbar.hidden = NO;
    if (animated) {
        [UIView animateWithDuration:0.25
                         animations:^{
                             self.webView.frame = webviewFrame;
                             self.toolbar.frame = barFrame;
                         }
                         completion:completion];
    } else {
        completion(YES);
    }
}

#pragma mark - UIWebviewNavigation
- (void)goBackActionFired {
    if ([self.webView respondsToSelector:@selector(goBack)] && [self.webView respondsToSelector:@selector(canGoBack)] && [(UIWebView *)self.webView canGoBack]) {
        [(UIWebView *)self.webView goBack];
    }
}

- (void)goForwardActionFired {
    if ([self.webView respondsToSelector:@selector(goForward)] && [self.webView respondsToSelector:@selector(canGoForward)] && [(UIWebView *)self.webView canGoForward]) {
        [(UIWebView *)self.webView goForward];
    }
}

- (void)goRefreshActionFired {
    if ([self.webView respondsToSelector:@selector(reload)]) {
        [(UIWebView *)self.webView reload];
    }
}

#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    if (self.showIndicatorWhenLoading) {
        [STIndicatorView showInView:self.view animated:NO];
    }
    self.toolbar.refreshButton.hidden = YES;
    [self.toolbar.indicatorView startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (self.showIndicatorWhenLoading) {
        [STIndicatorView hideInView:self.view animated:YES];
    }
    self.toolbar.backButton.enabled = webView.canGoBack;
    self.toolbar.forwardButton.enabled = webView.canGoForward;
    self.toolbar.refreshButton.hidden = NO;
    [self.toolbar.indicatorView stopAnimating];

    NSString *title = webView.request.URL.host;
    if (!title) {
        title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    }
    self.titleLabel.text = title;
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (self.showIndicatorWhenLoading) {
        [STIndicatorView hideInView:self.view animated:YES];
    }
    self.toolbar.backButton.enabled = webView.canGoBack;
    self.toolbar.forwardButton.enabled = webView.canGoForward;
    self.toolbar.refreshButton.hidden = NO;
    [self.toolbar.indicatorView stopAnimating];
}

@end

@implementation STWebViewController (STLocalFile)

- (instancetype)initWithContentsOfFile:(NSString *)path {
    self = [self initWithURLString:nil];
    if (self) {
        self.contentsOfFile = path;
    }
    return self;
}

- (void)_loadWebViewContent {
    if (self.contentsOfFile) {
        NSError *error = nil;
        NSString *contents = [NSString stringWithContentsOfFile:self.contentsOfFile encoding:NSUTF8StringEncoding error:&error];
        if (contents) {
            [self.webView loadHTMLString:contents baseURL:nil];
        }
    }
}

@end
