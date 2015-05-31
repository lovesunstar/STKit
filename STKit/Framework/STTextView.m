//
//  STTextView.m
//  STKit
//
//  Created by SunJiangting on 14-1-7.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STTextView.h"

@interface STTextView ()

@property(nonatomic, strong) STLabel *placeholderLabel;

@end

@implementation STTextView

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self _commonInitializer];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _commonInitializer];
    }
    return self;
}

- (void)_commonInitializer {
    self.placeholderLabel = ({
        STLabel *label = [[STLabel alloc] initWithFrame:self.bounds];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor colorWithRed:204. / 255. green:204. / 255. blue:204. / 255. alpha:1.0];
        label.userInteractionEnabled = NO;
        label.font = self.font;
        label.numberOfLines = 0;
        label.verticalAlignment = STVerticalAlignmentTop;
        label;
    });
    [self addSubview:self.placeholderLabel];
    
    if ([self respondsToSelector:@selector(layoutManager)]) {
        self.layoutManager.allowsNonContiguousLayout = NO;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChanged:) name:UITextViewTextDidChangeNotification object:self];
}

- (void)setFont:(UIFont *)font {
    [super setFont:font];
    self.placeholderLabel.font = font;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UIEdgeInsets containerInset = self.contentInset;
    if ([self respondsToSelector:@selector(textContainer)]) {
        containerInset = self.textContainerInset;
        containerInset.left += self.textContainer.lineFragmentPadding;
        containerInset.right += self.textContainer.lineFragmentPadding;
    }
    self.placeholderLabel.contentInsets = containerInset;
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment {
    [super setTextAlignment:textAlignment];
    self.placeholderLabel.textAlignment = textAlignment;
}

#pragma mark -
#pragma mark Notifications

- (void)textDidChanged:(id)notification {
    self.placeholderLabel.hidden = (self.text.length > 0 || self.attributedText.length > 0);
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    [super setAttributedText:attributedText];
    [self textDidChanged:nil];
}

- (void)setText:(NSString *)text {
    [super setText:text];
    [self textDidChanged:nil];
}

#pragma mark - Getters and Setters

- (void)setPlaceholder:(NSString *)placeholder {
    _placeholder = placeholder;
    self.placeholderLabel.text = placeholder;
}

@end
