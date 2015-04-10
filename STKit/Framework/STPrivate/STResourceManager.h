//
//  STResourceManager.h
//  STKit
//
//  Created by SunJiangting on 14-5-11.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/// 目前只支持以下列表中的资源ID
@interface STResourceManager : NSObject
/// 根据ResourceID 生成image。
+ (UIImage *)imageWithResourceID:(NSString *)resourceID;

@end

/// 下拉可以刷新，箭头
extern NSString *const STImageResourceRefreshControlArrowID;
extern NSString *const STImageResourceAccessoryDataZeroID;
/// 导航返回按钮
extern NSString *const STImageResourceNavigationItemBackID;
/// push导航侧边阴影
extern NSString *const STImageResourceViewControllerShadowID;
/// 相册选中效果
extern NSString *const STImageResourceImagePickerSelectedID;
extern NSString *const STImageResourceImagePickerLockedID;
/// WebView
/// 返回
extern NSString *const STImageResourceWebViewBackNormalID;
extern NSString *const STImageResourceWebViewBackHighlightedID;
extern NSString *const STImageResourceWebViewBackDisabledID;
/// 前进 forward
extern NSString *const STImageResourceWebViewForwardNormalID;
extern NSString *const STImageResourceWebViewForwardHighlightedID;
extern NSString *const STImageResourceWebViewForwardDisabledID;
/// 刷新按钮
extern NSString *const STImageResourceWebViewRefreshNormalID;
extern NSString *const STImageResourceWebViewRefreshHighlightedID;
extern NSString *const STImageResourceWebViewRefreshDisabledID;

/// 支付
extern NSString *const STImageResourcePaySelectedID;
extern NSString *const STImageResourcePayDeselectedID;
extern NSString *const STImageResourcePayPlatformAliID;
extern NSString *const STImageResourcePayPlatformWXID;

extern NSString *const STImageResourcePlaceholderID;
extern NSString *const STImageResourceSaveToAlbumID;
extern NSString *const STImageResourceNavigationBarID;