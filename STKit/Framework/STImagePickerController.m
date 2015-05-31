//
//  STImagePickerController.m
//  STKit
//
//  Created by SunJiangting on 14-1-3.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STImagePickerController.h"
#import <UIKit/UIKit.h>
#import "Foundation+STKit.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "STResourceManager.h"
#import <Photos/Photos.h>

@class _STPhotoGroupViewController, _STAssetViewController;
@protocol _STImagePickerControllerDelegate <NSObject>
@optional
- (void)groupViewControllerDidCancel:(_STPhotoGroupViewController *)groupViewController;
@optional
- (void)assetViewController:(_STAssetViewController *)assetViewController didFinishWithPhotoArray:(NSArray *)photoArray;

@end
#pragma mark - STPhotoCell
@interface _STAssetCollectionCell : UICollectionViewCell

@property(nonatomic, strong) UIImageView *thumbView;

@property(nonatomic, strong) UIImageView *selectedImageView;
@property(nonatomic, strong) UIView *highlightedView;
@property(nonatomic, assign) NSInteger requestID;

@end

const NSInteger _STAssetViewControllerPageSize = 100000000;
@interface _STAssetViewController : STViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout> {
  @private
    NSInteger _page;
}
@property(nonatomic, strong) UIButton    *backBarButton;
@property(nonatomic, weak) id<_STImagePickerControllerDelegate> pickerDelegate;
/// 最多能选取多少张图片
@property(nonatomic, assign) NSInteger maximumNumberOfSelection;
@property(nonatomic, strong) UICollectionView *collectionView;
/// ALAssets/PHAssets, 根据dataSource中的数据，得到所选中的，dataSource为什么类型，asset就是什么类型
@property(nonatomic, strong) NSMutableArray *selectedAssets;
/// 数据源，需要显示的Asset集合
@property(nonatomic, strong) NSMutableArray *dataSource;
/// 即将获取下一页，子类需重写， range会在 0, dataSource.count 之间
- (void)fetchAssetWithRange:(NSRange)range options:(NSEnumerationOptions)options;
/// 共有多少Asset
- (NSInteger)numberOfAssets;
- (void)updatePhotoCellPhotoCell:(_STAssetCollectionCell *)photoCell asset:(NSObject *)asset;
- (NSArray *)compressedImageWithAssets:(NSArray *)assets;
@end

#pragma mark - STPhotoViewController
@interface _STGroupAssetViewController : _STAssetViewController

@property(nonatomic, strong) ALAssetsGroup *assetsGroup;

- (instancetype)initWithAssetsGroup:(ALAssetsGroup *)assetsGroup;

@end

@interface _STPhotoAssetViewController : _STAssetViewController

@property(nonatomic, strong) PHFetchResult *fetchResult;

- (instancetype)initWithFetchResult:(PHFetchResult *)fetchResult;

@end

@interface _STAssetCell : UITableViewCell

@property(nonatomic, strong) UIImageView *posterImageView;

@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UILabel *countLabel;

@property(nonatomic, strong) UIView *topSeparatorView;
@property(nonatomic, strong) UIView *separatorView;

@end

#pragma mark - STPhotoGroupCell
@interface _STGroupAssetCell : _STAssetCell

@property(nonatomic, strong) ALAssetsGroup *assetsGroup;
@end

@interface _STPhotoAssetCell : _STAssetCell

@property(nonatomic, strong) NSObject *fetchResult;
@property(nonatomic, assign) NSInteger imageRequestID;

@end

#pragma mark - STPhotoGroupViewController
@interface _STPhotoGroupViewController : UITableViewController

@property(nonatomic, strong) UIButton    *backBarButton;

@property(nonatomic, strong) ALAssetsLibrary *assetsLibiary;
@property(nonatomic, assign) BOOL allowsMultipleSelection;
@property(nonatomic) BOOL wantsEnterFirstAlbumWhenLoaded;
@property(nonatomic, strong) NSArray *dataSource;
@property(nonatomic, weak) id<_STImagePickerControllerDelegate> pickerDelegate;

@property(nonatomic, assign) NSInteger maximumNumberOfSelection;

@property(nonatomic, strong) UIView *albumEmptyView;
@property(nonatomic, strong) UIView *permissionDeniedView;

@property(nonatomic, strong) NSObject *fetchResult;

@end

#pragma mark - STImagePickerController

@interface STImagePickerController () <_STImagePickerControllerDelegate> {
    UIStatusBarStyle _previousStatusBarStyle;
}

@property(nonatomic, strong) _STPhotoGroupViewController *photoGroupViewController;

@end

@implementation STImagePickerController

