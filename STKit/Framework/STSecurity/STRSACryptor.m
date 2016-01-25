//
//  STRSACryptor.m
//  STKit
//
//  Created by SunJiangting on 14-9-19.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STRSACryptor.h"
#import "Foundation+STKit.h"
#import <CommonCrypto/CommonDigest.h>

extern NSData *_STExtractKeyContentFromPEMString(NSString *string);
extern SecKeyRef _STExtractSecKeyFromPEMData(NSData *data, BOOL privateKey);

extern OSStatus _STExtractIdentityAndTrust(CFDataRef inPKCS12Data,
                                           SecIdentityRef *outIdentity,
                                           SecTrustRef *outTrust,
                                           CFStringRef password);

extern SecKeyRef _STSecPublicKeyFromDERData(NSData *data);

extern NSData *_STStripPublicKeyHeaderWithData(NSData *data);

extern SecKeyRef STSecPrivateKeyFromPEMData(NSData *data) {
    return _STExtractSecKeyFromPEMData(data, YES);
}

extern SecKeyRef STSecPrivateKeyFromPEMBase64String(NSString *base64String) {
    NSData *data = _STExtractKeyContentFromPEMString(base64String);
    return STSecPrivateKeyFromPEMData(data);
}

SecKeyRef STSecPrivateKeyFromP12Data(NSData *data, NSString *password) {
    if (password.length == 0) {
        return nil;
    }
    CFDataRef PKCS12Data = (__bridge CFDataRef)data;
    CFStringRef passwordRef = (__bridge CFStringRef)password;
    
    SecIdentityRef identity = NULL;
    SecTrustRef trust = NULL;
    SecTrustResultType trustResult;
    SecKeyRef privateKey = NULL;
    
    OSStatus status =
    _STExtractIdentityAndTrust(PKCS12Data, &identity, &trust, passwordRef);
    if (status == noErr &&
        (status = SecTrustEvaluate(trust, &trustResult)) == noErr) {
        SecIdentityCopyPrivateKey(identity, &privateKey);
    }
    if (privateKey) {
        CFAutorelease(privateKey);
    }
    return privateKey;
}

extern BOOL STSecKeyEqualToSecKey(SecKeyRef key1, SecKeyRef key2) {
    return [(__bridge id)key1 isEqual:(__bridge id)key2];
}

extern SecKeyRef STSecPublicKeyFromDERData(NSData *data) {
    return _STSecPublicKeyFromDERData(data);
}

extern SecKeyRef STSecPublicKeyFromDERBase64String(NSString *base64String) {
    NSData *data = [NSData st_dataWithBase64EncodedString:base64String];
    return STSecPublicKeyFromDERData(data);
}

extern SecKeyRef STSecPublicKeyFromPEMData(NSData *data) {
    return _STExtractSecKeyFromPEMData(data, NO);
}

extern SecKeyRef STSecPublicKeyFromPEMBase64String(NSString *base64String) {
    NSData *data = _STExtractKeyContentFromPEMString(base64String);
    return STSecPublicKeyFromPEMData(data);
}

@interface STRSACryptor () {
@private
    SecKeyRef _publicKeyRef;
    SecKeyRef _privateKeyRef;
}

@end

@implementation STRSACryptor

- (void)dealloc {
    if (_publicKeyRef) {
        CFRelease(_publicKeyRef);
    }
    if (_privateKeyRef) {
        CFRelease(_privateKeyRef);
    }
}

- (instancetype)initWithPublicSecKey:(SecKeyRef)publicSecKey
                       privateSecKey:(SecKeyRef)privateSecKey {
    self = [super init];
    if (self) {
        _padding = kSecPaddingPKCS1;
        _publicKeyRef = (SecKeyRef)CFRetain(publicSecKey);
        _privateKeyRef = (SecKeyRef)CFRetain(privateSecKey);
    }
    return self;
}

- (NSData *)signData:(NSData *)data {
    return [self _signData:data usingSecKey:_privateKeyRef];
}

- (BOOL)verifySignature:(NSData *)signature signedData:(NSData *)signedData {
    return [self _verifySignature:signature
                      usingSecKey:_publicKeyRef
                       signedData:signedData];
}

- (NSData *)encryptData:(NSData *)data {
    return [self _encryptData:data usingKey:_publicKeyRef];
}

- (NSData *)decryptData:(NSData *)data {
    return [self _decryptData:data usingKey:_privateKeyRef];
}

- (NSData *)decryptDataUsingPublicKey:(NSData *)data {
    return [self _decryptData:data usingKey:_publicKeyRef];
}

- (NSData *)encryptDataUsingPrivateKey:(NSData *)data {
    return [self _encryptData:data usingKey:_privateKeyRef];
}

