//
//  Encoding.swift
//  
//
//  Created by Paul on 27/06/2022.
//

import Foundation

// TODO method ? class ?
let default_encoding = String.Encoding.ascii

let encodings = [
    "8859/1": String.Encoding.isoLatin1,
    "8859/15": String.Encoding.isoLatin1,
    "8859/2": String.Encoding.isoLatin2,
    "8859/3": String.Encoding.isoLatin1,
    "8859/4": String.Encoding.isoLatin1,
    "8859/5": String.Encoding.isoLatin1,
    "8859/6": String.Encoding.isoLatin1,
    "8859/7": String.Encoding.isoLatin1,
    "8859/8": String.Encoding.isoLatin1,
    "8859/9": String.Encoding.isoLatin1,
    "ASCII": String.Encoding.ascii,
    "BIG-5": String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.big5.rawValue))),
    "CNS 11643-1992": String.Encoding.unicode,
    "GB 18030-2000": String.Encoding.unicode,
    "ISO IR14": String.Encoding.unicode,
    "ISO IR159": String.Encoding.unicode,
    "ISO IR87": String.Encoding.unicode,
    "KS X 1001": String.Encoding.unicode,
    "UNICODE": String.Encoding.unicode,//    The world wide character standard from ISO/IEC 10646-1-1993[5]    Deprecated. Retained for backward compatibility only as v 2.5. Replaced by specific Unicode encoding codes.
    "UNICODE UTF-16": String.Encoding.utf16,//    UCS Transformation Format, 16-bit form    UTF-16 is identical to ISO/IEC 10646 UCS-2. Note that the code contains a space before UTF but not before and after the hyphen.
    "UNICODE UTF-32": String.Encoding.utf32,//    UCS Transformation Format, 32-bit form    UTF-32 is defined by Unicode Technical Report #19, and is an officially recognized encoding as of Unicode Version 3.1. UTF-32 is a proper subset of ISO/IEC 10646 UCS-4.
    "UNICODE UTF-8": String.Encoding.utf8//
]
