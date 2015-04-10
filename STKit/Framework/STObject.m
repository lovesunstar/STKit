//
//  STObject.m
//  STKit
//
//  Created by SunJiangting on 14-8-30.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#define ST_IMPLEMENTION_FILE

#import "STObject.h"
#import "Foundation+STKit.h"
#import <objc/runtime.h>

@interface _STPropertyAttribute : NSObject


typedef NS_OPTIONS(NSUInteger, STPropertyPolicy){
    STPropertyPolicyAssign = 1 << 0,
    STPropertyPolicyRetain = 1 << 1,
    STPropertyPolicyCopy   = 1 << 2,
    
    STPropertyPolicyAtomic    = 1 << 10,
    STPropertyPolicyNonatomic = 1 << 11,
};

@property(nonatomic, strong) NSString  *type;
@property(nonatomic, strong) NSString  *variable;
@property(nonatomic, copy)   NSString  *name;
@property(nonatomic) BOOL   readonly;
@property(nonatomic) STPropertyPolicy policy;

@end

@implementation _STPropertyAttribute

- (instancetype)initWithProperty:(objc_property_t)property {
    if (!property) {
        return nil;
    }
    self = [super init];
    if (self) {
        unsigned int propertyCount = 0;
        objc_property_attribute_t *property_attribute_t = property_copyAttributeList(property, &propertyCount);
        for (int i = 0; i < propertyCount; i++) {
            objc_property_attribute_t attribute_t = property_attribute_t[i];
            size_t len = strlen(attribute_t.name);
            if (len == 0) {
                continue;
            }
            if (attribute_t.name[0] == 'T') {
                self.type = [NSString stringWithUTF8String:attribute_t.value];
            }
            if (attribute_t.name[0] == '&') {
                self.policy |= STPropertyPolicyRetain;
            }
            if (attribute_t.name[0] == 'C') {
                self.policy |= STPropertyPolicyCopy;
            }
            if (attribute_t.name[0] == 'N') {
                self.policy |= STPropertyPolicyNonatomic;
            }
            if (attribute_t.name[0] == 'R') {
                self.readonly = YES;
            }
            if (attribute_t.name[0] == 'V') {
                self.variable = [NSString stringWithUTF8String:attribute_t.value];
            }
        }
        _name = [[NSString stringWithUTF8String:property_getName(property)] copy];
        if (property_attribute_t) {
            free(property_attribute_t);
        }
        if (!(self.policy & STPropertyPolicyNonatomic)) {
            self.policy |= STPropertyPolicyAtomic;
        }
        if (!(self.policy & STPropertyPolicyRetain) && !(self.policy & STPropertyPolicyCopy)) {
            self.policy |= STPropertyPolicyAssign;
        }
    }
    return self;
}

- (NSString *)description {
    NSMutableString *description = [@"@property(" mutableCopy];
    if (self.policy & STPropertyPolicyNonatomic) {
        [description appendString:@"nonatomic"];
    } else {
        [description appendString:@"atomic"];
    }
    if (self.policy & STPropertyPolicyRetain) {
        [description appendString:@", strong"];
    } else if (self.policy & STPropertyPolicyCopy) {
        [description appendString:@", copy"];
    } else {
        [description appendString:@", assign"];
    }
    if (self.readonly) {
        [description appendString:@", readonly"];
    }
    [description appendFormat:@") %@ *%@;", self.type, self.name];
    return [description copy];
}

@end

ST_EXTERN void STObjectSetValueForKey(id object, id value, NSString *key) {
    if (!key || !object) {
        return;
    }
    @try {
        [object setValue:value forKey:key];
    }
    @catch (NSException *exception) {
#ifdef DEBUG
        NSLog(@"%@", exception);
#endif
    }
}


void STPrintPropertyAttribute(_STPropertyAttribute *attribute) {
    NSLog(@"%@", attribute);
};
#if DEBUG
#define STCanPrint 0
#endif

#if STCanPrint
#define STPrintPropertyAttributeIfDebug(attribute) STPrintPropertyAttribute(attribute)
#else
#define STPrintPropertyAttributeIfDebug(attribute)
#endif

ST_EXTERN id STObjectCreate(Class objectClass, NSDictionary *dictionary) {
    if (!objectClass) {
        return nil;
    }
    NSObject *object = [[objectClass alloc] init];
    STObjectResetValue(object, dictionary);
    return object;
}

