//
//  STCollectionViewFlowLayout.m
//  STKit
//
//  Created by SunJiangting on 14-5-8.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STCollectionViewFlowLayout.h"
#import <objc/runtime.h>

@interface STCollectionViewFlowLayout ()

@property(nonatomic, weak) id<STCollectionViewFlowLayoutDelegate> delegate;

@property(nonatomic, strong) NSMutableArray *columnHeights;

@property(nonatomic, strong) NSMutableArray *sectionItemAttributes;
@property(nonatomic, strong) NSMutableArray *itemAttributes;

@property(nonatomic, assign) CGFloat itemWidth;

@end

@implementation STCollectionViewFlowLayout
- (instancetype)init {
    self = [super init];
    if (self) {
        _numberOfColumns = 2;
        _minimumLineSpacing = 10;
        _minimumInteritemSpacing = 10;
        _sectionInset = UIEdgeInsetsZero;

        self.columnHeights = [NSMutableArray arrayWithCapacity:_numberOfColumns];
        self.itemAttributes = [NSMutableArray arrayWithCapacity:2];
        self.sectionItemAttributes = [NSMutableArray arrayWithCapacity:2];
    }
    return self;
}

- (CGFloat)itemWidthInSectionAtIndex:(NSInteger)section {
    if (self.itemWidth > 0) {
        return self.itemWidth;
    }
    UIEdgeInsets sectionInset = self.sectionInset;
    ;
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)]) {
        sectionInset = [self.delegate collectionView:self.collectionView layout:self insetForSectionAtIndex:section];
    }
    CGFloat minimumLineSpacing = self.minimumLineSpacing;
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:minimumLineSpacingForSectionAtIndex:)]) {
        minimumLineSpacing = [self.delegate collectionView:self.collectionView layout:self minimumLineSpacingForSectionAtIndex:section];
    }
    CGFloat width = self.collectionView.frame.size.width - sectionInset.left - sectionInset.right;
    self.itemWidth = floorf((width - (self.numberOfColumns - 1) * minimumLineSpacing) / self.numberOfColumns);
    return self.itemWidth;
}

- (id<STCollectionViewFlowLayoutDelegate>)delegate {
    return (id<STCollectionViewFlowLayoutDelegate>)self.collectionView.delegate;
}

