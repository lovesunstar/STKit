//
//  Foundation+STKit.m
//  STKit
//
//  Created by SunJiangting on 13-10-5.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import "Foundation+STKit.h"
#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>

ST_EXTERN BOOL STClassIsKindOfClass(Class _class, Class parentClass) {
    if (!parentClass || !_class) {
        return NO;
    }
    while (_class && _class != parentClass) {
        _class = class_getSuperclass(_class);
    }
    return !!(_class);
}

NSValue *STCreateValueFromPrimitivePointer(void *pointer, const char *objCType) {
// CASE marcro inspired by https://www.mikeash.com/pyblog/friday-qa-2013-02-08-lets-build-key-value-coding.html
#define CASE(ctype)                                                                                                                                  \
    if (strcmp(objCType, @encode(ctype)) == 0) {                                                                                                     \
        return @((*(ctype *)pointer));                                                                                                               \
    }
    CASE(BOOL);
    CASE(char);
    CASE(unsigned char);
    CASE(short);
    CASE(unsigned short);
    CASE(int);
    CASE(unsigned int);
    CASE(long);
    CASE(unsigned long);
    CASE(long long);
    CASE(unsigned long long);
    CASE(float);
    CASE(double);
#undef CASE
    @try {
        return [NSValue valueWithBytes:pointer objCType:objCType];
    }
    @catch (NSException *exception) {
    }
    return nil;
}

BOOL STClassRespondsToSelector(Class class, SEL aSelector) {
    if (!class || !aSelector) {
        return NO;
    }
    Method method = class_getClassMethod(class, aSelector);
    return (method != nil);
}


void STPrintClassMethods(Class cls) {
    if (!cls) {
        return;
    }
    unsigned int count = 0;
    Method *methods = class_copyMethodList(cls, &count);
    for (int i = 0; i < count; i ++) {
        struct objc_method_description *description = method_getDescription(methods[i]);
        NSLog(@"%@", NSStringFromSelector(description->name));
    }
}
extern void _STClassGetAllProperities(Class class, NSMutableSet *mutableSet);
extern void STPrintClassProperities(Class cls) {
    NSMutableSet *set = [NSMutableSet setWithCapacity:5];
    _STClassGetAllProperities(cls, set);
    NSLog(@"%@", set);
}

void _STClassGetAllProperities(Class class, NSMutableSet *mutableSet) {
    if (!class) {
        return;
    }
    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList(class, &propertyCount);
    for (unsigned int i = 0; i < propertyCount; ++i) {
        objc_property_t property = properties[i];
        const char *name = property_getName(property);
        [mutableSet addObject:[NSString stringWithUTF8String:name]];
    }
    free(properties);
    _STClassGetAllProperities(class_getSuperclass(class), mutableSet);
}


inline NSString *STLibiaryDirectory() {
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *cachePath = cachePaths[0];
    return cachePath;
}

inline NSString *STDocumentDirectory() {
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *cachePath = cachePaths[0];
    return cachePath;
}

