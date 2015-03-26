//
//  STImagePresent.m
//  STKit
//
//  Created by SunJiangting on 14-9-21.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STImagePresent.h"
#import "STImageCollectionView.h"
#import "STImageScrollView.h"
#import "STRoundProgressView.h"
#import "STIndicatorView.h"
#import "STAlbumManager.h"

@interface _STImagePresentViewController : UIViewController

@property(nonatomic, strong) UIView *backgroundView;
@property(nonatomic, strong) STImageCollectionView *collectionView;

@end

@implementation _STImagePresentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.view.frame = [UIScreen mainScreen].bounds;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.backgroundView.backgroundColor = [UIColor blackColor];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.backgroundView];

    self.collectionView = [[STImageCollectionView alloc] initWithFrame:self.view.bounds];
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.collectionView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.collectionView];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self.collectionView.collectionView reloadData];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection
              withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    [self.collectionView.collectionView reloadData];
}

@end

@interface _STImagePresentWindow : UIWindow

@property(nonatomic, strong) _STImagePresentViewController *viewController;

@end

@implementation _STImagePresentWindow

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (CGRectIsEmpty(frame)) {
        frame = [UIScreen mainScreen].bounds;
    }
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _STImagePresentViewController *viewController = [[_STImagePresentViewController alloc] initWithNibName:nil bundle:nil];
        self.rootViewController = viewController;
        viewController.view.frame = self.bounds;
        viewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.viewController = viewController;
    }
    return self;
}

- (void)makeKeyAndVisible {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    [super makeKeyAndVisible];
    [keyWindow makeKeyWindow];
}

@end

@interface STImagePresent () <STImageCollectionViewDelegate> {
    __strong UIImageView *_presentedImageView;
}

@property(nonatomic, strong) _STImagePresentWindow *window;
@property(nonatomic, strong) NSArray *images;
@end

@implementation STImagePresent

static STImagePresent *_imagePresent;
+ (instancetype)standardImagePresent {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ _imagePresent = [[self alloc] init]; });
    return _imagePresent;
}

+ (void)presentImageView:(UIImageView *)imageView {
    if (!imageView.image) {
        return;
    }
    STImageItem *imageItem = [[STImageItem alloc] init];
    imageItem.thumb = imageView.image;
    [self presentImageItem:imageItem imageView:imageView animated:YES];
}

+ (void)presentImageItem:(STImageItem *)imageItem imageView:(UIImageView *)imageView animated:(BOOL)animated {
    [_previousImagePresent dismissAnimated:NO];
    [STImagePresent standardImagePresent]->_presentedImageView = imageView;
    [STImagePresent standardImagePresent].images = @[ imageItem ];
    [[STImagePresent standardImagePresent] presentImageAtIndex:0 animated:YES];
}

+ (void)presentImageView:(UIImageView *)imageView hdImage:(UIImage *)hdImage {
    if (!imageView.image && !hdImage) {
        return;
    }
    STImageItem *imageItem = [[STImageItem alloc] init];
    imageItem.thumb = imageView.image;
    imageItem.image = hdImage;
    [self presentImageItem:imageItem imageView:imageView animated:YES];
}

+ (void)presentImageView:(UIImageView *)imageView hdImageURL:(NSString *)hdImageURL {
    if (!imageView.image && hdImageURL.length == 0) {
        return;
    }
    STImageItem *imageItem = [[STImageItem alloc] init];
    imageItem.thumb = imageView.image;
    imageItem.imageURLString = hdImageURL;
    [self presentImageItem:imageItem imageView:imageView animated:YES];
}

static STImagePresent *_previousImagePresent;
- (instancetype)init {
    self = [super init];
    if (self) {
        _previousImagePresent = self;
    }
    return self;
}

- (instancetype)initWithImages:(NSArray *)images {
    self = [super init];
    if (self) {
        self.window.viewController.collectionView.images = images;
    }
    return self;
}

- (void)presentImageAtIndex:(NSInteger)index animated:(BOOL)animated {
    _previousImagePresent = self;
    _presentedIndex = index;
    _STImagePresentWindow *window = self.window;
    window.viewController.collectionView.currentImageIndex = index;
    CGRect frame = window.viewController.collectionView.bounds;
    frame.origin.x -= window.viewController.collectionView.horizontalSpacing / 2.0;
    frame.size.width -= window.viewController.collectionView.horizontalSpacing;
    STImageScrollView *imageScrollView = [[STImageScrollView alloc] initWithFrame:frame];
    [window.viewController.collectionView setValue:imageScrollView forKey:@"_defaultImageScrollView"];
    [window makeKeyAndVisible];

    UIImageView *imageView = _presentedImageView;
    if ([self.delegate respondsToSelector:@selector(imagePresent:imageViewForImageAtIndex:)]) {
        imageView = [self.delegate imagePresent:self imageViewForImageAtIndex:index];
    }
    if (imageView) {
        [self _presentFromImageView:imageView animated:YES];
    } else {
        [self _fadeInAnimated:YES];
    }
}

- (void)dismissAnimated:(BOOL)animated {
    UIImageView *imageView = _presentedImageView;
    if ([self.delegate respondsToSelector:@selector(imagePresent:imageViewForImageAtIndex:)]) {
        imageView = [self.delegate imagePresent:self imageViewForImageAtIndex:self.presentedIndex];
    }
    if (!imageView) {
        [self _fadeOutAnimated:YES];
    } else {
        [self _dismissToImageView:imageView animated:YES];
    }
}

#pragma mark - ImageCollectionViewDelegate
- (void)imageCollectionView:(STImageCollectionView *)collectionView didTapImageAtIndex:(NSInteger)index {
    // dismiss
    _presentedIndex = index;
    [self dismissAnimated:YES];
}

