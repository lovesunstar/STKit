//
//  STLinkLabel.m
//  STKit
//
//  Created by SunJiangting on 13-11-27.
//  Copyright (c) 2013年 SunJiangting. All rights reserved.
//

#import "STLinkLabel.h"
#import <CoreText/CoreText.h>
#import "UIKit+STKit.h"
#import "STStringTokenizer.h"

ST_INLINE CGRect STRunGetRect(CTLineRef line, CTRunRef run, CGPoint lineOrigin) {
    CGRect runBounds = CGRectZero;
    CGFloat ascent, descent, leading;
    CGFloat width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, &leading);
    runBounds.size.width = width;
    CGFloat lineHeight = ascent + fabs(descent) + leading;
    runBounds.size.height = lineHeight;
    CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL);
    runBounds.origin.x = lineOrigin.x + xOffset;
    runBounds.origin.y = lineOrigin.y - descent;
    return runBounds;
}

@interface STLinkObject ()
@property(nonatomic, strong) NSURL *URL;
@property(nonatomic, strong) NSString *value;
@property(nonatomic, assign) NSRange range;
@property(nonatomic, copy) NSString *content;
@property(nonatomic, assign) NSRange nativeRange;

@property(nonatomic, strong) UIColor *linkColor;
@property(nonatomic, strong) UIColor *backgroundColor;
@property(nonatomic, strong) UIColor *highlightLinkColor;
@property(nonatomic, strong) UIColor *highlightBackgroundColor;
@end

@implementation STLinkObject

- (NSString *)description {
    return [NSString stringWithFormat:@"{URL:%@, range:%@}", self.URL, NSStringFromRange(self.range)];
}
@end

@interface STLinkLabel () {
    CTFrameRef _frame;
    BOOL _touchEffective;
    CGPoint _lineOrigins;
    CGRect _boundingBox;
    CGSize _suggestionSize;
    BOOL _completelyDisplay;
}

@property(nonatomic, strong) NSDataDetector *dataDetector;

@property(nonatomic, strong) NSArray *linkObjects;
@property(nonatomic, strong) STLinkObject *selectedLinkObject;
@property(nonatomic, strong) NSString *displayText;

@end

@implementation STLinkLabel

- (void)dealloc {
    if (_frame) {
        CFRelease(_frame);
    }
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _textCheckingTypes = NSTextCheckingTypeLink | STTextCheckingTypeCustomLink;

        _lineBreakMode = NSLineBreakByWordWrapping;
        _numberOfLines = 0;
        _textAlignment = NSTextAlignmentLeft;
        _baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
        _font = [UIFont systemFontOfSize:17.0];
        _textColor = [UIColor blackColor];
        _highlightedTextColor = [UIColor whiteColor];

        _linkColor = [UIColor blueColor];
        _highlightedLinkColor = [UIColor redColor];
        _highlightedLinkBackgroundColor = [UIColor grayColor];
        _verticalTouchAreaFactor = 1.0;

        self.autoHyperlink = YES;
        self.continueTouchEvent = YES;
        self.backgroundColor = [UIColor whiteColor];
        self.userInteractionEnabled = NO;
        __weak STLinkLabel *weakSelf = self;
        self.hitTestBlock = ^(CGPoint point, UIEvent *event, BOOL *returnSuper) {
            if (weakSelf.userInteractionEnabled) {
                *returnSuper = YES;
                return (UIView *)nil;
            }
            if (weakSelf.hidden || weakSelf.alpha < 0.01) {
                *returnSuper = YES;
                return (UIView *)nil;
            }
            if ([weakSelf hasLinkObjectAtPoint:point]) {
                return (UIView *)weakSelf;
            }
            return (UIView *)nil;
        };
    }
    return self;
}

