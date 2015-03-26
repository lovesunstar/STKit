//
//  STHTTPNetwork.m
//  STKit
//
//  Created by SunJiangting on 13-11-25.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import "STHTTPNetwork.h"

#import "STHTTPOperation.h"

typedef void (^STXMLReaderHandler)(NSXMLParser *XMLparser, id object, NSError *error);

@interface STXMLReader : NSObject <NSXMLParserDelegate>
@property(nonatomic, strong) STXMLReaderHandler completionHandler;

+ (void)parseXMLObjectWithData:(NSData *)data
             elementContentKey:(NSString *)contentKey
                       options:(STXMLParseOptions)opt
             completionHandler:(STXMLReaderHandler)handler;

- (void)parseXMLObjectWithData:(NSData *)data
             elementContentKey:(NSString *)contentKey
                       options:(STXMLParseOptions)opt
             completionHandler:(STXMLReaderHandler)handler;

@end

@implementation STXMLReader {
    NSMutableArray *_tempDictionaries;
    NSMutableString *_textInProgress;
    __weak NSXMLParser *_XMLParser;

    NSString *_elementContentKey;
}

+ (void)parseXMLObjectWithData:(NSData *)data
             elementContentKey:(NSString *)contentKey
                       options:(STXMLParseOptions)opt
             completionHandler:(STXMLReaderHandler)handler {
    STXMLReader *XMLReader = [[STXMLReader alloc] init];
    [XMLReader parseXMLObjectWithData:data elementContentKey:contentKey options:opt completionHandler:handler];
}

- (void)parseXMLObjectWithData:(NSData *)data
             elementContentKey:(NSString *)contentKey
                       options:(STXMLParseOptions)opt
             completionHandler:(STXMLReaderHandler)handler {
    if (_XMLParser) {
        _XMLParser.delegate = nil;
        [_XMLParser abortParsing];
        NSError *error = [NSError errorWithDomain:@"com.suen.xml.parse" code:100001 userInfo:@{@"info" : @"User Cancelled the parse operation" }];
        if (self.completionHandler) {
            self.completionHandler(_XMLParser, nil, error);
        }
    }
    self.completionHandler = handler;
    _elementContentKey = [contentKey copy];
    _tempDictionaries = [NSMutableArray arrayWithCapacity:2];
    _textInProgress = [[NSMutableString alloc] init];
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    parser.delegate = self;
    parser.shouldProcessNamespaces = opt & STXMLParseOptionsProcessNamespaces;
    parser.shouldReportNamespacePrefixes = opt & STXMLParseOptionsReportNamespacePrefixes;
    parser.shouldResolveExternalEntities = opt & STXMLParseOptionsResolveExternalEntities;
    [parser parse];
    _XMLParser = parser;
}

#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser
    didStartElement:(NSString *)elementName
       namespaceURI:(NSString *)namespaceURI
      qualifiedName:(NSString *)qName
         attributes:(NSDictionary *)attributeDict {
    // Get the dictionary for the current level in the stack
    NSMutableDictionary *parentDict = [_tempDictionaries lastObject];
    // Create the child dictionary for the new element, and initilaize it with the attributes
    NSMutableDictionary *childDict = [NSMutableDictionary dictionary];
    [childDict addEntriesFromDictionary:attributeDict];

    // If there's already an item for this key, it means we need to create an array
    id existingValue = [parentDict objectForKey:elementName];
    if (existingValue) {
        NSMutableArray *array = nil;
        if ([existingValue isKindOfClass:[NSMutableArray class]]) {
            // The array exists, so use it
            array = (NSMutableArray *)existingValue;
        } else {
            // Create an array if it doesn't exist
            array = [NSMutableArray array];
            [array addObject:existingValue];

            // Replace the child dictionary with an array of children dictionaries
            [parentDict setObject:array forKey:elementName];
        }
        // Add the new child dictionary to the array
        [array addObject:childDict];
    } else {
        // No existing value, so update the dictionary
        [parentDict setObject:childDict forKey:elementName];
    }
    // Update the stack
    [_tempDictionaries addObject:childDict];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    // Update the parent dict with text info
    NSMutableDictionary *dictInProgress = [_tempDictionaries lastObject];

    // Set the text property
    if (_textInProgress.length > 0) {
        [dictInProgress setObject:_textInProgress forKey:_elementContentKey];
        // Reset the text
        _textInProgress = [NSMutableString stringWithCapacity:2];
    }
    // Pop the current dict
    [_tempDictionaries removeLastObject];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (self.completionHandler) {
        self.completionHandler(parser, [[_tempDictionaries firstObject] copy], [parser parserError]);
    }
    self.completionHandler = nil;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    // Build the text value
    [_textInProgress appendString:string];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    // Set the error pointer to the parser's error object
    if (self.completionHandler) {
        self.completionHandler(parser, [[_tempDictionaries firstObject] copy], parseError);
    }
    self.completionHandler = nil;
}

- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validationError {
    // Set the error pointer to the parser's error object
    if (self.completionHandler) {
        self.completionHandler(parser, [[_tempDictionaries firstObject] copy], validationError);
    }
    self.completionHandler = nil;
}

@end

static NSString *const STHTTPNetworkDomain = @"com.suen.network.http";
@interface STHTTPNetwork ()

@property(nonatomic, strong) STNetworkConfiguration *configuraiton;
/// 回调Queue
@property(nonatomic, strong) NSOperationQueue   *networkQueue;

@end

@interface STHTTPNetwork (STXMLParser)

@end

@implementation STHTTPNetwork

static NSOperationQueue *_defaultNetworkQueue;
+ (NSOperationQueue *)defaultNetworkQueue {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultNetworkQueue = [[NSOperationQueue alloc] init];
        _defaultNetworkQueue.name = @"com.suen.HTTPNetwork";
        _defaultNetworkQueue.maxConcurrentOperationCount = 6;
    });
    return _defaultNetworkQueue;
}

@synthesize maxConcurrentRequestCount = _maxConcurrentRequestCount;

static STHTTPNetwork *_HTTPNetwork;
+ (instancetype)defaultHTTPNetwork {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _HTTPNetwork = [[self alloc] init];
    });
    return _HTTPNetwork;
}

static NSURLCache *_HTTPCache;
+ (NSURLCache *)defaultHTTPCache {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _HTTPCache = [[NSURLCache alloc] initWithMemoryCapacity:4*1024*1024 diskCapacity:50*1024*1024 diskPath:@"STHTTPCache"];
    });
    return _HTTPCache;
}

- (instancetype)init {
    return [self initWithConfiguration:[STNetworkConfiguration sharedConfiguration]];
}

- (instancetype)initWithConfiguration:(STNetworkConfiguration *)configuration {
    if (!configuration) {
        configuration = [STNetworkConfiguration sharedConfiguration];
    }
    self = [super init];
    if (self) {
        self.configuraiton = configuration;
        _maxConcurrentRequestCount = 6;
    }
    return self;
}

- (NSOperationQueue *)networkQueue {
    if (!_networkQueue) {
        _networkQueue = [[self class] defaultNetworkQueue];
        _networkQueue.maxConcurrentOperationCount = _maxConcurrentRequestCount;
    }
    return _networkQueue;
}

- (void)sendHTTPOperation:(STHTTPOperation *)operation {
    if ([operation isSynchronous]) {
        if (operation.willStartHandler) {
            operation.willStartHandler(operation);
        }
        NSURLResponse *URLResponse = nil;
        NSError *error = nil;
        if (!operation.configuration) {
            operation.configuration = self.configuraiton;
        }
        [operation.request prepareToRequest];
        NSData *data = [NSURLConnection sendSynchronousRequest:operation.request.URLRequest returningResponse:&URLResponse error:&error];
        if (operation.finishedHandler) {
            [operation setValue:URLResponse forVar:@"_HTTPResponse"];
            operation.finishedHandler(operation, data, error);
        }
    } else {
        [operation setValue:self forVar:@"_networkDelegate"];
        if (!operation.configuration) {
            operation.configuration = self.configuraiton;
        }
        [self.networkQueue addOperation:operation];
    }
}
- (void)cancelHTTPOperation:(STHTTPOperation *)operation {
    [operation cancel];
}

- (void)setMaxConcurrentRequestCount:(NSInteger)maxConcurrentRequestCount {
    _networkQueue.maxConcurrentOperationCount=  maxConcurrentRequestCount;
    _maxConcurrentRequestCount = maxConcurrentRequestCount;
}

- (NSInteger)maxConcurrentRequestCount {
    return _networkQueue.maxConcurrentOperationCount;
}

#pragma mark -STHTTPOperationDelegate

- (void)HTTPOperationWillStart:(STHTTPOperation *)operation {
    dispatch_queue_t delegateQueue = self.callbackQueue ?:dispatch_get_main_queue();
    dispatch_async(delegateQueue, ^{
        if (operation.willStartHandler) {
            operation.willStartHandler(operation);
        }
    });
}

- (void)HTTPOperation:(STHTTPOperation *)operation didSendRequestWithCompletionPercent:(CGFloat)completionPercent {
    dispatch_queue_t delegateQueue = self.callbackQueue ?:dispatch_get_main_queue();
    dispatch_async(delegateQueue, ^{
        if (operation.requestProgressHandler) {
            operation.requestProgressHandler(operation, completionPercent);
        }
    });
}

