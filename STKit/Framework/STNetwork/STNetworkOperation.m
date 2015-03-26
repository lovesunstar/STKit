//
//  STNetworkOperation.m
//  STKit
//
//  Created by SunJiangting on 14-7-3.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STNetworkOperation.h"

#import "Foundation+STKit.h"
#import "STApplicationContext.h"
#import "STRSACryptor.h"
#import <zlib.h>

typedef NSInteger STIdentifier;
#pragma mark - NSArrayCategory

@interface NSArray (STNetwork)

- (NSString *)st_componentsJoinedUsingURLEncode;

- (NSString *)st_componentsJoinedUsingSeparator:(NSString *)separator;

@end

@interface NSData (STGZip)

- (NSData *)st_compressDataUsingGZip;
+ (NSData *)st_dataWithZipCompressedData:(NSData *)data;

@end

@implementation NSArray (STNetwork)

- (NSString *)st_componentsJoinedUsingURLEncode {
    NSMutableString *mutableString = [NSMutableString string];
    [self enumerateObjectsUsingBlock:^(NSDictionary *parameter, NSUInteger idx, BOOL *stop) {
        NSString *key = [parameter.allKeys firstObject];
        NSString *value = [parameter valueForKey:key];
        if ([value isKindOfClass:[NSString class]]) {
            [mutableString appendFormat:@"%@=%@&", [key stringByURLEncoded], [value stringByURLEncoded]];
        } else {
            [mutableString appendFormat:@"%@=%@&", [key stringByURLEncoded], value];
        }
    }];
    if (mutableString.length > 0) {
        [mutableString deleteCharactersInRange:NSMakeRange(mutableString.length - 1, 1)];
    }
    return mutableString;
}

- (NSString *)st_componentsJoinedUsingSeparator:(NSString *)separator {
    if (!separator) {
        separator = @"&";
    }
    NSMutableString *mutableString = [NSMutableString string];
    [self enumerateObjectsUsingBlock:^(NSDictionary *parameter, NSUInteger idx, BOOL *stop) {
        NSString *key = [parameter.allKeys firstObject];
        NSString *value = [parameter valueForKey:key];
        [mutableString appendFormat:@"%@=%@%@", key, value, separator];
    }];
    if (mutableString.length > 0) {
        [mutableString deleteCharactersInRange:NSMakeRange(mutableString.length - separator.length, separator.length)];
    }
    return mutableString;
}

@end

typedef enum {
    STNetworkStateReady,
    STNetworkStateExecuting,
    STNetworkStateFinished,
} _STNetworkState;

static STIdentifier _autoIncrementIdentifier = 100000;

static inline BOOL _STNetworkOperationCouldChangeToState(STNetworkOperation *operation, _STNetworkState state);

@interface STNetworkOperation () {
    BOOL _cancelled;
    BOOL _willBeCancelled;
}

#pragma mark - URLRequest
@property(nonatomic, copy) NSString *URLString;
@property(nonatomic, copy) NSString *HTTPMethod;
@property(nonatomic, strong) NSMutableURLRequest *mutableURLRequest;
@property(nonatomic, strong) NSMutableDictionary *requestParams;

#pragma mark - URLResponse
@property(nonatomic, strong) NSHTTPURLResponse *URLResponse;
@property(nonatomic, strong) NSMutableData *responseData;
@property(nonatomic, strong) NSError *responseError;

@property(nonatomic, weak) NSURLConnection *URLConnection;

@property(nonatomic, assign) _STNetworkState networkState;

@property(nonatomic, strong) NSMutableArray *responseHandlers;
@property(nonatomic, strong) NSMutableArray *progressHandlers;
@property(nonatomic, strong) NSMutableArray *finishedHandlers;

- (void)prepareToRequest;

@end

@implementation STNetworkOperation

- (void)dealloc {
    [self.responseHandlers removeAllObjects];
    [self.progressHandlers removeAllObjects];
    [self.finishedHandlers removeAllObjects];
}

