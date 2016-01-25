//
//  STHTTPOperation.m
//  STKit
//
//  Created by SunJiangting on 15-2-4.
//  Copyright (c) 2015年 SunJiangting. All rights reserved.
//

#import "STHTTPOperation.h"
#import "STHTTPNetwork.h"

typedef enum {
    STHTTPOperationStateReady,
    STHTTPOperationStateExecuting,
    STHTTPOperationStateFinished,
} _STHTTPOperationState;

static NSString *const STURLCacheResponseUserInfoTimeIntervalKey = @"STURLCacheResponseUserInfoTimeIntervalKey";

@interface STHTTPNetwork (SSHTTPOperationDelegate)

- (void)HTTPOperationWillStart:(STHTTPOperation *)operation;

- (void)HTTPOperation:(STHTTPOperation *)operation didSendRequestWithCompletionPercent:(CGFloat)completionPercent;

- (void)HTTPOperation:(STHTTPOperation *)operation didReceiveResponse:(NSURLResponse *)response;

- (void)HTTPOperation:(STHTTPOperation *)operation
       didReceiveData:(NSData *)receivedData
    completionPercent:(CGFloat)completionPercent;

- (void)HTTPOperation:(STHTTPOperation *)operation
    didFinishWithData:(NSData *)data
                error:(NSError *)error;

@end

@interface STHTTPOperation () {
 @private
    BOOL             _isCancelled;
    NSURLRequest    *_originalURLRequest;
    NSData          *_cachedResponseData;
}

@property(nonatomic, strong) NSHTTPURLResponse  *HTTPResponse;
@property(nonatomic, strong) NSMutableData      *HTTPResponseData;
@property(nonatomic, strong) NSError            *responseError;
@property(nonatomic, strong) NSURLConnection    *URLConnection;

@property(nonatomic) _STHTTPOperationState operationState;

@end

@interface STHTTPOperation (STNotify)

- (void)_notifyWillStartWithOperation:(STHTTPOperation *)operation;
- (void)_notifySendProgressWithOperation:(STHTTPOperation *)operation completionPercent:(CGFloat)percent;
- (void)_notifyResponseWithOperation:(STHTTPOperation *)operation response:(NSHTTPURLResponse *)HTTPResponse;
- (void)_notifyReceiveProgressWithOperation:(STHTTPOperation *)operation receivedData:(NSData *)receivedData completionPercent:(CGFloat)percent;
- (void)_notifyFinishWithOperation:(STHTTPOperation *)operation responseData:(NSData *)responseData error:(NSError *)error;
@end

static inline BOOL _STHTTPOperationCouldChangeToState(STHTTPOperation *operation, _STHTTPOperationState state);

@implementation STHTTPOperation

static NSThread *_standardNetworkThread;
+ (NSThread *)standardNetworkThread {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _standardNetworkThread = [[NSThread alloc] initWithTarget:self selector:@selector(startNetworkThread) object:nil];
        _standardNetworkThread.name = @"com.suen.STNetworkThread";
        [_standardNetworkThread start];
    });
    return _standardNetworkThread;
}

+ (void)startNetworkThread {
    // Should keep the runloop from exiting
    while (YES) {
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"STOperation:%@ %@",self.request.URLRequest.HTTPMethod, self.request.URLRequest.URL.absoluteString];
}

- (instancetype)initWithHTTPRequest:(STHTTPRequest *)request {
    self = [super init];
    if (self) {
        _request = request;
        _identifier = [[self class] _incrementdIdentifier];
        if ([NSOperation instancesRespondToSelector:@selector(setName:)]) {
            self.name = @"STNetworkOperation";
        }
        _originalURLRequest = [self.request st_valueForVar:@"_mutableURLRequest"];
    }
    return self;
}

#pragma mark - NSURLConnectionDelegate

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection {
    return YES;
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    STNetworkConfiguration *configuration = self.configuration ?: [STNetworkConfiguration sharedConfiguration];
    
    NSArray *authenticalionMethods = @[NSURLAuthenticationMethodDefault, NSURLAuthenticationMethodHTTPBasic, NSURLAuthenticationMethodHTTPDigest, NSURLAuthenticationMethodNTLM];
    
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
            
            for (CFIndex i = 0; i < certificateCount; i ++) {
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
        NSMutableURLRequest *URLRequest = [_originalURLRequest mutableCopy];
        URLRequest.URL = request.URL;
        return URLRequest;
    } else {
        return request;
    }
}

