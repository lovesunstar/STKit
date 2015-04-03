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
#endif
