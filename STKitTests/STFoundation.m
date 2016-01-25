//
//  STFoundation.m
//  STKit
//
//  Created by SunJiangting on 16/1/20.
//  Copyright © 2016年 SunJiangting. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <STKit/Foundation+STKit.h>

@interface STTObject : NSObject {
    NSInteger _privateVar;
}

@end

@implementation STTObject {
    
}


@end

@interface STFoundation : XCTestCase {
    NSInteger _privateVar;
}

@end

@implementation STFoundation

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSetValueForVar {
    [self st_setValue:@(456) forVar:@"_privateVar"];
    XCTAssert(_privateVar == 456);
    
    [self st_setValue:@"Suen" forVar:@"_name"];
    XCTAssertEqual(self.name, @"Suen");
}

- (void)testValueForVar {
    _privateVar = 123;
    XCTAssert([[self st_valueForVar:@"_privateVar"] integerValue] == 123);
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
