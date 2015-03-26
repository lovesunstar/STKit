//
//  STTableView.m
//  STKit
//
//  Created by SunJiangting on 14-5-14.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STTableView.h"

@interface STTableView ()

@property(nonatomic, strong) NSMutableDictionary *classIdentifier;

@property(nonatomic, strong) UIView *footerView;
@property(nonatomic, strong) UIView *conditionView;

@end

@implementation STTableView

- (void)registerClass:(Class)cellClass forCellReuseIdentifier:(NSString *)identifier {
    if ([UITableView instancesRespondToSelector:@selector(registerClass:forCellReuseIdentifier:)]) {
        [super registerClass:cellClass forCellReuseIdentifier:identifier];
    } else {
        if (identifier.length == 0) {
            @throw [NSException exceptionWithName:@"RegisterClass or identifier can not be NULL" reason:nil userInfo:nil];
        } else {
            [self.classIdentifier setValue:cellClass ? NSStringFromClass(cellClass):nil forKey:identifier];
        }
    }
}

- (NSMutableDictionary *)classIdentifier {
    if (!_classIdentifier) {
        _classIdentifier = [NSMutableDictionary dictionaryWithCapacity:5];
    }
    return _classIdentifier;
}

- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier {
    id cell = [super dequeueReusableCellWithIdentifier:identifier];
    if (!cell && [self.classIdentifier valueForKey:identifier]) {
        NSString *class = [self.classIdentifier valueForKey:identifier];
        Class cellCls = NSClassFromString(class);
        if ([cellCls instancesRespondToSelector:@selector(initWithStyle:reuseIdentifier:)]) {
            cell = [[cellCls alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        }
    }
    return cell;
}

- (void)setConditionView:(UIView *)conditionView {
    if (conditionView) {
        [super setTableFooterView:conditionView];
    } else {
        [super setTableFooterView:self.footerView];
    }
    _conditionView = conditionView;
}

- (void)setTableFooterView:(UIView *)tableFooterView {
    if (!self.conditionView) {
        [super setTableFooterView:tableFooterView];
    }
    _footerView = tableFooterView;
}
@end