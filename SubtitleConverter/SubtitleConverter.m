//
//  SubtitleConverter.m
//  SubtitleConverter
//
//  Created by Hyunmin Kang on 2/22/14.
//  Copyright (c) 2014 Hyunmin Kang. All rights reserved.
//

#import "SubtitleConverter.h"
#import "NSString+MFExtended.h"
#import "NSRegularExpression+MFExtended.h"


NSString *const LineDelimiterUnix = @"\n";
NSString *const LineDelimiterWindows = @"\r\n";


NSRegularExpression *SubRipRegularExpression;
NSRegularExpression *SubRipRegularDataExpression;
NSRegularExpression *SAMIRegularExpression;
NSRegularExpression *SAMIDataRegularExpression;
NSRegularExpression *SAMINewLineTagRegularExpression;
NSRegularExpression *SAMITagRegularExpression;
NSRegularExpression *LeftTrimRegularExpression;
NSRegularExpression *RightTrimRegularExpression;
NSRegularExpression *SpaceRegularExpression;
NSRegularExpression *CommentRegularExpression;


@interface Subtitle : NSObject {
	@package
	NSTimeInterval _start;
	NSTimeInterval _end;
	NSString *_text;
}
@end


@implementation Subtitle

- (instancetype)initWithType:(SubtitleType)type start:(NSTimeInterval)start end:(NSTimeInterval)end text:(NSString *)text {
	self = [self init];
	if (self) {
		_start = start;
		_end = end;
		_text = text;
	}
	return self;
}

- (NSTimeInterval)startWithSync:(NSTimeInterval)sync {
	return MAX(_start + sync, 0.0);
}

- (NSTimeInterval)endWithSync:(NSTimeInterval)sync {
	return MAX(_end + sync, 0.0);
}

- (NSString *)samiWithType:(SubtitleType)type {
	switch (type) {
		case SubtitleTypeSAMI:
			return _text;
		default:
			return [_text stringByReplacingOccurrencesOfString:LineDelimiterUnix withString:@"<BR>\n"];
	}
}

- (NSString *)plainWithType:(SubtitleType)type {
	switch (type) {
		case SubtitleTypeSAMI: {
			NSString *text = _text;
			text = [SAMINewLineTagRegularExpression stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:LineDelimiterUnix];
			text = [SAMITagRegularExpression stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:@""];
			text = [text stringByXMLEntity];
			text = [SpaceRegularExpression stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:@" "];
			text = [LeftTrimRegularExpression stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:LineDelimiterUnix];
			text = [RightTrimRegularExpression stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:LineDelimiterUnix];

			return [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		}

		default:
			return _text;
	}
}

- (NSString *)description {
	return _text;
}

@end


@implementation SubtitleConverter {
@private
	NSMutableArray *_subtitles;
	NSString *_inputPath;
	NSDateFormatter *_subRipDateFormatter;
	SubtitleType _inputType;
}

+ (void)load {
	NSError *error;
	SubRipRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"\\s{2,}\\d+\\s+" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
	SubRipRegularDataExpression = [[NSRegularExpression alloc] initWithPattern:@"(\\d{2}:\\d{2}:\\d{2},\\d{1,3})\\s+-->\\s+(\\d{2}:\\d{2}:\\d{2},\\d{1,3})\\s+(.+)" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
	SAMIRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"\\s*<sync\\s+" options:NSRegularExpressionCaseInsensitive error:&error];
	SAMIDataRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"start=['\"]?(\\d+)['\"]?\\s*[^>]*>\\s*(.*)\\s*" options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators error:&error];
	SAMINewLineTagRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"<br[^>]*/?>" options:NSRegularExpressionCaseInsensitive error:&error];
	SAMITagRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"</?\\w+\\s*[^>]*\\s*/?>" options:0 error:&error];
	LeftTrimRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"\\n\\s+" options:0 error:&error];
	RightTrimRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"\\s+\\n" options:0 error:&error];
	SpaceRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"[　  ]+" options:0 error:&error];
	CommentRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"<!--.*?-->" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
}