#pragma mark - Private Method
- (NSData *)_signData:(NSData *)data usingSecKey:(SecKeyRef)privateKey {
    if (data.length == 0 || !privateKey) {
        return nil;
    }
    uint8_t *signedHashBytes = NULL;
    size_t signedHashBytesSize = SecKeyGetBlockSize(privateKey);
    // Malloc a buffer to hold signature.
    signedHashBytes = malloc(signedHashBytesSize * sizeof(uint8_t));
    memset((void *)signedHashBytes, 0x0, signedHashBytesSize);
    
    uint8_t result[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (CC_LONG)data.length, result);
    // Sign the SHA1 hash.
    OSStatus status = SecKeyRawSign(
                                    privateKey, kSecPaddingPKCS1SHA1, result, CC_SHA1_DIGEST_LENGTH,
                                    (uint8_t *)signedHashBytes, &signedHashBytesSize);
    NSData *signature = [NSData dataWithBytes:(const void *)signedHashBytes
                                       length:(NSUInteger)signedHashBytesSize];
    if (status != noErr) {
        STLog(@"======= RSA签名失败");
    }
    if (signedHashBytes) {
        free(signedHashBytes);
    }
    return signature;
}

- (BOOL)_verifySignature:(NSData *)signature
             usingSecKey:(SecKeyRef)publicKey
              signedData:(NSData *)signedData {
    if (signedData.length == 0 || signature.length == 0 || !publicKey) {
        return NO;
    }
    uint8_t result[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(signedData.bytes, (CC_LONG)signedData.length, result);
    OSStatus status = SecKeyRawVerify(publicKey, kSecPaddingPKCS1SHA1, result,
                                      CC_SHA1_DIGEST_LENGTH, signature.bytes,
                                      SecKeyGetBlockSize(publicKey));
    return (status == noErr);
}

- (NSData *)_encryptData:(NSData *)data usingKey:(SecKeyRef)key {
    if (!key || data.length == 0) {
        return nil;
    }
    size_t keyBlockSize = SecKeyGetBlockSize(key);
    size_t blockSize = keyBlockSize - 11;
    size_t blockCount = (size_t)ceil(data.length / (double)blockSize);
    
    NSMutableData *encryptedData = [NSMutableData dataWithCapacity:0];
    for (int i = 0; i < blockCount; i++) {
        NSInteger bufferSize = MIN(blockSize, data.length - i * blockSize);
        NSData *component =
        [data subdataWithRange:NSMakeRange(i * blockSize, bufferSize)];
        NSMutableData *data =
        [[NSMutableData alloc] initWithLength:SecKeyGetBlockSize(key)];
        size_t length = SecKeyGetBlockSize(key);
        OSStatus status =
        SecKeyEncrypt(key, kSecPaddingPKCS1, component.bytes, component.length,
                      data.mutableBytes, &length);
        if (status == noErr) {
            data.length = length;
            [encryptedData appendData:data];
        } else {
            return nil;
        }
    }
    return [encryptedData copy];
}

- (NSData *)_decryptData:(NSData *)data usingKey:(SecKeyRef)key {
    if (data.length == 0 || !key) {
        return nil;
    }
    size_t cipherBufferSize = SecKeyGetBlockSize(key);
    size_t keyBufferSize = data.length;
    NSMutableData *result = [NSMutableData dataWithLength:keyBufferSize];
    OSStatus sanityCheck =
    SecKeyDecrypt(key, kSecPaddingPKCS1, (const uint8_t *)data.bytes,
                  cipherBufferSize, [result mutableBytes], &keyBufferSize);
    if (sanityCheck != noErr) {
        return nil;
    }
    result.length = keyBufferSize;
    return [result copy];
}

@end

#pragma mark - MethodImplementions
SecKeyRef _STExtractSecKeyFromPEMData(NSData *data, BOOL privateKey) {
    if (data.length == 0) {
        return nil;
    }
    if (!privateKey) {
        data = _STStripPublicKeyHeaderWithData(data);
    }
    NSData *tagData = [STSecAttrApplicationTag st_UTF8EncodedData];
    // Delete any old lingering key with the same tag
    NSMutableDictionary *query = [@{
                                    (__bridge id)kSecClass : (__bridge id)kSecClassKey, (__bridge id)
                                    kSecAttrKeyType : (__bridge id)kSecAttrKeyTypeRSA
                                    } mutableCopy];
    
    [query setObject:tagData forKey:(__bridge id)kSecAttrApplicationTag];
    SecItemDelete((__bridge CFDictionaryRef)query);
    
    CFTypeRef persistKey = nil;
    // Add persistent version of the key to system keychain
    [query setValue:data forKey:(__bridge id)kSecValueData];
    [query setValue:(__bridge id)(privateKey ? kSecAttrKeyClassPrivate
                                  : kSecAttrKeyClassPublic)
             forKey:(__bridge id)kSecAttrKeyClass];
    [query setValue:@(YES) forKey:(__bridge id)kSecReturnPersistentRef];
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)query, &persistKey);
    if (persistKey) {
        CFRelease(persistKey);
    }
    if ((status != noErr) && (status != errSecDuplicateItem)) {
        return nil;
    }
    [query removeObjectsForKeys:@[
                                  (__bridge id)kSecValueData,
                                  (__bridge id)kSecReturnPersistentRef
                                  ]];
    [query setValue:@(YES) forKey:(__bridge id)kSecReturnRef];
    [query setValue:(__bridge id)kSecAttrKeyTypeRSA
             forKey:(__bridge id)kSecAttrKeyType];
    SecKeyRef secKeyRef = NULL;
    SecItemCopyMatching((__bridge CFDictionaryRef)query,
                                 (CFTypeRef *)&secKeyRef);
    if (secKeyRef) {
        CFAutorelease(secKeyRef);
    }
    return secKeyRef;
}