- (void)HTTPOperation:(STHTTPOperation *)operation
   didReceiveResponse:(NSHTTPURLResponse *)response {
    dispatch_queue_t delegateQueue = self.callbackQueue ?:dispatch_get_main_queue();
    dispatch_async(delegateQueue, ^{
        if (operation.responseHandler) {
            operation.responseHandler(operation, response);
        }
    });
}

- (void)HTTPOperation:(STHTTPOperation *)operation
       didReceiveData:(NSData *)receivedData
    completionPercent:(CGFloat)completionPercent {
    dispatch_queue_t delegateQueue = self.callbackQueue ?:dispatch_get_main_queue();
    dispatch_async(delegateQueue, ^{
        if (operation.progressHandler) {
            operation.progressHandler(operation, receivedData, completionPercent);
        }
    });
}

- (void)HTTPOperation:(STHTTPOperation *)operation
    didFinishWithData:(NSData *)data
                error:(NSError *)error {
    if (error) {
        [self _invokeHandlerOnDelegateQueue:operation.finishedHandler withOperation:operation responseData:data error:error];
    } else {
        STHTTPConfiguration *configuration = operation.request.HTTPConfiguration?:self.configuraiton.HTTPConfiguration;
        if (!configuration.decodeResponseData) {
            [self _invokeHandlerOnDelegateQueue:operation.finishedHandler withOperation:operation responseData:data error:error];
        } else {
            [self _decodeData:data
           withConfiguration:configuration
           completionHandler:^(id responseData, NSError *error) {
                  [self _invokeHandlerOnDelegateQueue:operation.finishedHandler withOperation:operation responseData:responseData error:error];
           }];
        }
    }
}

- (NSStringEncoding)_responseStringEncoding:(NSHTTPURLResponse *)response {
    NSStringEncoding stringEncoding = NSUTF8StringEncoding;
    if (response.textEncodingName) {
        CFStringEncoding IANAEncoding = CFStringConvertIANACharSetNameToEncoding((__bridge CFStringRef)response.textEncodingName);
        if (IANAEncoding != kCFStringEncodingInvalidId) {
            stringEncoding = CFStringConvertEncodingToNSStringEncoding(IANAEncoding);
        }
    }
   return stringEncoding;
}


- (void)_invokeHandlerOnDelegateQueue:(STHTTPNetworkHandler)handler
                        withOperation:(STHTTPOperation *)operation
                         responseData:(NSObject *)responseData
                                error:(NSError *)error {
    dispatch_queue_t delegateQueue = self.callbackQueue ?:dispatch_get_main_queue();
    dispatch_async(delegateQueue, ^{
        if (handler) {
            handler(operation, responseData, error);
        }
    });
}

- (void)_decodeData:(NSData *)data
  withConfiguration:(STHTTPConfiguration *)configuration
  completionHandler:(void (^)(id data, NSError *error))handler {
    STHTTPResponseDataType dataType = configuration.dataType;
    switch (dataType) {
        case STHTTPResponseDataTypeTextHTML: {
            NSString *string = [[NSString alloc] initWithData:data encoding:configuration.dataEncoding];
            if (handler) {
                handler(string, nil);
            }
            break;
        }
        case STHTTPResponseDataTypeTextJSON: {
            NSError *error;
            id responseData = [NSJSONSerialization JSONObjectWithData:data options:configuration.JSONReadingOptions error:&error];
            if (handler) {
                handler(responseData, error);
            }
            break;
        }
        case STHTTPResponseDataTypeTextXML: {
            [STXMLReader parseXMLObjectWithData:data
                              elementContentKey:configuration.XMLElementContextKey
                                        options:0
                              completionHandler:^(NSXMLParser *XMLparser, id object, NSError *error) {
                                  if (handler) {
                                      handler(object, error);
                                  }
                              }];
            break;
        }
        default: {
            NSError *error = [NSError errorWithDomain:STHTTPNetworkDomain code:1001 userInfo:@{ @"info" : @"Unsupported dataType." }];
            if (handler) {
                handler(data, error);
            }
        } break;
    }
}

@end

@implementation STHTTPNetwork (STHTTPConvenience)

- (void)sendHTTPOperation:(STHTTPOperation *)operation
        completionHandler:(STHTTPNetworkHandler)completionHandler {
    operation.finishedHandler = completionHandler;
    [self sendHTTPOperation:operation];
}

- (STHTTPOperation *)sendRequestWithURLString:(NSString *)URLString
                                   parameters:(NSDictionary *)parameters
                            completionHandler:(STHTTPNetworkHandler)completionHandler {
    STHTTPOperation *operation = [STHTTPOperation operationWithURLString:URLString parameters:parameters];
    [self sendHTTPOperation:operation completionHandler:completionHandler];
    return operation;
}

@end

NSString *const STHTTPNetworkErrorDomain = @"com.suen.stkit.network";
NSString *const STHTTPNetworkErrorDescriptionUserInfoKey = @"STDescription";