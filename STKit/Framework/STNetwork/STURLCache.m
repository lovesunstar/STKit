//
//  STURLCache.m
//  STKit
//
//  Created by SunJiangting on 15-4-20.
//  Copyright (c) 2015年 SunJiangting. All rights reserved.
//

#import "STURLCache.h"
#import <STKit/Foundation+STKit.h>
#import <STKit/UIKit+STKit.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface NSURLRequest (STCachedURLRequest)

- (NSURLRequest *)st_cachableRequestIngoreParameters:(NSArray *)ingoredParameters;
@end

@interface STURLCache ()

@end

@implementation STURLCache

- (void)storeCachedResponse:(NSCachedURLResponse *)cachedResponse forRequest:(NSURLRequest *)request {
    NSURLRequest *adapterRequest = request;
    if ([self _needRequestAdaptor] && cachedResponse.storagePolicy == NSURLCacheStorageAllowed) {
        adapterRequest = [adapterRequest st_cachableRequestIngoreParameters:nil];
    }
    [super storeCachedResponse:cachedResponse forRequest:adapterRequest];
}

- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request {
    NSCachedURLResponse *cachedResponse = [super cachedResponseForRequest:request];
    if (!cachedResponse && [self _needRequestAdaptor]) {
        cachedResponse = [super cachedResponseForRequest:[request st_cachableRequestIngoreParameters:nil]];
    }
    return cachedResponse;
}

- (BOOL)_needRequestAdaptor {
    if (STGetSystemVersion() > 8.1) {
        return YES;
    }
    return NO;
}
@end


@implementation NSURLRequest (STCachedURLRequest)

- (NSURLRequest *)st_cachableRequestIngoreParameters:(NSArray *)ingoredParameters {
    NSURL *URL = self.URL;
    NSString *absoluteString = URL.absoluteString;
    NSRange range = [absoluteString rangeOfString:@"?"];
    if (!URL || [self.HTTPMethod isEqualToString:@"POST"] || (range.location == NSNotFound)) {
        return self;
    }
    absoluteString = [absoluteString substringToIndex:range.location];
    NSString *query = URL.query;
    NSMutableDictionary *params = [NSMutableDictionary st_dictionaryWithURLQuery:query];
    [params removeObjectsForKeys:ingoredParameters];
    NSString *sortedQuery = [self _keySortedURLQueryStringWithParameters:params sortSelector:@selector(caseInsensitiveCompare:)];
    if (![absoluteString hasSuffix:@"/"]) {
        absoluteString = [absoluteString stringByAppendingString:@"/"];
    }
    absoluteString = [absoluteString stringByAppendingFormat:@"%@/", sortedQuery.st_md5String];
    URL = [NSURL URLWithString:absoluteString];
    NSMutableURLRequest *request = [self mutableCopy];
    request.URL = URL;
    return request;
}

- (NSString *)_keySortedURLQueryStringWithParameters:(NSDictionary *)parameters sortSelector:(SEL)sortSelector {
    if (!sortSelector || ![NSString instancesRespondToSelector:sortSelector]) {
        sortSelector = @selector(caseInsensitiveCompare:);
    }
    NSArray *keys = [parameters.allKeys sortedArrayUsingSelector:sortSelector];
    NSMutableString *sortedQuery = [NSMutableString stringWithCapacity:20];
    [keys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        id obj = parameters[key];
        if ([obj isKindOfClass:[NSString class]]) {
            [sortedQuery appendFormat:@"%@=%@&", [key st_stringByURLEncoded], [obj st_stringByURLEncoded]];
        } else {
            [sortedQuery appendFormat:@"%@=%@&", [key st_stringByURLEncoded], obj];
        }
    }];
    if (sortedQuery.length > 0) {
        [sortedQuery deleteCharactersInRange:NSMakeRange(sortedQuery.length - 1, 1)];
    }
    return sortedQuery;
}

@end