#pragma mark - Methods to Override
- (void)prepareLayout {
    [super prepareLayout];
    NSInteger numberOfSections = [self.collectionView numberOfSections];
    if (numberOfSections == 0 || self.numberOfColumns == 0) {
        return;
    }
    self.itemWidth = 0;
    [self.columnHeights removeAllObjects];
    [self.itemAttributes removeAllObjects];
    [self.sectionItemAttributes removeAllObjects];
    for (NSInteger i = 0; i < self.numberOfColumns; i++) {
        [self.columnHeights addObject:@(0)];
    }
    CGRect headerViewFrame = self.collectionView.collectionHeaderView.frame;
    headerViewFrame.origin = CGPointZero;
    headerViewFrame.size.width = CGRectGetWidth(self.collectionView.bounds);
    self.collectionView.collectionHeaderView.frame = headerViewFrame;
    CGFloat top = CGRectGetMaxY(headerViewFrame);

    for (NSInteger section = 0; section < numberOfSections; section++) {
        CGFloat minimumLineSpacing = self.minimumLineSpacing;
        if ([self.delegate respondsToSelector:@selector(collectionView:layout:minimumLineSpacingForSectionAtIndex:)]) {
            minimumLineSpacing = [self.delegate collectionView:self.collectionView layout:self minimumLineSpacingForSectionAtIndex:section];
        }
        CGFloat minimumInteritemSpacing = self.minimumInteritemSpacing;
        ;
        if ([self.delegate respondsToSelector:@selector(collectionView:layout:minimumInteritemSpacingForSectionAtIndex:)]) {
            minimumInteritemSpacing = [self.delegate collectionView:self.collectionView layout:self minimumInteritemSpacingForSectionAtIndex:section];
        }
        UIEdgeInsets sectionInset = self.sectionInset;
        if ([self.delegate respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)]) {
            sectionInset = [self.delegate collectionView:self.collectionView layout:self insetForSectionAtIndex:section];
        }
        CGFloat width = CGRectGetWidth(self.collectionView.frame) - (sectionInset.left + sectionInset.right);
        CGFloat itemWidth = floorf((width - (self.numberOfColumns - 1) * minimumLineSpacing) / self.numberOfColumns);
        top += sectionInset.top;
        /// 每个section是顶部对齐的
        for (NSInteger i = 0; i < self.numberOfColumns; i++) {
            self.columnHeights[i] = @(top);
        }
        NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:section];
        NSMutableArray *itemAttributes = [NSMutableArray arrayWithCapacity:numberOfItems];
        for (NSInteger i = 0; i < numberOfItems; i++) {
            /// 每一次都把下一个元素添加到最短的那一列上
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:section];
            NSUInteger columnIndex = [self indexOfMinimumHeightColumn];
            CGFloat left = sectionInset.left + (itemWidth + minimumLineSpacing) * columnIndex;
            CGFloat top = [self.columnHeights[columnIndex] floatValue];
            CGSize size = self.itemSize;
            if ([self.delegate respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)]) {
                size = [self.delegate collectionView:self.collectionView layout:self sizeForItemAtIndexPath:indexPath];
            }
            CGFloat itemHeight = 0;
            if (size.height > 0 && size.width > 0) {
                itemHeight = floorf(size.height * itemWidth / size.width);
            }
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            attributes.frame = CGRectMake(left, top, itemWidth, itemHeight);
            [itemAttributes addObject:attributes];

            [self.itemAttributes addObject:attributes];
            self.columnHeights[columnIndex] = @(CGRectGetMaxY(attributes.frame) + minimumInteritemSpacing);
        }

        [self.sectionItemAttributes addObject:itemAttributes];
        NSUInteger columnIndex = [self indexOfMaximumHeightColumn];

        top = [self.columnHeights[columnIndex] floatValue] - minimumInteritemSpacing + sectionInset.bottom;
        for (NSInteger i = 0; i < self.numberOfColumns; i++) {
            self.columnHeights[i] = @(top);
        }
    }

    CGRect footerViewFrame = self.collectionView.collectionFooterView.frame;
    footerViewFrame.origin.x = 0;
    footerViewFrame.origin.y = [self.columnHeights[0] intValue];
    footerViewFrame.size.width = CGRectGetWidth(self.collectionView.frame);
    self.collectionView.collectionFooterView.frame = footerViewFrame;
    CGFloat totalHeight = [self.columnHeights[0] floatValue] + CGRectGetHeight(footerViewFrame);
    for (NSInteger i = 0; i < self.numberOfColumns; i++) {
        self.columnHeights[i] = @(totalHeight);
    }
}

//- (NSArray *)

- (CGSize)collectionViewContentSize {
    CGFloat headerHeight = CGRectGetHeight(self.collectionView.collectionHeaderView.frame);
    CGFloat footerHeight = CGRectGetHeight(self.collectionView.collectionFooterView.frame);

    NSInteger numberOfSections = [self.collectionView numberOfSections];
    CGFloat width = CGRectGetWidth(self.collectionView.frame);
    CGFloat height = headerHeight + footerHeight;
    if (numberOfSections > 0) {
        height = [self.columnHeights[0] floatValue];
    }
    CGFloat insets = self.collectionView.contentInset.top + self.collectionView.contentInset.bottom;
    CGFloat effectedHeight = CGRectGetHeight(self.collectionView.frame) - insets;
    if (height <= effectedHeight) {
        height = effectedHeight + 1;
    }
    return CGSizeMake(width, height);
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)path {
    if (path.section >= self.sectionItemAttributes.count || path.item >= [self.sectionItemAttributes[path.section] count]) {
        return nil;
    }
    return (self.sectionItemAttributes[path.section])[path.item];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *attributes = [NSMutableArray arrayWithCapacity:2];
    [self.itemAttributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *attribute, NSUInteger idx, BOOL *stop) {
        CGRect frame = attribute.frame;
        if (CGRectIntersectsRect(frame, rect)) {
            [attributes addObject:attribute];
        }
    }];
    return [attributes copy];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    CGRect oldBounds = self.collectionView.bounds;
    if (CGRectGetWidth(newBounds) != CGRectGetWidth(oldBounds)) {
        return YES;
    }
    return NO;
}