inline NSString *STTemporaryDirectory() {
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = cachePaths[0];
    NSString *cacheDirectory = [cachePath stringByAppendingPathComponent:@"com.suen.stkit.temp"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cacheDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    return cacheDirectory;
}

inline NSString *STCacheDirectory() {
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = cachePaths[0];
    NSString *cacheDirectory = [cachePath stringByAppendingPathComponent:@"com.suen.stkit.caches"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cacheDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    return cacheDirectory;
}

inline CGFloat STRadianToDegree(CGFloat radian) { return ((radian / M_PI) * 180.0f); }

inline CGFloat STDegreeToRadian(CGFloat degree) { return ((degree / 180.0f) * M_PI); }

BOOL STGetBitOffset(NSInteger value, NSInteger offset) { return !!(value & (1 << offset)); }

inline NSInteger STSetBitOffset(NSInteger value, NSInteger bit, BOOL t) { return (value | (1 << bit)); }

inline NSInteger STCleanBitOffset(NSInteger value, NSInteger bit) { return (value & (~(1 << bit))); }

@implementation NSObject (STKit)
/// 设置全局变量的值,包括private类型的
- (void)setValue:(id)value forVar:(NSString *)varName {
    const char *varNameChar = [varName cStringUsingEncoding:NSUTF8StringEncoding];
    Ivar var = class_getInstanceVariable(self.class, varNameChar);
    if (var) {
        const char *typeEncodingCString = ivar_getTypeEncoding(var);
        if (typeEncodingCString[0] == '@') {
            object_setIvar(self, var, value);
        } else if ([value isKindOfClass:[NSValue class]]) {
            // Primitive - unbox the NSValue.
            NSValue *valueValue = (NSValue *)value;
            if (strcmp([valueValue objCType], typeEncodingCString) != 0) {
                return;
            }
            NSUInteger bufferSize = 0;
            @try {
                // NSGetSizeAndAlignment barfs on type encoding for bitfields.
                NSGetSizeAndAlignment(typeEncodingCString, &bufferSize, NULL);
            }
            @catch (NSException *exception) {
#if DEBUG
                NSLog(@"STKit === %@", exception);
#endif
            }
            if (bufferSize > 0) {
                void *buffer = calloc(1, bufferSize);
                [valueValue getValue:buffer];
                ptrdiff_t offset = ivar_getOffset(var);
                void *pointer = (__bridge void *)self + offset;
                memcpy(pointer, buffer, bufferSize);
                free(buffer);
            }
        }
    }
}

- (id)valueForVar:(NSString *)varName {
    const char *varNameChar = [varName cStringUsingEncoding:NSUTF8StringEncoding];
    Ivar var = class_getInstanceVariable(self.class, varNameChar);
    if (var) {
        const char *type = ivar_getTypeEncoding(var);
        if (type[0] == @encode(id)[0] || type[0] == @encode(Class)[0]) {
            return object_getIvar(self, var);
        } else {
            ptrdiff_t offset = ivar_getOffset(var);
            void *pointer = (__bridge void *)self + offset;
            return STCreateValueFromPrimitivePointer(pointer, type);
        }
    }
    return nil;
}

+ (BOOL)classRespondsToSelector:(SEL)aSelector {
    return STClassRespondsToSelector(self, aSelector);
}

@end

@implementation NSObject (STPerformSelector)

/// 注明： 如果返回值为基本类型，struct除外，其余都转换为NSNumber。 如果返回值是struct。则转为NSValue
- (id)performSelector:(SEL)aSelector withObjects:(id)object, ... {
    NSMutableArray *parameters = [NSMutableArray arrayWithCapacity:2];
    if (object) {
        [parameters addObject:object];
        va_list arglist;
        va_start(arglist, object);
        id arg;
        while ((arg = va_arg(arglist, id))) {
            if (arg) {
                [parameters addObject:arg];
            }
        }
        va_end(arglist);
    }
    if (![self respondsToSelector:aSelector]) {
        return nil;
    }
    NSMethodSignature *methodSignature = [self methodSignatureForSelector:aSelector];
    if (!methodSignature) {
        return nil;
    }
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    invocation.selector = aSelector;
    NSUInteger numberOfArguments = methodSignature.numberOfArguments;
    if (numberOfArguments > 2) {
        for (int i = 2; i < numberOfArguments; i++) {
            NSInteger idx = i - 2;
            id parameter = (parameters.count > idx) ? parameters[idx] : nil;
            [invocation setArgument:&parameter atIndex:i];
        }
    }
    [invocation invokeWithTarget:self];
    const char *type = methodSignature.methodReturnType;
    if (!strcmp(type, @encode(void)) || methodSignature.methodReturnLength == 0) {
        return nil;
    }
    id returnValue;
    if (!strcmp(type, @encode(id))) {
        [invocation getReturnValue:&returnValue];
        return returnValue;
    }
    //    NSNumber, 基本类型都转换位NSNumber
    void *buffer = (void *)malloc(methodSignature.methodReturnLength);
    [invocation getReturnValue:buffer];
    returnValue = STCreateValueFromPrimitivePointer(buffer, type);
    free(buffer);
    return returnValue;
}

- (id)st_performSelector:(SEL)aSelector withObjects:(id)object, ... {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    return [self performSelector:aSelector withObjects:object, nil];
#pragma clang diagnostic pop
}
@end

@implementation NSString (STKit)

- (BOOL)contains:(NSString *)substring {
    return [self rangeOfString:substring].location != NSNotFound;
}

- (NSString *)stringByTrimingWhitespace {
    if (self.length > 0) {
        return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    return self;
}

- (NSArray *)rangesOfString:(NSString *)string {
    NSMutableArray *ranges = [NSMutableArray arrayWithCapacity:2];
    NSUInteger location = 0;
    while (location < self.length) {
        NSRange range = [self rangeOfString:string options:NSLiteralSearch range:NSMakeRange(location, self.length - location)];
        location = range.location + range.length;
        if (range.location != NSNotFound) {
            [ranges addObject:NSStringFromRange(range)];
        }
    }
    return ranges;
}

- (NSArray *)componentsSeparatedByRegex:(NSString *)regex {
    return [self componentsSeparatedByRegex:regex regexRanges:nil];
}

- (NSArray *)componentsSeparatedByRegex:(NSString *)regex ranges:(NSArray **)ranges {
    return [self componentsSeparatedByRegex:regex ranges:ranges checkingResults:nil];
}

- (NSArray *)componentsSeparatedByRegex:(NSString *)regex regexRanges:(NSArray **)ranges {
    return [self componentsSeparatedByRegex:regex ranges:nil checkingResults:ranges];
}

- (NSArray *)componentsSeparatedByRegex:(NSString *)regex ranges:(NSArray **)_ranges checkingResults:(NSArray **)__ranges {
    NSError *error;
    NSRegularExpression *regularExpression =
        [NSRegularExpression regularExpressionWithPattern:regex
                                                  options:NSRegularExpressionAllowCommentsAndWhitespace | NSRegularExpressionDotMatchesLineSeparators
                                                    error:&error];
    if (error) {
        return nil;
    }
    NSMutableArray *substrings = [NSMutableArray arrayWithCapacity:2];
    NSMutableArray *subranges = [NSMutableArray arrayWithCapacity:2];
    NSMutableArray *ranges = [NSMutableArray arrayWithCapacity:2];
    NSMutableArray *checkingResults = [NSMutableArray arrayWithCapacity:2];
    [regularExpression enumerateMatchesInString:self
                                        options:NSMatchingReportCompletion
                                          range:NSMakeRange(0, self.length)
                                     usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                         NSRange range = [result rangeAtIndex:0];
                                         if (range.length > 0) {
                                             [ranges addObject:NSStringFromRange([result rangeAtIndex:0])];
                                             [checkingResults addObject:result];
                                         }
                                     }];
    /// 根据正则表达的区间
    __block NSUInteger location = 0;
    [ranges enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        NSRange range = NSRangeFromString(obj);
        if (range.location != NSNotFound) {
            NSRange subrange = NSMakeRange(location, range.location - location);
            location = range.location + range.length;
            if (subrange.length > 0) {
                NSString *substring = [self substringWithRange:subrange];
                [subranges addObject:NSStringFromRange(subrange)];
                [substrings addObject:substring];
            }
        }
    }];
    if (location < self.length) {
        NSRange subrange = NSMakeRange(location, self.length - location);
        NSString *substring = [self substringWithRange:subrange];
        [subranges addObject:NSStringFromRange(subrange)];
        [substrings addObject:substring];
    }
    if (_ranges) {
        *_ranges = [subranges copy];
    }
    if (__ranges) {
        *__ranges = [checkingResults copy];
    }
    return substrings;
}

- (NSString *)stringByAddingHTMLEscapes {
    if (self.length == 0) {
        return self;
    }
    static NSDictionary *escapingDictionary = nil;
    static NSRegularExpression *regex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        escapingDictionary = @{ @" " : @"&nbsp;",
                                @">" : @"&gt;",
                                @"<" : @"&lt;",
                                @"&" : @"&amp;",
                                @"'" : @"&apos;",
                                @"\"" : @"&quot;",
                                @"«" : @"&laquo;",
                                @"»" : @"&raquo;"
                                };
        regex = [NSRegularExpression regularExpressionWithPattern:@"(&|>|<|'|\"|«|»)" options:0 error:NULL];
    });
    NSMutableString *mutableString = [self mutableCopy];
    NSArray *matches = [regex matchesInString:mutableString options:0 range:NSMakeRange(0, [mutableString length])];
    for (NSTextCheckingResult *result in matches.reverseObjectEnumerator) {
        NSString *foundString = [mutableString substringWithRange:result.range];
        NSString *replacementString = escapingDictionary[foundString];
        if (replacementString) {
            [mutableString replaceCharactersInRange:result.range withString:replacementString];
        }
    }
    return [mutableString copy];
}

