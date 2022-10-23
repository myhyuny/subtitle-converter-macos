//
//  NSString+MFExtended.h
//  SubtitleConverter
//
//  Created by Hyunmin Kang on 11. 7. 30..
//  Copyright (c) 2014 Hyunmin Kang. All rights reserved.
//

#import <Foundation/Foundation.h>


enum : NSStringEncoding {
    NSKoreanDOSStringEncoding = 2147484706,
    NSKoreanEUCStringEncoding = 2147486016,
};


@interface NSString (MFExtended)

+ (instancetype)stringWithUnicodeContentsOfFile:(NSString *)path error:(NSError *__autoreleasing *)error;

- (instancetype)initWithUnicodeData:(NSData *)data;
- (instancetype)initWithUnicodeContentsOfFile:(NSString *)path error:(NSError *__autoreleasing *)error;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *stringByTrimming;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *stringByXMLEntity;

@property (NS_NONATOMIC_IOSONLY, getter=isEmpty, readonly) BOOL empty;

@end