#pragma mark - PrivateKeyImplemention
extern OSStatus _STExtractIdentityAndTrust(CFDataRef inPKCS12Data,
                                           SecIdentityRef *outIdentity,
                                           SecTrustRef *outTrust,
                                           CFStringRef password) {
    
    NSMutableDictionary *options = [NSMutableDictionary dictionaryWithCapacity:2];
    [options setValue:(__bridge id)(password)
               forKey:(__bridge id)kSecImportExportPassphrase];
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    OSStatus status =
    SecPKCS12Import(inPKCS12Data, (__bridge CFDictionaryRef)options, &items);
    if (status == noErr) {
        CFDictionaryRef identityAndTrust = CFArrayGetValueAtIndex(items, 0);
        const void *tempIdentity = NULL;
        tempIdentity =
        CFDictionaryGetValue(identityAndTrust, kSecImportItemIdentity);
        *outIdentity = (SecIdentityRef)tempIdentity;
        const void *tempTrust =
        CFDictionaryGetValue(identityAndTrust, kSecImportItemTrust);
        *outTrust = (SecTrustRef)tempTrust;
    }
    return status;
}

#pragma mark - PublicKeyImplemention
SecKeyRef _STSecPublicKeyFromDERData(NSData *data) {
    if (!data) {
        return nil;
    }
    SecCertificateRef secCertificateRef = SecCertificateCreateWithData(kCFAllocatorDefault, (__bridge CFDataRef)data);
    if (!secCertificateRef) {
        return nil;
    }
    SecPolicyRef secPolicyRef = SecPolicyCreateBasicX509();
    SecTrustRef secTrustRef = NULL;
    OSStatus status = SecTrustCreateWithCertificates(secCertificateRef,
                                                     secPolicyRef, &secTrustRef);
    SecTrustResultType trustResultType = 0;
    if (status == noErr) {
        SecTrustEvaluate(secTrustRef, &trustResultType);
    }
    SecKeyRef secKeyRef = SecTrustCopyPublicKey(secTrustRef);
    CFRelease(secCertificateRef);
    if (secPolicyRef) {
        CFRelease(secPolicyRef);
    }
    if (secTrustRef) {
        CFRelease(secTrustRef);
    }
    CFAutorelease(secKeyRef);
    return secKeyRef;
}

NSData *_STExtractKeyContentFromPEMString(NSString *string) {
    NSArray *components = [string componentsSeparatedByString:@"-----"];
    __block NSString *content = nil;
    // 获取最长的字符串，就是内容
    [components
     enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
         if (obj.length > content.length) {
             content = obj;
         }
     }];
    NSString *base64String =
    [content stringByTrimmingCharactersInSet:
     [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [NSData st_dataWithBase64EncodedString:base64String];
}

NSData *_STStripPublicKeyHeaderWithData(NSData *data) {
    if (data.length == 0) {
        return nil;
    }
    unsigned char *bytes = (unsigned char *)data.bytes;
    unsigned int index = 0;
    if (bytes[index++] != 0x30) {
        return nil;
    }
    if (bytes[index] > 0x80) {
        index += bytes[index] - 0x80 + 1;
    } else {
        index++;
    }
    // PKCS #1 rsaEncryption szOID_RSA_RSA
    static unsigned char seqiod[] = {0x30, 0x0d, 0x06, 0x09, 0x2a,
        0x86, 0x48, 0x86, 0xf7, 0x0d,
        0x01, 0x01, 0x01, 0x05, 0x00};
    if (memcmp(&bytes[index], seqiod, 15)) {
        return nil;
    }
    index += 15;
    if (bytes[index++] != 0x03) {
        return nil;
    }
    if (bytes[index] > 0x80) {
        index += bytes[index] - 0x80 + 1;
    } else {
        index++;
    }
    if (bytes[index++] != '\0') {
        return nil;
    }
    return [NSData dataWithBytes:&bytes[index] length:data.length - index];
}

NSString *const STSecAttrApplicationTag = @"STSecAttrApplicationTag";