/// 此方法可能会被调用多次，每次调用时，需要清空前一次调用的所有东西，包括Data
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
    self.HTTPResponse = HTTPResponse;
    self.HTTPResponseData = [NSMutableData data];
    _cachedResponseData = nil;
    _HTTPStatusCode = HTTPResponse.statusCode;
    [self _notifyResponseWithOperation:self response:HTTPResponse];
    [self _notifyReceiveProgressWithOperation:self receivedData:self.responseData completionPercent:0];
}

/// 数据传输过程中，每次收到数据就会调用此方法
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.HTTPResponseData appendData:data];
    _cachedResponseData = nil;
    long long startPosition = 0;
    /// Http headers 中包含Range，即断点传送中，请求Range以后的数据
    NSString *rangeValue = [_originalURLRequest valueForHTTPHeaderField:@"Range"];
    if ([rangeValue hasPrefix:@"bytes="] && [rangeValue hasSuffix:@"-"]) {
        NSString *rangeText = [rangeValue substringWithRange:NSMakeRange(6, rangeValue.length - 7)];
        // 从 startPosition 开始请求数据
        startPosition = [rangeText longLongValue];
    }
    long long expectedContentLength = MAX(self.HTTPResponse.expectedContentLength, 0);
    if (expectedContentLength > 0) {
        long long receiveDataLength = self.HTTPResponseData.length;
        double progress = ((double)(receiveDataLength + startPosition) / (double)expectedContentLength);
        NSData *responseData = self.responseData;
        [self _notifyReceiveProgressWithOperation:self receivedData:responseData completionPercent:progress];
    }
}

- (NSInputStream *)connection:(NSURLConnection *)connection needNewBodyStream:(NSURLRequest *)request {
    return nil;
}

- (void)connection:(NSURLConnection *)connection
   didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    if (totalBytesExpectedToWrite > 0) {
        CGFloat percent = ((double)totalBytesWritten / (double)totalBytesExpectedToWrite);
        [self _notifySendProgressWithOperation:self completionPercent:percent];
    }
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    if (cachedResponse && self.request.HTTPConfiguration.supportCachePolicy) {
        NSMutableDictionary *userInfo = [cachedResponse.userInfo mutableCopy];
        if (!userInfo) {
            userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
        }
        [userInfo setValue:@([[NSDate date] timeIntervalSince1970]) forKey:STURLCacheResponseUserInfoTimeIntervalKey];
        NSCachedURLResponse *preferredCachedResponse = [[NSCachedURLResponse alloc] initWithResponse:cachedResponse.response data:cachedResponse.data userInfo:userInfo storagePolicy:cachedResponse.storagePolicy];
        [[STHTTPNetwork defaultHTTPCache] storeCachedResponse:preferredCachedResponse forRequest:_originalURLRequest];
    }
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    /// 200 成功,
    [self _handleFinishLoadingWithHTTPResponse:self.HTTPResponse data:self.responseData isLoadedFromCache:NO];
}