+ (STIdentifier)_incrementdIdentifier {
    @synchronized(self) {
        _autoIncrementIdentifier++;
        return _autoIncrementIdentifier;
    }
}

- (instancetype)initWithURLString:(NSString *)URLString parameters:(NSDictionary *)params HTTPMethod:(NSString *)HTTPMethod {
    self = [super init];
    if (self) {
        if ([NSOperation instanceMethodForSelector:@selector(setName:)]) {
             self.name = @"STNetworkOperation";   
        }
        self.timeoutInterval = STRequestTimeoutInterval;
        if (params) {
            _requestParams = [NSMutableDictionary dictionaryWithDictionary:params];
        }
        self.URLString = URLString;
        if (HTTPMethod.length == 0) {
            HTTPMethod = @"GET";
        }
        self.HTTPMethod = HTTPMethod;
        self.mutableURLRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]
                                                         cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                     timeoutInterval:self.timeoutInterval];
        self.mutableURLRequest.HTTPMethod = HTTPMethod;

        NSString *userAgent = [NSString stringWithFormat:@"%@/%@ (%@; %@ %@) STKit/1.0", [STApplicationContext sharedContext].name,
                                                         [STApplicationContext sharedContext].bundleVersion, [UIDevice currentDevice].systemName,
                                                         [UIDevice currentDevice].localizedModel, [UIDevice currentDevice].systemVersion];
        [self.mutableURLRequest addValue:userAgent forHTTPHeaderField:@"User-Agent"];

        self.networkState = STNetworkStateReady;

        self.responseHandlers = [NSMutableArray arrayWithCapacity:1];
        self.progressHandlers = [NSMutableArray arrayWithCapacity:1];
        self.finishedHandlers = [NSMutableArray arrayWithCapacity:1];
        self.enctype = STNetworkFormEnctypeURLEncoded;
        _identifier = [[self class] _incrementdIdentifier];
        _willBeCancelled = NO;
    }
    return self;
}

- (instancetype)init {
    return [self initWithURLString:nil parameters:nil HTTPMethod:@"GET"];
}

#pragma mark - Add Handler
- (void)addResponseHandler:(STNetworkResponseHandler)responseHandler {
    if (responseHandler) {
        [self.responseHandlers addObject:responseHandler];
    }
}
- (void)addProgressHanlder:(STNetworkProgressHandler)progressHandler {
    if (progressHandler) {
        [self.progressHandlers addObject:progressHandler];
    }
}

- (void)addFinishedHandler:(STNetworkFinishedHandler)finishedHandler {
    if (finishedHandler) {
        if (self.networkState == STNetworkStateFinished) {
            finishedHandler(self, self.responseData, self.responseError);
        } else {
            [self.finishedHandlers addObject:finishedHandler];
        }
    }
}

