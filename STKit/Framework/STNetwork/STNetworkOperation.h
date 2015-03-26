//
//  STNetworkOperation.h
//  STKit
//
//  Created by SunJiangting on 14-7-3.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <STKit/STNetwork.h>

/// 如果有file，会强制使用mutilpart/form-data
/// 否则服务端不能接收数据,一般没有特殊需求就不要乱搞
typedef NS_ENUM(NSInteger, STNetworkFormEnctype) {
    STNetworkFormEnctypeURLEncoded,    /// Default
    STNetworkFormEnctypeMultipartData, /// 如果有文件/图片,会使用此格式
    STNetworkFormEnctypeTextPlain,     /// 慎用。如果你不知道什么意思,你就不要用这个,一般服务器都不支持。
};

@interface STNetworkOperation : NSOperation

@property(atomic, readonly) NSInteger identifier;

@property(nonatomic, copy, readonly) NSString *URLString;
// GET/POST/PUT/DELETE/PATCH
@property(nonatomic, copy, readonly) NSString *HTTPMethod; // default GET

@property(nonatomic, assign, readonly) NSInteger HTTPStatusCode;

@property(nonatomic, strong, readonly) NSURLRequest *URLRequest;
@property(nonatomic, strong, readonly) NSHTTPURLResponse *URLResponse;
@property(nonatomic, assign) NSURLRequestCachePolicy     cachePolicy;
/// default value = STNetworkConfiguration.sharedConfiguration
@property(nonatomic, strong) STNetworkConfiguration *configuration;
/// 表单提交是，格式化内容的方式，GET请求请忽略此项
@property(nonatomic, assign) STNetworkFormEnctype enctype;
/// 超时时间 default 120s
@property(nonatomic, assign) NSTimeInterval timeoutInterval;
/// 收到请求应答回调
- (void)addResponseHandler:(STNetworkResponseHandler)responseHandler;
/// 当Response比较大时，比如图片，音频，文件等会分批次接受，该回调为每次接收到的%比。参考Content-Length
- (void)addProgressHanlder:(STNetworkProgressHandler)progressHandler;
/// 请求结束时的回调
- (void)addFinishedHandler:(STNetworkFinishedHandler)finishedHandler;

@property(nonatomic, strong) STNetworkWillStartHandler willStartHandler;
/// 请求过程回调
@property(nonatomic, strong) STNetworkProgressHandler requestProgressHandler;

/// 服务端返回字符串的编码，默认UTF-8
@property(nonatomic, assign) NSStringEncoding stringEncoding;
/// 每一个请求均有唯一的signature
@property(nonatomic, readonly, strong) NSString *signature;
/// ready to request
- (void)prepareToRequest;

- (instancetype)initWithURLString:(NSString *)URLString parameters:(NSDictionary *)parameters HTTPMethod:(NSString *)HTTPMethod;

/// 比较两个请求是否为同一个，如果为同一个请求，可能会和并请求。
- (BOOL)isEqualToNetworkOperation:(STNetworkOperation *)networkOperation;
- (BOOL)isEqualWithURLString:(NSString *)URLString HTTPMethod:(NSString *)HTTPMethod parameters:(NSDictionary *)params;

@end

@interface STNetworkOperation (STHTTPHeader)

/*!
 @method setAllHTTPHeaderFields:
 @abstract Sets the HTTP header fields of the receiver to the given
 dictionary.
 @discussion This method replaces all header fields that may have
 existed before this method call.
 <p>Since HTTP header fields must be string values, each object and
 key in the dictionary passed to this method must answer YES when
 sent an <tt>-isKindOfClass:[NSString class]</tt> message. If either
 the key or value for a key-value pair answers NO when sent this
 message, the key-value pair is skipped.
 @param headerFields a dictionary containing HTTP header fields.
 */
- (void)setAllHTTPHeaderFields:(NSDictionary *)headerFields;

/*!
 @method setValue:forHTTPHeaderField:
 @abstract Sets the value of the given HTTP header field.
 @discussion If a value was previously set for the given header
 field, that value is replaced with the given value. Note that, in
 keeping with the HTTP RFC, HTTP header field names are
 case-insensitive.
 @param value the header field value.
 @param field the header field name (case-insensitive).
 */
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

/*!
 @method addValue:forHTTPHeaderField:
 @abstract Adds an HTTP header field in the current header
 dictionary.
 @discussion This method provides a way to add values to header
 fields incrementally. If a value was previously set for the given
 header field, the given value is appended to the previously-existing
 value. The appropriate field delimiter, a comma in the case of HTTP,
 is added by the implementation, and should not be added to the given
 value by the caller. Note that, in keeping with the HTTP RFC, HTTP
 header field names are case-insensitive.
 @param value the header field value.
 @param field the header field name (case-insensitive).
 */
- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

@end