//
//  STNetwork.h
//  STKit
//
//  Created by SunJiangting on 13-11-13.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import <STKit/STDefines.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <STKit/STNetworkConfiguration.h>

typedef NS_ENUM(NSInteger, STNetworkErrorCode) {
    STNetworkErrorCodeUserCancelled = 11, // 用户手动取消
};

@interface STPostDataItem : NSObject

@property(nonatomic, copy) NSString *name;
/// 如果传送文件
@property(nonatomic, copy) NSString *path;
/// 发送图片或者data
@property(nonatomic, strong) UIImage *image;
@property(nonatomic, strong) NSData *data;
@end

@class STNetworkOperation;

/**
 * @abstract 网络请求结束的回调
 *
 * @param response 包含网络返回的数据
 */
typedef void (^STNetworkResponseHandler)(STNetworkOperation *operation, id response, NSError *error);

// 请求时时相应，下载资源等
/**
 * @abstract
 *网络请求时，服务器应答的回调，服务器有时候可能不是一次接受到所有数据，所以会分几次接受
 *
 * @param    data 服务端返回的数据
 * @param    completion 完成度，完成的百分比
 */
typedef void (^STNetworkProgressHandler)(STNetworkOperation *operation, NSData *data, CGFloat completion);

typedef void (^STNetworkFinishedHandler)(STNetworkOperation *operation, NSData *data, NSError *error);

/// 即将开始网络请求，可以配置一些参数（cookies，headerfields等等）
typedef void (^STNetworkWillStartHandler)(STNetworkOperation *operation);

@class STNetworkOperation;
@interface STNetwork : NSObject
/// 回调Queue
@property(nonatomic, strong) NSOperationQueue *networkQueue;
/// 是否把同样的请求merge在一起
@property(nonatomic, assign) BOOL automaticallyMergeRequest;
@property(nonatomic, assign) NSTimeInterval timeoutInterval;
@property(nonatomic, assign) NSInteger  maxConcurrentRequestCount;

/**
 * @abstract 发送异步网络请求
 *
 * @param    URLString    请求的地址
 * @param    HTTPMethod   请求的方式，有POST/GET/PUT/DELETE 等，默认为GET
 * @param    parameters   请求的参数，如果有文件资源，请参考 @see STPostDataItem
 * @param    handlers     请求各个阶段的回调
 *
 * @attention  所有handlers 均会在defaultQueue 回调
 */
- (STNetworkOperation *)sendAsynchronousRequestWithURLString:(NSString *)URLString
                                                  HTTPMethod:(NSString *)HTTPMethod
                                                  parameters:(NSDictionary *)parameters
                                             responseHandler:(STNetworkResponseHandler)responseHandler
                                             progressHandler:(STNetworkProgressHandler)progressHandler
                                             finishedHandler:(STNetworkFinishedHandler)finishedHandler;

/**
 * @abstract 取消异步请求
 *
 * @param    URLString  请求的地址
 * @param    HTTPMethod 请求的方式，有POST/GET/PUT/DELETE 等，默认为GET
 * @param    parameters 请求的参数，如果有文件资源，请参考 @see STPostDataItem
 *
 * @attention
 */
- (void)cancelAsynchronousRequestWithURLString:(NSString *)URLString HTTPMethod:(NSString *)HTTPMethod parameters:(NSDictionary *)parameters;

- (void)cancelAsynchronousRequestWithIdentifier:(NSInteger)identifier;

+ (NSThread *)standardNetworkThread;

@end

@interface STNetwork (STSynchronousRequest)

/**
 * @abstract 发送同步网络请求
 *
 * @param    URLString  请求的地址
 * @param    HTTPMethod 请求的方式，有POST/GET/PUT/DELETE 等，默认为GET
 * @param    parameters 请求的参数，如果有文件资源，请参考 @see STPostDataItem
 * @param    error      请求失败的error
 *
 * @attention  同步请求会阻塞当前线程，请谨慎使用.@see
 *sendAsynchronousRequestWithURLString:
 */
- (NSData *)sendSynchronousRequestWithURLString:(NSString *)URLString
                                     HTTPMethod:(NSString *)HTTPMethod
                                     parameters:(NSDictionary *)parameters
                                          error:(NSError **)error;

- (NSData *)sendSynchronousRequestWithURLString:(NSString *)URLString
                                     HTTPMethod:(NSString *)HTTPMethod
                                     parameters:(NSDictionary *)params
                                       response:(NSURLResponse **)response
                                          error:(NSError **)error;

@end

@interface NSDictionary (STNetwork)
- (NSString *)componentsJoinedUsingURLEncode;
@end
/// 默认超时时间，default 60s
extern NSTimeInterval const STRequestTimeoutInterval;
