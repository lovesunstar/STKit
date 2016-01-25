//
//  STModel.m
//  STKit
//
//  Created by SunJiangting on 13-12-17.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import "STModel.h"

@interface STModel ()

@end

@implementation STModel

- (BOOL)hasNextPage {
    return NO;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self saveDataToCache];
}

- (instancetype)init {
    self = [super init];
    if (self) {
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(_applicationDidEnterBackground:)
//                                                     name:UIApplicationDidEnterBackgroundNotification
//                                                   object:nil];
    }
    return self;
}

- (NSInteger)numberOfDataItems {
    return 0;
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

/// 从Cache加载
- (void)loadDataFromCache {
    self.sourceType = STModelDataSourceTypeCache;
}

- (void)loadDataFromRemote {
    if (self.paginationOperation) {
        [self.paginationOperation cancel];
        [self requestDidCancelWithObject:nil];
    }
    self.sourceType = STModelDataSourceTypeRemote;
    if ([self.delegate respondsToSelector:@selector(modelWillStartLoadData:)]) {
        [self.delegate modelWillStartLoadData:self];
    }
}

- (void)loadDataFromPagination {
    self.sourceType = STModelDataSourceTypePagination;
    if ([self.delegate respondsToSelector:@selector(modelWillStartLoadData:)]) {
        [self.delegate modelWillStartLoadData:self];
    }
}

- (void)saveDataToCache {

}

/// 清除缓存
- (void)invalidateData {
    
}

- (void)requestDidFinishWithObject:(id)object {
    if ([self.delegate respondsToSelector:@selector(modelDidFinishLoadData:)]) {
        [self.delegate modelDidFinishLoadData:self];
    }
    if (self.paginationOperation) {
        self.paginationOperation = nil;
    }
}

- (void)requestDidCancelWithObject:(id)object {
    if (self.paginationOperation) {
        self.paginationOperation = nil;
        if ([self.delegate respondsToSelector:@selector(modelDidCancelLoadData:)]) {
            [self.delegate modelDidCancelLoadData:self];
        }
    }
}

- (void)requestDidFailedWithObject:(id)object error:(NSError *)error {
    self.error = error;
    if ([self.delegate respondsToSelector:@selector(modelDidFailedLoadData:)]) {
        [self.delegate modelDidFailedLoadData:self];
    }
    if (self.paginationOperation) {
        /// 加载更多失败
        self.paginationOperation = nil;
    }
}

- (void)_applicationDidEnterBackground:(NSNotification *)notification {
    [self saveDataToCache];
}

- (void)insertItem:(id)item atIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)deleteItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)deleteItemsAtIndexPaths:(NSArray *)indexPaths {
    
}

- (NSArray *)itemsAtIndexPaths:(NSArray *)indexPaths {
    return nil;
}

@end