- (void)setText:(NSString *)text {
    self.selectedLinkObject = nil;
    self.linkObjects = nil;
    if (text.length == 0) {
        _text = [text copy];
        self.displayText = [text copy];
        [self setNeedsDisplay];
        return;
    }
    NSMutableString *displayString = [NSMutableString stringWithString:text];
    NSMutableArray *linkObjects = [NSMutableArray arrayWithCapacity:5];
    if (self.textCheckingTypes & STTextCheckingTypeCustomLink) {
        NSString *const regex = @"<link([^>]*)>(.*?)</link>";
        NSArray *subranges, *regexRanges;
        NSArray *substrings = [text st_componentsSeparatedByRegex:regex ranges:&subranges checkingResults:&regexRanges];
        NSMutableArray *systemLinkObjects = [NSMutableArray arrayWithCapacity:5];
        [substrings enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [systemLinkObjects addObjectsFromArray:[self _linkObjectsInString:obj subrange:NSRangeFromString(subranges[idx])]];
        }];
        [linkObjects addObjectsFromArray:systemLinkObjects];
        NSMutableArray *customLinkObjects = [NSMutableArray arrayWithCapacity:5];
        [regexRanges enumerateObjectsWithOptions:NSEnumerationReverse
                                      usingBlock:^(NSTextCheckingResult *result, NSUInteger idx, BOOL *stop) {
                                          NSInteger rangeCount = [result numberOfRanges];
                                          if (rangeCount >= 2) {
                                              NSRange range = [result rangeAtIndex:0];
                                              NSRange range1 = [result rangeAtIndex:1];
                                              NSRange range2 = [result rangeAtIndex:2];
                                              NSString *style = [text substringWithRange:range1];
                                              NSString *content = [text substringWithRange:range2];
                                              NSDictionary *attrs = [STStringTokenizer dictionaryWithMarkedString:style];
                                              [displayString replaceCharactersInRange:[result rangeAtIndex:0] withString:content];
                                              STLinkObject *linkObject = [[STLinkObject alloc] init];
                                              linkObject.value = [attrs valueForKey:@"value"];
                                              if ([attrs valueForKey:@"href"]) {
                                                  linkObject.URL =
                                                      [NSURL URLWithString:[attrs valueForKey:@"href"]];
                                              }
                                              NSString *colorString = [attrs valueForKey:@"color"];
                                              if (colorString.length > 0) {
                                                  colorString = [colorString stringByReplacingOccurrencesOfString:@"#" withString:@"0x"];
                                                  linkObject.linkColor = [UIColor st_colorWithHexString:colorString];
                                              }
                                              NSString *backgroundColorString = [attrs valueForKey:@"backgroundColor"];
                                              if (backgroundColorString.length > 0) {
                                                  backgroundColorString = [backgroundColorString stringByReplacingOccurrencesOfString:@"#" withString:@"0x"];
                                                  linkObject.backgroundColor = [UIColor st_colorWithHexString:backgroundColorString];
                                              }
                                              NSString *highlightedColor = [attrs valueForKey:@"highlightedColor"];
                                              if (highlightedColor.length > 0) {
                                                  highlightedColor = [highlightedColor stringByReplacingOccurrencesOfString:@"#" withString:@"0x"];
                                                  linkObject.highlightLinkColor = [UIColor st_colorWithHexString:highlightedColor];
                                              }
                                              NSString *highlightBackgroundColor = [attrs valueForKey:@"highlightBackgroundColor"];
                                              if (highlightBackgroundColor) {
                                                  highlightBackgroundColor = [highlightBackgroundColor stringByReplacingOccurrencesOfString:@"#" withString:@"0x"];
                                                  linkObject.highlightBackgroundColor = [UIColor st_colorWithHexString:highlightBackgroundColor];
                                              }
                                              linkObject.range = range;
                                              linkObject.content = content;
                                              [customLinkObjects insertObject:linkObject atIndex:0];
                                          }
                                      }];
        [linkObjects addObjectsFromArray:customLinkObjects];
        [linkObjects sortUsingComparator:^NSComparisonResult(STLinkObject *obj1, STLinkObject *obj2) {
            return (obj1.range.location < obj2.range.location) ? NSOrderedAscending : NSOrderedDescending;
        }];
        __block NSUInteger minusOffset = 0;
        [linkObjects enumerateObjectsUsingBlock:^(STLinkObject *obj, NSUInteger idx, BOOL *stop) {
            NSRange range = obj.range;
            NSUInteger length = range.length;
            range.location = (range.location - minusOffset);
            if (obj.content.length > 0) {
                NSInteger contentLength = obj.content.length;
                range.length = contentLength;
                minusOffset += (length - contentLength);
            }
            obj.range = range;
        }];
        self.linkObjects = systemLinkObjects;
    } else {
        linkObjects = (NSMutableArray *)[self _linkObjectsInString:text subrange:NSMakeRange(0, text.length)];
    }
    self.linkObjects = linkObjects;
    _text = [text copy];
    self.displayText = displayString;
    [self setNeedsDisplay];
}

