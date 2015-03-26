//
//  STAESCryptor.m
//  STKit
//
//  Created by SunJiangting on 14-9-19.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STAESCryptor.h"

@interface STAESCryptor ()

@property(nonatomic, copy) NSString *key;
@property(nonatomic, copy) NSString *iv;
@property(nonatomic) STAESCryptorOptions options;

@end

@implementation STAESCryptor

- (instancetype)init {
    return [self initWithKey:nil];
}

- (instancetype)initWithKey:(NSString *)key {
    return [self initWithKey:key options:STAESCryptorOptionsKeySize128 | STAESCryptorOptionsPKCS7Padding | STAESCryptorOptionsCBCMode];
}

- (instancetype)initWithKey:(NSString *)key options:(STAESCryptorOptions)options {
    return [self initWithKey:key options:options iv:nil];
}

- (instancetype)initWithKey:(NSString *)key options:(STAESCryptorOptions)options iv:(NSString *)iv {
    self = [super init];
    if (self) {
        self.key = key;
        self.options = options;
        self.iv = iv;
    }
    return self;
}

- (NSData *)encryptData:(NSData *)data {
    return [self cryptData:data operation:kCCEncrypt];
}

- (NSData *)cryptData:(NSData *)data operation:(CCOperation)operation {
    CCOptions options = 0;
    if (self.options & STAESCryptorOptionsECBMode) {
        options |= kCCOptionECBMode;
    }
    BOOL PKCS7Padding = !(self.options & STAESCryptorOptionsNoPadding) && !(self.options & STAESCryptorOptionsZerosPadding);
    if (PKCS7Padding) {
        options |= kCCOptionPKCS7Padding;
    }

    NSUInteger keySize = kCCKeySizeAES128;
    if (self.options & STAESCryptorOptionsKeySize192) {
        keySize = kCCKeySizeAES192;
    } else if (self.options & STAESCryptorOptionsKeySize256) {
        keySize = kCCKeySizeAES256;
    }
    NSMutableData *keyData = [[self.key dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
    keyData.length = keySize;

    NSUInteger dataLength = data.length;
    if (operation == kCCEncrypt && self.options & STAESCryptorOptionsZerosPadding) {
        NSUInteger paddingSize = keySize - (dataLength % keySize);
        NSMutableData *cryptData = [data mutableCopy];
        cryptData.length = paddingSize + data.length;
        data = cryptData;
        dataLength = data.length;
    }
    NSMutableData *ivData = [[self.iv dataUsingEncoding:NSASCIIStringEncoding] mutableCopy];
    ivData.length = kCCBlockSizeAES128;
    
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);

    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(operation, kCCAlgorithmAES128, options, keyData.bytes, keySize, ivData.bytes, data.bytes, dataLength, buffer, bufferSize, &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    free(buffer);
    return nil;
}

- (NSData *)decryptData:(NSData *)data {
    return [self cryptData:data operation:kCCDecrypt];
}

@end

@implementation NSData (STAESCryptor)

- (NSData *)AES128EncryptedDataWithKey:(NSString *)key {
    return [self AESEncryptedDataWithKey:key options:STAESCryptorOptionsKeySize128 | STAESCryptorOptionsPKCS7Padding | STAESCryptorOptionsCBCMode];
}
- (NSData *)AES192EncryptedDataWithKey:(NSString *)key {
    return [self AESEncryptedDataWithKey:key options:STAESCryptorOptionsKeySize192 | STAESCryptorOptionsPKCS7Padding | STAESCryptorOptionsCBCMode];
}
- (NSData *)AES256EncryptedDataWithKey:(NSString *)key {
    return [self AESEncryptedDataWithKey:key options:STAESCryptorOptionsKeySize256 | STAESCryptorOptionsPKCS7Padding | STAESCryptorOptionsCBCMode];
}

- (NSData *)AESEncryptedDataWithKey:(NSString *)key options:(STAESCryptorOptions)options {
    STAESCryptor *AESCryptor = [[STAESCryptor alloc] initWithKey:key options:options];
    return [AESCryptor encryptData:self];
}

- (NSData *)decryptAES128DataWithKey:(NSString *)key {
    return [self decryptAESWithKey:key options:STAESCryptorOptionsKeySize128 | STAESCryptorOptionsPKCS7Padding | STAESCryptorOptionsCBCMode];
}

- (NSData *)decryptAES192DataWithKey:(NSString *)key {
    return [self decryptAESWithKey:key options:STAESCryptorOptionsKeySize192 | STAESCryptorOptionsPKCS7Padding | STAESCryptorOptionsCBCMode];
}

- (NSData *)decryptAES256DataWithKey:(NSString *)key {
    return [self decryptAESWithKey:key options:STAESCryptorOptionsKeySize256 | STAESCryptorOptionsPKCS7Padding | STAESCryptorOptionsCBCMode];
}

- (NSData *)decryptAESWithKey:(NSString *)key options:(STAESCryptorOptions)options {
    STAESCryptor *AESCryptor = [[STAESCryptor alloc] initWithKey:key options:options];
    return [AESCryptor decryptData:self];
}
@end
