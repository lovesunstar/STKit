//
//  STAESTestCase.m
//  STKit
//
//  Created by SunJiangting on 14-10-19.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@interface STCryptorTestCase : XCTestCase

@end

@implementation STCryptorTestCase

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAESCryptor {
    NSString *key = @"123123";
    NSString *string = @"I am SunJiangting";
    NSString *encryptorString = [[[string UTF8EncodedData] AES256EncryptedDataWithKey:key] base64String];
    NSString *decryptorString = [[[NSData dataWithBase64EncodedString:encryptorString] decryptAES256DataWithKey:key] UTF8String];
    XCTAssertTrue([string isEqualToString:decryptorString]);
}

- (void) testRSASignCryptor {
    SecKeyRef publicKey = STSecPublicKeyFromDERBase64String(MYPublicDERKey);
    SecKeyRef privateKey = STSecPrivateKeyFromPEMBase64String(MYPrivatePEMKey);
    STRSACryptor * cryptor = [[STRSACryptor alloc] initWithPublicSecKey:publicKey privateSecKey:privateKey];
    NSString * string = @"I am SunJiangting";
    NSData * signarate = [cryptor signData:string.UTF8EncodedData];
    BOOL verify = [cryptor verifySignature:signarate signedData:string.UTF8EncodedData];
    XCTAssertTrue(verify);
}

- (void) testRSACrypto {
    SecKeyRef publicKey = STSecPublicKeyFromDERBase64String(MYPublicDERKey);
    SecKeyRef privateKey = STSecPrivateKeyFromPEMBase64String(MYPrivatePEMKey);
    STRSACryptor * cryptor = [[STRSACryptor alloc] initWithPublicSecKey:publicKey privateSecKey:privateKey];
    NSString * string = @"I am SunJiangting";
    NSData * encryptedData = [cryptor encryptData:string.UTF8EncodedData];
    NSData * decryptedData = [cryptor decryptData:encryptedData];
    NSString * decryptedString = decryptedData.UTF8String;
    XCTAssertTrue([string isEqualToString:decryptedString]);
}

@end