- (NSArray *)_linkObjectsInString:(NSString *)string subrange:(NSRange)subrange {
    NSError *error;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:_textCheckingTypes error:&error];
    if (error) {
        return nil;
    }
    NSArray *textCheckingResults = [detector matchesInString:string options:NSMatchingReportCompletion range:NSMakeRange(0, string.length)];
    NSMutableArray *linkObjects = [NSMutableArray arrayWithCapacity:textCheckingResults.count];
    [textCheckingResults enumerateObjectsUsingBlock:^(NSTextCheckingResult *obj, NSUInteger idx, BOOL *stop) {
        STLinkObject *linkObject = [[STLinkObject alloc] init];
        NSRange range = obj.range;
        range.location += subrange.location;
        linkObject.range = range;
        linkObject.URL = obj.URL;
        [linkObjects addObject:linkObject];

    }];
    return (linkObjects.count > 0) ? linkObjects : nil;
}

- (void)setVerticalTouchAreaFactor:(CGFloat)verticalTouchAreaFactor {
    _verticalTouchAreaFactor = MAX(1.0, verticalTouchAreaFactor);
}

- (void)drawRect:(CGRect)rect {
    if (!self.displayText) {
        return;
    }
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);

    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:5];
    [attributes setValue:self.font forKey:NSFontAttributeName];
    [attributes setValue:self.textColor forKey:NSForegroundColorAttributeName];
    NSMutableParagraphStyle *paragraphStyle = [STLinkLabel systemParagraphStyleWithFont:self.font];
    paragraphStyle.lineBreakMode = self.lineBreakMode;
    paragraphStyle.alignment = self.textAlignment;
    [attributes setValue:paragraphStyle forKey:NSParagraphStyleAttributeName];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:self.displayText attributes:attributes];
    for (STLinkObject *linkObject in self.linkObjects) {
        NSRange linkRange = linkObject.range;
        if (linkRange.location == NSNotFound || linkRange.length == 0) {
            continue;
        }
        UIColor *linkColor = linkObject.linkColor ?:self.linkColor;
        if (linkColor && ![linkColor isEqual:self.textColor]) {
            [attributedString addAttribute:NSForegroundColorAttributeName value:linkColor range:linkRange];
        }
        UIColor *highlightedLinkColor = linkObject.highlightLinkColor?:self.highlightedLinkColor;
        if (linkObject == self.selectedLinkObject && highlightedLinkColor && ![highlightedLinkColor isEqual:linkColor]) {
            [attributedString addAttribute:NSForegroundColorAttributeName value:highlightedLinkColor range:linkRange];
        }
    }
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attributedString);

    UIBezierPath *path = [UIBezierPath bezierPathWithRect:rect];
    if (_frame) {
        CFRelease(_frame);
        _frame = NULL;
    }
    _frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path.CGPath, NULL);
    _boundingBox = CGPathGetBoundingBox(path.CGPath);

    CFRange fitRange;
    _suggestionSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), NULL, self.frame.size, &fitRange);
    _completelyDisplay = (fitRange.location == 0) && (fitRange.length == attributedString.length);
    for (STLinkObject *linkObject in self.linkObjects) {
        NSRange linkRange = linkObject.range;
        if (linkRange.location == NSNotFound || linkRange.length == 0) {
            continue;
        }
        [self drawBackgroundColor:linkObject.backgroundColor?:self.linkBackgroundColor withLinkObject:linkObject inContext:context path:path.CGPath];
    }
    UIColor *backgroundColor = self.selectedLinkObject.highlightBackgroundColor?:self.highlightedLinkBackgroundColor;
    if (self.selectedLinkObject) {
        [self drawBackgroundColor:backgroundColor withLinkObject:self.selectedLinkObject inContext:context path:path.CGPath];
    }
    CTFrameDraw(_frame, context);
    CFRelease(framesetter);
}

