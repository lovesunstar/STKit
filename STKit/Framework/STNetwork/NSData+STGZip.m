//
//  NSData+STGZip.m
//  STKit
//
//  Created by SunJiangting on 15-3-26.
//  Copyright (c) 2015年 SunJiangting. All rights reserved.
//

#import "NSData+STGZip.h"
#if STKit_STDefines_GZip
@implementation NSData (STGZip)

- (NSData *)st_gzipCompressedDataWithLevel:(NSInteger)compressLevel
                                windowSize:(NSInteger)windowBits
                               memoryLevel:(NSInteger)memLevel
                                  strategy:(NSInteger)strategy
                                     error:(NSError * __autoreleasing *)error {
    if ([self length] == 0) {
        return self;
    }
    
    z_stream zStream;
    bzero(&zStream, sizeof(z_stream));
    
    zStream.zalloc = Z_NULL;
    zStream.zfree = Z_NULL;
    zStream.opaque = Z_NULL;
    zStream.next_in = (Bytef *)[self bytes];
    zStream.avail_in = (unsigned int)[self length];
    zStream.total_out = 0;
    
    OSStatus status;
    if ((status = deflateInit2(&zStream, compressLevel, Z_DEFLATED, windowBits, memLevel, strategy)) != Z_OK) {
        if (error) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Failed deflateInit", nil) forKey:NSLocalizedDescriptionKey];
            *error = [[NSError alloc] initWithDomain:STGZipErrorDomain code:status userInfo:userInfo];
        }
        
        return nil;
    }
    
    NSMutableData *compressedData = [NSMutableData dataWithLength:STGZipChunkSize];
    
    do {
        if ((status == Z_BUF_ERROR) || (zStream.total_out == [compressedData length])) {
            [compressedData increaseLengthBy:STGZipChunkSize];
        }
        
        zStream.next_out = (Bytef*)[compressedData mutableBytes] + zStream.total_out;
        zStream.avail_out = (unsigned int)([compressedData length] - zStream.total_out);
        
        status = deflate(&zStream, Z_FINISH);
    } while ((status == Z_OK) || (status == Z_BUF_ERROR));
    
    deflateEnd(&zStream);
    
    if ((status != Z_OK) && (status != Z_STREAM_END)) {
        if (error) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Error deflating payload", nil) forKey:NSLocalizedDescriptionKey];
            *error = [[NSError alloc] initWithDomain:STGZipErrorDomain code:status userInfo:userInfo];
        }
        
        return nil;
    }
    
    [compressedData setLength:zStream.total_out];
    
    return compressedData;
}


- (NSData *)st_gzipCompressedDataWithError:(NSError * __autoreleasing *)error {
    NSInteger windowSize = 16 + STGZipDefaultWindowBits;
    return [self st_gzipCompressedDataWithLevel:Z_DEFAULT_COMPRESSION windowSize:windowSize memoryLevel:STGZipDefaultMemoryLevel strategy:Z_DEFAULT_STRATEGY error:error];
}


- (NSData *)st_gzipDecompressedDataWithError:(NSError * __autoreleasing *)error {
    NSInteger windowSize = 16 + STGZipDefaultWindowBits;
    return [self st_gzipDecompressedDataWithWindowSize:windowSize error:error];
}

- (NSData *)st_gzipDecompressedDataWithWindowSize:(NSInteger)windowBits
                                            error:(NSError * __autoreleasing *)error {
    if ([self length] == 0) {
        return self;
    }
    
    z_stream zStream;
    bzero(&zStream, sizeof(z_stream));
    
    zStream.zalloc = Z_NULL;
    zStream.zfree = Z_NULL;
    zStream.opaque = Z_NULL;
    zStream.avail_in = (unsigned int)[self length];
    zStream.next_in = (Byte *)[self bytes];
    
    OSStatus status;
    if ((status = inflateInit2(&zStream, windowBits)) != Z_OK) {
        if (error) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Failed inflateInit", nil) forKey:NSLocalizedDescriptionKey];
            *error = [[NSError alloc] initWithDomain:STGZipErrorDomain code:status userInfo:userInfo];
        }
        
        return nil;
    }
    
    NSUInteger estimatedLength = (NSUInteger)((double)[self length] * 1.5);
    NSMutableData *decompressedData = [NSMutableData dataWithLength:estimatedLength];
    
    do {
        if ((status == Z_BUF_ERROR) || (zStream.total_out == [decompressedData length])) {
            [decompressedData increaseLengthBy:estimatedLength / 2];
        }
        
        zStream.next_out = (Bytef*)[decompressedData mutableBytes] + zStream.total_out;
        zStream.avail_out = (unsigned int)([decompressedData length] - zStream.total_out);
        
        status = inflate(&zStream, Z_FINISH);
    } while ((status == Z_OK) || (status == Z_BUF_ERROR));
    
    inflateEnd(&zStream);
    
    if ((status != Z_OK) && (status != Z_STREAM_END)) {
        if (error) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Error inflating payload", nil) forKey:NSLocalizedDescriptionKey];
            *error = [[NSError alloc] initWithDomain:STGZipErrorDomain code:status userInfo:userInfo];
        }
        
        return nil;
    }
    
    [decompressedData setLength:zStream.total_out];
    
    return decompressedData;
}

@end

NSInteger const STGZipDefaultMemoryLevel = 8;
NSInteger const STGZipDefaultWindowBits = 15;
NSInteger const STGZipChunkSize = 1024;

NSString *const STGZipErrorDomain = @"com.suen.STGZip.Error";
#endif