- (NSString *)stringByReplacingHTMLEscapes {
    if (self.length == 0) {
        return self;
    }
    static NSDictionary *escapingDictionary = nil;
    static NSRegularExpression *regex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        escapingDictionary = @{@"&nbsp;" : @" ",
                               @"&gt;" : @">",
                               @"&lt;" : @"<",
                               @"&amp;": @"&",
                               @"&apos;":@"'",
                               @"&quot;": @"\"",
                               @"&laquo;":@"«",
                               @"&raquo;":@"»"
                                };
        regex = [NSRegularExpression regularExpressionWithPattern:@"((&nbsp;)|(&gt;)|(&lt;)|(&amp;)|(&apos;)|(&quot;)|(&laquo;)|(&raquo;))" options:0 error:NULL];
    });
    NSMutableString *mutableString = [self mutableCopy];
    NSArray *matches = [regex matchesInString:mutableString options:0 range:NSMakeRange(0, [mutableString length])];
    for (NSTextCheckingResult *result in matches.reverseObjectEnumerator) {
        NSString *foundString = [mutableString substringWithRange:result.range];
        NSString *replacementString = escapingDictionary[foundString];
        if (replacementString) {
            [mutableString replaceCharactersInRange:result.range withString:replacementString];
        }
    }
    return [mutableString copy];
}