- (instancetype)init {
    _STPhotoGroupViewController *photoGroupViewController = [[_STPhotoGroupViewController alloc] initWithStyle:UITableViewStylePlain];
    self = [super initWithRootViewController:photoGroupViewController];
    if (self) {
        self.photoGroupViewController = photoGroupViewController;
        self.photoGroupViewController.pickerDelegate = self;
        self.maximumNumberOfSelection = 20;
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    return [self init];
}

- (void)setMaximumNumberOfSelection:(NSInteger)maximumNumberOfSelection {
    self.photoGroupViewController.maximumNumberOfSelection = maximumNumberOfSelection;
    _maximumNumberOfSelection = maximumNumberOfSelection;
}

- (void)setWantsEnterFirstAlbumWhenLoaded:(BOOL)wantsEnterFirstAlbumWhenLoaded {
    self.photoGroupViewController.wantsEnterFirstAlbumWhenLoaded = wantsEnterFirstAlbumWhenLoaded;
    _wantsEnterFirstAlbumWhenLoaded = wantsEnterFirstAlbumWhenLoaded;
}

- (void)viewDidLoad {
    self.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor blackColor]};
    self.photoGroupViewController.backBarButton = self.backBarButton;
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    UIApplication *application = [UIApplication sharedApplication];
    if ([application respondsToSelector:@selector(setStatusBarStyle:)]) {
        _previousStatusBarStyle = application.statusBarStyle;
        application.statusBarStyle = UIStatusBarStyleDefault;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    UIApplication *application = [UIApplication sharedApplication];
    if ([application respondsToSelector:@selector(setStatusBarStyle:)]) {
        application.statusBarStyle = _previousStatusBarStyle;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)groupViewControllerDidCancel:(_STPhotoGroupViewController *)groupViewController {
    if ([self.delegate respondsToSelector:@selector(imagePickerControllerDidCancel:)]) {
        [self.delegate imagePickerControllerDidCancel:self];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)assetViewController:(_STAssetViewController *)photoController didFinishWithPhotoArray:(NSArray *)photoArray {
    if ([self.delegate respondsToSelector:@selector(imagePickerController:didFinishPickingImageWithInfo:)]) {
        [self.delegate imagePickerController:self didFinishPickingImageWithInfo:@{ @"data" : photoArray }];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)setBackBarButton:(UIButton *)backBarButton {
    _backBarButton = backBarButton;
    self.photoGroupViewController.backBarButton = backBarButton;
}

+ (UIImage *)imageWithIdentifier:(NSString *)identifier {
    NSString *filePath = [STTemporaryDirectory() stringByAppendingPathComponent:identifier];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:NULL]) {
        return [UIImage imageWithContentsOfFile:filePath];
    }
    return nil;
}
@end

NSString *const STImagePickerControllerImageIdentifierKey = @"STImagePickerControllerImageIdentifierKey"; // an path of image in temp
NSString *const STImagePickerControllerThumbImageKey = @"STImagePickerControllerThumbImageKey";
NSString *const STImagePickerControllerImageSizeKey = @"STImagePickerControllerImageSizeKey";

#pragma mark AssetCell

@implementation _STAssetCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.posterImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 57, 57)];
        self.posterImageView.clipsToBounds = YES;
        self.posterImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:self.posterImageView];

        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.font = [UIFont boldSystemFontOfSize:17];
        titleLabel.textColor = [UIColor blackColor];
        titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:titleLabel];
        self.titleLabel = titleLabel;

        UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        countLabel.font = [UIFont systemFontOfSize:17];
        countLabel.textColor = [UIColor colorWithWhite:0.498 alpha:1.0];
        [self.contentView addSubview:countLabel];
        self.countLabel = countLabel;

        self.separatorView = [[UIView alloc] init];
        self.separatorView.backgroundColor = [UIColor colorWithRGB:0xcccccc];
        [self addSubview:self.separatorView];

        self.topSeparatorView = [[UIView alloc] init];
        self.topSeparatorView.backgroundColor = [UIColor colorWithRGB:0xcccccc];
        self.topSeparatorView.hidden = YES;
        [self addSubview:self.topSeparatorView];
    }

    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    self.topSeparatorView.frame = CGRectMake(0, 0, frame.size.width, STOnePixel());
    self.separatorView.frame = CGRectMake(0, frame.size.height - STOnePixel(), frame.size.width, STOnePixel());
}

- (void)setTitle:(NSString *)title count:(NSUInteger)count {
    [self setImage:nil title:title count:count];
}

