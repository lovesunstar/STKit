//
//  NSData+STGZip.h
//  STKit
//
//  Created by SunJiangting on 15-3-26.
//  Copyright (c) 2015年 SunJiangting. All rights reserved.
//

#import <Foundation/Foundation.h>

// 需要引入 zib
#define STKit_STDefines_GZip 1
#if STKit_STDefines_GZip
#import <zlib.h>
@interface NSData (STGZip)

- (NSData *)st_gzipCompressedDataWithError:(NSError * __autoreleasing *)error;

- (NSData *)st_gzipDecompressedDataWithError:(NSError * __autoreleasing *)error;

@end

extern NSInteger const STGZipChunkSize;
extern NSInteger const STGZipDefaultMemoryLevel;
extern NSInteger const STGZipDefaultWindowBits;

extern NSString *const STGZipErrorDomain;
#endif