#pragma mark - Setters
- (void)setNumberOfColumns:(NSUInteger)numberOfColumns {
    if (_numberOfColumns != numberOfColumns) {
        _numberOfColumns = numberOfColumns;
        [self invalidateLayout];
    }
}

- (void)setMinimumLineSpacing:(CGFloat)minimumLineSpacing {
    if (_minimumLineSpacing != minimumLineSpacing) {
        _minimumLineSpacing = minimumLineSpacing;
        [self invalidateLayout];
    }
}

- (void)setMinimumInteritemSpacing:(CGFloat)minimumInteritemSpacing {
    if (_minimumInteritemSpacing != minimumInteritemSpacing) {
        _minimumInteritemSpacing = minimumInteritemSpacing;
        [self invalidateLayout];
    }
}

- (void)setSectionInset:(UIEdgeInsets)sectionInset {
    if (!UIEdgeInsetsEqualToEdgeInsets(_sectionInset, sectionInset)) {
        _sectionInset = sectionInset;
        [self invalidateLayout];
    }
}

- (void)setItemSize:(CGSize)itemSize {
    if (!CGSizeEqualToSize(_itemSize, itemSize)) {
        _itemSize = itemSize;
        [self invalidateLayout];
    }
}

#pragma mark - Private Methods
/// 高度最矮的那个列
- (NSUInteger)indexOfMinimumHeightColumn {
    __block NSUInteger index = 0;
    __block CGFloat shortestHeight = MAXFLOAT;
    [self.columnHeights enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CGFloat height = [obj floatValue];
        if (height < shortestHeight) {
            shortestHeight = height;
            index = idx;
        }
    }];
    return index;
}

/// 高度最高的那一列
- (NSUInteger)indexOfMaximumHeightColumn {
    __block NSUInteger index = 0;
    __block CGFloat longestHeight = 0;
    [self.columnHeights enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CGFloat height = [obj floatValue];
        if (height > longestHeight) {
            longestHeight = height;
            index = idx;
        }
    }];

    return index;
}
@end

@implementation UICollectionView (STHeaderFooterView)

const char *STCollectionViewHeaderViewKey = "STCollectionViewHeaderViewKey";

- (void)setCollectionHeaderView:(UIView *)collectionHeaderView {
    UIView *previousHeaderView = [self collectionHeaderView];
    objc_setAssociatedObject(self, STCollectionViewHeaderViewKey, collectionHeaderView, OBJC_ASSOCIATION_RETAIN);
    [previousHeaderView removeFromSuperview];
    [self addSubview:collectionHeaderView];
    [self.collectionViewLayout invalidateLayout];
}

- (UIView *)collectionHeaderView {
    return objc_getAssociatedObject(self, STCollectionViewHeaderViewKey);
}

const char *STCollectionFooterViewKey = "STCollectionFooterViewKey";

- (void)setCollectionFooterView:(UIView *)collectionFooterView {
    UIView *previousFooter = [self collectionFooterView];
    objc_setAssociatedObject(self, STCollectionFooterViewKey, collectionFooterView, OBJC_ASSOCIATION_RETAIN);
    [previousFooter removeFromSuperview];
    [self addSubview:collectionFooterView];
    [self.collectionViewLayout invalidateLayout];
}

- (UIView *)collectionFooterView {
    return objc_getAssociatedObject(self, STCollectionFooterViewKey);
}
@end