- (void)drawBackgroundColor:(UIColor *)backgroundColor withLinkObject:(STLinkObject *)linkObject inContext:(CGContextRef)context path:(CGPathRef)path {
    if (!linkObject || !backgroundColor) {
        return;
    }
    /// 计算出里面的最大高度，作为渲染高亮的高度
    __block CGFloat height = 0;
    __block CGRect previousRect = CGRectMake(999999999.0f, 999999999.0f, 0, 0);
    NSMutableArray *rectArrays = [NSMutableArray arrayWithCapacity:2];
    [rectArrays addObject:NSStringFromCGRect(previousRect)];
    [self enumerateRunsUsingBlock:^(CTLineRef line, CGPoint lineOrigin, CTRunRef run, NSUInteger idx, BOOL *stop) {
        CFRange runCFRange = CTRunGetStringRange(run);
        NSRange runRange = NSMakeRange(runCFRange.location, runCFRange.length);
        if (STRangeContainsRange(linkObject.range, runRange)) {
            CGRect runRect = STRunGetRect(line, run, lineOrigin);
            CGRect rect = CGRectOffset(runRect, _boundingBox.origin.x, _boundingBox.origin.y);
            /// 如果当前的和以前的在同一行
            if (ABS(rect.origin.y - previousRect.origin.y) < 5) {
                previousRect.origin.y = MIN(previousRect.origin.y, rect.origin.y);
                previousRect.origin.x = MIN(previousRect.origin.x, rect.origin.x);
                previousRect.size.width = CGRectGetMaxX(rect) - CGRectGetMinX(previousRect);
                [rectArrays replaceObjectAtIndex:rectArrays.count - 1 withObject:NSStringFromCGRect(previousRect)];
            } else {
                CGRect effectRect = CGRectMake(999999999.0f, 999999999.0f, 0, 0);
                effectRect.origin.y = MIN(effectRect.origin.y - 1, rect.origin.y - 1);
                effectRect.origin.x = MIN(effectRect.origin.x, rect.origin.x);
                effectRect.size.width = CGRectGetMaxX(rect) - CGRectGetMinX(effectRect);
                [rectArrays addObject:NSStringFromCGRect(effectRect)];
                previousRect = effectRect;
            }
            height = MAX(runRect.size.height, height);
        }
    }];
    [rectArrays enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CGRect rect = CGRectFromString(obj);
        rect.size.height = height;
        CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRect:rect];
        CGContextAddPath(context, bezierPath.CGPath);
        CGContextFillPath(context);
    }];
}

- (void)enumerateLinesUsingBlock:(void (^)(CTLineRef line, CGPoint lineOrigin, NSUInteger index, BOOL *stop))block {
    if (!block) {
        return;
    }
    if (!_frame) {
        return;
    }
    CFArrayRef lines = CTFrameGetLines(_frame);
    NSUInteger lineCount = CFArrayGetCount(lines);
    CGPoint lineOrigins[lineCount];
    CTFrameGetLineOrigins(_frame, CFRangeMake(0, 0), lineOrigins);
    for (int i = 0; i < lineCount; i++) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CGPoint lineOrigin = lineOrigins[i];
        BOOL stop = NO;
        block(line, lineOrigin, i, &stop);
        if (stop) {
            break;
        }
    }
}

- (void)enumerateRunsUsingBlock:(void (^)(CTLineRef line, CGPoint lineOrigin, CTRunRef run, NSUInteger idx, BOOL *stop))block {
    if (!block) {
        return;
    }
    [self enumerateLinesUsingBlock:^(CTLineRef line, CGPoint lineOrigin, NSUInteger index, BOOL *stop) {
        NSArray *runs = (__bridge NSArray *)CTLineGetGlyphRuns(line);
        [runs enumerateObjectsUsingBlock:^(id obj, NSUInteger runIdx, BOOL *runStop) {
            CTRunRef run = (__bridge CTRunRef)obj;
            block(line, lineOrigin, run, runIdx, runStop);
        }];
    }];
}

- (BOOL)canBecomeFirstResponder {
    return [super canBecomeFirstResponder];
}

- (BOOL)isFirstResponder {
    return [super isFirstResponder];
}