- (NSData *)UTF8EncodedData {
    return [self dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)md5String {
    const char *cStr = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", result[i]];
    }
    return [output copy];
}

- (NSString *)sha1String {
    const char *cStr = [self UTF8String];
    unsigned char result[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(cStr, (CC_LONG)strlen(cStr), result);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", result[i]];
    }
    return [output copy];
}

@end

@implementation NSData (STKit)

+ (NSData *)dataWithBase64EncodedString:(NSString *)base64String {
    if ([self instancesRespondToSelector:@selector(initWithBase64EncodedString:options:)]) {
        return [[self alloc] initWithBase64EncodedString:base64String options:NSDataBase64DecodingIgnoreUnknownCharacters];
    }
    return [[self alloc] initWithBase64Encoding:base64String];
}

- (NSString *)base64String {
    if ([self respondsToSelector:@selector(base64EncodedStringWithOptions:)]) {
        return [self base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    }
    return [self base64Encoding];
}

- (NSString *)UTF8String {
    return [[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding];
}

@end

@implementation NSString (STPagination)

- (NSString *)reverseString {
    NSInteger length = self.length;
    unichar *reverseChars = (unichar *)malloc(sizeof(unichar) * length);
    for (NSInteger i = 0, j = length - 1; i < length; i++, j--) {
        reverseChars[i] = [self characterAtIndex:j];
    }
    NSString *resultStr = [NSString stringWithCharacters:reverseChars length:length];
    free(reverseChars);
    return resultStr;
}

- (NSString *)substringWithSeekOffset:(NSUInteger)_offset
                    constrainedToSize:(CGSize)size
                            direction:(STBookSeekDirection)direction
                           attributes:(NSDictionary *)attributes {

    NSUInteger offset = _offset;
    if (offset > self.length) {
        offset = self.length;
    }
    CGRect rect = CGRectZero;
    rect.size = size;
    // 一页最多显示 500个字
    static NSInteger maxPageSize = 500;
    NSString *childString;
    if (direction == STBookSeekDirectionForward) {
        NSRange range = NSMakeRange(offset, MIN(maxPageSize, self.length - offset));
        childString = [self substringWithRange:range];
    } else {
        NSInteger length = MIN(500, offset);
        NSRange range = NSMakeRange(offset - length, length);
        childString = [[self substringWithRange:range] reverseString];
    }

    UIBezierPath *path = [UIBezierPath bezierPathWithRect:rect];
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:childString attributes:attributes];
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attributedString);
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path.CGPath, NULL);
    CFRange range = CTFrameGetVisibleStringRange(frame);
    NSString *pagedString;
    if (range.length > 0 && range.length <= childString.length) {
        pagedString = [childString substringToIndex:range.length];
    }
    CFRelease(frame);
    CFRelease(framesetter);

    return direction == STBookSeekDirectionForward ? pagedString : [pagedString reverseString];
}