- (void)_handleFinishLoadingWithHTTPResponse:(NSHTTPURLResponse *)response data:(NSData *)data isLoadedFromCache:(BOOL)isFromCache {
    NSInteger HTTPStatusCode = response.statusCode;
    if (HTTPStatusCode == 304 && self.request.HTTPConfiguration.supportCachePolicy) {
        /// Not-Modified
        NSCachedURLResponse *cachedURLResponse = [[STHTTPNetwork defaultHTTPCache] cachedResponseForRequest:_originalURLRequest];
        if (cachedURLResponse) {
            response = [self _getHTTPURLResponseFromCachedURLResponse:cachedURLResponse];
            data = cachedURLResponse.data;
            HTTPStatusCode = response.statusCode;
        }
    }
    if (HTTPStatusCode >= 200 && HTTPStatusCode < 300) {
        /// 成功
        [self _notifyFinishWithOperation:self responseData:self.responseData error:nil];
    } else if (HTTPStatusCode >= 300 && HTTPStatusCode < 400) {
     
        if (HTTPStatusCode == 301) {
            /// 永久重定向
        } else if (HTTPStatusCode == 302) {
            /// 暂时重定向
        } else if (HTTPStatusCode == 304) {
            
        }
        NSString *description = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSDictionary *userInfo = nil;
        if (description) {
            userInfo = @{STHTTPNetworkErrorDescriptionUserInfoKey:description};
        }
        NSError *error = [NSError errorWithDomain:STHTTPNetworkErrorDomain code:HTTPStatusCode userInfo:userInfo];
        [self _notifyFinishWithOperation:self responseData:nil error:error];
    } else if (HTTPStatusCode >= 400 && HTTPStatusCode < 500) {
        /// 服务端错误
        NSString *description = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSDictionary *userInfo = nil;
        if (description) {
            userInfo = @{STHTTPNetworkErrorDescriptionUserInfoKey:description};
        }
        NSError *error = [NSError errorWithDomain:STHTTPNetworkErrorDomain code:HTTPStatusCode userInfo:userInfo];
        [self _notifyFinishWithOperation:self responseData:nil error:error];
    } else if (HTTPStatusCode >= 500) {
        NSString *description = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSDictionary *userInfo = nil;
        if (description) {
            userInfo = @{STHTTPNetworkErrorDescriptionUserInfoKey:description};
        }
        NSError *error = [NSError errorWithDomain:STHTTPNetworkErrorDomain code:HTTPStatusCode userInfo:userInfo];
        [self _notifyFinishWithOperation:self responseData:nil error:error];
    }
    self.operationState = STHTTPOperationStateFinished;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    /// 请求失败
    NSInteger errCode = error.code;
    NSArray *badNetworkCodes = @[@(NSURLErrorCannotConnectToHost), @(NSURLErrorCannotFindHost), @(NSURLErrorNetworkConnectionLost), @(NSURLErrorDNSLookupFailed), @(NSURLErrorNotConnectedToInternet), @(NSURLErrorCannotLoadFromNetwork)];
    NSError *newError = nil;
    if ([badNetworkCodes containsObject:@(errCode)]) {
        newError = [NSError errorWithDomain:STHTTPNetworkErrorDomain code:STHTTPNetworkErrorCodeBadNetwork userInfo:error.userInfo];
    } else if (errCode == NSURLErrorTimedOut) {
        newError = [NSError errorWithDomain:STHTTPNetworkErrorDomain code:STHTTPNetworkErrorCodeTimeout userInfo:error.userInfo];
    } else {
        newError = error;
    }
    [self _notifyFinishWithOperation:self responseData:nil error:newError];
    self.operationState = STHTTPOperationStateFinished;
}

#pragma mark - OverrideMethod

#pragma mark - STOperationCallbacks
- (void)cancel {
    [self performSelector:@selector(_cancelOnNetworkThread) onThread:[[self class] standardNetworkThread] withObject:nil waitUntilDone:NO];
}

- (BOOL)isCancelled {
    return _isCancelled;
}

- (BOOL)isExecuting {
    return (self.operationState == STHTTPOperationStateExecuting);
}