- (instancetype)init {
    return [self init];
}

- (instancetype)initWithFile:(NSString *)path outputType:(SubtitleType)type inputEncoding:(NSStringEncoding)inputEncoding outputEncoding:(NSStringEncoding)outputEncoding lineDelimiterType:(LineDelimiterType)lineDelimiterType sync:(NSTimeInterval)sync {
	self = [super init];
	if (self) {
		_inputPath = path;
		_outputType = type;
		_inputEncoding = inputEncoding;
		_outputEncoding = outputEncoding;
		_lineDelimiterType = lineDelimiterType;
		_sync = sync;

		_subRipDateFormatter = [[NSDateFormatter alloc] init];
		_subRipDateFormatter.dateFormat = @"HH:mm:ss,SSS";
		_subRipDateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];

		[self openWithFile:path];
	}
	return self;
}

- (void)openWithFile:(NSString *)path {
	NSString *inputSubtitle = nil;

	if (_inputEncoding == 0) {
		NSData *data = [[NSData alloc] initWithContentsOfFile:path];
		Byte *bytes = (Byte *)data.bytes;

        if (bytes[0] == (Byte)0x00 && bytes[1] == (Byte)0x00 && bytes[2] == (Byte)0xFE && bytes[3] == (Byte)0xFF) {
            _inputEncoding = NSUTF32BigEndianStringEncoding;
        } else if (bytes[0] == (Byte)0xEF && bytes[1] == (Byte)0xBB && bytes[2] == (Byte)0xBF) {
            _inputEncoding = NSUTF8StringEncoding;
        } else if (bytes[0] == (Byte)0xFE && bytes[1] == (Byte)0xFF) {
            _inputEncoding = NSUTF16BigEndianStringEncoding;
        } else if (bytes[0] == (Byte)0xFF && bytes[1] == (Byte)0xFE) {
            if (bytes[2] == (Byte)0x00 && bytes[3] == (Byte)0x00) {
                _inputEncoding = NSUTF32LittleEndianStringEncoding;
            } else {
                _inputEncoding = NSUTF16LittleEndianStringEncoding;
            }
		} else {
			NSString *kor = [[NSString alloc] initWithContentsOfFile:path encoding:NSKoreanDOSStringEncoding error:nil];
			NSString *def = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];

			if ((kor != nil && def == nil) || (kor.length < def.length)) {
				_inputEncoding = NSUTF8StringEncoding;
				inputSubtitle = kor;
			} else {
				_inputEncoding = [NSString defaultCStringEncoding];
				inputSubtitle = def;
			}
		}
	}

    if (inputSubtitle == nil) {
        inputSubtitle = [[NSString alloc] initWithContentsOfFile:path encoding:_inputEncoding error:nil];
    }

    if (_outputEncoding == 0) {
        _outputEncoding = _inputEncoding;
    }

	[self loadingWithFile:path subtitle:[inputSubtitle stringByReplacingOccurrencesOfString:LineDelimiterWindows withString:LineDelimiterUnix]];
}

- (void)loadingWithFile:(NSString *)path subtitle:(NSString *)subtitle {
	_inputPath = path;

	NSString *extension = path.pathExtension.lowercaseString;
	if ([extension rangeOfString:@"^sa?mi$" options:NSRegularExpressionSearch].location != NSNotFound) {
		_inputType = SubtitleTypeSAMI;
        if (![self loadingWithSAMI:subtitle]) {
            [self loadingWithSubtitle:subtitle];
        }
	} else if ([extension isEqualToString:@"srt"]) {
		_inputType = SubtitleTypeSubRip;
        if (![self loadingWithSubRip:subtitle]) {
            [self loadingWithSubtitle:subtitle];
        }
	}
}

- (void)loadingWithSubtitle:(NSString *)subtitle {
    if ([self loadingWithSAMI:subtitle]) {
        return;
    }

    if ([self loadingWithSubRip:subtitle]) {
        return;
    }
}