#pragma mark - Touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.continueTouchEvent) {
        [super touchesBegan:touches withEvent:event];
    }
    _touchEffective = YES;
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    CGRect rect = _boundingBox;
    rect.size = _suggestionSize;
    if (!CGRectContainsPoint(rect, location)) {
        return;
    }
    __block CTLineRef __line = NULL;
    __block CGPoint __lineOrigin = CGPointZero;
    [self enumerateLinesUsingBlock:^(CTLineRef line, CGPoint lineOrigin, NSUInteger index, BOOL *stop) {
        if ([self pointInLineWithLocation:location lineOrigin:lineOrigin] && (location.x >= lineOrigin.x)) {
            __line = line;
            __lineOrigin = lineOrigin;
        }
    }];
    location.x -= __lineOrigin.x;
    CFIndex index = CTLineGetStringIndexForPosition(__line, location);
    self.selectedLinkObject = nil;
    for (STLinkObject *linkObject in self.linkObjects) {
        NSRange linkRange = linkObject.range;
        if (STLocationInRange(linkRange, index)) {
            self.selectedLinkObject = linkObject;
            break;
        }
    }
}

- (void)setSelectedLinkObject:(STLinkObject *)selectedLinkObject {
    if (selectedLinkObject) {
        BOOL shouldSelect = self.autoHyperlink;
        if ([self.delegate respondsToSelector:@selector(linkLabel:shouldSelectLinkObject:)]) {
            shouldSelect = [self.delegate linkLabel:self shouldSelectLinkObject:selectedLinkObject];
        }
        if (shouldSelect) {
            _selectedLinkObject = selectedLinkObject;
        }
    } else {
        _selectedLinkObject = nil;
        [self setNeedsDisplay];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.continueTouchEvent) {
        [super touchesMoved:touches withEvent:event];
    }
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    __block CTLineRef __line = NULL;
    __block CGPoint __lineOrigin = CGPointZero;
    [self enumerateLinesUsingBlock:^(CTLineRef line, CGPoint lineOrigin, NSUInteger index, BOOL *stop) {
        if ([self pointInLineWithLocation:location lineOrigin:lineOrigin] && (location.x >= lineOrigin.x)) {
            __line = line;
            __lineOrigin = lineOrigin;
        }
    }];
    location.x -= __lineOrigin.x;
    CFIndex index = CTLineGetStringIndexForPosition(__line, location);
    self.selectedLinkObject = nil;
    for (STLinkObject *linkObject in self.linkObjects) {
        NSRange linkRange = linkObject.range;
        if (STLocationInRange(linkRange, index)) {
            self.selectedLinkObject = linkObject;
            break;
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.continueTouchEvent) {
         [super touchesCancelled:touches withEvent:event];
    }
    [self endTouches];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.continueTouchEvent) {
        [super touchesEnded:touches withEvent:event];
    }
    if (!self.selectedLinkObject) {
        [self endTouches];
        return;
    }
    if (_touchEffective && [self.delegate respondsToSelector:@selector(linkLabel:didSelectLinkObject:)]) {
        [self.delegate linkLabel:self didSelectLinkObject:self.selectedLinkObject];
    }
    [self endTouches];
}

#pragma mark - PrivateMethod

- (void)endTouches {
    _touchEffective = NO;
    self.selectedLinkObject = nil;
}

- (CGFloat)touchAreaOffset {
    return (self.font.lineHeight * self.verticalTouchAreaFactor) - self.font.lineHeight;
}

- (BOOL)pointInLineWithLocation:(CGPoint)location lineOrigin:(CGPoint)_lineOrigin {
    CGPoint lineOrigin = _lineOrigin;
    lineOrigin.y = CGRectGetMaxY(_boundingBox) - lineOrigin.y;
    CGFloat top = lineOrigin.y - self.font.lineHeight;
    CGFloat bottom = lineOrigin.y;
    CGFloat topOffset = location.y - top;
    CGFloat bottomOffset = bottom - location.y;
    CGFloat offset = [self touchAreaOffset];
    return (topOffset >= -offset && bottomOffset >= -offset);
}

