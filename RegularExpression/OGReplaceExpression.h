/*
 * Name: OGReplaceExpression.h
 * Project: OgreKit
 *
 * Creation Date: Sep 22 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>
#import <OgreKit/OGRegularExpression.h>

@class OGRegularExpressionMatch;

extern NSString	* const OgreReplaceException;

@interface OGReplaceExpression : NSObject <NSCopying, NSCoding>
{
	NSMutableArray	*_compiledReplaceString;
	NSMutableArray	*_compiledReplaceStringType;
	NSMutableArray	*_nameArray;
	OgreOption		_options;
}

/**************************
 * Initialization (初期化) *
 **************************/
/*
 The following special characters can be used in expressionString.
    \& \0 matched string
    \1 ... \9 content of the n-th parentheses
    \+ String that corresponds to the end of the brackets
    \`Matched before the string from part (prematchString)
    \And 'matched behind the string from part (postmatchString)
    \- The last match was part and, string between the matched part before one (stringBetweenLastMatchAndLastButOneMatch)
    \g <name> (? <name> ...) matched substring to (can be used if you have specified a OgreCaptureGroupOption)
    to \g <index> index th (...) or (? <name> ...) matched substring to (can be used if you have specified a OgreCaptureGroupOption)
    \\Backslash "\"
    \t horizontal tab (0x09)
    \n newline (0x0A)
    \r return (0x0D)
    \x {HHHH} 16-bit Unicode character U + HHHH
    \other-characters \other characters
 
 expressionString中では次の特殊文字が使用できる。
  \&, \0		マッチした文字列
  \1 ... \9		n番目の括弧の内容
  \+			最後の括弧に対応する文字列
  \`			マッチした部分より前の文字列 (prematchString)
  \'			マッチした部分より後ろの文字列 (postmatchString)
  \-			最後にマッチした部分と、一つ前にマッチした部分の間の文字列 (stringBetweenLastMatchAndLastButOneMatch)
  \g<name>  	(?<name>...)にマッチした部分文字列 (OgreCaptureGroupOptionを指定した場合に使用可能)
  \g<index> 	index番目に(...)か(?<name>...)にマッチした部分文字列 (OgreCaptureGroupOptionを指定した場合に使用可能)
  \\			バックスラッシュ "\"
  \t			水平タブ (0x09)
  \n			改行 (0x0A)
  \r			復帰 (0x0D)
  \x{HHHH}		16-bit Unicode character U+HHHH
  \その他の文字	\その他の文字
 */
- (instancetype)initWithString:(NSString*)replaceString 
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character;
- (instancetype)initWithString:(NSString*)replaceString
	escapeCharacter:(NSString*)character;
- (instancetype)initWithString:(NSString*)replaceString;

- (instancetype)initWithAttributedString:(NSAttributedString*)replaceString
	options:(OgreOption)options
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character;
- (instancetype)initWithAttributedString:(NSAttributedString*)replaceString
	options:(OgreOption)replaceOptions;
- (instancetype)initWithAttributedString:(NSAttributedString*)replaceString;

- (instancetype)initWithOGString:(id<OGStringProtocol>)replaceString
	options:(OgreOption)options 
	syntax:(OgreSyntax)syntax
	escapeCharacter:(NSString*)character NS_DESIGNATED_INITIALIZER;

+ (instancetype)replaceExpressionWithString:(NSString*)replaceString 
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character;
+ (instancetype)replaceExpressionWithString:(NSString*)replaceString 
	escapeCharacter:(NSString*)character;
+ (instancetype)replaceExpressionWithString:(NSString*)replaceString;

+ (instancetype)replaceExpressionWithAttributedString:(NSAttributedString*)replaceString
	options:(OgreOption)options 
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character;
+ (instancetype)replaceExpressionWithAttributedString:(NSAttributedString*)replaceString
	options:(OgreOption)options;
+ (instancetype)replaceExpressionWithAttributedString:(NSAttributedString*)replaceString;

+ (instancetype)replaceExpressionWithOGString:(id<OGStringProtocol>)replaceString 
	options:(OgreOption)options 
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character;

/*******
 * 置換 *
 *******/
- (id<OGStringProtocol>)replaceMatchedOGStringOf:(OGRegularExpressionMatch*)match;
- (NSString*)replaceMatchedStringOf:(OGRegularExpressionMatch*)match;
- (NSAttributedString*)replaceMatchedAttributedStringOf:(OGRegularExpressionMatch*)match;

@end
