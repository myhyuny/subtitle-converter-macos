//
//  SubtitleConverter.cpp
//  SubtitleConverter
//
//  Created by Hyunmin Kang on 3/13/14.
//  Copyright (c) 2014 Hyunmin Kang. All rights reserved.
//

#include "SubtitleConverter.h"
#include <sstream>
#include <regex>
#include <algorithm>

using namespace std;


const wchar_t Endl = L'\n';


wstring wstring_right_trim(const wstring &str) {
    return regex_replace(str, wregex(L"\\s+$"), L"");
}

wstring wstring_trim(const wstring &str) {
    return wstring_right_trim(regex_replace(str, wregex(L"^\\s+"), L""));
}

wstring wstring_content_trim(const wstring &str) {
    return wstring_trim(regex_replace(regex_replace(str, wregex(L"\\n\\s+"), L""), wregex(L"\\s+\\n"), L""));
}

wstring wstring_windows_to_unix(const wstring &str) {
    return regex_replace(str, wregex(L"\r\n"), L"\n");
}

SubtitleConverter::Subtitle::Subtitle(time_t start, time_t end) : start(start), end(end) {}

SubtitleConverter::Subtitle::Subtitle(wstring* text, time_t start, time_t end) : text(text), start(start), end(end) {}

SubtitleConverter::Subtitle::~Subtitle() {
    delete text;
}

wstring SubtitleConverter::Subtitle::plain(Type type) {
    switch (type) {
        case SAMI: {
            wstring text = regex_replace(*(this->text), wregex(L"<br[^>]*/?>", regex_constants::icase), L"\n");
            text = regex_replace(text, wregex(L"</?\\w+\\s*[^>]*\\s*/?>"), L"");
            text = regex_replace(text, wregex(L"&nbsp;", regex_constants::icase), L" ");
            text = regex_replace(text, wregex(L"[　  ]+"), L" ");
            text = wstring_content_trim(text);
            
            return text;
        }
        default:
            return *(text);
    }
}

wstring SubtitleConverter::Subtitle::sami(Type type) {
    switch (type) {
        case SAMI:
            return *(text);
        default:
            return regex_replace(*(text), wregex(L"\\n"), L"<BR>\n");
    }
}

void SubtitleConverter::initializer(wstring subtitle, Type inputType, time_t sync) {
    this->inputType = inputType;
    this->sync = sync;
    
    subtitle = wstring_windows_to_unix(subtitle);
    
    switch (inputType) {
        case SAMI:
            readSAMI(subtitle);
            break;
        case SubRip:
            readSubRip(subtitle);
            break;
        default:
            if (!readSAMI(subtitle)) {
                readSubRip(subtitle);
            }
            break;
    }
}

SubtitleConverter::SubtitleConverter(const wchar_t* subtitle, Type inputType, time_t sync) {
    initializer(subtitle, inputType, sync);
}

SubtitleConverter::~SubtitleConverter() {
    for (Subtitle* subtitle : subtitles) {
        delete subtitle;
    }
}

bool SubtitleConverter::readSAMI(wstring &sami) {
    sami = regex_replace(sami, wregex(L"<!--[.\\n]*?-->"), L"");
    
    time_t start = 0, end;
    wstringstream sout;
    for (wsmatch m; regex_search(sami, m, wregex(L"\\s*<sync\\s+start=['\"]?(\\d+)['\"]?\\s*[^>]*>\\s*", regex_constants::icase)); sami = m.suffix()) {
        sout << m[1];
        sout >> end;
        sout.clear();
        
        
        wstring text = m.prefix();
        if (!text.empty()) {
            subtitles.push_back(new Subtitle(new wstring(text), start, end));
        }
        
        start = end;
    }
    
    if (subtitles.size() < 1) {
        return false;
    }
    
    delete subtitles.front();
    subtitles.pop_front();
    
    if (subtitles.size() > 0) {
        inputType = SAMI;
    }
    
    return inputType == SAMI;
}

time_t DateToTime(wstring hour, wstring minute, wstring second, wstring millisecond) {
    wstringstream sout;
    
    int hou;
    sout << hour;
    sout >> hou;
    
    sout.clear();
    
    int min;
    sout << minute;
    sout >> min;
    
    sout.clear();
    
    int sec;
    sout << second;
    sout >> sec;
    
    sout.clear();
    
    int mil;
    sout << millisecond;
    sout >> mil;
    
    return hou * 3600000 + min * 60000 + sec * 1000 + mil;
}

