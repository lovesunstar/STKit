//
//  STTextView.m
//  STKit
//
//  Created by SunJiangting on 14-1-7.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STTextView.h"

@interface STTextView ()

@property(nonatomic, strong) UIColor *color;

@property(nonatomic, strong) NSString *lastText;
@property(nonatomic, getter=isUsingPlaceholder) BOOL usingPlaceholder;
@property(nonatomic, getter=isSettingPlaceholder) BOOL settingPlaceholder;

@end

@implementation STTextView

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textDidBeginEditing:)
                                                     name:UITextViewTextDidBeginEditingNotification
                                                   object:self];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textDidChanged:)
                                                     name:UITextViewTextDidChangeNotification
                                                   object:self];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textDidEndEditing:)
                                                     name:UITextViewTextDidEndEditingNotification
                                                   object:self];
        self.placeholderColor = [UIColor colorWithRed:204. / 255. green:204. / 255. blue:204. / 255. alpha:1.0];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textDidBeginEditing:)
                                                     name:UITextViewTextDidBeginEditingNotification
                                                   object:self];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textDidChanged:)
                                                     name:UITextViewTextDidChangeNotification
                                                   object:self];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textDidEndEditing:)
                                                     name:UITextViewTextDidEndEditingNotification
                                                   object:self];
        self.placeholderColor = [UIColor colorWithRed:204. / 255. green:204. / 255. blue:204. / 255. alpha:1.0];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    // Fixes iOS 5.x cursor when becomeFirstResponder
    if ([UIDevice currentDevice].systemVersion.floatValue < 6.000000) {
        if (self.isUsingPlaceholder && self.isFirstResponder) {
            self.text = @"";
        }
    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (self.isUsingPlaceholder && action != @selector(paste:)) {
        return NO;
    }

    return [super canPerformAction:action withSender:sender];
}

- (NSString *)text {
    NSString *text = [super text];
    if (self.isUsingPlaceholder) {
        return nil;
    }
    return text;
}

#pragma mark -
#pragma mark Notifications

- (void)textDidBeginEditing:(id)notification {
    if (self.isUsingPlaceholder) {
        [self sendCursorToBeginning];
    }
}

- (void)textDidEndEditing:(id)notification {
    if (super.text.length == 0) {
        [self setupPlaceholder];
    }
}

- (void)textDidChanged:(id)notification {
    // self.text received the placeholder text by CPTex tViewPlaceholder
    if (self.isSettingPlaceholder || (self.isUsingPlaceholder && [self.lastText isEqualToString:super.text])) {
        return;
    }

    if (super.text.length == 0) {
        [self setupPlaceholder];
        return;
    }

    if (self.isUsingPlaceholder) {
        self.usingPlaceholder = NO;
        NSRange range;
        range.location = NSNotFound;
        if (self.placeholder.length > 0) {
            range = [super.text rangeOfString:self.placeholder options:NSLiteralSearch];   
        }
        if (range.location != NSNotFound) {
            NSString *newText = [super.text stringByReplacingCharactersInRange:range withString:@""];
            super.textColor = self.color;
            // User pasted a text equals to placeholder or setText was called
            if ([newText isEqualToString:self.placeholder]) {
                [self sendCursorToEnd];
                // this is necessary for iOS 5.x
            } else if (newText.length == 0) {
                [self setupPlaceholder];
                return;
            }
            self.text = newText;
        }
    }
    self.lastText = super.text;
}

#pragma mark - Getters and Setters

- (void)setPlaceholder:(NSString *)placeholder {
    _placeholder = placeholder;
    if (self.isUsingPlaceholder || super.text.length == 0) {
        [self setupPlaceholder];
    }
}

- (void)setTextColor:(UIColor *)textColor {
    [super setTextColor:textColor];
    self.color = textColor;
}

- (void)setSelectedRange:(NSRange)selectedRange {
    if (self.isUsingPlaceholder) {
        [self sendCursorToBeginning];
    } else {
        [super setSelectedRange:selectedRange];
    }
}

- (void)setSelectedTextRange:(UITextRange *)selectedTextRange {
    if (self.isUsingPlaceholder) {
        [self sendCursorToBeginning];
    } else {
        [super setSelectedTextRange:selectedTextRange];
    }
}

- (void)setupPlaceholder {
    super.autocorrectionType = UITextAutocorrectionTypeNo;
    self.usingPlaceholder = YES;
    self.settingPlaceholder = YES;
    self.text = self.placeholder;
    self.settingPlaceholder = NO;
    super.textColor = self.placeholderColor;
    [self sendCursorToBeginning];
    self.lastText = self.placeholder;
}

- (void)sendCursorToBeginning {
    // code required to send the cursor correctly
    [self performSelector:@selector(cursorToBeginning) withObject:nil afterDelay:0.01];
}

- (void)cursorToBeginning {
    super.selectedRange = NSMakeRange(0, 0);
}

- (void)sendCursorToEnd {
    // code required to send the cursor correctly
    [self performSelector:@selector(cursorToEnd) withObject:nil afterDelay:0.01];
}

- (void)cursorToEnd {
    super.selectedRange = NSMakeRange(super.text.length, 0);
}

@end
