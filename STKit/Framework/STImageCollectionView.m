//
//  STImageCollectionView.m
//  STKit
//
//  Created by SunJiangting on 14-8-25.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STImageCollectionView.h"
#import "UIKit+STKit.h"
#import "STImageScrollView.h"
#import "STResourceManager.h"
#import "STImageCache.h"

@class STImageCollectionViewCell;
@protocol STImageCollectionViewCellDelegate <NSObject>

@optional
- (void)imageCollectionViewCellDidTap:(STImageCollectionViewCell *)cell;
@optional
- (void)imageCollectionViewCellDidLongPress:(STImageCollectionViewCell *)cell;

@end

@interface STImageCollectionViewCell : UICollectionViewCell <STImageScrollViewDelegate>

@property(nonatomic, strong) STImageScrollView *imageView;
@property(nonatomic, weak) STImageItem *imageItem;

@property(nonatomic, weak) id<STImageCollectionViewCellDelegate> delegate;

@end

@implementation STImageCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (STImageScrollView *)imageView {
    if (!_imageView) {
        _imageView = [[STImageScrollView alloc] initWithFrame:self.bounds];
        _imageView.autoFitImageView = NO;
        _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_imageView];
    }
    return _imageView;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    _imageView.frame = self.bounds;
}

- (void)setImageItem:(STImageItem *)imageItem {
    if (imageItem) {
        self.imageView.interactionDelegate = self;
    }
    _imageItem = imageItem;
}

- (void)imageScrollViewDidTapped:(STImageScrollView *)imageScrollView {
    if ([self.delegate respondsToSelector:@selector(imageCollectionViewCellDidTap:)]) {
        [self.delegate imageCollectionViewCellDidTap:self];
    }
}

- (void)imageScrollViewDidLongPressed:(STImageScrollView *)imageScrollView {
    if ([self.delegate respondsToSelector:@selector(imageCollectionViewCellDidLongPress:)]) {
        [self.delegate imageCollectionViewCellDidLongPress:self];
    }
}

@end

@interface STImageCollectionView () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,
                                     STImageCollectionViewCellDelegate>

@property(nonatomic, strong) UICollectionView *collectionView;
@property(nonatomic, strong) UIButton *saveButton;

@end

@implementation STImageCollectionView {
    STImageScrollView *_defaultImageScrollView;
    STIdentifier _imageCacheIdentifier;
    CGSize _itemSize;
}

