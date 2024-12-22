/*
 * Name: OGRegularExpressionPrivate.m
 * Project: OgreKit
 *
 * Creation Date: Sep 01 2003
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#ifndef NOT_RUBY
# define NOT_RUBY
#endif
#ifndef HAVE_CONFIG_H
# define HAVE_CONFIG_H
#endif
#import <OgreKit/onigmo.h>

#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGRegularExpressionPrivate.h>
#import <OgreKit/OGString.h>
#import <OgreKit/OGMutableString.h>


OnigSyntaxType  OgrePrivatePOSIXBasicSyntax;
OnigSyntaxType  OgrePrivatePOSIXExtendedSyntax;
OnigSyntaxType  OgrePrivateEmacsSyntax;
OnigSyntaxType  OgrePrivateGrepSyntax;
OnigSyntaxType  OgrePrivateGNURegexSyntax;
OnigSyntaxType  OgrePrivateJavaSyntax;
OnigSyntaxType  OgrePrivatePerlSyntax;
OnigSyntaxType  OgrePrivateRubySyntax;


@implementation OGRegularExpression (Private)

// oniguruma regular expression buffer
- (regex_t*)patternBuffer
{
	return _regexBuffer;
}

// OgreSyntaxに対応するOnigSyntaxType*を返す。
+ (OnigSyntaxType*)onigSyntaxTypeForSyntax:(OgreSyntax)syntax
{
	if(syntax == OgreSimpleMatchingSyntax)	return &OgrePrivateRubySyntax;
	if(syntax == OgrePOSIXBasicSyntax)		return &OgrePrivatePOSIXBasicSyntax;
	if(syntax == OgrePOSIXExtendedSyntax)	return &OgrePrivatePOSIXExtendedSyntax;
	if(syntax == OgreEmacsSyntax)			return &OgrePrivateEmacsSyntax;
	if(syntax == OgreGrepSyntax)			return &OgrePrivateGrepSyntax;
	if(syntax == OgreGNURegexSyntax)		return &OgrePrivateGNURegexSyntax;
	if(syntax == OgreJavaSyntax)			return &OgrePrivateJavaSyntax;
	if(syntax == OgrePerlSyntax)			return &OgrePrivatePerlSyntax;
	if(syntax == OgreRubySyntax)			return &OgrePrivateRubySyntax;
	
	[NSException raise:OgreException format:@"unknown syntax."];
	return NULL;	// dummy
}

// string中の\をcharacterに置き換えた文字列を返す。characterがnilの場合、stringを返す。
+ (id<OGStringProtocol>)changeEscapeCharacterInOGString:(id<OGStringProtocol>)string toCharacter:(NSString*)character
{
	if ( (character == nil) || (string == nil) || ([character length] == 0) ) {
		// エラー。例外を発生させる。
		[NSException raise:NSInvalidArgumentException format:@"nil string (or other) argument"];
	}
	
	if ([character isEqualToString:OgreBackslashCharacter]) {
		return string;
	}
	
	NSString	*plainString = [string string];
	NSUInteger	strLength = [plainString length];
	NSRange		scanRange = NSMakeRange(0, strLength);	// スキャンする範囲
	NSRange		matchRange;					// escapeの発見された範囲(lengthは常に1)
	
	/* escape character set */
	NSCharacterSet	*swapCharSet = [NSCharacterSet characterSetWithCharactersInString:
		[OgreBackslashCharacter stringByAppendingString:character]];
	
	NSObject<OGStringProtocol,OGMutableStringProtocol>	*resultString;
	resultString = [[[[string mutableClass] alloc] init] autorelease];
	
	unsigned			counterOfAutorelease = 0;
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	while ( matchRange = [plainString rangeOfCharacterFromSet:swapCharSet options:0 range:scanRange], 
			matchRange.length > 0 ) {
		NSUInteger  lastMatchLocation = scanRange.location;
		[resultString appendOGString:[string substringWithRange:NSMakeRange(lastMatchLocation, matchRange.location - lastMatchLocation)]];
		
		if ([[plainString substringWithRange:matchRange] isEqualToString:OgreBackslashCharacter]) {
			// \ -> \\ .
			[resultString appendOGString:[string substringWithRange:matchRange]];
			[resultString appendOGString:[string substringWithRange:matchRange]];
			scanRange.location = matchRange.location + 1;
		} else {
			if (matchRange.location + 1 < strLength && [[plainString substringWithRange:NSMakeRange(matchRange.location + 1, 1)] isEqualToString:character]) {
				// \\ -> \ .
				[resultString appendOGString:[string substringWithRange:matchRange]];
				scanRange.location = matchRange.location + 2;
			} else {
				// \(?=[^\]) -> \ .
				[resultString appendString:OgreBackslashCharacter hasAttributesOfOGString:[string substringWithRange:matchRange]];
				scanRange.location = matchRange.location + 1;
			}
		}
		scanRange.length = strLength - scanRange.location;
		
		counterOfAutorelease++;
		if (counterOfAutorelease % 100 == 0) {
			[pool release];
			pool = [[NSAutoreleasePool alloc] init];
		}
	}
	[resultString appendOGString:[string substringWithRange:NSMakeRange(scanRange.location, scanRange.length)]];
	
	[pool release];
	
	//NSLog(@"%@", resultString);
	return resultString;
}