bool SubtitleConverter::readSubRip(wstring &srt) {
    Subtitle* subtitle = new Subtitle;
    wsmatch m;
    for (; regex_search(srt, m, wregex(L"\\s*(\\d+)\\s*\\n+\\s*(\\d{1,2}):(\\d{1,2}):(\\d{1,2}),(\\d{1,3})\\s+-->\\s+(\\d{1,2}):(\\d{1,2}):(\\d{1,2}),(\\d{1,3})\\s*")); srt = m.suffix()) {
        subtitle->text = new wstring(wstring_content_trim(m.prefix()));
        subtitles.push_back(subtitle);
        
        subtitle = new Subtitle(DateToTime(m[2], m[3], m[4], m[5]), DateToTime(m[6], m[7], m[8], m[9]));
    }
    
    if (subtitles.size() < 1) {
        return false;
    }
    
    subtitle->text = new wstring(srt);
    subtitles.push_back(subtitle);
    
    delete subtitles.front();
    subtitles.pop_front();
    
    if (subtitles.size() > 0) {
        inputType = SubRip;
    }
    
    return inputType == SubRip;
}

wstring SubtitleConverter::parseSAMI() {
    if ((inputType == SAMI && sync == 0) || subtitles.size() < 1) {
        return L"";
    }
    
    wstringstream sout;
    sout << L"<SAMI>\n<HEAD>\n<TITLE></TITLE>\n<STYLE>\n<!--\nP { font-family: sans-serif; text-align: center; }\n-->\n</STYLE>\n</HEAD>\n<BODY>\n";
    
    time_t end = 0;
    for (Subtitle* subtitle : subtitles) {
        time_t e = max(subtitle->end + sync, (time_t)0);
        if (e < 0) {
            continue;
        }
        
        time_t start = max(subtitle->start + sync, (time_t)0);
        if (start != end && end != 0) {
            sout << L"<SYNC Start=" << end << L">&nbsp;\n";
        }
        sout << L"<SYNC Start=" << start << L">\n<P>" << subtitle->sami(inputType) << Endl;
        
        end = e;
    }
    
    sout << L"<SYNC Start=" << end << L">&nbsp;\n</BODY>\n</SAMI>";
    
    return sout.str();
}

class SubRipDateFormat {
    time_t time;
    
public:
    SubRipDateFormat(time_t time) : time(max(time, (time_t)0)) {}
    
    template <class _CharT, class _Traits>
    friend
    basic_ostream<_CharT, _Traits>&
    operator<<(basic_ostream<_CharT, _Traits>& os, const SubRipDateFormat& f) {
        time_t time = f.time;
        int millisecond	= time % 1000;
        int second	= (time /= 1000) % 60;
        int minute	= (time /= 60) % 60;
        int hour	= (int)(time / 60);
        
        os.width(2);
        os.fill(L'0');
        os << hour;
        
        os << L':';
        
        os.width(2);
        os.fill(L'0');
        os << minute;
        
        os << L':';
        
        os.width(2);
        os.fill(L'0');
        os << second;
        
        os << L',';
        
        os.width(3);
        os.fill(L'0');
        os << millisecond;
        
        return os;
    }
};

wstring SubtitleConverter::parseSubRip() {
    if ((inputType == SubRip && sync == 0) || subtitles.size() < 1) {
        return L"";
    }
    
    size_t i = 0;
    wstringstream sout;
    for (Subtitle* subtitle : subtitles) {
        if (subtitle->end < 0) {
            continue;
        }
        
        wstring text = subtitle->plain(inputType);
        if (text.empty()) {
            continue;
        }
        
        sout << ++i << Endl << SubRipDateFormat(subtitle->start + sync) << L" --> " << SubRipDateFormat(subtitle->end + sync) << Endl << text << L"\n\n";
    }
    
    return wstring_right_trim(sout.str());
}

wstring SubtitleConverter::parse(Type type) {
    switch (type) {
        case SAMI:
            return parseSAMI();
        case SubRip:
            return parseSubRip();
    }
    return L"";
}
