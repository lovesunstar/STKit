//
//  STObjectTestCase.m
//  STKit
//
//  Created by SunJiangting on 14-8-31.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface STAnimal : STObject

@property (nonatomic, copy) NSString * name;

@property (nonatomic, strong) STAnimal * parent;
@end

@implementation STAnimal


@end

@interface STPeople : STAnimal

@property (nonatomic, assign) NSInteger    age;

@property (nonatomic, strong) STPeople      * partner;
@property (nonatomic, copy)   NSArray       * friends;

@end

@implementation STPeople

+ (Class) friendsClass {
    return [STAnimal class];
}

+ (NSDictionary *) relationship {
    return @{@"age":@"age_key"};
}

@end

@interface STObjectTestCase : XCTestCase {
    NSString     * _name;
    NSInteger      _age;
    NSString     * _parentName;
    NSString     * _partnerName;
    NSInteger      _partnerAge;
    NSDictionary * _dictionary;
    NSDictionary * _relationshipDictionary;
    
    NSDictionary * _itemDictionary;
    
    NSDictionary * _itemsDictionary;
}

@end

@implementation STObjectTestCase

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _age = 23;
    _name = @"技术哥", _parentName = @"上帝", _partnerName = @"技术嫂", _partnerAge = 24;
    _dictionary = @{@"name":_name, @"sex":@(1)};
    _relationshipDictionary = @{@"name":_name, @"age_key":@(_age)};
    
    _itemDictionary = @{@"name":_name, @"parent":@{@"name":_parentName}, @"age_key":@(_age) , @"partner":@{@"name": _partnerName, @"age_key":@(_partnerAge)}};
    
    _itemsDictionary = @{@"name":_name, @"parent":@{@"name":_parentName}, @"age_key":@(_age) , @"partner":@{@"name": _partnerName, @"age_key":@(_partnerAge)} , @"friends":@[@{@"name":@"Test1"}, @{@"name":@"Test2"}]};
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    _name = nil, _dictionary = nil, _itemDictionary = nil, _itemsDictionary = nil;
    [super tearDown];
}

- (void)testCreateObject {
    STAnimal * animal = STObjectCreate([STAnimal class], _dictionary);
    XCTAssertEqual(animal.name, _name, @"the name should be assign to the object");
    XCTAssertNil(animal.parent, @"the animal's parent should be nil because of nil value");
}

- (void) testInitWithDictionary {
    STAnimal * testObject = [[STAnimal alloc] initWithDictinoary:_dictionary];
    XCTAssertEqual(testObject.name, _name, @"the name should be assign to the object");
}

- (void) testCreateObjectWithRelationship {
    STPeople * people = STObjectCreate([STPeople class], _relationshipDictionary);
    XCTAssertEqual(_age, people.age, @"The relationship_age in dictionary should be assign to object");
    XCTAssertEqual(people.name, _name, @"the name should be assign to the object");
}

- (void) testCreateObjectContainsItem {
    STPeople * people = STObjectCreate([STPeople class], _itemDictionary);
    STPeople * partner = people.partner;
    STAnimal * parent = people.parent;
    XCTAssertEqual(partner.name, _partnerName, @"The _partnerName should be assign to object's property partner");
    XCTAssertEqual(parent.name, _parentName, @"the name should be assign to the object's property ");
}

- (void) testCreateObjectContainsItems {
    STPeople * people = STObjectCreate([STPeople class], _itemsDictionary);
    XCTAssert([people.friends isKindOfClass:[NSArray class]], @"people's friend must be class array");
    STAnimal * aFriend = people.friends[0];
    XCTAssert([aFriend isKindOfClass:[STAnimal class]], @"each friend should be class Animal");
}
@end