- (BOOL)isFinished {
    return (self.operationState == STHTTPOperationStateFinished);
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isReady {
    BOOL ready = [super isReady];
    return (self.operationState == STHTTPOperationStateReady && ready);
}

- (void)start {
    [self performSelector:@selector(_startOnNetworkThread) onThread:[[self class] standardNetworkThread] withObject:nil waitUntilDone:NO];
}

#pragma mark - PrivateMethod

- (void)setOperationState:(_STHTTPOperationState)operationState {
    if (!_STHTTPOperationCouldChangeToState(self, operationState)) {
        return;
    }
    @synchronized(self) {
        switch (operationState) {
            case STHTTPOperationStateReady:
                [self willChangeValueForKey:@"isReady"];
                break;
            case STHTTPOperationStateExecuting:
                [self willChangeValueForKey:@"isReady"];
                [self willChangeValueForKey:@"isExecuting"];
                break;
            case STHTTPOperationStateFinished:
                [self willChangeValueForKey:@"isExecuting"];
                [self willChangeValueForKey:@"isFinished"];
                break;
        }
        _operationState = operationState;
        switch (operationState) {
            case STHTTPOperationStateReady:
                [self didChangeValueForKey:@"isReady"];
                break;
            case STHTTPOperationStateExecuting:
                [self didChangeValueForKey:@"isReady"];
                [self didChangeValueForKey:@"isExecuting"];
                break;
            case STHTTPOperationStateFinished:
                [self didChangeValueForKey:@"isExecuting"];
                [self didChangeValueForKey:@"isFinished"];
                break;
        }
    }
}

- (void)_configRedirectedURLRequest:(NSMutableURLRequest *)URLRequest {
    URLRequest.cachePolicy = self.request.HTTPConfiguration.cachePolicy;
    URLRequest.timeoutInterval = self.request.HTTPConfiguration.timeoutInterval;
}

- (void)_startOnNetworkThread {
    @synchronized(self) {
        if (!_originalURLRequest.URL) {
            [self _cancelOnNetworkThread];
            return;
        }
        if ([self isReady]) {
            self.operationState = STHTTPOperationStateExecuting;
        }
        // 超时启动
        @autoreleasepool {
            // 如果未取消，则发起请求
            if (![self isCancelled]) {
                if (!self.request.HTTPConfiguration) {
                    self.request.HTTPConfiguration = (self.configuration?:[STNetworkConfiguration sharedConfiguration]).HTTPConfiguration;
                }
                STHTTPConfiguration *configuration = self.request.HTTPConfiguration;
                [self.request prepareToRequest];
                [self _preprocessRequest:(NSMutableURLRequest *)_originalURLRequest withHTTPConfiguration:configuration completionHandler:^(NSHTTPURLResponse *response, NSData *data, NSError *error, BOOL shouldContinue) {
                    if (shouldContinue) {
                        [self _notifyWillStartWithOperation:self];
//                        NSURLSessionDataTask *task = [self.URLSession dataTaskWithRequest:_originalURLRequest];
//                        [task resume];
                        NSURLConnection *URLConnection = [[NSURLConnection alloc] initWithRequest:_originalURLRequest delegate:self startImmediately:NO];
                        [URLConnection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                        [URLConnection start];
                        self.URLConnection = URLConnection;
                    } else {
                        self.HTTPResponseData = [data mutableCopy];
                        _cachedResponseData = data;
                        self.HTTPResponse = response;
                        if (!error) {
                            [self connectionDidFinishLoading:nil];
                        } else {
                            [self connection:nil didFailWithError:error];
                        }
                    }
                }];
            } else {
                /// 已经被取消
                self.operationState = STHTTPOperationStateFinished;
            }
        }
    }
}

- (void)_preprocessRequest:(NSMutableURLRequest *)URLRequest
     withHTTPConfiguration:(STHTTPConfiguration *)configuration
         completionHandler:(void(^)(NSHTTPURLResponse *response, NSData *data, NSError *error, BOOL shouldContinue))completionHandler {
    void (^varCompletionHandler)(NSHTTPURLResponse *, NSData *, NSError *, BOOL) = ^(NSHTTPURLResponse *response, NSData *data, NSError *error, BOOL shouldContinue){
        if (completionHandler) {
            completionHandler(response, data, error, shouldContinue);
        }
    };
    NSURLRequestCachePolicy cachePolicy = URLRequest.cachePolicy;
    if (cachePolicy == NSURLRequestReloadIgnoringLocalCacheData || !configuration.supportCachePolicy) {
        varCompletionHandler(nil, nil, nil, YES);
        return;
    }
    
    NSCachedURLResponse *cachedResponse = [[STHTTPNetwork defaultHTTPCache] cachedResponseForRequest:_originalURLRequest];
    NSHTTPURLResponse *HTTPResponse = [self _getHTTPURLResponseFromCachedURLResponse:cachedResponse];
    BOOL varShouldContinue = YES;
    /// 从缓存取，不管有没有过期，只要有就返回
    if (cachePolicy == NSURLRequestReturnCacheDataElseLoad) {
        if (cachedResponse) {
            varCompletionHandler(HTTPResponse, cachedResponse.data, nil, NO);
        } else {
            varCompletionHandler(nil, nil, nil, YES);
        }
        return;
    }
    ///  从缓存取，不管有没有，都不继续，如果没有的话，返回错误
    if (cachePolicy == NSURLRequestReturnCacheDataDontLoad) {
        NSError *error = nil;
        if (!cachedResponse) {
            error = [NSError errorWithDomain:STHTTPNetworkErrorDomain code:STHTTPNetworkErrorCodeCantLoadCache userInfo:@{STHTTPNetworkErrorDescriptionUserInfoKey:@"DnotLoad with no cache"}];
        }
        varCompletionHandler(HTTPResponse, cachedResponse.data, error, NO);
        return;
    }
    /// 按照HTTP标准协议来处理
    NSDate *expiredDate = [self _getExpiredDateFromHTTPHeaderFields:HTTPResponse.allHeaderFields];
    if (expiredDate && [[NSDate date] compare:expiredDate] != NSOrderedDescending) {
        // 没有超过maxAge
        varShouldContinue = NO;
        varCompletionHandler(HTTPResponse, cachedResponse.data, nil, NO);
    } else {
        varShouldContinue = YES;
        NSDictionary *modifyHeaders = [self _requestHeadersFromCachedResponse:cachedResponse];
        [modifyHeaders enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [URLRequest addValue:obj forHTTPHeaderField:key];
        }];
        varCompletionHandler(nil, nil, nil, YES);
    }
}

- (NSHTTPURLResponse *)_getHTTPURLResponseFromCachedURLResponse:(NSCachedURLResponse *)cachedResponse {
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)cachedResponse.response;
    return ([response isKindOfClass:[NSHTTPURLResponse class]]) ? response : nil;
}

