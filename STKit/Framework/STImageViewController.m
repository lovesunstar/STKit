//
//  STImageViewController.m
//  STKit
//
//  Created by SunJiangting on 13-12-25.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import "STImageViewController.h"

#import "STImageScrollView.h"

@interface STPreviewCollectionViewCell : UICollectionViewCell

@property(nonatomic, strong) STImageScrollView *imageScrollView;

@end

@implementation STPreviewCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.imageScrollView = [[STImageScrollView alloc] initWithFrame:self.bounds];
        self.imageScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.imageScrollView];
    }
    return self;
}

@end

@interface STPreviewContentView : UIView <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property(nonatomic, strong) UICollectionView *collectionView;

@property(nonatomic, weak) id<STImageViewControllerDelegate> delegate;

@property(nonatomic, assign) NSInteger selectedIndex;
/// 所有Image 数组
@property(nonatomic, copy) NSArray *imageDataSource;

@end

@implementation STPreviewContentView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.minimumLineSpacing = 0;
        flowLayout.minimumInteritemSpacing = 0;
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;

        self.collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:flowLayout];
        self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.collectionView.dataSource = self;
        self.collectionView.delegate = self;
        self.collectionView.pagingEnabled = YES;
        self.collectionView.showsHorizontalScrollIndicator = NO;
        self.collectionView.showsVerticalScrollIndicator = NO;
        [self addSubview:self.collectionView];
        [self.collectionView registerClass:[STPreviewCollectionViewCell class] forCellWithReuseIdentifier:@"Identifier"];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self.collectionView reloadData];
}

#pragma mark - UICollecitonViewDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView
                    layout:(UICollectionViewLayout *)collectionViewLayout
    sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize size = collectionView.bounds.size;
    size.width -= 2;
    size.height -= 2;
    return size;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                                 layout:(UICollectionViewLayout *)collectionViewLayout
    minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                                      layout:(UICollectionViewLayout *)collectionViewLayout
    minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsZero;
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.imageDataSource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    STPreviewCollectionViewCell *collectionViewCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Identifier" forIndexPath:indexPath];
    NSDictionary *imageInfo = self.imageDataSource[indexPath.row];

    STImageScrollView *imageScrollView = collectionViewCell.imageScrollView;

    NSString *thumb = [imageInfo valueForKey:STImagePreviewThumbImageURLKey], *image = [imageInfo valueForKey:STImagePreviewOriginalImageURLKey];
    UIImage *thumbImage = [image valueForKey:STImagePreviewThumbImageKey];
    BOOL thumbCached = [STImageCache hasCachedImageForKey:thumb];
    BOOL imageCached = [STImageCache hasCachedImageForKey:image];
    if (imageCached) {
        [imageScrollView setImageURL:image animated:NO];
    } else {
        if (thumbImage) {
            [imageScrollView setImage:thumbImage animated:NO];
        } else if (thumbCached) {
            [imageScrollView setImageURL:thumb animated:NO];
        }
        [imageScrollView setImageURL:image animated:YES];
    }
    return collectionViewCell;
}

#pragma mark - PrivateMethod

#pragma mark - Preload
- (void)_preloadImageAtIndex:(NSInteger)index {
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    _selectedIndex = selectedIndex;
    if (selectedIndex >= [self.collectionView numberOfItemsInSection:0]) {
        return;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:selectedIndex inSection:0];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
}

- (void)setImageDataSource:(NSArray *)imageDataSource {
    _imageDataSource = [imageDataSource copy];
    self.selectedIndex = 0;
    [self.collectionView reloadData];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = CGRectGetWidth(scrollView.bounds);
    CGFloat pageNO = scrollView.contentOffset.x / pageWidth;
    NSInteger page = floor(pageNO);
    if (page != self.selectedIndex && ABS(page - pageNO) < 0.2) {
        self.selectedIndex = page;
    }
}

@end

@interface STImageViewController ()

@property(nonatomic, assign) BOOL navigationBarTranslucent;

@property(nonatomic, strong) STPreviewContentView *contentView;

@end

@implementation STImageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = self.navigationTitle;
    self.view.backgroundColor = [UIColor grayColor];

    CGRect frame = self.view.bounds;
    if (STGetSystemVersion() >= 7) {
        frame.origin.y = 20;
        frame.size.height -= 20;
    }

    self.contentView = [[STPreviewContentView alloc] initWithFrame:frame];
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.contentView];
    self.contentView.selectedIndex = self.selectedIndex;
    self.contentView.imageDataSource = self.imageDataSource;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - PrivateMethod

- (void)setImageDataSource:(NSArray *)imageDataSource {
    self.contentView.imageDataSource = imageDataSource;

    _imageDataSource = [imageDataSource copy];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    self.contentView.selectedIndex = selectedIndex;
    _selectedIndex = selectedIndex;
}

- (void)setDelegate:(id<STImageViewControllerDelegate>)delegate {
    self.contentView.delegate = delegate;
}

- (id<STImageViewControllerDelegate>)delegate {
    return self.contentView.delegate;
}

@end

// PS. 以下key为imageDataSource Key
/// 预览图片缩略图
NSString *const STImagePreviewThumbImageKey = @"STImagePreviewThumbImageKey";
/// 预览图片缩略图 URL
NSString *const STImagePreviewThumbImageURLKey = @"STImagePreviewThumbImageURLKey";
/// 预览图片大图
NSString *const STImagePreviewOriginalImageURLKey = @"STImagePreviewOriginalImageURLKey";