- (BOOL)hasLinkObjectAtPoint:(CGPoint)point {
    CGPoint location = point;
    __block CTLineRef __line = NULL;
    __block CGPoint __lineOrigin = CGPointZero;
    [self enumerateLinesUsingBlock:^(CTLineRef line, CGPoint lineOrigin, NSUInteger index, BOOL *stop) {
        if ([self pointInLineWithLocation:location lineOrigin:lineOrigin] && (location.x >= lineOrigin.x)) {
            __line = line;
            __lineOrigin = lineOrigin;
        }
    }];
    if (!__line) {
        return NO;
    }
    location.x -= __lineOrigin.x;
    CFIndex index = CTLineGetStringIndexForPosition(__line, location);
    for (STLinkObject *linkObject in self.linkObjects) {
        NSRange linkRange = linkObject.range;
        if (STLocationInRange(linkRange, index)) {
            return YES;
        }
    }
    return NO;
}

- (void)sizeToFit {
    CGSize size = [self.displayText sizeWithFont:self.font
                               constrainedToSize:CGSizeMake(self.width, 9999)
                                  paragraphStyle:[[self class] systemParagraphStyleWithFont:self.font]];
    if (self.numberOfLines == 1) {
    }
    self.size = size;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self setNeedsDisplay];
}

+ (NSMutableParagraphStyle *)systemParagraphStyleWithFont:(UIFont *)font {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentLeft;
    paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
    paragraphStyle.lineHeightMultiple = 1.0;
    if (font) {
        paragraphStyle.maximumLineHeight = font.lineHeight;
        paragraphStyle.minimumLineHeight = font.lineHeight;
    }
    return paragraphStyle;
}

+ (NSString *)displayTextWithTextCheckingType:(NSTextCheckingType)textCheckingTypes text:(NSString *)text {
    if (!text) {
        return nil;
    }
    NSMutableString *displayString = [NSMutableString stringWithString:text];
    if (textCheckingTypes & STTextCheckingTypeCustomLink) {
        NSString *regex = @"<link([^>]*)>(.*?)(</link>)";
        NSArray *regexRanges;
        [text st_componentsSeparatedByRegex:regex ranges:nil checkingResults:&regexRanges];
        [regexRanges enumerateObjectsWithOptions:NSEnumerationReverse
                                      usingBlock:^(NSTextCheckingResult *result, NSUInteger idx, BOOL *stop) {
                                          NSInteger rangeCount = [result numberOfRanges];
                                          if (rangeCount >= 3) {
                                              NSString *content = [text substringWithRange:[result rangeAtIndex:2]];
                                              [displayString replaceCharactersInRange:[result rangeAtIndex:0] withString:content];
                                          }
                                      }];
    }
    return displayString;
}

+ (CGSize)sizeWithText:(NSString *)linkText font:(UIFont *)font constrainedToSize:(CGSize)constrainedSize paragraphStyle:(NSParagraphStyle *)paragraphStyle {
    return [self sizeWithText:linkText textCheckingTypes:NSTextCheckingAllSystemTypes | STTextCheckingTypeCustomLink font:font constrainedToSize:constrainedSize paragraphStyle:paragraphStyle];
}


+ (CGSize)sizeWithText:(NSString *)linkText textCheckingTypes:(NSTextCheckingTypes)checkingTypes font:(UIFont *)font constrainedToSize:(CGSize)constrainedSize paragraphStyle:(NSParagraphStyle *)paragraphStyle {
    NSString *displayString = [self displayTextWithTextCheckingType:checkingTypes text:linkText];
    return [displayString sizeWithFont:font constrainedToSize:constrainedSize paragraphStyle:nil];
}

@end

@implementation NSString (STLinkLabel)

- (CGSize)sizeWithFont:(UIFont *)font constrainedToSize:(CGSize)constrainedSize paragraphStyle:(NSParagraphStyle *)paragraphStyle {
    if (self.length == 0) {
        return CGSizeZero;
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:5];
    // 字体
    [dict setValue:font forKey:NSFontAttributeName];
    // 排版
    if (!paragraphStyle) {
        paragraphStyle = [STLinkLabel systemParagraphStyleWithFont:font];
    }
    [dict setValue:paragraphStyle forKey:NSParagraphStyleAttributeName];
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:self attributes:dict];
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attributedString);
    CFRange fitRange = CFRangeMake(0, 0);
    CGSize size =
        CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, attributedString.length), NULL, constrainedSize, &fitRange);
    CFRelease(framesetter);
    return CGSizeMake(size.width + 2, size.height + 5);
}

@end
