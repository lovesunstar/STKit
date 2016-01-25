//
//  STVisualBlurView.h
//  STKit
//
//  Created by SunJiangting on 14-9-22.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <STKit/UIKit+STKit.h>

ST_ASSUME_NONNULL_BEGIN
@interface STVisualBlurView : UIView

- (instancetype)initWithBlurEffectStyle:(STBlurEffectStyle)blurEffectStyle NS_DESIGNATED_INITIALIZER;
/// subviews must add to contentView
@property(nonatomic, strong, readonly) UIView         *contentView;
@property(STPROPERTYNULLABLE nonatomic, copy) UIColor *color;
@property(nonatomic, getter=hasBlurEffect) BOOL hasBlurEffect;

@end
ST_ASSUME_NONNULL_END