/**
 * @abstract 根据指定的大小,对字符串进行分页,计算出每页显示的字符串区间(NSRange)
 *
 * @param    attributes
 *分页所需的字符串样式,需要指定字体大小,行间距等。iOS6.0以上请参见UIKit中NSAttributedString的扩展,iOS6.0以下请参考CoreText中的CTStringAttributes.h
 * @param    size        需要参考的size。即在size区域内
 */
- (NSArray *)paginationWithAttributes:(NSDictionary *)attributes constrainedToSize:(CGSize)size {
    NSMutableArray *resultRange = [NSMutableArray arrayWithCapacity:5];
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    // 构造NSAttributedString
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:self attributes:attributes];
    //    以下方法耗时 基本再 0.5s 以内
    //    NSDate * date = [NSDate date];
    NSInteger rangeIndex = 0;
    do {
        NSInteger length = MIN(500, attributedString.length - rangeIndex);
        NSAttributedString *childString = [attributedString attributedSubstringFromRange:NSMakeRange(rangeIndex, length)];
        CTFramesetterRef childFramesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)childString);
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRect:rect];
        CTFrameRef frame = CTFramesetterCreateFrame(childFramesetter, CFRangeMake(0, 0), bezierPath.CGPath, NULL);
        CFRange range = CTFrameGetVisibleStringRange(frame);
        NSRange r = {rangeIndex, range.length};
        if (r.length > 0) {
            [resultRange addObject:NSStringFromRange(r)];
        }
        rangeIndex += r.length;
        CFRelease(frame);
        CFRelease(childFramesetter);
    } while (rangeIndex < attributedString.length && attributedString.length > 0);
    //    NSTimeInterval millionSecond = [[NSDate date] timeIntervalSinceDate:date];
    //    // NSLog(@"耗时 %lf", millionSecond);
    return resultRange;
}

@end

@implementation NSString (STDrawSize)

- (CGFloat)heightWithFont:(UIFont *)font constrainedToWidth:(CGFloat)width {
    if (self.length == 0 || !font) {
        return 0;
    }
    if ([self respondsToSelector:@selector(sizeWithFont:constrainedToSize:lineBreakMode:)]) {
        return [self sizeWithFont:font constrainedToSize:CGSizeMake(width, 999999999.0f) lineBreakMode:NSLineBreakByWordWrapping].height;
    }
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    return [self boundingRectWithSize:CGSizeMake(width, 9999999999.0f)
                              options:NSStringDrawingUsesLineFragmentOrigin
                           attributes:@{
                               NSFontAttributeName : font,
                               NSParagraphStyleAttributeName : paragraphStyle
                           } context:nil].size.height;
}

@end

#pragma mark - NSNotificationOnMainThread
@implementation NSNotificationCenter (STPostOnMainThread)

- (void)postNotificationOnMainThread:(NSNotification *)notification {
    if ([NSThread isMainThread]) {
        [self postNotification:notification];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{ [self postNotification:notification]; });
    }
}
- (void)postNotificationOnMainThreadWithName:(NSString *)aName object:(id)anObject {
    if ([NSThread isMainThread]) {
        [self postNotificationName:aName object:anObject];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{ [self postNotificationName:aName object:anObject]; });
    }
}

- (void)postNotificationOnMainThreadWithName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo {
    if ([NSThread isMainThread]) {
        [self postNotificationName:aName object:anObject userInfo:aUserInfo];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{ [self postNotificationName:aName object:anObject userInfo:aUserInfo]; });
    }
}

@end

@interface _STTimerWrapper : NSObject

@property (nonatomic, strong)STTimerFiredHandler   firedHandler;

@end

@implementation _STTimerWrapper

- (instancetype)initWithTimerFiredHandler:(STTimerFiredHandler)firedHandler {
    self = [super init];
    if (self) {
        self.firedHandler = firedHandler;
    }
    return self;
}

- (void)timerActionFired:(NSTimer *)timer {
    if (!self.firedHandler) {
        [timer invalidate];
    }
    BOOL invalidate = NO;
    if (self.firedHandler) {
        self.firedHandler(timer, &invalidate);
        if (invalidate) {
            [timer invalidate];
        }
    }
}