- (void)setImage:(UIImage *)image title:(NSString *)title count:(NSUInteger)count {
    CGFloat textWidth = CGRectGetWidth(self.contentView.bounds) - 95;
    self.posterImageView.image = image;
    self.titleLabel.text = [NSString stringWithFormat:@"%@  ", title];
    NSNumber *number = @(count);
    self.countLabel.text = [NSString stringWithFormat:@"(%@)", number];
    [self.titleLabel sizeToFit];
    [self.countLabel sizeToFit];

    CGRect titleFrame = self.titleLabel.frame;
    CGRect countFrame = self.countLabel.frame;
    CGFloat titleWidth = textWidth - CGRectGetWidth(countFrame);
    if (CGRectGetWidth(titleFrame) > titleWidth) {
        titleFrame.size.width = titleWidth;
    }
    titleFrame.origin.y = countFrame.origin.y = 0;
    titleFrame.size.height = countFrame.size.height = 55;
    titleFrame.origin.x = 65;
    self.titleLabel.frame = titleFrame;
    countFrame.origin.x = CGRectGetMaxX(titleFrame);
    self.countLabel.frame = countFrame;
}

@end

@implementation _STGroupAssetCell

- (void)setAssetsGroup:(ALAssetsGroup *)assetsGroup {
    _assetsGroup = assetsGroup;
    UIImage *image = [UIImage imageWithCGImage:assetsGroup.posterImage];
    NSString *title = [assetsGroup valueForProperty:ALAssetsGroupPropertyName];
    NSUInteger count = assetsGroup.numberOfAssets;
    [self setImage:image title:title count:count];
}

@end

@implementation _STPhotoAssetCell

- (void)setFetchResult:(NSObject *)__fetchResult {
    if (NSClassFromString(@"PHFetchResult")) {
        PHFetchResult *fetchResult = (PHFetchResult *)__fetchResult;
        PHAsset *asset = fetchResult.lastObject;

        NSString *title = @"所有照片";
        NSInteger count = fetchResult.count;

        [[PHImageManager defaultManager] cancelImageRequest:(PHImageRequestID)self.imageRequestID];
        self.imageRequestID = [[PHImageManager defaultManager]
            requestImageForAsset:asset
                      targetSize:CGSizeMake(57 * [UIScreen mainScreen].scale, 57 * [UIScreen mainScreen].scale)
                     contentMode:PHImageContentModeAspectFill
                         options:nil
                   resultHandler:^(UIImage *result, NSDictionary *info) { [self setImage:result title:title count:count]; }];
        [self setImage:nil title:title count:count];
    }

    _fetchResult = __fetchResult;
}

@end

@implementation _STPhotoGroupViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.assetsLibiary = [[ALAssetsLibrary alloc] init];
        [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
        [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
        NSMutableArray *dataSource = [NSMutableArray arrayWithCapacity:2];
        self.dataSource = dataSource;
        self.clearsSelectionOnViewWillAppear = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"照片";
    UIColor *tintColor = self.customNavigationController.navigationBar.titleTextAttributes[NSForegroundColorAttributeName];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" tintColor:tintColor target:self action:@selector(dismissActionFired:)];

    [self.tableView registerClass:[_STGroupAssetCell class] forCellReuseIdentifier:@"GroupAssetIdentifier"];
    [self.tableView registerClass:[_STPhotoAssetCell class] forCellReuseIdentifier:@"PhotoAssetIdentifier"];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)];
    [self reloadDataSource];
    self.tableView.separatorColor = [UIColor clearColor];

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 10)];
    self.tableView.tableHeaderView = headerView;
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.fetchResult) {
        return 2;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.fetchResult && section == 0) {
        return 1;
    }
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    _STAssetCell *tableViewCell;
    if (self.fetchResult && indexPath.section == 0) {
        _STPhotoAssetCell *assetCell = [tableView dequeueReusableCellWithIdentifier:@"PhotoAssetIdentifier"];
        assetCell.fetchResult = self.fetchResult;
        tableViewCell = assetCell;
        tableViewCell.topSeparatorView.hidden = NO;
    } else {
        _STGroupAssetCell *groupCell = [tableView dequeueReusableCellWithIdentifier:@"GroupAssetIdentifier"];
        ALAssetsGroup *assetsGroup = [self.dataSource objectAtIndex:indexPath.row];
        groupCell.assetsGroup = assetsGroup;
        tableViewCell = groupCell;
        tableViewCell.topSeparatorView.hidden = YES;
    }
    tableViewCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return tableViewCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 57.;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self _selectRowAtIndexPath:indexPath animated:YES];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)_selectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {
    _STAssetViewController *assetViewController;
    if (self.fetchResult && indexPath.section == 0) {
        _STPhotoAssetViewController *viewController = [[_STPhotoAssetViewController alloc] initWithFetchResult:(PHFetchResult *)self.fetchResult];
        assetViewController = viewController;
    } else {
        ALAssetsGroup *assetsGroup = [self.dataSource st_objectAtIndex:indexPath.row];
        if (assetsGroup) {
            assetViewController = [[_STGroupAssetViewController alloc] initWithAssetsGroup:assetsGroup];
        }
    }
    
    assetViewController.pickerDelegate = self.pickerDelegate;
    assetViewController.maximumNumberOfSelection = self.maximumNumberOfSelection;
    assetViewController.backBarButton = self.backBarButton;
    if (assetViewController) {
        [self.customNavigationController pushViewController:assetViewController animated:animated];
    }
}

