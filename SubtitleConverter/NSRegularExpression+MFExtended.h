//
//  NSRegularExpression+MFExtended.h
//  SubtitleConverter
//
//  Created by Hyunmin Kang on 2/23/14.
//  Copyright (c) 2014 Hyunmin Kang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSRegularExpression (MFExtended)

- (NSArray *)componentsSeparatedByString:(NSString *)string options:(NSMatchingOptions)options range:(NSRange)range;

- (NSString *)stringByFirstMatchInString:(NSString *)string options:(NSMatchingOptions)options range:(NSRange)aRange;

@end