- (void)imageCollectionView:(STImageCollectionView *)collectionView didDisplayImageAtIndex:(NSInteger)index {
    _presentedIndex = index;
    if ([self.delegate respondsToSelector:@selector(imagePresent:didPresentImageAtIndex:)]) {
        [self.delegate imagePresent:self didPresentImageAtIndex:index];
    }
}

- (void)imageCollectionView:(STImageCollectionView *)collectionView didLongPressImage:(UIImage *)image atIndex:(NSInteger)index {
    if ([self.delegate respondsToSelector:@selector(imagePresent:didLongPressImage:atIndex:)]) {
        [self.delegate imagePresent:self didLongPressImage:image atIndex:index];
    } else {
        if (image) {
            __weak STImagePresent *weakSelf = self;
            STImageWriteToPhotosAlbum(image, @"STKitDemo",
                                      ^(UIImage *image, NSError *error) { [weakSelf _image:image didFinishSavingWithError:error contextInfo:NULL]; });
        }
    }
}

- (void)_image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (!error) {
        STIndicatorView *indicatorView = [STIndicatorView showInView:self.window animated:YES];
        indicatorView.blurEffectStyle = STBlurEffectStyleDark;
        indicatorView.indicatorType = STIndicatorTypeText;
        indicatorView.textLabel.text = @"保存成功";
        indicatorView.cornerRadius = 2;
        indicatorView.textLabel.font = [UIFont systemFontOfSize:18];
        indicatorView.minimumSize = CGSizeMake(130, 80);
        indicatorView.forceSquare = NO;
        [indicatorView hideAnimated:YES afterDelay:1.5];
    }
}

- (void)_presentFromImageView:(UIImageView *)imageView animated:(BOOL)animated {
    _STImagePresentWindow *window = self.window;
    CGRect imageViewFrame = [imageView.superview convertRect:imageView.frame toView:window];
    STImageScrollView *imageScrollView = window.viewController.collectionView.imageScrollView;

    UIImageView *presentingImageView = imageScrollView.imageView;
    presentingImageView.frame = imageViewFrame;
    presentingImageView.image = imageView.image;
    window.viewController.backgroundView.alpha = 0.1;
    presentingImageView.alpha = 0.1;

    void (^animations)(void) = ^{
        imageView.window.transform = CGAffineTransformMakeScale(0.95, 0.95);
        presentingImageView.alpha = 1.0;
        window.viewController.backgroundView.alpha = 1.0;
        STImageItem *item = window.viewController.collectionView.images[self.presentedIndex];
        if (item.imageURLString) {
            [imageScrollView setImageURL:item.imageURLString animated:NO];
        } else {
            if (item.image) {
                [imageScrollView setImage:item.image animated:NO];
            }
        }
        [imageScrollView zoomToFit];
    };
    void (^completion)(BOOL) = ^(BOOL finished) {
        presentingImageView.alpha = 1.0;
        window.viewController.backgroundView.alpha = 1.0;
        imageView.window.transform = CGAffineTransformMakeScale(1.0, 1.0);
        [window.viewController.collectionView.collectionView reloadData];
    };
    if (animated) {
        [UIView animateWithDuration:0.25 animations:animations completion:completion];
    } else {
        completion(YES);
    }
}

- (void)_dismissToImageView:(UIImageView *)imageView animated:(BOOL)animated {
    CGRect imageViewFrame = [imageView.superview convertRect:imageView.frame toView:self.window.viewController.collectionView.imageScrollView];
    self.window.viewController.collectionView.imageScrollView.roundProgressView.hidden = YES;

    void (^animations)(void) = ^{
        self.window.viewController.backgroundView.alpha = 0.1f;
        self.window.viewController.collectionView.imageScrollView.imageView.frame = imageViewFrame;
        imageView.window.transform = CGAffineTransformIdentity;
    };
    void (^completion)(BOOL) = ^(BOOL finished) {
        self.window = nil;
        _previousImagePresent = nil;
        _presentedImageView = nil;
    };
    if (animated) {
        imageView.window.transform = CGAffineTransformMakeScale(0.95, 0.95);
        [UIView animateWithDuration:0.25 animations:animations completion:completion];
    } else {
        completion(YES);
    }
}

#pragma mark - fadeInOut
- (void)_fadeInAnimated:(BOOL)animated {
    self.window.alpha = 0.1;
    void (^animations)(void) = ^{ self.window.alpha = 1.0; };
    void (^completion)(BOOL) = ^(BOOL finished) {

    };
    if (animated) {
        [UIView animateWithDuration:0.25 animations:animations completion:completion];
    } else {
        completion(YES);
    }
}

- (void)_fadeOutAnimated:(BOOL)animated {
    void (^animations)(void) = ^{ self.window.alpha = 0.1; };
    void (^completion)(BOOL) = ^(BOOL finished) {
        self.window = nil;
        _presentedImageView = nil;
    };
    if (animated) {
        [UIView animateWithDuration:0.25 animations:animations completion:completion];
    } else {
        completion(YES);
    }
}

#pragma mark - PrivateMethod
- (_STImagePresentWindow *)window {
    if (!_window) {
        _window = [[_STImagePresentWindow alloc] init];
        _window.windowLevel = UIWindowLevelStatusBar + 1;
        _window.viewController.collectionView.delegate = self;
    }
    return _window;
}

- (void)setImages:(NSArray *)images {
    self.window.viewController.collectionView.images = images;
}

- (NSArray *)images {
    return self.window.viewController.collectionView.images;
}
@end