#pragma mark - Private Method
- (void)reloadDataSource {
    NSMutableArray *dataSource = (NSMutableArray *)self.dataSource;
    [dataSource removeAllObjects];
    self.fetchResult = nil;
    ALAssetsLibraryGroupsEnumerationResultsBlock assetsEnumerationBlock = ^(ALAssetsGroup *group, BOOL *stop) {
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        if (group) {
            if (group.numberOfAssets > 0) {
                [dataSource addObject:group];
            }
        } else {
            [dataSource sortUsingComparator:^NSComparisonResult(ALAssetsGroup *obj1, ALAssetsGroup * obj2) {
                return obj1.numberOfAssets < obj2.numberOfAssets;
            }];
            if (NSClassFromString(@"PHFetchResult")) {
                PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
                PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:fetchOptions];
                if ([fetchResult countOfAssetsWithMediaType:PHAssetMediaTypeImage] > 0) {
                    self.fetchResult = fetchResult;
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                BOOL empty = (dataSource.count > 0 || self.fetchResult);
                self.tableView.backgroundView = empty ? nil : self.albumEmptyView;
                if (self.wantsEnterFirstAlbumWhenLoaded) {
                    [self _selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO];
                }
            });
        }
    };
    ALAssetsLibraryAccessFailureBlock assetsFailureBlock = ^(NSError *error) {
        [self.tableView reloadData];
        self.tableView.backgroundView = self.permissionDeniedView;
    };
    ALAssetsGroupType supportedType = ALAssetsGroupAll;
    [self.assetsLibiary enumerateGroupsWithTypes:supportedType usingBlock:assetsEnumerationBlock failureBlock:assetsFailureBlock];
}

- (void)dismissActionFired:(id)sender {
    if ([self.pickerDelegate respondsToSelector:@selector(groupViewControllerDidCancel:)]) {
        [self.pickerDelegate groupViewControllerDidCancel:self];
    }
}

