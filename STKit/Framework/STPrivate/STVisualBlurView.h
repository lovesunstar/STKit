//
//  STVisualBlurView.h
//  STKit
//
//  Created by SunJiangting on 14-9-22.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <STKit/UIKit+STKit.h>

@interface STVisualBlurView : UIView

- (instancetype)initWithBlurEffectStyle:(STBlurEffectStyle)blurEffectStyle;

@property (nonatomic, strong, readonly) UIView  *contentView;
@property (nonatomic, strong) UIColor           *tintColor;
@property (nonatomic, assign) BOOL              hasBlurEffect;

@end
