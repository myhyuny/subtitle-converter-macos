//
//  SubtitleConverter.h
//  SubtitleConverter
//
//  Created by Hyunmin Kang on 2/22/14.
//  Copyright (c) 2014 Hyunmin Kang. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(UInt8, SubtitleType) {
    SubtitleTypeSAMI	= 0x1 << 0,
    SubtitleTypeSubRip	= 0x1 << 1,
};

typedef NS_OPTIONS(UInt8, LineDelimiterType) {
    LineDelimiterTypeUnix	    = 0x1 << 0,
    LineDelimiterTypeWindows	= 0x1 << 1,
};


@interface SubtitleConverter : NSObject

@property (assign, nonatomic) NSTimeInterval sync;
@property (assign, nonatomic) NSStringEncoding inputEncoding;
@property (assign, nonatomic) NSStringEncoding outputEncoding;
@property (assign, nonatomic) LineDelimiterType lineDelimiterType;
@property (assign, nonatomic) SubtitleType outputType;

- (instancetype)initWithFile:(NSString *)path outputType:(SubtitleType)type inputEncoding:(NSStringEncoding)inputEncoding outputEncoding:(NSStringEncoding)outputEncoding lineDelimiterType:(LineDelimiterType)lineDelimiterType sync:(NSTimeInterval)sync NS_DESIGNATED_INITIALIZER;

- (void)save;

@end