- (UIView *)albumEmptyView {
    if (_albumEmptyView) {
        return _albumEmptyView;
    }

    UIView *centerView = UIView.new;
    centerView.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *titleLabel = UILabel.new;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.textColor = [UIColor colorWithRed:153.0 / 255.0 green:153.0 / 255.0 blue:153.0 / 255.0 alpha:1];
    titleLabel.preferredMaxLayoutWidth = 304.0f;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.numberOfLines = 5;
    titleLabel.font = [UIFont systemFontOfSize:26.0];
    titleLabel.text = @"没有照片或视频。";
    [centerView addSubview:titleLabel];

    UILabel *messageLabel = UILabel.new;
    messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    messageLabel.textColor = [UIColor colorWithRed:153.0 / 255.0 green:153.0 / 255.0 blue:153.0 / 255.0 alpha:1];
    messageLabel.preferredMaxLayoutWidth = 304.0f;
    messageLabel.textAlignment = NSTextAlignmentCenter;
    messageLabel.numberOfLines = 5;
    messageLabel.font = [UIFont systemFontOfSize:18.0];
    messageLabel.text = @"您可以使用 iTunes 将照片和视频\n同步到 iPhone。";
    [centerView addSubview:messageLabel];

    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(titleLabel, messageLabel);
    [centerView addConstraint:[NSLayoutConstraint constraintWithItem:titleLabel
                                                           attribute:NSLayoutAttributeCenterX
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:centerView
                                                           attribute:NSLayoutAttributeCenterX
                                                          multiplier:1.0f
                                                            constant:0.0f]];
    [centerView addConstraint:[NSLayoutConstraint constraintWithItem:messageLabel
                                                           attribute:NSLayoutAttributeCenterX
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:titleLabel
                                                           attribute:NSLayoutAttributeCenterX
                                                          multiplier:1.0f
                                                            constant:0.0f]];
    [centerView addConstraints:
                    [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[titleLabel]-[messageLabel]|" options:0 metrics:nil views:viewsDictionary]];

    UIView *backgroundView = UIView.new;
    [backgroundView addSubview:centerView];
    [backgroundView addConstraint:[NSLayoutConstraint constraintWithItem:centerView
                                                               attribute:NSLayoutAttributeCenterX
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:backgroundView
                                                               attribute:NSLayoutAttributeCenterX
                                                              multiplier:1.0f
                                                                constant:0.0f]];
    [backgroundView addConstraint:[NSLayoutConstraint constraintWithItem:centerView
                                                               attribute:NSLayoutAttributeCenterY
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:backgroundView
                                                               attribute:NSLayoutAttributeCenterY
                                                              multiplier:1.0f
                                                                constant:0.0f]];
    _albumEmptyView = backgroundView;
    return _albumEmptyView;
}

- (UIView *)permissionDeniedView {
    if (_permissionDeniedView) {
        return _permissionDeniedView;
    }

    UIView *centerView = UIView.new;
    centerView.translatesAutoresizingMaskIntoConstraints = NO;

    UIImageView *deniedImageView = UIImageView.new;
    deniedImageView.image = [STResourceManager imageWithResourceID:STImageResourceImagePickerLockedID];
    deniedImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [centerView addSubview:deniedImageView];

    UILabel *titleLabel = UILabel.new;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.textColor = [UIColor colorWithRed:129.0 / 255.0 green:136.0 / 255.0 blue:148.0 / 255.0 alpha:1];
    titleLabel.preferredMaxLayoutWidth = 304.0f;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.numberOfLines = 5;
    titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
    titleLabel.text = @"此应用无法使用您的照片或视频。";
    [centerView addSubview:titleLabel];

    UILabel *messageLabel = UILabel.new;
    messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    messageLabel.textColor = [UIColor colorWithRed:129.0 / 255.0 green:136.0 / 255.0 blue:148.0 / 255.0 alpha:1];
    messageLabel.preferredMaxLayoutWidth = 304.0f;
    messageLabel.textAlignment = NSTextAlignmentCenter;
    messageLabel.numberOfLines = 5;
    messageLabel.font = [UIFont systemFontOfSize:14.0];
    messageLabel.text = @"你可以在「隐私设置」中启用存取。";
    [centerView addSubview:messageLabel];

    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(deniedImageView, titleLabel, messageLabel);
    [centerView addConstraint:[NSLayoutConstraint constraintWithItem:deniedImageView
                                                           attribute:NSLayoutAttributeCenterX
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:centerView
                                                           attribute:NSLayoutAttributeCenterX
                                                          multiplier:1.0f
                                                            constant:0.0f]];
    [centerView addConstraint:[NSLayoutConstraint constraintWithItem:titleLabel
                                                           attribute:NSLayoutAttributeCenterX
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:deniedImageView
                                                           attribute:NSLayoutAttributeCenterX
                                                          multiplier:1.0f
                                                            constant:0.0f]];
    [centerView addConstraint:[NSLayoutConstraint constraintWithItem:messageLabel
                                                           attribute:NSLayoutAttributeCenterX
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:deniedImageView
                                                           attribute:NSLayoutAttributeCenterX
                                                          multiplier:1.0f
                                                            constant:0.0f]];
    [centerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[deniedImageView]-[titleLabel]-[messageLabel]|"
                                                                       options:0
                                                                       metrics:nil
                                                                         views:viewsDictionary]];

    UIView *backgroundView = UIView.new;
    [backgroundView addSubview:centerView];
    [backgroundView addConstraint:[NSLayoutConstraint constraintWithItem:centerView
                                                               attribute:NSLayoutAttributeCenterX
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:backgroundView
                                                               attribute:NSLayoutAttributeCenterX
                                                              multiplier:1.0f
                                                                constant:0.0f]];
    [backgroundView addConstraint:[NSLayoutConstraint constraintWithItem:centerView
                                                               attribute:NSLayoutAttributeCenterY
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:backgroundView
                                                               attribute:NSLayoutAttributeCenterY
                                                              multiplier:1.0f
                                                                constant:0.0f]];
    _permissionDeniedView = backgroundView;
    return _permissionDeniedView;
}

@end

#pragma mark AssetCollectionViewCell

@implementation _STAssetCollectionCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.thumbView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.thumbView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.thumbView.contentMode = UIViewContentModeScaleAspectFill;
        self.thumbView.clipsToBounds = YES;
        [self addSubview:self.thumbView];

        self.highlightedView = [[UIView alloc] initWithFrame:self.thumbView.frame];
        self.highlightedView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.highlightedView.backgroundColor = [UIColor colorWithRGB:0x0 alpha:0.5];
        self.highlightedView.userInteractionEnabled = NO;
        [self addSubview:self.highlightedView];
        self.highlightedView.hidden = YES;

        self.selectedImageView = [[UIImageView alloc] initWithFrame:self.thumbView.frame];
        UIImage *selectedImage =
            [[STResourceManager imageWithResourceID:STImageResourceImagePickerSelectedID] resizableImageWithCapInsets:UIEdgeInsetsMake(1, 1, 30, 30)
                                                                                                         resizingMode:UIImageResizingModeStretch];
        self.selectedImageView.image = selectedImage;
        self.selectedImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.selectedImageView.userInteractionEnabled = NO;
        [self addSubview:self.selectedImageView];
        self.selectedImageView.hidden = YES;
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    self.highlightedView.hidden = NO;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    self.highlightedView.hidden = YES;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    self.highlightedView.hidden = YES;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.selectedImageView.hidden = !selected;
}

@end

#pragma mark - AssetViewController
@implementation _STAssetViewController

