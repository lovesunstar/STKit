//
//  STSearchBar.m
//  STKit
//
//  Created by SunJiangting on 14-9-4.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STSearchBar.h"
#import "../UIKit+STKit.h"

const CGFloat STSearchViewDefaultHeight = 44;
const CGFloat STSearchViewHorizontalMargin = 5.0;

const CGSize STDefaultSearchEditViewSize = {50, STSearchViewDefaultHeight};

@interface STSearchEditView ()

@end

@implementation STSearchEditView

- (instancetype)initWithFrame:(CGRect)frame {
    if (frame.size.width < STDefaultSearchEditViewSize.width) {
        frame.size.width = STDefaultSearchEditViewSize.width;
    }
    if (frame.size.height < STDefaultSearchEditViewSize.height) {
        frame.size.height = STDefaultSearchEditViewSize.height;
    }
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundImageView = [[UIImageView alloc]
                                    initWithFrame:CGRectMake(6, 6, CGRectGetWidth(frame) - 12, 31)];
        self.backgroundImageView.autoresizingMask =
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        UIImage *image = [[UIImage imageNamed:@"searchbar_bkg"]
                          resizableImageWithCapInsets:UIEdgeInsetsMake(15, 30, 15, 30)
                          resizingMode:UIImageResizingModeStretch];
        self.backgroundImageView.image = image;
        [self addSubview:self.backgroundImageView];
        
        self.editTextField = [[UITextField alloc]
                              initWithFrame:CGRectMake(20, 11, CGRectGetWidth(frame) - 40, 20)];
        self.editTextField.autoresizingMask =
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.editTextField.textColor = [UIColor st_colorWithRGB:0x636363];
        self.editTextField.placeholder = @"请输入关键字";
        self.editTextField.returnKeyType = UIReturnKeySearch;
        [self addSubview:self.editTextField];
        
        self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.deleteButton.frame = CGRectMake(0, 0, 22, 44);
        [self.deleteButton setImage:[UIImage imageNamed:@"textfield_delete_normal"]
                           forState:UIControlStateNormal];
        [self addSubview:self.deleteButton];
        
        [self reloadInputState];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.deleteButton.right = self.backgroundImageView.right - 5;
}

- (void)reloadInputState {
    self.deleteButton.hidden =
    [self.editTextField.text st_stringByTrimingWhitespace].length <= 0;
}

- (BOOL)canBecomeFirstResponder {
    return [self.editTextField canBecomeFirstResponder];
}

- (BOOL)becomeFirstResponder {
    return [self.editTextField becomeFirstResponder];
}

- (BOOL)canResignFirstResponder {
    return [self.editTextField canResignFirstResponder];
}

- (BOOL)resignFirstResponder {
    [super resignFirstResponder];
    return [self.editTextField resignFirstResponder];
}

- (BOOL)isFirstResponder {
    return [self.editTextField isFirstResponder];
}

@end

@interface STSearchBar () <UITextFieldDelegate>

@property(nonatomic, strong) UIImageView *backgroundImageView;
@property(nonatomic, strong) STSearchEditView *searchEditView;

@property(nonatomic, strong) UIButton *cancelView;
@property(nonatomic, strong) UIButton *leftButton;
@property(nonatomic, strong) UIButton *rightButton;

@property(nonatomic, strong) UIView *contentView;

@property(nonatomic, strong) UIView *backgroundToolbar;

@property(nonatomic, assign) BOOL editing;

@end