- (void)dealloc {
    STImageCachePopContext(_imageCacheIdentifier);
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame images:nil];
}
- (instancetype)initWithFrame:(CGRect)frame images:(NSArray *)images {
    self = [super initWithFrame:frame];
    if (self) {
        _imageCacheIdentifier = STImageCacheBeginContext();
        STImageCachePushContext(_imageCacheIdentifier);

        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.minimumInteritemSpacing = 0;
        flowLayout.minimumLineSpacing = 0;
        flowLayout.itemSize = CGSizeZero;
        flowLayout.headerReferenceSize = CGSizeZero;
        flowLayout.footerReferenceSize = CGSizeZero;
        flowLayout.sectionInset = UIEdgeInsetsZero;
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;

        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:flowLayout];
        collectionView.delaysContentTouches = NO;
        collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [collectionView registerClass:[STImageCollectionViewCell class] forCellWithReuseIdentifier:@"Identifier"];
        collectionView.pagingEnabled = YES;
        collectionView.dataSource = self;
        collectionView.delegate = self;
        collectionView.backgroundView = nil;
        collectionView.backgroundColor = [UIColor clearColor];
        collectionView.showsHorizontalScrollIndicator = NO;
        collectionView.showsVerticalScrollIndicator = NO;
        [self addSubview:collectionView];
        self.collectionView = collectionView;

        __block NSInteger index;
        __weak STImageCollectionView *weakSelf = self;
        collectionView.willReloadData = ^{ index = weakSelf.currentImageIndex; };
        collectionView.didReloadData = ^{ weakSelf.currentImageIndex = index; };

        UIButtonType buttonType = STGetSystemVersion() >= 7 ? UIButtonTypeSystem : UIButtonTypeCustom;
        self.saveButton = [UIButton buttonWithType:buttonType];
        [self.saveButton setImage:[STResourceManager imageWithResourceID:STImageResourceSaveToAlbumID] forState:UIControlStateNormal];
        [self.saveButton addTarget:self action:@selector(saveToAlbumActionFired:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.saveButton];

        self.horizontalSpacing = 10;
        _images = images;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.saveButton.frame = CGRectMake(CGRectGetWidth(self.frame) - 80, CGRectGetHeight(self.frame) - 60, 60, 40);
}
- (void)saveToAlbumActionFired:(id)sender {
    if ([self.delegate respondsToSelector:@selector(imageCollectionView:didLongPressImage:atIndex:)]) {
        [self.delegate imageCollectionView:self didLongPressImage:self.imageScrollView.imageView.image atIndex:self.currentImageIndex];
    }
}

- (void)setImages:(NSArray *)images {
    [self setImages:images animated:NO];
}

- (void)setImages:(NSArray *)images animated:(BOOL)animated {
    if (_currentImageIndex >= images.count) {
        _currentImageIndex = 0;
    }
    _images = [images copy];
    self.collectionView.scrollEnabled = (images.count > 1);
    [self.collectionView reloadData];
}

- (void)setCurrentImageIndex:(NSUInteger)currentImageIndex {
    if (currentImageIndex < self.images.count) {
        _currentImageIndex = currentImageIndex;
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:currentImageIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    }
}

#pragma mark - UICollectionFlowLayoutDelegate

- (CGSize)preferredItemSize {
    UIEdgeInsets insets = self.collectionView.contentInset;
    CGSize size = self.frame.size;
    size.height -= (insets.top + insets.bottom);
    if (size.height < 0) {
        size = CGSizeZero;
    }
    _itemSize = size;
    return size;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                    layout:(UICollectionViewLayout *)collectionViewLayout
    sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self preferredItemSize];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.images.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    STImageCollectionViewCell *collectionViewCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Identifier" forIndexPath:indexPath];
    if (_defaultImageScrollView) {
        collectionViewCell.imageView = _defaultImageScrollView;
        _defaultImageScrollView.autoFitImageView = NO;
        [collectionViewCell addSubview:_defaultImageScrollView];
        _defaultImageScrollView = nil;
    }
    collectionViewCell.delegate = self;
    STImageItem *imageItem = self.images[indexPath.row];
    collectionViewCell.imageItem = imageItem;
    if ([imageItem isKindOfClass:[STImageItem class]]) {
        UIImage *thumb = imageItem.thumb;
        if (!thumb) {
            thumb = [STImageCache cachedImageForKey:imageItem.thumbURLString];
        }
        if (!thumb) {
            thumb = [STResourceManager imageWithResourceID:STImageResourcePlaceholderID];
        }
        [collectionViewCell.imageView setImage:thumb animated:NO];
        if (imageItem.image) {
            [collectionViewCell.imageView setImage:imageItem.image animated:YES];
        } else {
            [collectionViewCell.imageView setImageURL:imageItem.imageURLString animated:YES];
        }
    }
    if (STGetSystemVersion() < 8) {
        /// 高于iOS8版本会自己调用
        [self _willDisplayCell:collectionViewCell forItemAtIndexPath:indexPath];
    }
    return collectionViewCell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [self _willDisplayCell:cell forItemAtIndexPath:indexPath];
}

- (void)_willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    STImageCollectionViewCell *collectionViewCell = (STImageCollectionViewCell *)cell;
    CGRect frame = collectionViewCell.bounds;
    CGFloat margin = self.horizontalSpacing / 2.0;
    frame.origin.x = margin;
    frame.size.width -= self.horizontalSpacing;
    collectionViewCell.imageView.frame = frame;
    [collectionViewCell.imageView zoomToFit];
    if ([self.delegate respondsToSelector:@selector(imageCollectionView:didDisplayImageAtIndex:)]) {
        [self.delegate imageCollectionView:self didDisplayImageAtIndex:indexPath.row];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    CGFloat targetX = (*targetContentOffset).x;
    if (_itemSize.width == 0) {
        _currentImageIndex = 0;
    }
    _currentImageIndex = targetX / _itemSize.width;
}

- (STImageScrollView *)imageScrollView {
    if (_defaultImageScrollView) {
        return _defaultImageScrollView;
    }
    if (_images.count == 0) {
        return nil;
    }
    NSArray *collectionViewCells = [self.collectionView visibleCells];
    if (collectionViewCells.count != 1) {
        return nil;
    }
    STImageCollectionViewCell *collectionViewCell = collectionViewCells[0];
    return collectionViewCell.imageView;
}

- (void)imageCollectionViewCellDidTap:(STImageCollectionViewCell *)cell {
    if ([self.delegate respondsToSelector:@selector(imageCollectionView:didTapImageAtIndex:)]) {
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        if (indexPath) {
            [self.delegate imageCollectionView:self didTapImageAtIndex:indexPath.row];
        }
    }
}

- (void)imageCollectionViewCellDidLongPress:(STImageCollectionViewCell *)cell {
    if ([self.delegate respondsToSelector:@selector(imageCollectionView:didLongPressImage:atIndex:)]) {
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        if (indexPath) {
            [self.delegate imageCollectionView:self didLongPressImage:self.imageScrollView.imageView.image atIndex:indexPath.row];
        }
    }
}

@end

@implementation STImageItem

@end