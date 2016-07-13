//
//  STStringTokenizer.m
//  STKit
//
//  Created by SunJiangting on 14-5-12.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STStringTokenizer.h"
#import <CoreText/CoreText.h>
#import "UIKit+STKit.h"
#import "Foundation+STKit.h"

@implementation STStringTokenizer

+ (NSAttributedString *)attributedStringWithMarkedString:(NSString *)markedText {
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    NSString *regex = @"<mark([^>]*)>(.*?)(</mark>)";
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regex options:NSRegularExpressionCaseInsensitive error:nil];
    [expression enumerateMatchesInString:markedText
                                 options:NSMatchingReportCompletion
                                   range:NSMakeRange(0, markedText.length)
                              usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                  NSInteger rangeCount = [result numberOfRanges];
                                  if (rangeCount >= 3) {
                                      NSRange range1 = [result rangeAtIndex:1];
                                      NSRange range2 = [result rangeAtIndex:2];
                                      NSString *style = [markedText substringWithRange:range1];
                                      NSString *content = [markedText substringWithRange:range2];
                                      NSDictionary *attrDict = [self dictionaryWithMarkedString:style];

                                      NSAttributedString *aString = [self attributedStringWithStyleDictionary:attrDict content:content];
                                      [attributedString appendAttributedString:aString];
                                  }
                              }];
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, 0)];
    return attributedString;
}

#pragma mark - Private Method
+ (NSDictionary *)dictionaryWithMarkedString:(NSString *)markedString {
    NSArray *attributeArray = [markedString st_componentsSeparatedByRegex:@"\\s+"];
    NSMutableDictionary *attributeDict = [NSMutableDictionary dictionaryWithCapacity:2];
    [attributeArray enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        NSRange range = [obj rangeOfString:@"="];
        if (range.location != NSNotFound) {
            NSString *key = [[[obj substringToIndex:range.location] st_stringByTrimingWhitespace] st_stringByTrimingQuotation];
            NSString *value = [[[obj substringFromIndex:range.location + 1] st_stringByTrimingWhitespace] st_stringByTrimingQuotation];
            if (key.length > 0 && value.length > 0) {
                [attributeDict setValue:value forKey:key];
            }
        }
    }];
    return attributeDict;
}

+ (NSAttributedString *)attributedStringWithStyleDictionary:(NSDictionary *)styleDict content:(NSString *)content {
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:styleDict.count];

    NSString *fontName = [UIFont systemFontOfSize:12].fontName;
    if ([styleDict valueForKey:@"name"]) {
        fontName = [styleDict valueForKey:@"name"];
    }
    CGFloat fontSize = 16.;
    if ([styleDict valueForKey:@"size"]) {
        fontSize = [[styleDict valueForKey:@"size"] floatValue];
    }
    UIFont *font = [UIFont fontWithName:fontName size:fontSize];
    [attributes setValue:font forKey:NSFontAttributeName];

    UIColor *color = [UIColor blackColor];
    NSString *colorString = [styleDict valueForKey:@"color"];
    if (colorString) {
        colorString = [colorString stringByReplacingOccurrencesOfString:@"#" withString:@"0x"];
        color = [UIColor st_colorWithHexString:colorString];
    }
    [attributes setValue:color forKey:NSForegroundColorAttributeName];

    NSUnderlineStyle underLineStyle = NSUnderlineStyleNone;
    NSString *underlineString = [styleDict valueForKey:@"underline"];
    if ([underlineString isEqualToString:@"single"]) {
        underLineStyle = NSUnderlineStyleSingle;
    } else if ([underlineString isEqualToString:@"thick"]) {
        underLineStyle = NSUnderlineStyleThick;
    }
    [attributes setValue:@(underLineStyle) forKey:NSUnderlineStyleAttributeName];

    NSUnderlineStyle throughStyle = NSUnderlineStyleNone;
    NSString *strikeThrough = [styleDict valueForKey:@"strikethrough"];
    if ([strikeThrough isEqualToString:@"single"]) {
        throughStyle = NSUnderlineStyleSingle;
    } else if ([underlineString isEqualToString:@"thick"]) {
        throughStyle = NSUnderlineStyleThick;
    }
    [attributes setValue:@(throughStyle) forKey:NSStrikethroughStyleAttributeName];
    return [[NSAttributedString alloc] initWithString:content attributes:attributes];
}

@end

@implementation UILabel (STStringTokenizer)

- (void)setMarkedText:(NSString *)markedString {
    if ([UILabel instancesRespondToSelector:@selector(setAttributedText:)]) {
        self.attributedText = [STStringTokenizer attributedStringWithMarkedString:markedString];
    }
}

@end

@implementation NSString (STStringTokenizer)

- (NSString *)st_stringByTrimingQuotation {
    NSString *results = self;
    if ([results hasPrefix:@"\""] || [results hasPrefix:@"'"]) {
        results = [results substringFromIndex:1];
    }
    if ([results hasSuffix:@"\""] || [results hasSuffix:@"'"]) {
        results = [results substringToIndex:results.length - 1];
    }
    return results;
}

@end