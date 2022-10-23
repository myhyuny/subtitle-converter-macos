//
//  NSString+MFExtended.m
//  SubtitleConverter
//
//  Created by Hyunmin Kang on 11. 7. 30..
//  Copyright (c) 2014 Hyunmin Kang. All rights reserved.
//

#import "NSString+MFExtended.h"


@interface MFXMLEntityParser : NSXMLParser <NSXMLParserDelegate> {
    @package
    NSMutableString *_string;
}
@end

@implementation MFXMLEntityParser

- (instancetype)initWithData:(NSData *)data {
    self = [super initWithData:data];
    if (self) {
        _string = [[NSMutableString alloc] init];
        self.delegate = self;
    }
    return self;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    [_string appendString:string];
}

@end


@implementation NSString (MFExtended)

+ (instancetype)stringWithUnicodeContentsOfFile:(NSString *)path error:(NSError *__autoreleasing *)error {
    return [[self alloc] initWithUnicodeContentsOfFile:path error:error];
}

- (instancetype)initWithUnicodeData:(NSData *)data {
    const Byte *bytes = (Byte *)data.bytes;
    
    NSStringEncoding encoding;
    if (bytes[0] == (Byte)0x00 && bytes[1] == (Byte)0x00 && bytes[2] == (Byte)0xFE && bytes[3] == (Byte)0xFF) {
        encoding = NSUTF32BigEndianStringEncoding;
    } else if (bytes[0] == (Byte)0xEF && bytes[1] == (Byte)0xBB && bytes[2] == (Byte)0xBF) {
        encoding = NSUTF8StringEncoding;
    } else if (bytes[0] == (Byte)0xFE && bytes[1] == (Byte)0xFF) {
        encoding = NSUTF16BigEndianStringEncoding;
    } else if (bytes[0] == (Byte)0xFF && bytes[1] == (Byte)0xFE) {
        if (bytes[2] == (Byte)0x00 && bytes[3] == (Byte)0x00) {
            encoding = NSUTF32LittleEndianStringEncoding;
        } else {
            encoding = NSUTF16LittleEndianStringEncoding;
        }
    } else {
        encoding = NSUTF8StringEncoding;
    }
    
    return [self initWithData:data encoding:encoding];
}

- (instancetype)initWithUnicodeContentsOfFile:(NSString *)path error:(NSError *__autoreleasing *)error {
    return [self initWithUnicodeData:[[NSData alloc] initWithContentsOfFile:path options:0 error:error]];
}

- (NSString *)stringByTrimming {
    NSUInteger length = self.length;
    
    CFMutableStringRef theString = CFStringCreateMutableCopy(kCFAllocatorDefault, length, (__bridge CFStringRef)self);
    CFStringTrimWhitespace(theString);
    
    NSString *str = CFStringGetLength(theString) == length ? self : CFBridgingRelease(CFStringCreateCopy(kCFAllocatorDefault, theString));
    CFRelease(theString);
    
    return str;
}

- (NSString *)stringByXMLEntity {
    NSString *xml = [[NSString alloc] initWithFormat:@"<_>%@</_>", self];
    MFXMLEntityParser *parser = [[MFXMLEntityParser alloc] initWithData:[xml dataUsingEncoding:NSUTF8StringEncoding]];
    [parser parse];
    
    return [parser->_string copy];
}

- (BOOL)isEmpty {
    NSUInteger length = self.length;
    
    if (length < 1) {
        return NO;
    }
    
    CFMutableStringRef theString = CFStringCreateMutableCopy(kCFAllocatorDefault, length, (__bridge CFStringRef)self);
    CFStringTrimWhitespace(theString);
    BOOL empty = CFStringGetLength(theString) < 1;
    CFRelease(theString);
    
    return empty;
}

@end