@implementation STSearchBar

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        if (STGetSystemVersion() >= 7) {
            UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:self.bounds];
            toolbar.autoresizingMask =
            UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            toolbar.translucent = YES;
            [self addSubview:toolbar];
            self.backgroundToolbar = toolbar;
            self.backgroundToolbar.hidden = YES;
        }
        
        self.contentView = [[UIView alloc] initWithFrame:CGRectZero];
        self.contentView.autoresizingMask =
        UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        [self addSubview:self.contentView];
        
        _searchEditView = STSearchEditView.new;
        _searchEditView.editTextField.delegate = self;
        [_searchEditView.editTextField
         addTarget:self
         action:@selector(searchEditViewDidChangeEditing:)
         forControlEvents:UIControlEventEditingChanged];
        [_searchEditView.deleteButton addTarget:self
                                         action:@selector(deleteButtonPressed:)
                               forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_searchEditView];
        
        self.cancelView = [UIButton buttonWithType:UIButtonTypeCustom];
        self.cancelView.titleEdgeInsets = UIEdgeInsetsMake(1, 0, 0, 0);
        self.cancelView.titleLabel.shadowOffset = CGSizeMake(-0.5, -0.5);
        self.cancelView.titleLabel.shadowColor = [UIColor colorWithRed:100 / 255.0
                                                                 green:26 / 255.0
                                                                  blue:4 / 255.0
                                                                 alpha:0.52];
        [self.cancelView setTitle:@"取消" forState:UIControlStateNormal];
        [self.cancelView setTitleColor:[UIColor blueColor]
                              forState:UIControlStateNormal];
        [self.cancelView addTarget:self
                            action:@selector(cancelButtonTouchUpInside:)
                  forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.cancelView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect frame = self.bounds;
    frame.size.height = 44;
    frame.origin.y = CGRectGetHeight(self.bounds) - 44;
    self.contentView.frame = frame;
    [self relayoutSearchEditView];
    [self relayoutSearchCancelView];
}

- (void)relayoutSearchEditView {
    BOOL leftButtonLoaded = !!(_leftButton);
    BOOL rightButtonLoaded = !!(_rightButton);
    CGFloat width = CGRectGetWidth(self.contentView.bounds);
    CGFloat height = CGRectGetHeight(self.contentView.bounds);
    CGRect rect = CGRectMake(0, 0, 0, height);
    if (self.editing) {
        rect.origin.x = STSearchViewHorizontalMargin;
        rect.size.width = width - STSearchViewHorizontalMargin * 3 -
        CGRectGetWidth(self.cancelView.bounds);
    } else {
        rect.origin.x = leftButtonLoaded * (!_leftButton.hidden) * 35 +
        STSearchViewHorizontalMargin;
        rect.size.width = width -
        (leftButtonLoaded * (!_leftButton.hidden) * 35 +
         rightButtonLoaded * (!_rightButton.hidden) * 35) -
        2 * STSearchViewHorizontalMargin;
    }
    _searchEditView.frame = rect;
}

- (void)relayoutSearchCancelView {
    if (self.cancelView.hidden) {
        return;
    }
    CGFloat width = CGRectGetWidth(self.contentView.bounds);
    CGFloat height = CGRectGetHeight(self.contentView.bounds);
    CGRect rect = CGRectMake(0, (height - 30) / 2, 60, 30);
    rect.origin.x = width - (self.editing) * (STSearchViewHorizontalMargin + 60);
    _cancelView.frame = rect;
}

#pragma mark - Getters
- (UIImageView *)backgroundImageView {
    if (!_backgroundImageView) {
        _backgroundImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _backgroundImageView.autoresizingMask =
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:_backgroundImageView];
        [self.contentView sendSubviewToBack:_backgroundImageView];
    }
    return _backgroundImageView;
}

- (UIButton *)leftButton {
    if (!_leftButton) {
        _leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _leftButton.frame = CGRectMake(5, 0, 30, CGRectGetHeight(self.bounds));
        _leftButton.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:_leftButton];
    }
    return _leftButton;
}

- (UIButton *)rightButton {
    if (!_rightButton) {
        _rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _rightButton.frame = CGRectMake(CGRectGetWidth(self.bounds) - 35, 0, 30,
                                        CGRectGetHeight(self.bounds));
        _rightButton.autoresizingMask =
        UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:_rightButton];
    }
    return _rightButton;
}

#pragma mark - EditingMode
- (void)setEditing:(BOOL)editing {
    [self setEditing:editing animated:NO completion:NULL];
}

- (void)setEditing:(BOOL)editing
          animated:(BOOL)animated
        completion:(void (^)(BOOL))_completion {
    _editing = editing;
    CGRect leftRect = _leftButton.frame;
    CGRect rightRect = _rightButton.frame;
    self.backgroundToolbar.hidden = !editing;
    if (editing) {
        leftRect.origin.x =
        -CGRectGetWidth(leftRect) - STSearchViewHorizontalMargin;
    } else {
        leftRect.origin.x = STSearchViewHorizontalMargin;
        _leftButton.hidden = editing;
    }
    _rightButton.hidden = editing;
    void (^animations)(void) = ^{
        self.cancelView.hidden = !editing;
        _leftButton.frame = leftRect;
        _rightButton.frame = rightRect;
        [self relayoutSearchEditView];
        [self relayoutSearchCancelView];
    };
    void (^completion)(BOOL) = ^(BOOL finished) {
        _leftButton.hidden = _rightButton.hidden = editing;
        if (_completion) {
            _completion(finished);
        }
    };
    if (animated) {
        [UIView animateWithDuration:0.25
                         animations:animations
                         completion:completion];
    } else {
        animations();
        completion(YES);
    }
}