- (BOOL)loadingWithSAMI:(NSString *)sami {
	sami = [CommentRegularExpression stringByReplacingMatchesInString:sami options:0 range:NSMakeRange(0, sami.length) withTemplate:@""];

	NSArray *components = [SAMIRegularExpression componentsSeparatedByString:sami options:0 range:NSMakeRange(0, sami.length)];

    if (components.count < 2) {
        return NO;
    }

	_inputType = SubtitleTypeSAMI;

	NSTimeInterval start, end = 0.0;
	NSString *text;
	_subtitles = [[NSMutableArray alloc] init];
	Subtitle *subtitle = [[Subtitle alloc] init];
	for (NSString *sync in components) {
		NSTextCheckingResult *result = [SAMIDataRegularExpression firstMatchInString:sync options:0 range:NSMakeRange(0, sync.length)];

        if (result == nil) {
            continue;
        }

		start = end;
		end = [sync substringWithRange:[result rangeAtIndex:1]].doubleValue / 1000.0;

		if (text.length > 0) {
            if ([subtitle->_text isEqualToString:text]) {
                subtitle->_end = end;
            } else {
				if (subtitle->_end > start)
					subtitle->_end = end;
				subtitle = [[Subtitle alloc] initWithType:SubtitleTypeSAMI start:start end:end text:text];
				[_subtitles addObject:subtitle];
			}
		}

		text = [[sync substringWithRange:[result rangeAtIndex:2]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	}

	return YES;
}

- (BOOL)loadingWithSubRip:(NSString *)srt {
	NSArray *components = [SubRipRegularExpression componentsSeparatedByString:srt options:0 range:NSMakeRange(0, srt.length)];

    if (components.count < 2) {
        return NO;
    }

	_inputType = SubtitleTypeSubRip;

	_subtitles = [[NSMutableArray alloc] init];
	for (NSString *component in components) {
		NSTextCheckingResult *result = [SubRipRegularDataExpression firstMatchInString:component options:0 range:NSMakeRange(0, component.length)];

        if (result == nil) {
            continue;
        }

		NSString *text = [component substringWithRange:[result rangeAtIndex:3]];
		text = [SpaceRegularExpression stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:@" "];
		text = [LeftTrimRegularExpression stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:@""];
		text = [RightTrimRegularExpression stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:@""];
		text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

		NSTimeInterval start = [_subRipDateFormatter dateFromString:[component substringWithRange:[result rangeAtIndex:1]]].timeIntervalSinceReferenceDate + 31622400.0;
		NSTimeInterval end = [_subRipDateFormatter dateFromString:[component substringWithRange:[result rangeAtIndex:2]]].timeIntervalSinceReferenceDate + 31622400.0;

		[_subtitles addObject:[[Subtitle alloc] initWithType:SubtitleTypeSubRip start:start end:end text:text]];
	}

	return YES;
}

- (NSString *)saveSAMI {
    if (_inputType == SubtitleTypeSAMI && _sync == 0.0) {
        return nil;
    }

    if (_lineDelimiterType == 0) {
        _lineDelimiterType = LineDelimiterTypeWindows;
    }

	NSString *p = nil;
	NSMutableString *str = [@"<SAMI>\n<HEAD>\n<TITLE></TITLE>\n<STYLE><!--\nP { font-family: sans-serif; text-align: center; }\n" mutableCopy];

	switch (_inputEncoding) {
		case NSKoreanDOSStringEncoding:
		case NSKoreanEUCStringEncoding:
			[str appendString:@".KRCC { Name: Korean; lang: ko-KR; }\n"];
			p = @"<P Class=KRCC>";
			break;
		default:
			p = @"<P>";
            break;
	}

	[str appendString:@"--></STYLE>\n</HEAD>\n<BODY>\n"];
	NSTimeInterval end = 0.0;
	for (Subtitle *subtitle in _subtitles) {
		NSTimeInterval e = [subtitle endWithSync:_sync];
        if (e < 0.0) {
            continue;
        }
		NSTimeInterval start = [subtitle startWithSync:_sync];
        if (start != end && end != 0.0) {
            [str appendFormat:@"<SYNC Start=%.0f>\n", end * 1000.0];
        }
		[str appendFormat:@"<SYNC Start=%.0f>\n%@%@\n", start * 1000.0, p, [subtitle samiWithType:_inputType]];
		end = e;
	}

	[str appendFormat:@"<SYNC Start=%.0f>\n</BODY>\n</SAMI>", end * 1000.0];
	NSString *text = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (_lineDelimiterType == LineDelimiterTypeWindows) {
        text = [text stringByReplacingOccurrencesOfString:LineDelimiterUnix withString:LineDelimiterWindows];
    }

	NSString *path = [_inputPath.stringByDeletingPathExtension stringByAppendingPathExtension:@"smi"];

	NSError *error;
    if (![text writeToFile:path atomically:NO encoding:_outputEncoding error:nil]) {
        NSLog(@"%@ %@", error, error.userInfo);
    }

	return path;
}

- (NSString *)saveSubRip {
    if (_inputType == SubtitleTypeSubRip && _sync == 0.0) {
        return nil;
    }

    if (_lineDelimiterType == 0) {
        _lineDelimiterType = LineDelimiterTypeWindows;
    }

	Subtitle *before;
	for (Subtitle *subtitle in [_subtitles copy]) {
		NSTimeInterval end = [subtitle endWithSync:_sync];
		if (end < 0.0) {
			[_subtitles removeObject:subtitle];
			continue;
		}

		NSString *text = [subtitle plainWithType:_inputType];
		if (text.length < 1) {
			[_subtitles removeObject:subtitle];
			continue;

		} else if (before != nil && [text isEqualToString:before->_text]) {
			before->_end = subtitle->_end;
			[_subtitles removeObject:subtitle];
			continue;
		}

		subtitle->_start = [subtitle startWithSync:_sync];
		subtitle->_end = end;
		subtitle->_text = text;
		before = subtitle;
	}

	NSUInteger i = 0;
	NSMutableString *str = [[NSMutableString alloc] init];
	for (Subtitle *subtitle in _subtitles) {
		[str appendFormat:@"%zu\n%@ --> %@\n%@\n\n", ++i, [_subRipDateFormatter stringFromDate:[[NSDate alloc] initWithTimeIntervalSinceReferenceDate:subtitle->_start]], [_subRipDateFormatter stringFromDate:[[NSDate alloc] initWithTimeIntervalSinceReferenceDate:subtitle->_end]], subtitle->_text];
	}

	NSString *text = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (_lineDelimiterType == LineDelimiterTypeWindows) {
        text = [text stringByReplacingOccurrencesOfString:LineDelimiterUnix withString:LineDelimiterWindows];
    }

	NSString *path = [_inputPath.stringByDeletingPathExtension stringByAppendingPathExtension:@"srt"];

	NSError *error;
    if (![text writeToFile:path atomically:NO encoding:_outputEncoding error:&error]) {
        NSLog(@"%@ %@", error, error.userInfo);
    }

	return path;
}

- (void)saveWithType:(SubtitleType)type {
	NSString *file = nil;

	switch (type) {
		case SubtitleTypeSAMI:
			file = [self saveSAMI];
			break;
		case SubtitleTypeSubRip:
			file = [self saveSubRip];
			break;
	}
    
    switch (_inputType) {
        case SubtitleTypeSAMI:
            file = [self saveSubRip];
            break;
        case SubtitleTypeSubRip:
            file = [self saveSAMI];
            break;
    }
    
#ifdef DEBUG
	if (file != nil)
		NSLog(@"%@ -> %@", _inputPath, file);
#endif
}

- (void)save {
	[self saveWithType:_outputType];
}

@end
