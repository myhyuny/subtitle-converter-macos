//
//  SubtitleConverter.h
//  SubtitleConverter
//
//  Created by Hyunmin Kang on 3/13/14.
//  Copyright (c) 2014 Hyunmin Kang. All rights reserved.
//

#ifndef __SubtitleConverter__SubtitleConverter__
#define __SubtitleConverter__SubtitleConverter__

#include <string>
#include <list>
#include <cstdint>
#ifdef __OBJC__
#import <Foundation/Foundation.h>
#endif

class SubtitleConverter {
public:
    typedef enum : uint8_t {
        SAMI = 0x1,
        SubRip = 0x2,
    } Type;
    
    SubtitleConverter(const wchar_t* subtitle, Type inputType = (Type)0, time_t sync = 0);
    ~SubtitleConverter();
    
    std::wstring parseSAMI();
    std::wstring parseSubRip();
    
    std::wstring parse(Type type);
    
#ifdef __OBJC__
    SubtitleConverter(NSString *subtitle, Type inputType = (Type)0, NSTimeInterval sync = 0.0);
    
    NSString *stringBySAMI();
    NSString *stringBySubRip();
    
    NSString *stringWithType(Type type);
#endif
    
private:
    struct Subtitle {
        std::wstring* text;
        time_t start;
        time_t end;
        
        Subtitle(time_t start = 0, time_t end = 0);
        Subtitle(std::wstring* text, time_t start = 0, time_t end = 0);
        ~Subtitle();
        
        std::wstring plain(Type type);
        std::wstring sami(Type type);
    };
    
    std::list<Subtitle*> subtitles;
    time_t sync;
    Type inputType;
    
    void initializer(std::wstring subtitle, Type inputType, time_t sync);
    
    bool readSAMI(std::wstring &sami);
    bool readSubRip(std::wstring &srt);
};


#endif /* defined(__SubtitleConverter__SubtitleConverter__) */
