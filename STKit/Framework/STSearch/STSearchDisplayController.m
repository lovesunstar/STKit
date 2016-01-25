//
//  STSearchDisplayController.m
//  STKit
//
//  Created by SunJiangting on 14-9-4.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STSearchDisplayController.h"
#import "UIKit+STKit.h"
#import "STViewController.h"
#import "STNavigationBar.h"
#import "STNavigationController.h"

@interface STSearchDisplayController () <STSearchBarDelegate> {
    CGRect _searchPreviousFrame;
}

@property(nonatomic, weak) STSearchBar      *searchBar;
@property(nonatomic, weak) UIViewController *searchContentsController;

@property(nonatomic, strong) UITableView *searchResultsTableView;

@property(nonatomic, strong) UIView *contentView;

@property(nonatomic, weak) UIView *searchBarSuperview;

@end

@implementation STSearchDisplayController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithSearchBar:(STSearchBar *)searchBar
     contentsController:(UIViewController *)viewController {
    self = [super init];
    if (self) {
        self.searchBar = searchBar;
        searchBar.delegate = self;
        self.searchContentsController = viewController;
        
        self.contentView = [[UIView alloc] initWithFrame:CGRectZero];
        self.contentView.backgroundColor = [UIColor st_colorWithRGB:0x0 alpha:0.3];
        [self.contentView st_addTouchTarget:self
                                     action:@selector(backgroundActionFired:)];
        
        self.searchResultsTableView =
        [[UITableView alloc] initWithFrame:self.contentView.bounds
                                     style:UITableViewStylePlain];
        self.searchResultsTableView.autoresizingMask =
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.searchResultsTableView.backgroundColor = [UIColor redColor];
        self.searchResultsTableView.backgroundView = nil;
        self.searchResultsTableView.tableFooterView =
        [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
        [self.contentView addSubview:self.searchResultsTableView];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(keyboardWillShowNotification:)
         name:UIKeyboardWillShowNotification
         object:nil];
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(keyboardWillHideNotification:)
         name:UIKeyboardWillHideNotification
         object:nil];
    }
    return self;
}