@end

@implementation NSTimer (STBlock)


+ (NSTimer *)timerWithTimeInterval:(NSTimeInterval)timeInterval firedHandler:(STTimerFiredHandler)handler {
    if (!handler) {
        return nil;
    }
    _STTimerWrapper *timerWrapper = [[_STTimerWrapper alloc] initWithTimerFiredHandler:handler];
    return [NSTimer timerWithTimeInterval:timeInterval target:timerWrapper selector:@selector(timerActionFired:) userInfo:nil repeats:YES];
}

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)timeInterval firedHandler:(STTimerFiredHandler)handler {
    if (!handler) {
        return nil;
    }
    _STTimerWrapper *timerWrapper = [[_STTimerWrapper alloc] initWithTimerFiredHandler:handler];
    return [NSTimer scheduledTimerWithTimeInterval:timeInterval target:timerWrapper selector:@selector(timerActionFired:) userInfo:nil repeats:YES];
}

- (instancetype)initWithFireDate:(NSDate *)date interval:(NSTimeInterval)interval  firedHandler:(STTimerFiredHandler)handler {
    if (!handler) {
        return nil;
    }
    _STTimerWrapper *timerWrapper = [[_STTimerWrapper alloc] initWithTimerFiredHandler:handler];
    return [self initWithFireDate:date interval:interval target:timerWrapper selector:@selector(timerActionFired:) userInfo:nil repeats:YES];
}

@end

#pragma mark - NSDateComponents

@implementation NSDate (STKit)

- (NSUInteger)calendarUnits {
    return NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute |
           NSCalendarUnitSecond;
}

- (NSDateComponents *)components {
    return [NSCalendar.autoupdatingCurrentCalendar components:self.calendarUnits fromDate:self];
}

- (NSInteger)year {
    return self.components.year;
}

- (NSInteger)month {
    return self.components.month;
}

- (NSInteger)day {
    return self.components.day;
}

- (NSInteger)hour {
    return self.components.hour;
}

- (NSInteger)minute {
    return self.components.minute;
}

- (NSInteger)second {
    return self.components.second;
}

+ (NSDate *)dateWithMSTimeIntervalSince1970:(NSTimeInterval)millisecond {
    return [NSDate dateWithTimeIntervalSince1970:millisecond * 0.001];
}

+ (NSString *)dateWithMSTimeIntervalSince1970:(NSTimeInterval)millisecond format:(NSString *)format {
    NSDate *date = [self dateWithMSTimeIntervalSince1970:millisecond];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = format;
    return [formatter stringFromDate:date];
}

@end

#pragma mark - STJSON

@implementation NSData (STKitJSON)

- (id)JSONValue {
    return [NSJSONSerialization JSONObjectWithData:self options:NSJSONReadingAllowFragments error:nil];
}

@end

@implementation NSString (STKitJSON)

- (id)JSONValue {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] JSONValue];
}

@end

@implementation NSDictionary (STKitJSON)

+ (id)dictionaryWithJSONString:(NSString *)JSONString {
    NSData *JSONData = [JSONString dataUsingEncoding:NSUTF8StringEncoding];
    return [self dictionaryWithJSONData:JSONData];
}

+ (id)dictionaryWithJSONData:(NSData *)JSONData {
    id JSONObject = [NSJSONSerialization JSONObjectWithData:JSONData options:NSJSONReadingAllowFragments error:nil];
    if ([JSONObject isKindOfClass:[NSDictionary class]]) {
        return JSONObject;
    }
    return nil;
}

- (NSString *)JSONString {
    NSError *error;
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:&error];
    if (error || JSONData.length == 0) {
        return nil;
    }
    return [[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding];
}

@end

@implementation NSArray (STKitJSON)

+ (id)arrayWithJSONString:(NSString *)JSONString {
    NSData *JSONData = [JSONString dataUsingEncoding:NSUTF8StringEncoding];
    return [self arrayWithJSONData:JSONData];
}

+ (id)arrayWithJSONData:(NSData *)JSONData {
    id JSONObject = [NSJSONSerialization JSONObjectWithData:JSONData options:NSJSONReadingAllowFragments error:nil];
    if ([JSONObject isKindOfClass:[NSArray class]]) {
        return JSONObject;
    }
    return nil;
}