- (void)dealloc {
    self.collectionView.delegate = nil;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.dataSource = [NSMutableArray arrayWithCapacity:5];
        self.selectedAssets = [NSMutableArray arrayWithCapacity:2];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadNextPage];
    if (self.backBarButton) {
        [self.backBarButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [self.backBarButton addTarget:self action:@selector(backViewControllerActionFired:) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.backBarButton];
    }
    UIColor *tintColor = self.customNavigationController.navigationBar.titleTextAttributes[NSForegroundColorAttributeName];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" tintColor:tintColor target:self action:@selector(finishActionFired:)];
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    NSInteger count = CGRectGetWidth(self.view.frame) / 78;
    CGFloat margin = (CGRectGetWidth(self.view.frame) - count * 78) / (count - 1);
    if (margin > 2) {
        margin = 2;
    }
    CGFloat itemWidth = (CGRectGetWidth(self.view.frame) - (count - 1) * margin) / count;

    flowLayout.minimumLineSpacing = margin;
    flowLayout.minimumInteritemSpacing = margin;
    flowLayout.itemSize = CGSizeMake(itemWidth, itemWidth);

    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:flowLayout];
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.collectionView.backgroundView = nil;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.allowsMultipleSelection = YES;
    [self.collectionView registerClass:[_STAssetCollectionCell class] forCellWithReuseIdentifier:@"Identifier"];
    self.collectionView.alwaysBounceHorizontal = NO;
    self.collectionView.alwaysBounceVertical = YES;
    [self.view addSubview:self.collectionView];

    UIEdgeInsets edgeInsets = self.collectionView.contentInset;
    edgeInsets.top += 5;
    edgeInsets.bottom += 5;
    self.collectionView.contentInset = edgeInsets;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![self hasNextPage]) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self.collectionView numberOfItemsInSection:0] - 1 inSection:0];
            [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
        }
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)backViewControllerActionFired:(id)sender {
    [self.customNavigationController popViewControllerAnimated:YES];
}

#pragma mark - UICollectionViewDataSource

- (CGFloat)collectionView:(UICollectionView *)collectionView
                                      layout:(UICollectionViewLayout *)collectionViewLayout
    minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    NSInteger count = CGRectGetWidth(self.view.frame) / 78;
    CGFloat margin = (CGRectGetWidth(self.view.frame) - count * 78) / (count - 1);
    if (margin > 2) {
        margin = 2;
    }
    return margin;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                                 layout:(UICollectionViewLayout *)collectionViewLayout
    minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    NSInteger count = CGRectGetWidth(self.view.frame) / 78;
    CGFloat margin = (CGRectGetWidth(self.view.frame) - count * 78) / (count - 1);
    if (margin > 2) {
        margin = 2;
    }
    return margin;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                    layout:(UICollectionViewLayout *)collectionViewLayout
    sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger count = CGRectGetWidth(self.view.frame) / 78;
    CGFloat margin = (CGRectGetWidth(self.view.frame) - count * 78) / (count - 1);
    if (margin > 2) {
        margin = 2;
    }
    CGFloat itemWidth = (CGRectGetWidth(self.view.frame) - (count - 1) * margin) / count;
    return CGSizeMake(itemWidth, itemWidth);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self.collectionView reloadData];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection
              withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self.collectionView reloadData];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.collectionView reloadData];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSObject *asset = [self.dataSource objectAtIndex:indexPath.row];
    _STAssetCollectionCell *photoCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Identifier" forIndexPath:indexPath];
    [self updatePhotoCellPhotoCell:photoCell asset:asset];
    if ([self.selectedAssets indexOfObject:asset] != NSNotFound) {
        photoCell.selected = YES;
        [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    } else {
        photoCell.selected = NO;
        [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
    return photoCell;
}

- (void)updatePhotoCellPhotoCell:(_STAssetCollectionCell *)photoCell asset:(NSObject *)asset {
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.selectedAssets removeObject:[self.dataSource objectAtIndex:indexPath.row]];
    NSInteger count = self.selectedAssets.count;
    self.navigationItem.rightBarButtonItem.enabled = (count > 0);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger count = self.selectedAssets.count;
    if (count >= self.maximumNumberOfSelection) {
        STIndicatorView *indicatorView = [STIndicatorView showInView:self.view animated:NO];
        indicatorView.indicatorType = STIndicatorTypeText;
        indicatorView.blurEffectStyle = STBlurEffectStyleDark;
        indicatorView.minimumSize = CGSizeMake(120, 80);
        NSNumber *number = @(self.maximumNumberOfSelection);
        indicatorView.textLabel.text = [NSString stringWithFormat:@"您最多只能选 %@ 张", number];
        [indicatorView hideAnimated:YES afterDelay:1.0];
        [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    } else {
        count++;
        [self.selectedAssets addObject:[self.dataSource objectAtIndex:indexPath.row]];
    }
    self.navigationItem.rightBarButtonItem.enabled = (count > 0);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (![self hasNextPage]) {
        return;
    }
    CGFloat contentOffset = scrollView.contentOffset.y + scrollView.contentInset.top;
    CGFloat contentHeight = scrollView.contentSize.height;
    CGFloat offset = (contentOffset + CGRectGetHeight(scrollView.frame)) - contentHeight;
    if (offset >= -50) {
        /// 开始加载更多
        [self loadNextPage];
        [self.collectionView reloadData];
    }
}

- (void)finishActionFired:(id)sender {
    NSArray *selectedItems = self.selectedAssets;
    if (selectedItems.count == 0) {
        return;
    }
    [STIndicatorView showInView:self.customNavigationController.view animated:NO];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSArray *sortedSelectedItems = [selectedItems sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSInteger index0 = [self.dataSource indexOfObject:obj1];
            NSInteger index1 = [self.dataSource indexOfObject:obj2];
            return index0 > index1;
        }];
        NSArray *imageArray = [self compressedImageWithAssets:sortedSelectedItems];
        dispatch_async(dispatch_get_main_queue(), ^{
            [STIndicatorView hideInView:self.customNavigationController.view animated:YES];
            if ([self.pickerDelegate respondsToSelector:@selector(assetViewController:didFinishWithPhotoArray:)]) {
                [self.pickerDelegate assetViewController:self didFinishWithPhotoArray:imageArray];
            }
        });
    });
}