- (void)keyboardWillShowNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    
    CGRect keyboardRect =
    [[userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    NSTimeInterval timeInterval = [[userInfo
                                    valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve animationCurve = [[[notification userInfo]
                                            objectForKey:UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions options =
    [self _animationOptionWithViewAnimationCurve:animationCurve];
    CGRect contentFrame = self.searchContentsController.view.bounds;
    if (self.searchBar.superview == self.searchContentsController.view) {
        contentFrame.origin.y = CGRectGetMaxY(self.searchBar.frame);
        contentFrame.size.height -= contentFrame.origin.y;
    } else {
        if (STGetSystemVersion() >= 7) {
            contentFrame.origin.y = CGRectGetMaxY(self.searchBar.frame);
            contentFrame.size.height -= contentFrame.origin.y;
        }
    }
    
    CGRect frameToWindow =
    [self.searchContentsController.view convertRect:contentFrame toView:nil];
    CGFloat heightOffset =
    CGRectGetMinY(keyboardRect) - CGRectGetMaxY(frameToWindow);
    contentFrame.size.height += heightOffset;
    [UIView animateWithDuration:timeInterval
                          delay:0.0
                        options:options
                     animations:^{ self.contentView.frame = contentFrame; }
                     completion:^(BOOL finished){
                         
                     }];
}

- (void)keyboardWillHideNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    CGRect keyboardRect =
    [[userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval timeInterval = [[userInfo
                                    valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect contentFrame = self.searchContentsController.view.bounds;
    if (self.searchBar.superview == self.searchContentsController.view) {
        contentFrame.origin.y = CGRectGetMaxY(self.searchBar.frame);
        contentFrame.size.height -= contentFrame.origin.y;
    } else {
        if (STGetSystemVersion() >= 7) {
            contentFrame.origin.y = CGRectGetMaxY(self.searchBar.frame);
            contentFrame.size.height -= contentFrame.origin.y;
        }
    }
    
    CGRect frameToWindow =
    [self.searchContentsController.view convertRect:contentFrame toView:nil];
    CGFloat heightOffset =
    CGRectGetMinY(keyboardRect) - CGRectGetMaxY(frameToWindow);
    contentFrame.size.height += heightOffset;
    [UIView animateWithDuration:timeInterval
                     animations:^{ self.contentView.frame = contentFrame; }];
}

- (void)setActive:(BOOL)active animated:(BOOL)animated {
    if (self.active == active) {
        return;
    }
    STViewController *viewController =
    (STViewController *)self.searchContentsController;
    STViewController *contentViewController =
    [viewController st_valueForVar:@"_st_toolBarController"];
    
    if (!contentViewController || !viewController.st_tabBarController ||
        viewController.hidesBottomBarWhenPushed) {
        contentViewController = viewController;
    } else {
        NSString *selectorString =
        active ? @"_st_requireCustomTabBar" : @"_st_resignCustomTabBar";
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        SEL selector = NSSelectorFromString(selectorString);
        if ([contentViewController respondsToSelector:selector]) {
            [contentViewController performSelector:selector];
        }
#pragma clang diagnostic pop
    }
    [self.searchBar removeFromSuperview];
    if (active) {
        [contentViewController.view addSubview:self.contentView];
        
        UIView *navigationView =
        [contentViewController st_valueForVar:@"_toolBarNavigationView"];
        if (navigationView) {
            [contentViewController.view bringSubviewToFront:navigationView];
        }
        [contentViewController.view addSubview:self.searchBar];
        
        CGRect frame =
        [self.searchBarSuperview convertRect:self.searchBar.frame
                                      toView:contentViewController.view];
        self.searchBar.frame = frame;
        CGRect contentFrame = contentViewController.view.frame;
        contentFrame.origin.y = CGRectGetMaxY(frame);
        self.contentView.frame = contentFrame;
    } else {
        [self.contentView removeFromSuperview];
        [self.searchBarSuperview addSubview:self.searchBar];
        self.searchBar.frame = _searchPreviousFrame;
    }
    void (^animations)(void) = ^{
        CGRect searchBarSuperFrame = self.searchBarSuperview.frame;
        NSString *selectorString =
        active ? @"_requireFullScreenLayout" : @"_resignFullScreenLayout";
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        SEL selector = NSSelectorFromString(selectorString);
        if ([self.searchBar respondsToSelector:selector]) {
            [self.searchBar performSelector:selector];
        }
#pragma clang diagnostic pop
        if (active) {
            searchBarSuperFrame.origin.y -= STSearchViewDefaultHeight;
            searchBarSuperFrame.size.height += STSearchViewDefaultHeight;
        } else {
            searchBarSuperFrame.origin.y += STSearchViewDefaultHeight;
            searchBarSuperFrame.size.height -= STSearchViewDefaultHeight;
            self.searchBar.frame = _searchPreviousFrame;
        }
        self.searchBarSuperview.frame = searchBarSuperFrame;
        CGRect contentFrame = contentViewController.view.frame;
        contentFrame.origin.y = CGRectGetMaxY(self.searchBar.frame);
        self.contentView.frame = contentFrame;
    };
    [viewController st_setNavigationBarHidden:active animated:animated alongWithAnimations:animations];
    self.active = active;
    
    if (active) {
        if ([self.delegate
             respondsToSelector:@selector(
                                          searchDisplayControllerWillBeginSearch:)]) {
                 [self.delegate searchDisplayControllerWillBeginSearch:self];
             }
    } else {
        if ([self.delegate
             respondsToSelector:@selector(
                                          searchDisplayControllerWillEndSearch:)]) {
                 [self.delegate searchDisplayControllerWillEndSearch:self];
             }
    }
    
    [self.searchBar
     setEditing:active
     animated:animated
     completion:^(BOOL finished) {
         if (active) {
             if ([self.delegate
                  respondsToSelector:
                  @selector(searchDisplayControllerDidBeginSearch:)]) {
                 [self.delegate searchDisplayControllerDidBeginSearch:self];
             }
         } else {
             if ([self.delegate
                  respondsToSelector:
                  @selector(searchDisplayControllerDidEndSearch:)]) {
                 [self.delegate searchDisplayControllerDidEndSearch:self];
             }
         }
     }];
}

- (void)maskViewTapFired:(id)sender {
    [self.searchBar.cancelView
     sendActionsForControlEvents:UIControlEventTouchUpInside];
    [self.searchBar resignFirstResponder];
}

#pragma mark -STSearchBarDelegate
- (BOOL)searchBarShouldBeginEditing:(STSearchBar *)searchBar {
    if (searchBar.superview != self.searchContentsController.view) {
        self.searchBarSuperview = searchBar.superview;
        _searchPreviousFrame = searchBar.frame;
    }
    [self setActive:YES animated:YES];
    return YES;
}

- (void)searchBarTextDidBeginEditing:(STSearchBar *)searchBar {
}

- (BOOL)searchBarShouldEndEditing:(STSearchBar *)searchBar {
    //    [self setActive:NO animated:YES];
    return YES;
}

- (void)searchBarSearchButtonClicked:(STSearchBar *)searchBar {
    NSString *keyword = searchBar.searchEditView.editTextField.text;
    if ([keyword st_stringByTrimingWhitespace].length > 0) {
    }
}

- (void)backgroundActionFired:(id)sender {
    [self.searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(STSearchBar *)searchBar {
    [self setActive:NO animated:YES];
}

- (void)searchBar:(STSearchBar *)searchBar
    textDidChange:(NSString *)searchText {
    if (searchText.length > 0 && self.searchResultsTableView.hidden) {
        if ([self.delegate
             respondsToSelector:@selector(searchDisplayController:
                                          willShowSearchResultsTableView:)]) {
                 [self.delegate searchDisplayController:self
                         willShowSearchResultsTableView:self.searchResultsTableView];
             }
        self.searchResultsTableView.hidden = NO;
    } else if (searchText.length == 0 && !self.searchResultsTableView.hidden) {
        if ([self.delegate
             respondsToSelector:@selector(searchDisplayController:
                                          willShowSearchResultsTableView:)]) {
                 [self.delegate searchDisplayController:self
                         willHideSearchResultsTableView:self.searchResultsTableView];
             }
        self.searchResultsTableView.hidden = YES;
    }
}

- (void)searchBarTextDidEndEditing:(STSearchBar *)searchBar {
    NSString *keyword = searchBar.searchEditView.editTextField.text;
    if ([keyword st_stringByTrimingWhitespace].length > 0) {
        //        [[STSearchManager defaultSearchManager]
        //        insertSearchKeyword:keyword
        //        effectToTableView:self.searchResultsTableView];
    }
}

- (BOOL)searchBar:(STSearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    return YES;
}

#pragma mark -Private Setter

- (void)setSearchResultsDataSource: (id<UITableViewDataSource>)searchResultsDataSource {
    _searchResultsTableView.dataSource = searchResultsDataSource;
    _searchResultsDataSource = searchResultsDataSource;
}

- (void)setSearchResultsDelegate: (id<UITableViewDelegate>)searchResultsDelegate {
    _searchResultsTableView.delegate = searchResultsDelegate;
    _searchResultsDelegate = searchResultsDelegate;
}

- (UIViewAnimationOptions)_animationOptionWithViewAnimationCurve:(UIViewAnimationCurve)animationCurve {
    UIViewAnimationOptions options = UIViewAnimationCurveEaseIn |
    UIViewAnimationCurveEaseOut |
    UIViewAnimationCurveLinear;
    switch (animationCurve) {
        case UIViewAnimationCurveEaseInOut:
            options = UIViewAnimationOptionCurveEaseInOut;
            break;
        case UIViewAnimationCurveEaseIn:
            options = UIViewAnimationOptionCurveEaseIn;
            break;
        case UIViewAnimationCurveEaseOut:
            options = UIViewAnimationOptionCurveEaseOut;
            break;
        case UIViewAnimationCurveLinear:
            options = UIViewAnimationOptionCurveLinear;
            break;
        default:
            options = animationCurve << 16;
            break;
    }
    return options;
}
@end