ST_EXTERN NSDictionary *STObjectToDictionary(NSObject *object) {
    if (!STClassRespondsToSelector([object class], @selector(relationship))) {
        return nil;
    }
    Class objectClass = [object class];
    NSDictionary *properties = STClassGetPropertyRelationship(objectClass);
    NSMutableDictionary *toDictionary = [NSMutableDictionary dictionaryWithCapacity:properties.count];
    [properties enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSString *relationName, BOOL *stop) {
        objc_property_t property = class_getProperty(objectClass, [propertyName UTF8String]);
        if (property) {
            id value = [object valueForKey:propertyName];
            if (STClassRespondsToSelector([value class], @selector(relationship))) {
                [toDictionary setValue:STObjectToDictionary(value) forKey:relationName];
            } else if ([value isKindOfClass:[NSArray class]] && ((NSArray *)value).count > 0) {
                NSArray *items = value;
                id item = items[0];
                NSMutableArray *itemsToDictionary = [NSMutableArray arrayWithCapacity:items.count];
                if (STClassRespondsToSelector([item class], @selector(relationship))) {
                    [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        NSDictionary *itemDictinoary = STObjectToDictionary(obj);
                        if (itemDictinoary) {
                            [itemsToDictionary addObject:itemDictinoary];
                        }
                    }];
                } else {
                    [itemsToDictionary addObjectsFromArray:items];
                }
                [toDictionary setValue:[itemsToDictionary copy] forKey:relationName];
            } else {
                [toDictionary setValue:value forKey:relationName];
            }
        }
    }];
    return [toDictionary copy];
}

ST_EXTERN void _STObjectSetPropertyValue(NSObject *object, NSString *propertyName, objc_property_t property, id value) {
    Class objectClass = [object class];
    if (property && object && objectClass) {
        _STPropertyAttribute *attribute = [[_STPropertyAttribute alloc] initWithProperty:property];
        NSMutableString *tempType = [attribute.type mutableCopy];
        if (tempType.length == 0) {
            return;
        }
        BOOL objCType = NO;
        if ([tempType hasPrefix:@"@"]) {
            // @类型的变量
            [tempType deleteCharactersInRange:NSMakeRange(0, 1)];
            [tempType replaceOccurrencesOfString:@"\"" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, tempType.length)];
            objCType = YES;
        }
        NSString *type = [tempType copy];
        Class class = NSClassFromString(type);
        NSString *varName = attribute.variable;
        id propertyValue = nil;
        SEL collectionSelector = NSSelectorFromString([NSString stringWithFormat:@"%@Class", propertyName]);

        Class collectionClass = Nil;
        if (STClassRespondsToSelector(objectClass, collectionSelector)) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            collectionClass = [objectClass performSelector:collectionSelector];
#pragma clang diagnostic pop
            if (!class) {
                class = collectionClass;
            }
        }

        if (STClassRespondsToSelector(class, @selector(relationship)) && [value isKindOfClass:[NSDictionary class]]) {
            propertyValue = STObjectCreate(class, value);
        } else if (STClassIsKindOfClass(class, [NSArray class]) && [value isKindOfClass:[NSArray class]] && collectionClass) {
            NSMutableArray *array = [NSMutableArray arrayWithCapacity:2];
            if (STClassRespondsToSelector(collectionClass, @selector(relationship))) {
                [value enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    if ([obj isKindOfClass:[NSDictionary class]]) {
                        [array addObject:STObjectCreate(collectionClass, obj)];
                    }
                }];
            } else {
                [array addObjectsFromArray:value];
            }
            /// 如果不是mutableClass
            propertyValue = STClassIsKindOfClass(class, [NSMutableArray class]) ? array : [array copy];
        } else if (STClassIsKindOfClass(class, [NSString class])) {
            if (![value isKindOfClass:[NSString class]]) {
                if ([value respondsToSelector:@selector(stringValue)]) {
                    propertyValue = [value stringValue];
                } else if (value) {
                    propertyValue = [NSString stringWithFormat:@"%@", value];
                } else {
                    propertyValue = nil;
                }
            } else {
                propertyValue = value;
            }
        } else if (objCType || [value isKindOfClass:[NSValue class]]) {
            propertyValue = value;
        } else {
            /// 基本类型,但是传入的数据有问题，比如 int varA 传入 字符串的 @"123"
            if ([value isKindOfClass:[NSString class]] || !value) {
                value = [value stringByTrimingWhitespace];
                NSNumber *numberValue;
                const char *cType = type.UTF8String;
                if (strcmp(cType, @encode(BOOL)) == 0) {
                    numberValue = @([value boolValue]);
                }
#define CASE(t, selector)                                                                                                                            \
    else if (strcmp(cType, @encode(t)) == 0) {                                                                                                       \
        numberValue = @([value selector##Value]);                                                                                                    \
    }
                CASE(short, int)
                CASE(int, int)
                CASE(long, integer)
                CASE(long long, longLong)
                CASE(double, double)
                CASE(float, float)
#undef CASE
                else {
                    numberValue = @(0);
                }
                propertyValue = numberValue;
            }
        }
        if (!attribute.readonly) {
            if (objCType || propertyValue) {
                STObjectSetValueForKey(object, propertyValue, propertyName);
            } else {
                int zeroValue = 0;
                STObjectSetValueForKey(object, STCreateValueFromPrimitivePointer(&zeroValue, attribute.type.UTF8String), propertyName);
            }
        } else {
            if (attribute.policy & STPropertyPolicyCopy) {
                propertyValue = [propertyValue copy];
            }
            [object setValue:propertyValue forVar:varName];
        }
    }
}