- (void)_requireFullScreenLayout {
    CGRect frame = self.frame;
    if (STGetSystemVersion() < 7) {
        frame.size.height = STSearchViewDefaultHeight;
    } else {
        frame.size.height =
        STSearchViewDefaultHeight +
        CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
    }
    self.frame = frame;
}

- (void)_resignFullScreenLayout {
    CGRect frame = self.frame;
    frame.size.height = STSearchViewDefaultHeight;
    self.frame = frame;
}

#pragma mark - SearchTextField
// return NO to disallow editing.
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    BOOL shouldBeginEditing = YES;
    if ([self.delegate
         respondsToSelector:@selector(searchBarShouldBeginEditing:)]) {
        shouldBeginEditing = [self.delegate searchBarShouldBeginEditing:self];
    }
    if (shouldBeginEditing) {
        [self.searchEditView reloadInputState];
    }
    return shouldBeginEditing;
}
// became first responder
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if ([self.delegate
         respondsToSelector:@selector(searchBarTextDidBeginEditing:)]) {
        [self.delegate searchBarTextDidBeginEditing:self];
    }
}
// return YES to allow editing to stop and to resign first responder status.NO
// to disallow the editing session to end
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    BOOL shouldEndEditing = YES;
    if ([self.delegate
         respondsToSelector:@selector(searchBarShouldBeginEditing:)]) {
        shouldEndEditing = [self.delegate searchBarShouldEndEditing:self];
    }
    return shouldEndEditing;
}
// may be called if forced even if shouldEndEditing returns NO (e.g. view
// removed from window) or endEditing:YES called
- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([self.delegate
         respondsToSelector:@selector(searchBarTextDidEndEditing:)]) {
        [self.delegate searchBarTextDidEndEditing:self];
    }
    textField.text = @"";
    [self.searchEditView reloadInputState];
}
// return NO to not change text
- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string {
    BOOL shouldChange = YES;
    if ([self.delegate respondsToSelector:@selector(searchBar:
                                                    shouldChangeTextInRange:
                                                    replacementText:)]) {
        shouldChange = [self.delegate searchBar:self
                        shouldChangeTextInRange:range
                                replacementText:string];
    }
    return shouldChange;
}

// called when clear button pressed. return NO to ignore (no notifications)
- (BOOL)textFieldShouldClear:(UITextField *)textField {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([self.delegate
         respondsToSelector:@selector(searchBarSearchButtonClicked:)]) {
        [self.delegate searchBarSearchButtonClicked:self];
    }
    return YES;
}

- (void)searchEditViewDidChangeEditing:(UITextField *)sender {
    [self.searchEditView reloadInputState];
    if ([self.delegate respondsToSelector:@selector(searchBar:textDidChange:)]) {
        [self.delegate searchBar:self textDidChange:sender.text];
    }
}

- (void)deleteButtonPressed:(id)sender {
    self.searchEditView.editTextField.text = @"";
    [self searchEditViewDidChangeEditing:self.searchEditView.editTextField];
}

#pragma mark - SearchCancelled
- (void)cancelButtonTouchUpInside:(id)sender {
    if ([self.searchEditView.editTextField isFirstResponder]) {
        [self.searchEditView.editTextField resignFirstResponder];
    }
    if ([self.delegate
         respondsToSelector:@selector(searchBarCancelButtonClicked:)]) {
        [self.delegate searchBarCancelButtonClicked:self];
    }
}

- (BOOL)canBecomeFirstResponder {
    return [self.searchEditView canBecomeFirstResponder];
}

- (BOOL)becomeFirstResponder {
    return [self.searchEditView becomeFirstResponder];
}

- (BOOL)canResignFirstResponder {
    return [self.searchEditView canResignFirstResponder];
}

- (BOOL)resignFirstResponder {
    [super resignFirstResponder];
    return [self.searchEditView resignFirstResponder];
}

- (BOOL)isFirstResponder {
    return [self.searchEditView isFirstResponder];
}
@end
