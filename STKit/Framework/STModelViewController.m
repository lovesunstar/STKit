//
//  STModelViewController.m
//  STKit
//
//  Created by SunJiangting on 13-12-17.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import "STModelViewController.h"
#import "Foundation+STKit.h"

@interface STModelViewController ()

@end

@implementation STModelViewController

+ (Class)modelClass {
    return Nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        Class class = [[self class] modelClass];
        if (STClassIsKindOfClass(class, [STModel class])) {
            self.model = [[class alloc] init];
            self.model.delegate = self;
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)modelWillStartLoadData:(STModel *)model {
}

- (void)modelDidFinishLoadData:(STModel *)model {
}

/// 当加载失败是，error不为nil。
- (void)modelDidFailedLoadData:(STModel *)model {
}

/// 如果正在加载更多，但是又触发了下拉刷新，则取消加载更多
- (void)modelDidCancelLoadData:(STModel *)model {
}

- (void)model:(STModel *)model didInsertItemAtIndexPaths:(NSArray *)indexPaths {
    
}

- (void)model:(STModel *)model didReloadItemAtIndexPaths:(NSArray *)indexPaths {
    
}

- (void)model:(STModel *)model didDeleteItemAtIndexPaths:(NSArray *)indexPaths {
    
}
@end