#pragma mark - HTTPBody
- (void)reloadHTTPBodyCompressed:(BOOL)compressed {
    //    NSString * const kBoundary = @"STKitNetworkBoundary";
    NSString *const kBoundary = @"f235dec111be2681";
    NSString *HTTPMethod = self.URLRequest.HTTPMethod;
    if ([HTTPMethod isEqualToString:@"PUT"] || [HTTPMethod isEqualToString:@"POST"] || [HTTPMethod isEqualToString:@"PATCH"]) {
        /// 需要拼接form
        NSMutableArray *unwrapParameters = [NSMutableArray arrayWithCapacity:self.requestParams.count];
        [self.requestParams enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([obj isKindOfClass:[NSArray class]]) {
                [obj enumerateObjectsUsingBlock:^(id elements, NSUInteger idx, BOOL *stop) { [unwrapParameters addObject:@{key : elements}]; }];
            } else {
                [unwrapParameters addObject:@{key : obj}];
            }
        }];
        __block NSInteger simpleFieldsCount = 0;
        [unwrapParameters enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (![obj isKindOfClass:[STPostDataItem class]]) {
                simpleFieldsCount++;
            }
        }];
        NSMutableData *postData = [NSMutableData data];
        if (simpleFieldsCount < unwrapParameters.count || self.enctype == STNetworkFormEnctypeMultipartData) {
            [unwrapParameters enumerateObjectsUsingBlock:^(NSDictionary *parameter, NSUInteger idx, BOOL *stop) {
                NSString *key = [parameter.allKeys firstObject];
                id obj = [parameter valueForKey:key];
                if ([obj isKindOfClass:[STPostDataItem class]]) {
                    STPostDataItem *postItem = (STPostDataItem *)obj;
                    if (postItem.name && (postItem.path || postItem.image || postItem.data)) {
                        NSString *body =
                            [NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\nContent-Type: "
                                                       @"application/octet-stream\r\nContent-Transfer-Encoding: binary\r\n\r\n",
                                                       kBoundary, key, postItem.name];
                        NSData *data;
                        if (postItem.data) {
                            data = postItem.data;
                        } else if (postItem.path) {
                            data = [NSData dataWithContentsOfFile:postItem.path];
                        } else {
                            data = UIImageJPEGRepresentation(postItem.image, 0.8);
                        }
                        [postData appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
                        [postData appendData:data];
                        [postData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                    }
                } else {
                    NSString *body =
                        [NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@", kBoundary, key, obj];
                    [postData appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
                    [postData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                }
            }];
            [postData appendData:[[NSString stringWithFormat:@"--%@--\r\n", kBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
            NSString *charset =
                (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
            [self.mutableURLRequest setValue:[NSString stringWithFormat:@"multipart/form-data; charset=%@; boundary=%@", charset, kBoundary]
                          forHTTPHeaderField:@"Content-Type"];
        } else if (self.enctype == STNetworkFormEnctypeTextPlain) {
            NSString *parameterString =
                [[unwrapParameters st_componentsJoinedUsingSeparator:@"\r\n"] stringByReplacingOccurrencesOfString:@" " withString:@"+"];
            [postData appendData:[parameterString dataUsingEncoding:NSUTF8StringEncoding]];
            NSString *charset =
                (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
            [self.mutableURLRequest setValue:[NSString stringWithFormat:@"text/plain; charset=%@;", charset] forHTTPHeaderField:@"Content-Type"];
        } else {
            NSString *parameterString = [unwrapParameters st_componentsJoinedUsingURLEncode];
            [postData appendData:[parameterString dataUsingEncoding:NSUTF8StringEncoding]];
            NSString *charset =
                (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
            [self.mutableURLRequest setValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@;", charset]
                          forHTTPHeaderField:@"Content-Type"];
        }
        NSData *body = compressed ? ([postData st_compressDataUsingGZip]?: postData) : postData;
        if (body.length > 0) {
            [self.mutableURLRequest setValue:[NSString stringWithFormat:@"%ld", (long)body.length] forHTTPHeaderField:@"Content-Length"];
        }
        [self.mutableURLRequest setHTTPBody:body];
    } else {
        NSAssert(1, @"httpbody must in post/put/patch method");
    }
}

#pragma mark - NSURLConnectionDelegate

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection {
    return YES;
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
    STNetworkConfiguration * configuration = self.configuration ?: [STNetworkConfiguration sharedConfiguration];
    
    NSArray * authenticalionMethods = @[NSURLAuthenticationMethodDefault, NSURLAuthenticationMethodHTTPBasic, NSURLAuthenticationMethodHTTPDigest, NSURLAuthenticationMethodNTLM];
    
    if ([authenticalionMethods containsObject:challenge.protectionSpace.authenticationMethod] && configuration.HTTPBasicCredential) {
        if (challenge.previousFailureCount == 0) {
            [challenge.sender useCredential:configuration.HTTPBasicCredential forAuthenticationChallenge:challenge];
        } else {
            [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
        }
    } else if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate] && configuration.clientCertificateCredential) {
        [challenge.sender useCredential:configuration.clientCertificateCredential forAuthenticationChallenge:challenge];
    } else if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if (challenge.previousFailureCount < 5) {
            if (configuration.allowsAnyHTTPSCertificate) {
                [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]
                     forAuthenticationChallenge:challenge];
                [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
                return;
            }
            STSSLPinningMode SSLPinningMode = configuration.SSLPinningMode;
            SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
            SecPolicyRef policy = SecPolicyCreateBasicX509();
            CFIndex certificateCount = SecTrustGetCertificateCount(serverTrust);
            NSMutableArray *trustChain = [NSMutableArray arrayWithCapacity:certificateCount];
            
            for (CFIndex i = 0; i < certificateCount; i++) {
                SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, i);
                if (SSLPinningMode == STSSLPinningModeCertificate) {
                    [trustChain addObject:(__bridge_transfer NSData *)SecCertificateCopyData(certificate)];
                } else if (SSLPinningMode == STSSLPinningModePublicKey) {
                    SecCertificateRef someCertificates[] = {certificate};
                    CFArrayRef certificates = CFArrayCreate(NULL, (const void **)someCertificates, 1, NULL);
                    
                    SecTrustRef trust = NULL;
                    
                    OSStatus status = SecTrustCreateWithCertificates(certificates, policy, &trust);
                    if (status == errSecSuccess) {
                        SecTrustResultType result;
                        status = SecTrustEvaluate(trust, &result);
                        if (status == errSecSuccess && trust) {
                            [trustChain addObject:(__bridge_transfer id)SecTrustCopyPublicKey(trust)];
                        }
                    }
                    if (trust) {
                         CFRelease(trust);   
                    }
                    CFRelease(certificates);
                }
            }
            CFRelease(policy);
            
            switch (configuration.SSLPinningMode) {
                case STSSLPinningModePublicKey: {
                    NSArray * pinnedPublicKeys = configuration.publicKeys;
                    for (id publicKey in trustChain) {
                        for (id pinnedPublicKey in pinnedPublicKeys) {
                            if (STSecKeyEqualToSecKey((__bridge SecKeyRef)publicKey, (__bridge SecKeyRef)pinnedPublicKey)) {
                                NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
                                [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
                                return;
                            }
                        }
                    }
                    [[challenge sender] cancelAuthenticationChallenge:challenge];
                }
                    break;
                case STSSLPinningModeCertificate: {
                    NSArray *certificates = configuration.certificates;
                    for (id serverCertificateData in trustChain) {
                        if ([certificates containsObject:serverCertificateData]) {
                            NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
                            [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
                            return;
                        }
                    }
                    [challenge.sender cancelAuthenticationChallenge:challenge];
                }
                    break;
                case STSSLPinningModeNone:
                default: {
                    SecTrustResultType result = 0;
                    SecTrustEvaluate(serverTrust, &result);
                    if (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed) {
                        NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
                        [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
                    } else {
                        [challenge.sender cancelAuthenticationChallenge:challenge];
                    }
                }
                    break;
            }
        } else {
            [challenge.sender cancelAuthenticationChallenge:challenge];
        }
    } else {
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
    }
    
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
    if (response) {
        NSMutableURLRequest *URLRequest = [self.URLRequest mutableCopy];
        URLRequest.URL = request.URL;
        return URLRequest;
    } else {
        return request;
    }
}

/// 此方法可能会被调用多次，每次调用时，需要清空前一次调用的所有东西，包括Data
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.URLResponse = (NSHTTPURLResponse *)response;
    self.responseData = [NSMutableData data];
    _HTTPStatusCode = self.URLResponse.statusCode;
    for (STNetworkResponseHandler responseHandler in self.responseHandlers) {
        responseHandler(self, response, nil);
    }
    for (STNetworkProgressHandler progressHandler in self.progressHandlers) {
        progressHandler(self, self.responseData, 0);
    }
}

/// 数据传输过程中，每次收到数据就会调用此方法
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
    long long startPosition = 0;
    /// Http headers 中包含Range，即断点传送中，请求Range以后的数据
    NSString *rangeValue = [self.URLRequest valueForHTTPHeaderField:@"Range"];
    if ([rangeValue hasPrefix:@"bytes="] && [rangeValue hasSuffix:@"-"]) {
        NSString *rangeText = [rangeValue substringWithRange:NSMakeRange(6, rangeValue.length - 7)];
        // 从 startPosition 开始请求数据
        startPosition = [rangeText longLongValue];
    }
    long long expectedContentLength = MAX(self.URLResponse.expectedContentLength, 0);
    if (expectedContentLength > 0) {
        long long receiveDataLength = self.responseData.length;
        double progress = ((double)(receiveDataLength + startPosition) / (double)expectedContentLength);
        for (STNetworkProgressHandler progressHandler in self.progressHandlers) {
            progressHandler(self, data, progress);
        }
    }
}

- (NSInputStream *)connection:(NSURLConnection *)connection needNewBodyStream:(NSURLRequest *)request {
    return nil;
}

- (void)connection:(NSURLConnection *)connection
              didSendBodyData:(NSInteger)bytesWritten
            totalBytesWritten:(NSInteger)totalBytesWritten
    totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    if (self.requestProgressHandler) {
        if (totalBytesExpectedToWrite > 0) {
            CGFloat percent = ((double)totalBytesWritten / (double)totalBytesExpectedToWrite);
            self.requestProgressHandler(self, nil, percent);
        }
    }
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return cachedResponse;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {

    if (self.requestProgressHandler) {
        self.requestProgressHandler(self, nil, 1);
    }
    self.requestProgressHandler = nil;

    for (STNetworkProgressHandler progressHandler in self.progressHandlers) {
        progressHandler(self, self.responseData, 1);
    }
    /// 200 成功,
    if (_HTTPStatusCode >= 200 && _HTTPStatusCode < 300) {
        /// 成功
        for (STNetworkFinishedHandler finishedHandler in self.finishedHandlers) {
            finishedHandler(self, self.responseData, nil);
        }
    } else if (_HTTPStatusCode >= 300 && _HTTPStatusCode < 400) {
        if (_HTTPStatusCode == 301) {
            /// 永久重定向
        } else if (_HTTPStatusCode == 302) {
            /// 暂时重定向
        } else if (_HTTPStatusCode == 304) {
            /// Not-Modified
        }
        NSArray *array = [NSArray arrayWithArray:self.finishedHandlers];
        for (STNetworkFinishedHandler finishedHandler in array) {
            finishedHandler(self, nil, nil);
        }

    } else if (_HTTPStatusCode >= 400 && _HTTPStatusCode < 500) {
        /// 服务端错误
        NSArray *array = [NSArray arrayWithArray:self.finishedHandlers];
        for (STNetworkFinishedHandler finishedHandler in array) {
            finishedHandler(self, self.responseData, [NSError errorWithDomain:@"com.suen.stkit.network" code:1001 userInfo:@{ @"key" : @"404" }]);
        }
    } else if (_HTTPStatusCode >= 500) {
        NSArray *array = [NSArray arrayWithArray:self.finishedHandlers];
        for (STNetworkFinishedHandler finishedHandler in array) {
            finishedHandler(self, self.responseData, [NSError errorWithDomain:@"com.suen.stkit.network" code:1001 userInfo:@{ @"key" : @"500", @"description":@"Server Error 500" }]);
        }
    }
    [self.responseHandlers removeAllObjects];
    [self.progressHandlers removeAllObjects];
    [self.finishedHandlers removeAllObjects];
    self.networkState = STNetworkStateFinished;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if (self.requestProgressHandler) {
        self.requestProgressHandler(self, nil, 1);
    }
    self.requestProgressHandler = nil;
    /// 请求失败
    for (STNetworkFinishedHandler finishedHandler in self.finishedHandlers) {
        finishedHandler(self, nil, error);
    }
    [self.responseHandlers removeAllObjects];
    [self.progressHandlers removeAllObjects];
    [self.finishedHandlers removeAllObjects];
    self.responseError = error;
    self.responseData = nil;
    self.networkState = STNetworkStateFinished;
}

- (void)prepareToRequest {
    BOOL compressedRequest = !!(self.configuration.compressionOptions & STCompressionOptionsRequestAllowed);
    if (compressedRequest) {
        [self setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
    }
    self.mutableURLRequest.HTTPMethod = self.HTTPMethod;
    if ([self.URLRequest.HTTPMethod isEqualToString:@"PUT"] || [self.URLRequest.HTTPMethod isEqualToString:@"POST"] ||
        [self.URLRequest.HTTPMethod isEqualToString:@"PATCH"]) {
        [self reloadHTTPBodyCompressed:compressedRequest];
    } else {
        NSMutableString *mutableString = [NSMutableString stringWithString:self.URLString];
        NSMutableArray *unwrapParameters = [NSMutableArray arrayWithCapacity:self.requestParams.count];
        [self.requestParams enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([obj isKindOfClass:[NSArray class]]) {
                [obj enumerateObjectsUsingBlock:^(id element, NSUInteger idx, BOOL *stop) { [unwrapParameters addObject:@{key : element}]; }];
            } else {
                [unwrapParameters addObject:@{key : obj}];
            }
        }];
        NSString *parameterString = [unwrapParameters st_componentsJoinedUsingURLEncode];
        if (parameterString.length > 0) {
            [mutableString appendFormat:@"?%@", parameterString];
        }
        self.mutableURLRequest.URL = [NSURL URLWithString:[mutableString copy]];
    }
    if (self.configuration.compressionOptions & STCompressionOptionsResponseAccepted) {
        [self setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    }
    if (self.willStartHandler) {
        self.willStartHandler(self);
    }
}

#pragma mark - OverrideMethod

- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval {
    self.mutableURLRequest.timeoutInterval = timeoutInterval;
    _timeoutInterval = timeoutInterval;
}
- (NSURLRequest *)URLRequest {
    return [self.mutableURLRequest copy];
}

- (void)start {
    [self performSelector:@selector(startOnNetworkThread) onThread:[STNetwork standardNetworkThread] withObject:nil waitUntilDone:NO];
}

- (void)cancelOnNetworkThread {
    @synchronized(self) {
        if ([self isFinished] || [self isCancelled]) {
            return;
        }
        [self.URLConnection cancel];
        [self.responseHandlers removeAllObjects];
        if (self.networkState == STNetworkStateExecuting) {
            self.networkState = STNetworkStateFinished;
        } else {
            [self willChangeValueForKey:@"isCancelled"];
            _cancelled = YES;
            [super cancel];
            [self didChangeValueForKey:@"isCancelled"];
        }

        if (self.requestProgressHandler) {
            self.requestProgressHandler(self, nil, 0);
        }
        self.requestProgressHandler = nil;

        for (STNetworkProgressHandler progressHandler in self.progressHandlers) {
            progressHandler(self, nil, 0);
        }
        [self.progressHandlers removeAllObjects];
        for (STNetworkFinishedHandler finishedHandler in self.finishedHandlers) {
            finishedHandler(nil, nil, [NSError errorWithDomain:@"com.suen.stkit.network"
                                                          code:STNetworkErrorCodeUserCancelled
                                                      userInfo:@{
                                                          @"error" : @"Request has been cancelled."
                                                      }]);
        }
        [self.finishedHandlers removeAllObjects];
    }
}

- (NSNumber *)__willBeCancelled {
    @synchronized(self) {
        return @(_willBeCancelled);
    }
}

- (void)cancel {
    _willBeCancelled = YES;
    [self performSelector:@selector(cancelOnNetworkThread) onThread:[STNetwork standardNetworkThread] withObject:nil waitUntilDone:NO];
}

- (BOOL)isCancelled {
    return _cancelled;
}

- (BOOL)isExecuting {
    return (self.networkState == STNetworkStateExecuting);
}

- (BOOL)isFinished {
    return (self.networkState == STNetworkStateFinished);
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isReady {
    BOOL ready = [super isReady];
    return (self.networkState == STNetworkStateReady && ready);
}

- (void)setNetworkState:(_STNetworkState)networkState {
    if (!_STNetworkOperationCouldChangeToState(self, networkState)) {
        return;
    }
    @synchronized(self) {
        switch (networkState) {
        case STNetworkStateReady:
            [self willChangeValueForKey:@"isReady"];
            break;
        case STNetworkStateExecuting:
            [self willChangeValueForKey:@"isReady"];
            [self willChangeValueForKey:@"isExecuting"];
            break;
        case STNetworkStateFinished:
            [self willChangeValueForKey:@"isExecuting"];
            [self willChangeValueForKey:@"isFinished"];
            break;
        }
        _networkState = networkState;
        switch (networkState) {
        case STNetworkStateReady:
            [self didChangeValueForKey:@"isReady"];
            break;
        case STNetworkStateExecuting:
            [self didChangeValueForKey:@"isReady"];
            [self didChangeValueForKey:@"isExecuting"];
            break;
        case STNetworkStateFinished:
            [self didChangeValueForKey:@"isExecuting"];
            [self didChangeValueForKey:@"isFinished"];
            break;
        }
    }
}

#pragma mark - signature
- (NSString *)signature {
    NSMutableString *requestString = [NSMutableString stringWithString:self.URLString];
    NSArray *paramKeys = [self.requestParams.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    [paramKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        id value = [self.requestParams valueForKey:key];
        if ([value isKindOfClass:[NSNumber class]]) {
            value = [value stringValue];
        }
        if ([value isKindOfClass:[NSString class]]) {
            [requestString appendFormat:@"%@=%@", key, value];
        }
    }];
    return [requestString md5String];
}

- (void)startOnNetworkThread {
    @synchronized(self) {
        if (self.URLString.length == 0 || !self.mutableURLRequest) {
            [self cancelOnNetworkThread];
            return;
        }
        if ([self isReady]) {
            self.networkState = STNetworkStateExecuting;
        }
        // 超时启动
        @autoreleasepool {
            // 如果未取消，则发起请求
            if (![self isCancelled]) {
                self.mutableURLRequest.timeoutInterval = self.timeoutInterval;
                [self prepareToRequest];
                NSURLConnection *URLConnection = [[NSURLConnection alloc] initWithRequest:self.mutableURLRequest delegate:self startImmediately:NO];
                [URLConnection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                [URLConnection start];
                self.URLConnection = URLConnection;
            } else {
                /// 已经被取消
                self.networkState = STNetworkStateFinished;
            }
        }
    }
}

#pragma mark - Equals
- (BOOL)isEqualToNetworkOperation:(STNetworkOperation *)networkOperation {
    if (![networkOperation isKindOfClass:[self class]]) {
        return NO;
    }
    if (self == networkOperation) {
        return YES;
    }
    return [self.signature isEqualToString:networkOperation.signature] && [self.requestParams isEqualToDictionary:networkOperation.requestParams] &&
           [self.HTTPMethod isEqualToString:networkOperation.HTTPMethod];
}

- (BOOL)isEqualWithURLString:(NSString *)URLString HTTPMethod:(NSString *)HTTPMethod parameters:(NSDictionary *)parameters {
    if (URLString.length == 0) {
        return NO;
    }
    if (HTTPMethod.length == 0) {
        HTTPMethod = @"GET";
    }
    BOOL dictionaryEquals = (parameters.count == 0 && self.requestParams.count == 0) || ([self.requestParams isEqualToDictionary:parameters]);
    return [self.URLString isEqualToString:URLString] && [self.HTTPMethod isEqualToString:HTTPMethod] && dictionaryEquals;
}


- (void)setCachePolicy:(NSURLRequestCachePolicy)cachePolicy {
    self.mutableURLRequest.cachePolicy = cachePolicy;
}

- (NSURLRequestCachePolicy)cachePolicy {
    return self.mutableURLRequest.cachePolicy;
}

@end

@implementation STNetworkOperation (STHTTPHeader)

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
- (void)setAllHTTPHeaderFields:(NSDictionary *)headerFields {
    [self.mutableURLRequest setAllHTTPHeaderFields:headerFields];
}

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
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    [self.mutableURLRequest setValue:value forHTTPHeaderField:field];
}

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
- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    [self.mutableURLRequest addValue:value forHTTPHeaderField:field];
}

@end

static inline BOOL _STNetworkOperationCouldChangeToState(STNetworkOperation *operation, _STNetworkState toState) {
    switch (operation.networkState) {
    case STNetworkStateReady:
        switch (toState) {
        case STNetworkStateExecuting:
            return YES;
        case STNetworkStateFinished:
            return [operation isCancelled];
        default:
            return NO;
        }
    case STNetworkStateExecuting:
        switch (toState) {
        case STNetworkStateFinished:
            return YES;
        default:
            return NO;
        }
    case STNetworkStateFinished:
        return NO;
    default:
        return YES;
    }
}

@implementation NSData (STGZip)
static const NSUInteger STGZipChunkSize = 16384;
- (NSData *)st_compressDataUsingGZip {
    if (self.length == 0) {
        return nil;
    }
    z_stream stream;
    stream.zalloc = Z_NULL;
    stream.zfree = Z_NULL;
    stream.opaque = Z_NULL;
    stream.avail_in = (uint)[self length];
    stream.next_in = (Bytef *)[self bytes];
    stream.total_out = 0;
    stream.avail_out = 0;
    
    int compression = Z_DEFAULT_COMPRESSION;
    if (deflateInit2(&stream, compression, Z_DEFLATED, 31, 8, Z_DEFAULT_STRATEGY) == Z_OK) {
        NSMutableData *data = [NSMutableData dataWithLength:STGZipChunkSize];
        while (stream.avail_out == 0) {
            if (stream.total_out >= data.length) {
                data.length += STGZipChunkSize;
            }
            stream.next_out = (uint8_t *)[data mutableBytes] + stream.total_out;
            stream.avail_out = (uInt)([data length] - stream.total_out);
            deflate(&stream, Z_FINISH);
        }
        deflateEnd(&stream);
        data.length = stream.total_out;
        return data;
    }
    return nil;
}

+ (NSData *)st_dataWithZipCompressedData:(NSData *)data {
    z_stream stream;
    stream.zalloc = Z_NULL;
    stream.zfree = Z_NULL;
    stream.avail_in = (uint)data.length;
    stream.next_in = (Bytef *)data.bytes;
    stream.total_out = 0;
    stream.avail_out = 0;
    NSMutableData *resultData = [NSMutableData dataWithLength:(NSUInteger)(data.length * 1.5)];
    if (inflateInit2(&stream, 47) == Z_OK) {
        int status = Z_OK;
        while (status == Z_OK) {
            if (stream.total_out >= resultData.length) {
                resultData.length += data.length / 2;
            }
            stream.next_out = (uint8_t *)resultData.mutableBytes + stream.total_out;
            stream.avail_out = (uInt)(resultData.length - stream.total_out);
            status = inflate (&stream, Z_SYNC_FLUSH);
        }
        if (inflateEnd(&stream) == Z_OK) {
            if (status == Z_STREAM_END) {
                resultData.length = stream.total_out;
                return resultData;
            }
        }
    }
    return nil;
}

@end