- (void)loadNextPage {
    NSInteger start = _page * _STAssetViewControllerPageSize;
    if (start < [self numberOfAssets]) {
        NSRange range = NSMakeRange(start, _STAssetViewControllerPageSize);
        _page++;
        if (start + _STAssetViewControllerPageSize > [self numberOfAssets]) {
            range.length = [self numberOfAssets] - start;
        }
        [self fetchAssetWithRange:range options:0];
    }
}

- (void)fetchAssetWithRange:(NSRange)range options:(NSEnumerationOptions)options {
}

- (BOOL)hasNextPage {
    return _page * _STAssetViewControllerPageSize < [self numberOfAssets];
}

- (NSInteger)numberOfAssets {
    return 0;
}

- (NSArray *)compressedImageWithAssets:(NSArray *)assets {
    return nil;
}

- (NSData *)compressedDataWithOriginalImage:(UIImage *)image {
    STImagePickerController *pickerController = (STImagePickerController *)self.customNavigationController;
    NSObject<STImageProcessDelegate> *processDelegate = [pickerController isKindOfClass:[STImagePickerController class]] ? pickerController.processDelegate : nil;
    if ([processDelegate respondsToSelector:@selector(compressedOriginalImage:)]) {
        return [processDelegate compressedOriginalImage:image];
    }
    return UIImageJPEGRepresentation(image, 1.0);
}

- (void)saveImageData:(NSData *)imageData withIdentifier:(NSString *)identifier {
    STImagePickerController *pickerController = (STImagePickerController *)self.customNavigationController;
    NSObject<STImageProcessDelegate> *processDelegate = [pickerController isKindOfClass:[STImagePickerController class]] ? pickerController.processDelegate : nil;
    if ([processDelegate respondsToSelector:@selector(saveImageData:withIdentifier:)]) {
        [processDelegate saveImageData:imageData withIdentifier:identifier];
    } else {
        NSString *filePath = [STTemporaryDirectory() stringByAppendingPathComponent:identifier];
        [imageData writeToFile:filePath atomically:YES];
    }
}

@end

@implementation _STGroupAssetViewController

- (instancetype)initWithAssetsGroup:(ALAssetsGroup *)assetsGroup {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.assetsGroup = assetsGroup;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = [NSString stringWithFormat:@"%@", [self.assetsGroup valueForProperty:ALAssetsGroupPropertyName]];
}

- (void)updatePhotoCellPhotoCell:(_STAssetCollectionCell *)photoCell asset:(ALAsset *)asset {
    if (![asset isKindOfClass:[ALAsset class]]) {
        return;
    }
    photoCell.thumbView.image = [UIImage imageWithCGImage:asset.thumbnail];
}

- (NSInteger)numberOfAssets {
    return [self.assetsGroup numberOfAssets];
}

- (void)fetchAssetWithRange:(NSRange)range options:(NSEnumerationOptions)options {
    NSIndexSet *indexSet = [[NSIndexSet alloc] initWithIndexesInRange:range];
    [self.assetsGroup enumerateAssetsAtIndexes:indexSet
                                       options:options
                                    usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                                        if (result) {
                                            [self.dataSource addObject:result];
                                        }
                                    }];
}

