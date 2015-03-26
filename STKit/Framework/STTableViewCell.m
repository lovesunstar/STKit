//
//  STTableViewCell.m
//  STKit
//
//  Created by SunJiangting on 15-1-19.
//  Copyright (c) 2015年 SunJiangting. All rights reserved.
//

#import "STTableViewCell.h"

@interface STTableViewCell ()

@property (nonatomic, strong)UIView *highlightedBackgroundView;
@property (nonatomic, strong)UIView *backgroundColorView;

@end

@implementation STTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.highlightedBackgroundView =[[UIView alloc] initWithFrame:self.bounds];
        self.highlightedBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:self.highlightedBackgroundView];
        self.highlightedBackgroundView.hidden = YES;
        [self.contentView sendSubviewToBack:self.highlightedBackgroundView];
        
        self.backgroundColorView = [[UIView alloc] initWithFrame:self.bounds];
        self.backgroundColorView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:self.backgroundColorView];
        [self.contentView sendSubviewToBack:self.backgroundColorView];
    }
    return self;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:[UIColor clearColor]];
    self.backgroundColorView.backgroundColor = backgroundColor;
}

- (void)setSelectedBackgroundColor:(UIColor *)selectedBackgroundColor {
    self.highlightedBackgroundView.backgroundColor = selectedBackgroundColor;
    _selectedBackgroundColor = selectedBackgroundColor;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    self.highlightedBackgroundView.hidden = !highlighted;
}

@end