// characterの文字種を返す。
/*
 戻り値:
  OgreKindOfNil			character == nil
  OgreKindOfEmpty		空文字 @""
  OgreKindOfBackslash	\ @"\\"
  OgreKindOfNormal		その他
 */
+ (OgreKindOfCharacter)kindOfCharacter:(NSString*)character
{
	if (character == nil) {
		// Characterがnilの場合
		return OgreKindOfNil;
	}
	if ([character length] == 0) {
		// Characterが空文字列の場合
		return OgreKindOfEmpty;
	}
	// characterの1文字目
	NSString	*substr = [character substringWithRange:NSMakeRange(0,1)];
		
	if ([substr isEqualToString:@"\\"]) {
		// \の場合
		return OgreKindOfBackslash;
	}
		
	// 特殊文字でない場合
	return OgreKindOfNormal;
}

// 空白で単語をグループ分けする。例: @"alpha beta gamma" -> @"(alpha)|(beta)|(gamma)"
+ (NSString*)delimitByWhitespaceInString:(NSString*)string
{	
	if (string == nil) {
		// エラー。例外を発生させる。
		[NSException raise:OgreException format:@"nil string (or other) argument"];
	}

	NSMutableString	*expressionString = [NSMutableString stringWithString:@""];
	BOOL	first = YES;
	NSString	*scannedName;
	NSScanner	*scanner = [NSScanner scannerWithString:string];
	NSCharacterSet	*whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
	
	unsigned	counterOfAutorelease = 0;
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];

	while (![scanner isAtEnd]) {
        if ([scanner scanUpToCharactersFromSet:whitespaceCharacterSet intoString:&scannedName]) {
			if ([scannedName length] == 0) continue;
			if (first) {
				[expressionString appendString: [NSString stringWithFormat:@"(%@)", scannedName]];
				first = NO;
			} else {
				[expressionString appendString: [NSString stringWithFormat:@"|(%@)", scannedName]];
			}
        }
        [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:nil];
		
		counterOfAutorelease++;
		if (counterOfAutorelease % 100 == 0) {
			[pool release];
			pool = [[NSAutoreleasePool alloc] init];
		}
    }
	
	[pool release];
	
	//NSLog(@"%@", expressionString);
	return expressionString;
}

// 名前がnameのgroup number
// 存在しない名前の場合は-1を返す。
// 同一の名前を持つ部分文字列が複数ある場合は-2を返す。
- (NSInteger)groupIndexForName:(NSString*)name
{
	if (name == nil) {
		[NSException raise:NSInvalidArgumentException format:@"nil string (or other) argument"];
	}
	
	if (_groupIndexForNameDictionary == nil) return -1;
	
	NSArray	*array = [_groupIndexForNameDictionary objectForKey:name];
	if (array == nil) return -1;
	if ([array count] != 1) return -2;
	
	return [[array objectAtIndex:0] unsignedIntValue];
}

// index番目の部分文字列の名前
// 存在しない名前の場合は nil を返す。
- (NSString*)nameForGroupIndex:(NSUInteger)index
{
	if ( (_nameForGroupIndexArray == nil) || (index < 1) || (index > [_nameForGroupIndexArray count])) {
		return nil;
	}
	
	NSString	*name = [_nameForGroupIndexArray objectAtIndex:(index - 1)];
	if ([name length] == 0) return nil;	// @"" は nil に読み替える。
	
	return name;
}


@end