- (NSDate *)_getExpiredDateFromHTTPHeaderFields:(NSDictionary *)headerFields {
    NSString *cacheControl = [[headerFields objectForKey:@"Cache-Control"] lowercaseString];
    double maxAge = 0.0;
    if (cacheControl) {
        NSScanner *scanner = [NSScanner scannerWithString:cacheControl];
        [scanner scanUpToString:@"max-age" intoString:NULL];
        if ([scanner scanString:@"max-age" intoString:NULL]) {
            [scanner scanString:@"=" intoString:NULL];
            [scanner scanDouble:&maxAge];
        }
    }
    if (maxAge > 0) {
        return [[NSDate date] dateByAddingTimeInterval:maxAge];
    } else {
        NSString *expires = [headerFields objectForKey:@"Expires"];
        if (expires) {
            return [self _dateFromRFC1123FormattedString:expires];
        }
    }
    return nil;
}

- (NSDate *)_dateFromRFC1123FormattedString:(NSString *)formatString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    // Does the string include a week day?
    NSString *day = @"";
    if ([formatString rangeOfString:@","].location != NSNotFound) {
        day = @"EEE, ";
    }
    // Does the string include seconds?
    NSString *seconds = @"";
    if ([[formatString componentsSeparatedByString:@":"] count] == 3) {
        seconds = @":ss";
    }
    [formatter setDateFormat:[NSString stringWithFormat:@"%@dd MMM yyyy HH:mm%@ z",day,seconds]];
    return [formatter dateFromString:formatString];
}

- (NSDictionary *)_requestHeadersFromCachedResponse:(NSCachedURLResponse *)cachedResponse  {
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithCapacity:2];
    NSHTTPURLResponse *HTTPResponse = [self _getHTTPURLResponseFromCachedURLResponse:cachedResponse];
    NSDictionary *cachedHeaders = HTTPResponse.allHeaderFields;
    [headers setValue:cachedHeaders[@"Etag"] forKey:@"If-None-Match"];
    [headers setValue:cachedHeaders[@"Last-Modified"] forKey:@"If-Modified-Since"];
    return headers;
}

- (void)_cancelOnNetworkThread {
    @synchronized(self) {
        if ([self isFinished] || [self isCancelled]) {
            return;
        }
        [self.URLConnection cancel];
        if (self.operationState == STHTTPOperationStateExecuting) {
            self.operationState = STHTTPOperationStateFinished;
        } else {
            [self willChangeValueForKey:@"isCancelled"];
            _isCancelled = YES;
            [super cancel];
            [self didChangeValueForKey:@"isCancelled"];
        }
        NSError *error = [NSError errorWithDomain:STHTTPNetworkErrorDomain
                                             code:STHTTPNetworkErrorCodeUserCancelled
                                         userInfo:@{
                                                    STHTTPNetworkErrorDescriptionUserInfoKey : @"Request has been cancelled."
                                                    }];
        if ([_networkDelegate respondsToSelector:@selector(HTTPOperation:didFinishWithData:error:)]) {
            [_networkDelegate HTTPOperation:self didFinishWithData:nil error:error];
        } else {
            if (self.finishedHandler) {
                self.finishedHandler(self, nil, error);
            }
        }
    }
}

- (void)setValue:(id)value forKey:(NSString *)key {
    static NSArray *excludeKeys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
       excludeKeys = @[@"_request", @"_isCancelled", @"_HTTPStatusCode"];
    });
    if (![excludeKeys containsObject:key]) {
        [super setValue:value forKey:key];
    }
}

- (id)valueForKey:(NSString *)key {
    static NSArray *excludeKeys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        excludeKeys = @[@"_request", @"_isCancelled", @"_HTTPStatusCode"];
    });
    if (![excludeKeys containsObject:key]) {
        return [super valueForKey:key];
    }
    return nil;
}

- (NSData *)responseData {
    if (_cachedResponseData.length == 0) {
        _cachedResponseData = [self.HTTPResponseData copy];
    }
    return _cachedResponseData;
}