- (NSString *)JSONString {
    NSError *error;
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:&error];
    if (error || JSONData.length == 0) {
        return nil;
    }
    return [[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding];
}

@end

#pragma mark - STSecureAccessor

@implementation NSArray (STSecure)

+ (void)load {
    Class inmutableClass = NSClassFromString(@"__NSArrayI") ? NSClassFromString(@"__NSArrayI") : [[NSArray array] class];

    method_exchangeImplementations(class_getInstanceMethod(inmutableClass, @selector(objectAtIndex:)),
                                   class_getInstanceMethod(inmutableClass, @selector(secureObjectAtIndex:)));
}

- (id)secureObjectAtIndex:(NSUInteger)index {
    if (index >= self.count) {
        return nil;
    }
    return [self secureObjectAtIndex:index];
}

@end

@implementation NSArray (STClass)

- (BOOL)containsClass:(Class)class {
    __block BOOL contains = NO;
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:class]) {
            contains = YES;
            *stop = YES;
        }
    }];
    return contains;
}

- (NSUInteger)indexOfClass:(Class)class {
    __block NSUInteger index = NSNotFound;
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:class]) {
            index = idx;
            *stop = YES;
        }
    }];
    return index;
}

- (NSUInteger)firstIndexOfClass:(Class)class {
    return [self indexOfClass:class];
}

- (NSUInteger)lastIndexOfClass:(Class)class {
    __block NSUInteger index = NSNotFound;
    [self enumerateObjectsWithOptions:NSEnumerationReverse
                           usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                               if ([obj isKindOfClass:class]) {
                                   index = idx;
                                   *stop = YES;
                               }
                           }];
    return index;
}

- (id)firstObjectOfClass:(Class)class {
    NSUInteger idx = [self firstIndexOfClass:class];
    if (idx == NSNotFound) {
        return nil;
    }
    return self[idx];
}

- (id)lastObjectOfClass:(Class)class {
    NSUInteger idx = [self lastIndexOfClass:class];
    if (idx == NSNotFound) {
        return nil;
    }
    return self[idx];
}

@end

@implementation NSDictionary (STURLQuery)

- (NSString *)st_compontentsJoinedByConnector:(NSString *)connector
                                    separator:(NSString *)separator {
    NSMutableString *mutableString = [NSMutableString string];
    [self enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            [mutableString appendFormat:@"%@%@%@%@", [key st_stringByURLEncoded], connector, [obj st_stringByURLEncoded], separator];
        } else {
            [mutableString appendFormat:@"%@%@%@%@", [key st_stringByURLEncoded], connector, obj, separator];
        }
    }];
    if (mutableString.length > 0 && separator.length > 0) {
        [mutableString deleteCharactersInRange:NSMakeRange(mutableString.length - separator.length, separator.length)];
    }
    return [mutableString copy];
}
/// URL
- (NSString *)st_compontentsJoinedUsingURLStyle {
    NSMutableString *mutableString = [NSMutableString string];
    [self enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            [mutableString appendFormat:@"%@=%@&", [key st_stringByURLEncoded], [obj st_stringByURLEncoded]];
        } else {
            [mutableString appendFormat:@"%@=%@&", [key st_stringByURLEncoded], obj];
        }
    }];
    if (mutableString.length > 0) {
        [mutableString deleteCharactersInRange:NSMakeRange(mutableString.length - 1, 1)];
    }
    return [mutableString copy];
}

@end

@implementation NSString (STNetwork)

- (NSString *)st_stringByURLEncoded { //
    CFStringRef encodedCFString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)self, nil,
                                                                          CFSTR("?!@#$^&%*+,:;='\"`<>()[]{}/\\| "), kCFStringEncodingUTF8);
    NSString *resultString = [NSString stringWithString:(__bridge NSString *)(encodedCFString)];
    CFRelease(encodedCFString);
    return resultString;
}

- (NSString *)st_stringByURLDecoded {
    CFStringRef decodedCFString =
    CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (__bridge CFStringRef)self, CFSTR(""), kCFStringEncodingUTF8);
    NSString *resultString = [NSString stringWithString:(__bridge NSString *)(decodedCFString)];
    CFRelease(decodedCFString);
    return resultString;
}

@end

NSString *STKitGetVersion(void) {
    return @"1.1";
}