- (NSArray *)compressedImageWithAssets:(NSArray *)assets {
    NSMutableArray *imageArray = [NSMutableArray arrayWithCapacity:assets.count];
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
    [assets enumerateObjectsUsingBlock:^(ALAsset *asset, NSUInteger idx, BOOL *stop) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
        ALAssetRepresentation *representation = [asset defaultRepresentation];
        UIImage *originalImage = [UIImage imageWithCGImage:representation.fullScreenImage];
        if (!originalImage) {
            originalImage = [UIImage imageWithCGImage:representation.fullResolutionImage scale:representation.scale orientation:(UIImageOrientation)representation.orientation];
            if (!originalImage) {
                originalImage = [UIImage imageWithCGImage:asset.aspectRatioThumbnail];
            }
        }
        NSData *data = [self compressedDataWithOriginalImage:originalImage];
        NSString *identifier = [NSString stringWithFormat:@"STImagePicker-%lld%ld.jpg", @(timeInterval * 1000).longLongValue, (long)idx];
        [self saveImageData:data withIdentifier:identifier];
        UIImage *image = [UIImage imageWithCGImage:[asset thumbnail]];
        [dict setValue:image forKey:STImagePickerControllerThumbImageKey];
        [dict setValue:identifier forKey:STImagePickerControllerImageIdentifierKey];
        dict[STImagePickerControllerImageSizeKey] = NSStringFromCGSize(originalImage.size);
        [imageArray addObject:dict];
    }];
    return imageArray;
}

@end

@implementation _STPhotoAssetViewController

- (instancetype)initWithFetchResult:(PHFetchResult *)fetchResult {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.fetchResult = fetchResult;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"全部照片";
}

- (void)updatePhotoCellPhotoCell:(_STAssetCollectionCell *)photoCell asset:(PHAsset *)asset {
    if (![asset isKindOfClass:[PHAsset class]]) {
        return;
    }
    [[PHImageManager defaultManager] cancelImageRequest:(PHImageRequestID)photoCell.requestID];
    static PHImageRequestOptions *requestOptions;
    if (!requestOptions) {
        requestOptions = [[PHImageRequestOptions alloc] init];
        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
        requestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
    }
    photoCell.requestID =
        [[PHImageManager defaultManager] requestImageForAsset:asset
                                                   targetSize:CGSizeMake(CGRectGetWidth(photoCell.thumbView.frame) * [UIScreen mainScreen].scale,
                                                                         CGRectGetHeight(photoCell.thumbView.frame) * [UIScreen mainScreen].scale)
                                                  contentMode:PHImageContentModeAspectFill
                                                      options:requestOptions
                                                resultHandler:^(UIImage *result, NSDictionary *info) { photoCell.thumbView.image = result; }];
}

- (NSInteger)numberOfAssets {
    return [self.fetchResult countOfAssetsWithMediaType:PHAssetMediaTypeImage];
}

- (void)fetchAssetWithRange:(NSRange)range options:(NSEnumerationOptions)options {
    NSIndexSet *indexSet = [[NSIndexSet alloc] initWithIndexesInRange:range];
    [self.fetchResult enumerateObjectsAtIndexes:indexSet
                                        options:options
                                     usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                         if (obj) {
                                             [self.dataSource addObject:obj];
                                         }
                                     }];
}

- (NSArray *)compressedImageWithAssets:(NSArray *)assets {
    NSMutableArray *imageArray = [NSMutableArray arrayWithCapacity:assets.count];
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    requestOptions.synchronous = YES;
    [assets enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
        if ([asset isKindOfClass:[PHAsset class]]) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
            [[PHImageManager defaultManager]
                requestImageForAsset:asset
                          targetSize:CGSizeMake(100 * [UIScreen mainScreen].scale, 100 * [UIScreen mainScreen].scale)
                         contentMode:PHImageContentModeAspectFill
                             options:requestOptions
                       resultHandler:^(UIImage *result, NSDictionary *info) {
                           [dict setValue:result forKey:STImagePickerControllerThumbImageKey];
                       }];
            [[PHImageManager defaultManager]
                requestImageDataForAsset:asset
                                 options:requestOptions
                           resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                               UIImage *originalImage = [UIImage imageWithData:imageData];
//                               originalImage = [UIImage imageWithCGImage:originalImage.CGImage scale:originalImage.scale orientation:orientation];
                               
                               NSData *data = [self compressedDataWithOriginalImage:originalImage];
                               NSString *identifier = [NSString stringWithFormat:@"STImagePicker-%lld%ld.jpg", @(timeInterval * 1000).longLongValue, (long)idx];
                               [self saveImageData:data withIdentifier:identifier];
                               dict[STImagePickerControllerImageSizeKey] = NSStringFromCGSize(originalImage.size);
                               [dict setValue:identifier forKey:STImagePickerControllerImageIdentifierKey];
                           }];
            [imageArray addObject:dict];
        }
    }];
    return imageArray;
}

@end
