//
//  STRateControl.m
//  STKit
//
//  Created by SunJiangting on 14-9-18.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STRateControl.h"

@implementation STRateControl

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _verticalMargin = 5;
        _maximumValue = 5;
        _value = 0;
        [self relayoutSubviews];
    }
    return self;
}

- (void)relayoutSubviews {
}

- (void)sizeToFit {
    [super sizeToFit];
}
@end
