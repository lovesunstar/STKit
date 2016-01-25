//
//  STHTTPRequest.m
//  STKit
//
//  Created by SunJiangting on 15-2-4.
//  Copyright (c) 2015年 SunJiangting. All rights reserved.
//

#import "STHTTPRequest.h"
#import "Foundation+STKit.h"
#import <UIKit/UIKit.h>
#import "NSData+STGZip.h"

@implementation STMultipartItem

- (BOOL)isEqualToItem:(STMultipartItem *)item {
    return NO;
}

- (NSData *)HTTPBodyDataWithBoundary:(NSString *)boundary fieldName:(NSString *)fieldName {
    NSData *data = self.data?:[NSData dataWithContentsOfFile:self.path];
    NSString *name =  self.name ?: @((long long)[[NSDate date] timeIntervalSince1970]).stringValue;
    if (!fieldName || !boundary||  ![data isKindOfClass:[NSData class]] || data.length == 0) {
        return nil;
    }
    NSMutableData *HTTPBody = [NSMutableData dataWithCapacity:300];
    NSString *body =
    [NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\nContent-Type: "
     @"application/octet-stream\r\nContent-Transfer-Encoding: binary\r\n\r\n",
     boundary, fieldName, name];
    [HTTPBody appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
    [HTTPBody appendData:data];
    [HTTPBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    return HTTPBody;
}

@end

@interface STHTTPBodyItem : NSObject

@property(nonatomic, copy) NSString *fieldName;
@property(nonatomic, strong) id     fieldValue;

@end

@implementation STHTTPBodyItem

- (instancetype)initWithFieldName:(NSString *)fieldName value:(id)value {
    self = [super init];
    if (self) {
        self.fieldName = fieldName;
        self.fieldValue = value;
    }
    return self;
}

- (NSData *)HTTPBodyDataWithBoundary:(NSString *)boundary {
    if ([self.fieldValue isKindOfClass:[STMultipartItem class]]) {
        return [(STMultipartItem *)self.fieldValue HTTPBodyDataWithBoundary:boundary fieldName:self.fieldName];
    }
    NSMutableData *HTTPBody = [NSMutableData dataWithCapacity:100];
    NSString *body =
    [NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@", boundary, self.fieldName, self.fieldValue];
    [HTTPBody appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
    [HTTPBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    return HTTPBody;
}

@end

static NSArray *STQueryComponentsWithParameters(NSDictionary *parameters);
static NSArray *STQueryComponents(NSString *key, id value);


@interface NSArray (STNetwork)

- (NSString *)st_componentsJoinedUsingURLEncode;

- (NSString *)st_componentsJoinedUsingSeparator:(NSString *)separator;

@end

@interface STHTTPRequest () {
@private
    NSString    *_URLString;
    NSString    *_HTTPMethod;
    NSMutableURLRequest *_mutableURLRequest;
    NSTimeInterval _timeoutInterval;
}
@property (nonatomic, strong)NSMutableDictionary    *parameters;
+ (BOOL)supportGZipCompress;
@end

@implementation STHTTPRequest

- (instancetype)init {
    return [self initWithURLString:@"" HTTPMethod:@"POST" parameters:nil];
}

- (instancetype)initWithURLString:(NSString *)URLString HTTPMethod:(NSString *)HTTPMethod parameters:(NSDictionary *)parameters {
    self = [super init];
    if (self) {
        self.parameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
        _URLString = [URLString copy];
        NSURL *URL = [NSURL URLWithString:URLString];
        _HTTPMethod = [HTTPMethod copy];
        _mutableURLRequest = [[NSMutableURLRequest alloc] initWithURL:URL];
        if (HTTPMethod) {
            _mutableURLRequest.HTTPMethod = HTTPMethod;
        }
        [_mutableURLRequest setValue:@"text/html,text/json,text/xml,application/xhtml+xml,application/xml,application/json,*/*;" forHTTPHeaderField:@"Accept"];
        
        NSString *name = [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleNameKey];
        NSString *bundleVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleVersionKey];
        NSString *userAgent = [NSString stringWithFormat:@"%@/%@ (%@; %@ %@) STKit/%@", name,
                               bundleVersion, [UIDevice currentDevice].systemName,
                               [UIDevice currentDevice].localizedModel, [UIDevice currentDevice].systemVersion, STKitGetVersion()];
        [_mutableURLRequest addValue:userAgent forHTTPHeaderField:@"User-Agent"];
    }
    return self;
}

+ (instancetype)requestWithURLString:(NSString *)URLString HTTPMethod:(NSString *)HTTPMethod parameters:(NSDictionary *)parameters {
    return [[self alloc] initWithURLString:URLString HTTPMethod:HTTPMethod parameters:parameters];
}

- (void)setHTTPConfiguration:(STHTTPConfiguration *)HTTPConfiguration {
    if (!_mutableURLRequest.HTTPMethod || !_HTTPMethod) {
        _mutableURLRequest.HTTPMethod = HTTPConfiguration.HTTPMethod;
        _HTTPMethod = HTTPConfiguration.HTTPMethod;
    }
    if (_timeoutInterval == 0) {
        _timeoutInterval = HTTPConfiguration.timeoutInterval;
        _mutableURLRequest.timeoutInterval = HTTPConfiguration.timeoutInterval;
    }
    if (_mutableURLRequest.timeoutInterval == 0) {
        _mutableURLRequest.timeoutInterval = 60;
    }
    _mutableURLRequest.cachePolicy = HTTPConfiguration.cachePolicy;
    _HTTPConfiguration = HTTPConfiguration;
}

- (void)prepareToRequest {
    STHTTPConfiguration *configuration = self.HTTPConfiguration?:[STHTTPConfiguration defaultConfiguration];
    BOOL supportZipCompress = [[self class] supportGZipCompress];
    BOOL compressedRequest = !!(configuration.compressionOptions & STCompressionOptionsRequestAllowed) && supportZipCompress;
    if (compressedRequest) {
        [_mutableURLRequest setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
    }
    NSString *HTTPMethod = _mutableURLRequest.HTTPMethod;
    if (!HTTPMethod) {
        HTTPMethod = configuration.HTTPMethod;
        if (!HTTPMethod) {
            HTTPMethod = @"GET";
        }
        _mutableURLRequest.HTTPMethod = HTTPMethod;
    }
    NSArray *bodyHTTPMethods = @[@"PUT", @"POST", @"PATCH"];
    NSArray *unwrapParameters = STQueryComponentsWithParameters(self.parameters);
    if ([bodyHTTPMethods containsObject:HTTPMethod]) {
        [self reloadHTTPBodyWithParameters:unwrapParameters compressed:compressedRequest];
    } else {
        NSMutableString *mutableString = [NSMutableString stringWithString:_URLString];
        NSString *parameterString = [unwrapParameters st_componentsJoinedUsingURLEncode];
        if (parameterString.length > 0) {
            [mutableString appendFormat:@"?%@", parameterString];
        }
        _mutableURLRequest.URL = [NSURL URLWithString:[mutableString copy]];
    }
    if (configuration.compressionOptions & STCompressionOptionsResponseAccepted) {
        [_mutableURLRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    }
    _mutableURLRequest.cachePolicy = configuration.cachePolicy;
}


#pragma mark - HTTPBody
/// parameters /*STHTTPBodyItem*/
- (void)reloadHTTPBodyWithParameters:(NSArray *)parameters
                          compressed:(BOOL)compressed {
    //    NSString * const kBoundary = @"STKitNetworkBoundary";
    STHTTPConfiguration *configuration = self.HTTPConfiguration?:[STHTTPConfiguration defaultConfiguration];
    NSString *const kBoundary = @"f235dec111be2681";
    NSString *HTTPMethod = _mutableURLRequest.HTTPMethod;
    if ([HTTPMethod isEqualToString:@"PUT"] || [HTTPMethod isEqualToString:@"POST"] || [HTTPMethod isEqualToString:@"PATCH"]) {
        /// 需要拼接form
        __block BOOL containsMutilpartItem = NO;
        [parameters enumerateObjectsUsingBlock:^(STHTTPBodyItem *obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[STHTTPBodyItem class]] && [obj.fieldValue isKindOfClass:[STMultipartItem class]]) {
                containsMutilpartItem = YES;
                *stop = YES;
            }
        }];
        NSMutableData *postData = [NSMutableData data];
        STHTTPRequestFormEnctype enctype = configuration.enctype;
        if (containsMutilpartItem) {
            enctype = STHTTPRequestFormEnctypeMultipartData;
        }
        if (enctype == STHTTPRequestFormEnctypeMultipartData) {
            [parameters enumerateObjectsUsingBlock:^(STHTTPBodyItem *parameter, NSUInteger idx, BOOL *stop) {
                if ([parameter isKindOfClass:[STHTTPBodyItem class]]) {
                    NSData *data = [parameter HTTPBodyDataWithBoundary:kBoundary];
                    if (data.length > 0) {
                        [postData appendData:data];
                    }
                }
            }];
            [postData appendData:[[NSString stringWithFormat:@"--%@--\r\n", kBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
            NSString *charset =
            (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
            [_mutableURLRequest setValue:[NSString stringWithFormat:@"multipart/form-data; charset=%@; boundary=%@", charset, kBoundary]
                      forHTTPHeaderField:@"Content-Type"];
        } else if (enctype == STHTTPRequestFormEnctypeTextPlain) {
            NSString *parameterString =
            [[parameters st_componentsJoinedUsingSeparator:@"\r\n"] stringByReplacingOccurrencesOfString:@" " withString:@"+"];
            [postData appendData:[parameterString dataUsingEncoding:NSUTF8StringEncoding]];
            NSString *charset =
            (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
            [_mutableURLRequest setValue:[NSString stringWithFormat:@"text/plain; charset=%@;", charset] forHTTPHeaderField:@"Content-Type"];
        } else {
            NSString *parameterString = [parameters st_componentsJoinedUsingURLEncode];
            [postData appendData:[parameterString dataUsingEncoding:NSUTF8StringEncoding]];
            NSString *charset =
            (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
            [_mutableURLRequest setValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@;", charset]
                      forHTTPHeaderField:@"Content-Type"];
        }
        NSData *body = postData;
        if (compressed) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            SEL selector = NSSelectorFromString(@"st_compressDataUsingGZip");
            if ([postData respondsToSelector:selector]) {
                body = [postData performSelector:selector];
            }
            if (!body) {
                body = postData;
            }
#pragma clang diagnostic pop
        }
        if (body.length > 0) {
            [_mutableURLRequest setValue:[NSString stringWithFormat:@"%ld", (long)body.length] forHTTPHeaderField:@"Content-Length"];
        }
        [_mutableURLRequest setHTTPBody:body];
    } else {
        NSAssert(1, @"httpbody must in post/put/patch method");
    }
}

- (NSURLRequest *)URLRequest {
    return [_mutableURLRequest copy];
}

- (id)valueForKey:(NSString *)key {
    if ([key isEqualToString:@"_mutableURLRequest"]) {
        return nil;
    }
    return [super valueForKey:key];
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if (![key isEqualToString:@"_mutableURLRequest"]) {
        [super setValue:value forKeyPath:key];
    }
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    return ![key isEqualToString:@"_mutableURLRequest"] && [super automaticallyNotifiesObserversForKey:key];
}


+ (BOOL)supportGZipCompress {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL selector = NSSelectorFromString(@"st_compressDataUsingGZip");
    return [NSData instancesRespondToSelector:selector];
#pragma clang diagnostic pop
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithCapacity:20];
    [description appendString:_mutableURLRequest.HTTPMethod];
    [description appendString:@":"];
    [description appendString:_URLString];
    return [description copy];
}
@end


@implementation STHTTPRequest (STHTTPHeader)

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
    [_mutableURLRequest setAllHTTPHeaderFields:headerFields];
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
    [_mutableURLRequest setValue:value forHTTPHeaderField:field];
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
    [_mutableURLRequest addValue:value forHTTPHeaderField:field];
}

- (void)setParameter:(id <NSCopying>)parameter forField:(NSString *)field {
    if (field.length == 0) {
        return;
    }
    [self.parameters setValue:parameter forKey:field];
}

- (void)addParameter:(id <NSCopying>)parameter forField:(NSString *)field {
    if (field.length == 0 || !parameter) {
        return;
    }
    id value = [self.parameters valueForKey:field];
    if ([value isKindOfClass:[NSArray class]]) {
        NSMutableArray *values = [value mutableCopy];
        [values addObject:parameter];
        [self.parameters setValue:values forKey:field];
    } else {
        if (value) {
            NSMutableArray *values = [NSMutableArray arrayWithObjects:value, parameter, nil];
            [self.parameters setValue:values forKey:field];
        } else {
            [self.parameters setValue:parameter forKey:field];
        }
    }
    
}

@end


@implementation NSArray (STNetwork)

- (NSString *)st_componentsJoinedUsingURLEncode {
    NSMutableString *mutableString = [NSMutableString string];
    [self enumerateObjectsUsingBlock:^(STHTTPBodyItem *parameter, NSUInteger idx, BOOL *stop) {
        NSString *key = parameter.fieldName;
        NSString *value = parameter.fieldValue;
        if ([value isKindOfClass:[NSString class]]) {
            [mutableString appendFormat:@"%@=%@&", [key st_stringByURLEncoded], [value st_stringByURLEncoded]];
        } else {
            [mutableString appendFormat:@"%@=%@&", [key st_stringByURLEncoded], value];
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
    [self enumerateObjectsUsingBlock:^(STHTTPBodyItem *parameter, NSUInteger idx, BOOL *stop) {
        NSString *key = parameter.fieldName;
        NSString *value = parameter.fieldValue;
        [mutableString appendFormat:@"%@=%@%@", key, value, separator];
    }];
    if (mutableString.length > 0) {
        [mutableString deleteCharactersInRange:NSMakeRange(mutableString.length - separator.length, separator.length)];
    }
    return mutableString;
}

@end


@implementation NSString (STURLParameters)

- (NSString *)stringByAppendingURLParameters:(NSDictionary *)parameters {
    NSString *result = [parameters st_compontentsJoinedByConnector:@"=" separator:@"&"];
    if (result.length == 0) {
        return self;
    }
    NSString *connector = ([self st_contains:@"?"])? @"&" : @"?";
    return [self stringByAppendingFormat:@"%@%@", connector, result];
}

@end


static NSArray *STQueryComponentsWithParameters(NSDictionary *parameters) {
    NSMutableArray *components = [NSMutableArray arrayWithCapacity:10];
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [components addObjectsFromArray:STQueryComponents(key, obj)];
    }];
    return components;
}

static NSArray *STQueryComponents(NSString *key, id value) {
    NSMutableArray *components = [NSMutableArray arrayWithCapacity:10];
    if ([value isKindOfClass:[NSDictionary class]]) {
        [value enumerateKeysAndObjectsUsingBlock:^(id nestedKey, id  obj, BOOL *stop) {
            [components addObjectsFromArray:STQueryComponents([NSString stringWithFormat:@"%@[%@]", key, nestedKey], obj)];
        }];
    } else if ([value isKindOfClass:[NSArray class]]) {
        [value enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [components addObjectsFromArray:STQueryComponents([NSString stringWithFormat:@"%@[]", key], obj)];
        }];
    } else {
        STHTTPBodyItem *item = [[STHTTPBodyItem alloc] initWithFieldName:key value:value];
        [components addObject:item];
    }
    return components;
}

NSString *STJoinQueryComponentsWithParameters(NSDictionary *parameters) {
    return [STQueryComponentsWithParameters(parameters) st_componentsJoinedUsingURLEncode];
}
