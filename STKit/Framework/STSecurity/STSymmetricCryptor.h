//
//  STSymmetricCryptor.h
//  STKit
//
//  Created by SunJiangting on 14-10-29.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import <Foundation/Foundation.h>

//kCCAlgorithmAES = 0,
//kCCAlgorithmDES,
//kCCAlgorithm3DES,
//kCCAlgorithmCAST,
//kCCAlgorithmRC4,
//kCCAlgorithmRC2,
//kCCAlgorithmBlowfish

typedef NS_OPTIONS(NSInteger, STAESCryptorOptions){
    /* 加密算法*/
    STCryptorOptionsAlgorithmAES        = 1 << 0,
    STCryptorOptionsAlgorithmDES        = 1 << 1,
    STCryptorOptionsAlgorithm3DES       = 1 << 2,
    STCryptorOptionsAlgorithmCAST       = 1 << 3,
    STCryptorOptionsAlgorithmRC4        = 1 << 4,
    STCryptorOptionsAlgorithmRC2        = 1 << 5,
    STCryptorOptionsAlgorithmBlowfish   = 1 << 6,
    
    /// 如果需要加密的数据 不是整Key对应的size的整数倍，补全方式
    STCryptorOptionsNoPadding    = 1 << 10,
    STCryptorOptionsZerosPadding = 1 << 11, // 补0
    STCryptorOptionsPKCS5Padding = 1 << 12,
    STCryptorOptionsPKCS7Padding = STCryptorOptionsPKCS5Padding, // default
    
    // 加密模式
    STCryptorOptionsCBCMode      = 1 << 15, // default
    STCryptorOptionsECBMode      = 1 << 16,
};

@interface STSymmetricCryptor : NSObject

@end
