//
//  SubtitleConverter.mm
//  SubtitleConverter
//
//  Created by Hyunmin Kang on 3/13/14.
//  Copyright (c) 2014 Hyunmin Kang. All rights reserved.
//

#import "SubtitleConverter.h"

using namespace std;


SubtitleConverter::SubtitleConverter(NSString *subtitle, Type inputType, NSTimeInterval sync) {
	initializer((const wchar_t*)[subtitle cStringUsingEncoding:NSUTF32LittleEndianStringEncoding], inputType, sync * 1000);
}

NSString *NSStringFromWString(const wstring &str) {
	return CFBridgingRelease(CFStringCreateWithBytes(kCFAllocatorDefault, (const UInt8 *)str.c_str(), str.length() * sizeof(wchar_t), kCFStringEncodingUTF32LE, FALSE));
}

NSString *SubtitleConverter::stringBySAMI() {
	return NSStringFromWString(this->parseSAMI());
}

NSString *SubtitleConverter::stringBySubRip() {
	return NSStringFromWString(this->parseSubRip());
}

NSString *SubtitleConverter::stringWithType(Type type) {
	return NSStringFromWString(this->parse(type));
}
