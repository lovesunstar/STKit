//
//  STNetworkConfiguration.m
//  STKit
//
//  Created by SunJiangting on 14-10-18.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STNetworkConfiguration.h"
#import "Foundation+STKit.h"

@implementation STCertificateItem

+ (instancetype) certificateItemWithFilePath:(NSString *) filePath {
    if (filePath.length == 0) {
        return nil;
    }
    STCertificateItem * item = [[[self class] alloc] init];
    item.filePath = filePath;
    return item;
}

+ (instancetype) certificateItemWithBase64String:(NSString *) base64String {
    if (base64String.length == 0) {
        return nil;
    }
    STCertificateItem * item = [[[self class] alloc] init];
    item.base64String = base64String;
    return item;
}

+ (instancetype) certificateItemWithData:(NSData *) data {
    if (data.length == 0) {
        return nil;
    }
    STCertificateItem * item = [[[self class] alloc] init];
    item.data = data;
    return item;
}

@end

@implementation STNetworkConfiguration {
    NSArray *_privateCertificates;
}

static STNetworkConfiguration * _sharedConfiguration;
+ (instancetype)sharedConfiguration {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedConfiguration = [[self alloc] init];
    });
    return _sharedConfiguration;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.allowsAnyHTTPSCertificate = YES;
        self.SSLPinningMode = STSSLPinningModeNone;
        self.HTTPConfiguration = [STHTTPConfiguration defaultConfiguration];
    }
    return self;
}

- (void)setCertificates:(NSArray *)certificates {
    if (_privateCertificates != certificates) {
        _privateCertificates = certificates;
        NSMutableArray * array = [NSMutableArray arrayWithCapacity:certificates.count];
        [certificates enumerateObjectsUsingBlock:^(STCertificateItem * obj, NSUInteger idx, BOOL *stop) {
            NSData * data;
            if (obj.data) {
                data = data;
            } else if (obj.base64String.length > 0) {
                data = [NSData dataWithBase64EncodedString:obj.base64String];
            } else if (obj.filePath.length > 0) {
                data =[NSData dataWithContentsOfFile:obj.filePath];
            }
            if (data) {
                [array addObject:data];   
            }
        }];
        _certificates = [array copy];
    }
}

- (NSArray *)publicKeys {
    if (!_publicKeys) {
        if (self.certificates.count == 0) {
            return nil;
        }
        NSMutableArray * array = [NSMutableArray arrayWithCapacity:self.certificates.count];
        [self.certificates enumerateObjectsUsingBlock:^(NSData * data, NSUInteger idx, BOOL *stop) {
            SecKeyRef publicKey = STSecPublicKeyFromDERData(data);
            if (publicKey) {
                [array addObject:(__bridge id)(publicKey)];
            }
        }];
        _publicKeys = [array copy];
    }
    return _publicKeys;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    STNetworkConfiguration *configuration = [[[self class] allocWithZone:zone] init];
    configuration.allowsAnyHTTPSCertificate = self.allowsAnyHTTPSCertificate;
    configuration.SSLPinningMode = self.SSLPinningMode;
    configuration.publicKeys = self.publicKeys;
    configuration.certificates = self.certificates;
    configuration.HTTPBasicCredential = [self.HTTPBasicCredential copy];
    configuration.clientCertificateCredential = [self.clientCertificateCredential copy];
    return configuration;
}
@end
