//
//  STHTTPRequest.m
//  STKit
//
//  Created by SunJiangting on 15-2-4.
//  Copyright (c) 2015年 SunJiangting. All rights reserved.
//

#import "STHTTPRequest.h"
#import <zlib.h>
#import "Foundation+STKit.h"
#import <UIKit/UIKit.h>

@implementation STMultipartItem

- (BOOL)isEqualToItem:(STMultipartItem *)item {
    return NO;
}
@end


@interface NSArray (STNetwork)

- (NSString *)st_componentsJoinedUsingURLEncode;

- (NSString *)st_componentsJoinedUsingSeparator:(NSString *)separator;

@end

@interface STHTTPRequest () {
 @private
    NSString    *_URLString;
    NSMutableURLRequest *_mutableURLRequest;
}

@property (nonatomic, strong)NSMutableDictionary    *parameters;
@end

@implementation STHTTPRequest

- (NSString *)description {
    return _URLString;
}

- (instancetype)init {
    return [self initWithURLString:nil HTTPMethod:nil parameters:nil];
}

- (instancetype)initWithURLString:(NSString *)URLString HTTPMethod:(NSString *)HTTPMethod parameters:(NSDictionary *)parameters {
    self = [super init];
    if (self) {
        self.parameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
        _URLString = [URLString copy];
        NSURL *URL = [NSURL URLWithString:URLString];
        _mutableURLRequest = [[NSMutableURLRequest alloc] initWithURL:URL];
        _mutableURLRequest.HTTPMethod = HTTPMethod;
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
    if (!_mutableURLRequest.HTTPMethod) {
        _mutableURLRequest.HTTPMethod = HTTPConfiguration.HTTPMethod;
    }
    if (_mutableURLRequest.timeoutInterval == 0) {
        _mutableURLRequest.timeoutInterval = HTTPConfiguration.timeoutInterval;
    }
    _mutableURLRequest.cachePolicy = HTTPConfiguration.cachePolicy;
    _HTTPConfiguration = HTTPConfiguration;
}

- (void)prepareToRequest {
    STHTTPConfiguration *configuration = self.HTTPConfiguration?:[STHTTPConfiguration defaultConfiguration];
    BOOL compressedRequest = !!(configuration.compressionOptions & STCompressionOptionsRequestAllowed);
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
    if ([bodyHTTPMethods containsObject:HTTPMethod]) {
        [self reloadHTTPBodyCompressed:compressedRequest];
    } else {
        NSMutableString *mutableString = [NSMutableString stringWithString:_URLString];
        NSMutableArray *unwrapParameters = [NSMutableArray arrayWithCapacity:self.parameters.count];
        [self.parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
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
        _mutableURLRequest.URL = [NSURL URLWithString:[mutableString copy]];
    }
    if (configuration.compressionOptions & STCompressionOptionsResponseAccepted) {
        [_mutableURLRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    }
    _mutableURLRequest.cachePolicy = configuration.cachePolicy;
}


#pragma mark - HTTPBody
- (void)reloadHTTPBodyCompressed:(BOOL)compressed {
    //    NSString * const kBoundary = @"STKitNetworkBoundary";
    STHTTPConfiguration *configuration = self.HTTPConfiguration?:[STHTTPConfiguration defaultConfiguration];
    NSString *const kBoundary = @"f235dec111be2681";
    NSString *HTTPMethod = _mutableURLRequest.HTTPMethod;
    if ([HTTPMethod isEqualToString:@"PUT"] || [HTTPMethod isEqualToString:@"POST"] || [HTTPMethod isEqualToString:@"PATCH"]) {
        /// 需要拼接form
        NSMutableArray *unwrapParameters = [NSMutableArray arrayWithCapacity:self.parameters.count];
        [self.parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([obj isKindOfClass:[NSArray class]]) {
                [obj enumerateObjectsUsingBlock:^(id elements, NSUInteger idx, BOOL *stop) { [unwrapParameters addObject:@{key : elements}]; }];
            } else {
                [unwrapParameters addObject:@{key : obj}];
            }
        }];
        __block NSInteger simpleFieldsCount = 0;
        [unwrapParameters enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (![obj isKindOfClass:[STMultipartItem class]]) {
                simpleFieldsCount++;
            }
        }];
        NSMutableData *postData = [NSMutableData data];
        STHTTPRequestFormEnctype enctype = configuration.enctype;
        if (simpleFieldsCount < unwrapParameters.count || enctype == STHTTPRequestFormEnctypeMultipartData) {
            [unwrapParameters enumerateObjectsUsingBlock:^(NSDictionary *parameter, NSUInteger idx, BOOL *stop) {
                NSString *key = [parameter.allKeys firstObject];
                id obj = [parameter valueForKey:key];
                if ([obj isKindOfClass:[STMultipartItem class]]) {
                    STMultipartItem *multipartItem = (STMultipartItem *)obj;
                    if (multipartItem.name && (multipartItem.path || multipartItem.data)) {
                        NSData *data = multipartItem.data?:[NSData dataWithContentsOfFile:multipartItem.path];
                        if (data.length > 0) {
                            NSString *body =
                            [NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\nContent-Type: "
                             @"application/octet-stream\r\nContent-Transfer-Encoding: binary\r\n\r\n",
                             kBoundary, key, multipartItem.name];
                            [postData appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
                            [postData appendData:data];
                            [postData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                        }
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
            [_mutableURLRequest setValue:[NSString stringWithFormat:@"multipart/form-data; charset=%@; boundary=%@", charset, kBoundary]
                          forHTTPHeaderField:@"Content-Type"];
        } else if (enctype == STHTTPRequestFormEnctypeTextPlain) {
            NSString *parameterString =
            [[unwrapParameters st_componentsJoinedUsingSeparator:@"\r\n"] stringByReplacingOccurrencesOfString:@" " withString:@"+"];
            [postData appendData:[parameterString dataUsingEncoding:NSUTF8StringEncoding]];
            NSString *charset =
            (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
            [_mutableURLRequest setValue:[NSString stringWithFormat:@"text/plain; charset=%@;", charset] forHTTPHeaderField:@"Content-Type"];
        } else {
            NSString *parameterString = [unwrapParameters st_componentsJoinedUsingURLEncode];
            [postData appendData:[parameterString dataUsingEncoding:NSUTF8StringEncoding]];
            NSString *charset =
            (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
            [_mutableURLRequest setValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@;", charset]
                          forHTTPHeaderField:@"Content-Type"];
        }
        NSData *body = compressed ? ([postData st_compressDataUsingGZip]?: postData) : postData;
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
    [self enumerateObjectsUsingBlock:^(NSDictionary *parameter, NSUInteger idx, BOOL *stop) {
        NSString *key = [parameter.allKeys firstObject];
        NSString *value = [parameter valueForKey:key];
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