static NSInteger _autoIncrementIdentifier = 100000;
+ (NSInteger)_incrementdIdentifier {
    @synchronized(self) {
        _autoIncrementIdentifier++;
        return _autoIncrementIdentifier;
    }
}

@end

@implementation STHTTPOperation (STNotify)


- (void)_notifySendProgressWithOperation:(STHTTPOperation *)operation completionPercent:(CGFloat)percent {
    if ([_networkDelegate respondsToSelector:@selector(HTTPOperation:didSendRequestWithCompletionPercent:)]) {
        [_networkDelegate HTTPOperation:self didSendRequestWithCompletionPercent:percent];
    } else {
        if (self.requestProgressHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.requestProgressHandler(self, percent);
            });
        }
    }
}

- (void)_notifyReceiveProgressWithOperation:(STHTTPOperation *)operation receivedData:(NSData *)receivedData completionPercent:(CGFloat)percent {
    if ([_networkDelegate respondsToSelector:@selector(HTTPOperation:didReceiveData:completionPercent:)]) {
        [_networkDelegate HTTPOperation:self didReceiveData:receivedData completionPercent:percent];
    } else {
        if (self.progressHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.progressHandler(self, receivedData, percent);
            });
        }
    }
}

- (void)_notifyFinishWithOperation:(STHTTPOperation *)operation responseData:(NSData *)responseData error:(NSError *)error {
    if ([_networkDelegate respondsToSelector:@selector(HTTPOperation:didFinishWithData:error:)]) {
        [_networkDelegate HTTPOperation:self didFinishWithData:self.responseData error:error];
    } else {
        if (self.finishedHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.finishedHandler(self, self.responseData, nil);
            });
        }
    }
}

- (void)_notifyWillStartWithOperation:(STHTTPOperation *)operation {
    if ([_networkDelegate respondsToSelector:@selector(HTTPOperationWillStart:)]) {
        [_networkDelegate HTTPOperationWillStart:self];
    } else {
        if (self.willStartHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.willStartHandler(self);
            });
        }
    }
}

- (void)_notifyResponseWithOperation:(STHTTPOperation *)operation response:(NSHTTPURLResponse *)HTTPResponse {
    if ([_networkDelegate respondsToSelector:@selector(HTTPOperation:didReceiveResponse:)]) {
        [_networkDelegate HTTPOperation:self didReceiveResponse:HTTPResponse];
    } else {
        if (self.responseHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.responseHandler(self, HTTPResponse);
            });
        }
    }
}

@end

@implementation STHTTPOperation (STHTTPRequest)

+ (instancetype)operationWithURLString:(NSString *)URLString parameters:(NSDictionary *)parameters {
    return [self operationWithURLString:URLString HTTPMethod:nil parameters:parameters];
}

+ (instancetype)operationWithURLString:(NSString *)URLString HTTPMethod:(NSString *)method parameters:(NSDictionary *)parameters {
    STHTTPRequest *HTTPRequest = [[STHTTPRequest alloc] initWithURLString:URLString HTTPMethod:method parameters:parameters];
    return [[self alloc] initWithHTTPRequest:HTTPRequest];
}

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
    [self.request setAllHTTPHeaderFields:headerFields];
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
    [self.request setValue:value forHTTPHeaderField:field];
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
    [self.request addValue:value forHTTPHeaderField:field];
}

- (void)setParameter:(id <NSCopying>)parameter forField:(NSString *)field {
    [self.request setParameter:parameter forField:field];
}

- (void)addParameter:(id <NSCopying>)parameter forField:(NSString *)field {
    [self.request addParameter:parameter forField:field];
}

- (void)setHTTPConfiguration:(STHTTPConfiguration *)configuration {
    self.request.HTTPConfiguration = configuration;
}

- (STHTTPConfiguration *)HTTPConfiguration {
    return self.request.HTTPConfiguration;
}

@end

static inline BOOL _STHTTPOperationCouldChangeToState(STHTTPOperation *operation, _STHTTPOperationState toState) {
    switch (operation.operationState) {
        case STHTTPOperationStateReady:
            switch (toState) {
                case STHTTPOperationStateExecuting:
                    return YES;
                case STHTTPOperationStateFinished:
                    return [operation isCancelled];
                default:
                    return NO;
            }
        case STHTTPOperationStateExecuting:
            switch (toState) {
                case STHTTPOperationStateFinished:
                    return YES;
                default:
                    return NO;
            }
        case STHTTPOperationStateFinished:
            return NO;
        default:
            return YES;
    }
}