ST_EXTERN void STObjectResetValue(NSObject *object, NSDictionary *dictionary) {
    if (!object) {
        return;
    }
    Class objectClass = [object class];
    NSDictionary *properties = STClassGetPropertyRelationship(objectClass);
    [properties enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSString *valueName, BOOL *stop) {
        objc_property_t property = class_getProperty(objectClass, [propertyName UTF8String]);
        // 最终的值
        id value = [dictionary valueForKey:valueName];
        if ([value isKindOfClass:[NSNull class]]) {
            value = nil;
        }
        _STObjectSetPropertyValue(object, propertyName, property, value);
    }];
}

ST_EXTERN void STObjectUpdateValue(NSObject *object, NSDictionary *dictionary) {
    if (!object) {
        return;
    }
    Class objectClass = [object class];
    NSDictionary *properties = STClassGetPropertyRelationship(objectClass);
    [properties enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSString *valueName, BOOL *stop) {
        objc_property_t property = class_getProperty(objectClass, [propertyName UTF8String]);
        // 最终的值
        id value = [dictionary valueForKey:valueName];
        if ([value isKindOfClass:[NSNull class]]) {
            value = nil;
        }
        if (value) {
            _STObjectSetPropertyValue(object, propertyName, property, value);
        }
    }];
}

ST_EXTERN id STObjectCreateCopy(NSObject *object) {
    NSDictionary *dictionary = STObjectToDictionary(object);
    return STObjectCreate([object class], dictionary);
}

ST_EXTERN void _STClassGetProperities(Class class, NSMutableArray *mutableArray) {
    if (!STClassRespondsToSelector(class, @selector(relationship))) {
        return;
    }
    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList(class, &propertyCount);
    for (unsigned int i = 0; i < propertyCount; ++i) {
        objc_property_t property = properties[i];
        const char *name = property_getName(property);
        [mutableArray addObject:[NSString stringWithUTF8String:name]];
    }
    free(properties);
    _STClassGetProperities(class_getSuperclass(class), mutableArray);
}

ST_EXTERN NSArray *STClassGetProperities(Class class) {
    NSMutableArray *properties = [NSMutableArray arrayWithCapacity:5];
    _STClassGetProperities(class, properties);
    return [properties copy];
}

ST_EXTERN NSDictionary *STClassGetPropertyRelationship(Class _class) {
    if (!_class) {
        return nil;
    }
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:5];
    NSArray *properties = STClassGetProperities(_class);
    [properties enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) { [dictionary setValue:obj forKey:obj]; }];
    Class class = _class;
    NSMutableArray *hierarchies = [NSMutableArray arrayWithCapacity:2];

    while (class) {
        BOOL hasRelationship = STClassRespondsToSelector(class, @selector(relationship));
        if (hasRelationship) {
            [hierarchies addObject:class];
        }
        class = class_getSuperclass(class);
    }
    [hierarchies enumerateObjectsWithOptions:NSEnumerationReverse
                                  usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                      id relationship = [obj relationship];
                                      if ([relationship isKindOfClass:[NSDictionary class]]) {
                                          [dictionary setValuesForKeysWithDictionary:relationship];
                                      }
                                  }];
    return [dictionary copy];
}

@implementation STObject

+ (instancetype)objectWithDictionary:(NSDictionary *)dictionary {
    return [[self alloc] initWithDictionary:dictionary];
}

- (instancetype)initWithDictinoary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        STObjectResetValue(self, dictionary);
    }
    return self;
}

/**
 * @abstract 根据dict更新Object中对应的属性
 *
 * @param dictionary 需要更新的字段值，需要与relationship对应。
 */
- (void)updateValueWithDictionary:(NSDictionary *)dictionary {
    STObjectUpdateValue(self, dictionary);
}

/**
 * @abstract 重置Object变量值，如果字段没有传值，则初始化为原始值，比如 0 nil 等
 *
 * @param dictionary 字段对应的值，需要与relationship对应。
 */
- (void)resetValueWithDictionary:(NSDictionary *)dictionary {
    STObjectResetValue(self, dictionary);
}

- (NSDictionary *)toDictionary {
    return STObjectToDictionary(self);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"\n<%@:%p>\n%@", [self class], self, [self toDictionary]];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    NSLog(@"setValue:%@ forUndefinedKey%@", value, key);
}

- (id)valueForUndefinedKey:(NSString *)key {
    NSLog(@"valueForUndefinedKey:%@", key);
    return nil;
}

+ (NSDictionary *)relationship {
    return nil;
}

@end
