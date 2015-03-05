/*
 * Name: OGRegularExpressionPrivate.m
 * Project: OgreKit
 *
 * Creation Date: Sep 01 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
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
#import <OgreKit/oniguruma.h>

#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGRegularExpressionPrivate.h>
#import <OgreKit/OGString.h>
#import <OgreKit/OGMutableString.h>


@implementation OGRegularExpression (Private)

/* Private method (非公開メソッド) */

#ifdef MAC_OS_X_VERSION_10_6
- (void)finalize
{
#ifdef DEBUG_OGRE
	NSLog(@"-finalize of %@", [self className]);
#endif
	// Oniguruma regular expression object (鬼車正規表現オブジェクト)
	if (_regexBuffer != NULL) onig_free(_regexBuffer);
	
	// A string that represents the regular expression (正規表現を表す文字列)
    NSZoneFree([self zone], _UTF16ExpressionString);
    [super finalize];
}
#endif

- (void)dealloc
{
#ifdef DEBUG_OGRE
	NSLog(@"-dealloc of %@", [self className]);
#endif
	// named group (reverse) dictionary (named group(逆引き)辞書)
	[_groupIndexForNameDictionary release];
	[_nameForGroupIndexArray release];
	
	// Oniguruma regular expression object (鬼車正規表現オブジェクト)
	if (_regexBuffer != NULL) onig_free(_regexBuffer);
	
	// A string that represents the regular expression (正規表現を表す文字列)
    NSZoneFree([self zone], _UTF16ExpressionString);
	[_expressionString release];
	
	// ¥ alternate character (¥の代替文字)
	[_escapeCharacter release];
	
	[super dealloc];
}

// oniguruma regular expression buffer
- (regex_t*)patternBuffer
{
	return _regexBuffer;
}

// I return the OnigSyntaxType * corresponding to OgreSyntax. (OgreSyntaxに対応するOnigSyntaxType*を返す。)
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

// I return a string replaced in string ¥ to the character. If character is nil, returns a string. (string中の¥をcharacterに置き換えた文字列を返す。characterがnilの場合、stringを返す。)
+ (NSObject<OGStringProtocol>*)changeEscapeCharacterInOGString:(NSObject<OGStringProtocol>*)string toCharacter:(NSString*)character
{
	if ( (character == nil) || (string == nil) || ([character length] == 0) ) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		[NSException raise:NSInvalidArgumentException format:@"nil string (or other) argument"];
	}
	
	if ([character isEqualToString:OgreBackslashCharacter]) {
		return string;
	}
	
	NSString	*plainString = [string string];
	NSUInteger	strLength = [plainString length];
	NSRange		scanRange = NSMakeRange(0, strLength);	// Range to be scanned (スキャンする範囲)
	NSRange		matchRange;					// discovered range of escape (length is always 1) (escapeの発見された範囲(lengthは常に1))
	
	/* escape character set */
	NSCharacterSet	*swapCharSet = [NSCharacterSet characterSetWithCharactersInString:
		[OgreBackslashCharacter stringByAppendingString:character]];
	
	NSObject<OGStringProtocol,OGMutableStringProtocol>	*resultString;
	resultString = [[[[string mutableClass] alloc] init] autorelease];
	
	NSUInteger			counterOfAutorelease = 0;
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	while ( matchRange = [plainString rangeOfCharacterFromSet:swapCharSet options:0 range:scanRange], 
			matchRange.length > 0 ) {
		NSUInteger	lastMatchLocation = scanRange.location;
		[resultString appendOGString:[string substringWithRange:NSMakeRange(lastMatchLocation, matchRange.location - lastMatchLocation)]];
		
		if ([[plainString substringWithRange:matchRange] isEqualToString:OgreBackslashCharacter]) {
			// ¥ -> ¥¥ .
			[resultString appendOGString:[string substringWithRange:matchRange]];
			[resultString appendOGString:[string substringWithRange:matchRange]];
			scanRange.location = matchRange.location + 1;
		} else {
			if (matchRange.location + 1 < strLength && [[plainString substringWithRange:NSMakeRange(matchRange.location + 1, 1)] isEqualToString:character]) {
				// ¥¥ -> ¥ .
				[resultString appendOGString:[string substringWithRange:matchRange]];
				scanRange.location = matchRange.location + 2;
			} else {
				// ¥(?=[^¥]) -> ¥ .
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

// I return the character type of character. (characterの文字種を返す。)
/*
 Returns:
  OgreKindOfNil			character == nil
  OgreKindOfEmpty		empty @""
  OgreKindOfBackslash	¥ @"¥¥"
  OgreKindOfNormal		other
 
 戻り値:
  OgreKindOfNil			character == nil
  OgreKindOfEmpty		空文字 @""
  OgreKindOfBackslash	¥ @"¥¥"
  OgreKindOfNormal		その他
 */
+ (OgreKindOfCharacter)kindOfCharacter:(NSString*)character
{
	if (character == nil) {
		// If character is nil (Characterがnilの場合)
		return OgreKindOfNil;
	}
	if ([character length] == 0) {
		// If character is an empty string (Characterが空文字列の場合)
		return OgreKindOfEmpty;
	}
	// The first character of the character (characterの1文字目)
	NSString	*substr = [character substringWithRange:NSMakeRange(0,1)];
		
	if ([substr isEqualToString:@"¥¥"]) {
		// In the case of ¥ (¥の場合)
		return OgreKindOfBackslash;
	}
		
	// If it is not a special character (特殊文字でない場合)
	return OgreKindOfNormal;
}

// I grouped the words with a space. Example: @ "alpha beta gamma" -> @ "(alpha) | (beta) | (gamma)" (// 空白で単語をグループ分けする。例: @"alpha beta gamma" -> @"(alpha)|(beta)|(gamma)")
+ (NSString*)delimitByWhitespaceInString:(NSString*)string
{	
	if (string == nil) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		[NSException raise:OgreException format:@"nil string (or other) argument"];
	}

	NSMutableString	*expressionString = [NSMutableString stringWithString:@""];
	BOOL	first = YES;
	NSString	*scannedName;
	NSScanner	*scanner = [NSScanner scannerWithString:string];
	NSCharacterSet	*whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
	
	NSUInteger	counterOfAutorelease = 0;
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

// Name of the name group number (// 名前がnameのgroup number)
// I return -1 in the case of a name that does not exist. (存在しない名前の場合は-1を返す。)
// If there are multiple sub-string with the same name I return -2. (同一の名前を持つ部分文字列が複数ある場合は-2を返す。)
- (NSInteger)groupIndexForName:(NSString*)name
{
	if (name == nil) {
		[NSException raise:NSInvalidArgumentException format:@"nil string (or other) argument"];
	}
	
	if (_groupIndexForNameDictionary == nil) return -1;
	
	NSArray	*array = _groupIndexForNameDictionary[name];
	if (array == nil) return -1;
	if ([array count] != 1) return -2;
	
	return [array[0] unsignedIntegerValue];
}

// The name of the index th substring (index番目の部分文字列の名前)
// I return nil if the name does not exist. (存在しない名前の場合は nil を返す。)
- (NSString*)nameForGroupIndex:(NSUInteger)index
{
	if ( (_nameForGroupIndexArray == nil) || (index < 1) || (index > [_nameForGroupIndexArray count])) {
		return nil;
	}
	
	NSString	*name = _nameForGroupIndexArray[(index - 1)];
	if ([name length] == 0) return nil;	// @ "" I read to nil. (@"" は nil に読み替える。)
	
	return name;
}


@end
