//
//  UIView+STConstraint.m
//  STKit
//
//  Created by SunJiangting on 15-1-21.
//  Copyright (c) 2015年 SunJiangting. All rights reserved.
//

#import "UIView+STConstraint.h"

@implementation UIView (STConstraint)

- (NSArray *)st_constraintsWithFirstItem:(UIView *)firstItem {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:2];
    [self.constraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *obj, NSUInteger idx, BOOL *stop) {
        if ([obj.firstItem isEqual:firstItem]) {
            [array addObject:obj];
        }
    }];
    return [array copy];
}

- (NSArray *)st_constraintsWithFirstItem:(UIView *)firstItem
                          firstAttribute:(NSLayoutAttribute)attribute {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:2];
    [self.constraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *obj, NSUInteger idx, BOOL *stop) {
        if ([obj.firstItem isEqual:firstItem] && obj.firstAttribute == attribute) {
            [array addObject:obj];
        }
    }];
    return [array copy];
}
@end
