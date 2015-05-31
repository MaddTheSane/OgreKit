/*
 * Name: OGRegularExpressionPrivate.h
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

#import <Foundation/Foundation.h>
#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGString.h>

@class OGRegularExpression;

typedef NS_ENUM(int, OgreKindOfCharacter) {
	OgreKindOfNil = -1,
	OgreKindOfEmpty, 
	OgreKindOfSpecial, 
	OgreKindOfBackslash, 
	OgreKindOfNormal
};

// Regular expression syntax (正規表現構文)
OnigSyntaxType  OgrePrivatePOSIXBasicSyntax;
OnigSyntaxType  OgrePrivatePOSIXExtendedSyntax;
OnigSyntaxType  OgrePrivateEmacsSyntax;
OnigSyntaxType  OgrePrivateGrepSyntax;
OnigSyntaxType  OgrePrivateGNURegexSyntax;
OnigSyntaxType  OgrePrivateJavaSyntax;
OnigSyntaxType  OgrePrivatePerlSyntax;
OnigSyntaxType  OgrePrivateRubySyntax;


@interface OGRegularExpression ()

/* Private method (非公開メソッド) */

// I return the OnigSyntaxType * corresponding to OgreSyntax. (OgreSyntaxに対応するOnigSyntaxType *を返す。)
+ (OnigSyntaxType *)onigSyntaxTypeForSyntax:(OgreSyntax)syntax;

// I return the string obtained by replacing the \ in string to character. If character is nil, returns a string. (string中の\をcharacterに置き換えた文字列を返す。characterがnilの場合、stringを返す。)
+ (id<OGStringProtocol>)changeEscapeCharacterInOGString:(id<OGStringProtocol>)string toCharacter:(NSString *)character;

// I return the character type of character. (characterの文字種を返す。)
/*
 戻り値:
  OgreKindOfNil			nil
  OgreKindOfEmpty		@""
  OgreKindOfBackslash	@"\\"
  OgreKindOfNormal		その他
 */
+ (OgreKindOfCharacter)kindOfCharacter:(NSString *)character;

// I grouped the words with a space. Example: @ "alpha beta gamma" -> @ "(alpha) | (beta) | (gamma)" (// 空白で単語をグループ分けする。例: @"alpha beta gamma" -> @"(alpha)|(beta)|(gamma)")
+ (NSString *)delimitByWhitespaceInString:(NSString *)string;

// oniguruma regular expression object
- (regex_t*)patternBuffer;

// Name of the name group number (名前がnameのgroup number)
// I return -1 in the case of a name that does not exist. (存在しない名前の場合は-1を返す。)
// If there are multiple sub-string with the same name I return -2. (同一の名前を持つ部分文字列が複数ある場合は-2を返す。)
- (int)groupIndexForName:(NSString *)name;
// The name of the index th substring (index番目の部分文字列の名前)
// I return nil if the name does not exist. (存在しない名前の場合は nil を返す。)
- (NSString *)nameForGroupIndex:(NSUInteger)index;


@end
