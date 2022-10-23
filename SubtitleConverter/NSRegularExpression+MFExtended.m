//
//  NSRegularExpression+MFExtended.m
//  SubtitleConverter
//
//  Created by Hyunmin Kang on 2/23/14.
//  Copyright (c) 2014 Hyunmin Kang. All rights reserved.
//

#import "NSRegularExpression+MFExtended.h"

@implementation NSRegularExpression (MFExtended)

- (NSArray *)componentsSeparatedByString:(NSString *)string options:(NSMatchingOptions)options range:(NSRange)range {
    NSArray *matches = [self matchesInString:string options:options range:range];
    if (matches.count < 1) {
        return nil;
    }
    
    NSMutableArray *components = [[NSMutableArray alloc] init];
    
    NSUInteger loc = 0;
    for (NSTextCheckingResult *result in matches) {
        NSRange range = result.range;
        NSUInteger location = range.location;
        
        [components addObject:[string substringWithRange:NSMakeRange(loc, location - loc)]];
        
        loc = location + range.length;
    }
    [components addObject:[string substringFromIndex:loc]];
    
    return [components copy];
}

- (NSString *)stringByFirstMatchInString:(NSString *)string options:(NSMatchingOptions)options range:(NSRange)aRange {
    return [string substringWithRange:[self firstMatchInString:string options:options range:aRange].range];
}

@end
