/*
 * Name: OGRegularExpressionMatch.h
 * Project: OgreKit
 *
 * Creation Date: Aug 30 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>
#ifndef NOT_RUBY
#	define NOT_RUBY
#endif
#ifndef HAVE_CONFIG_H
#	define HAVE_CONFIG_H
#endif
#import <OgreKit/oniguruma.h>


// constant
extern NSString	* const OgreMatchException;


@class OGRegularExpression, OGRegularExpressionEnumerator, OGRegularExpressionCapture;
@protocol OGStringProtocol;

@interface OGRegularExpressionMatch : NSObject <NSCopying, NSCoding>
{
	OnigRegion		*_region;						// match result region
	OGRegularExpressionEnumerator	*_enumerator;	// matcher
	NSUInteger 		_terminalOfLastMatch;           // End position of the matched string in the previous (_region->end[0] / sizeof (unichar)) (前回にマッチした文字列の終端位置 (_region->end[0] / sizeof(unichar)))
	
    id<OGStringProtocol>	_targetString;		// Search target string (検索対象文字列)
	NSRange			_searchRange;					// Search range (検索範囲)
	NSUInteger		_index;							// matched order (マッチした順番)
}

/*********
 * 諸情報 *
 *********/
// Matched the order 0, 1, 2, ... (// マッチした順番 0,1,2,...)
@property (nonatomic, readonly) NSUInteger index;

// Number of substrings + 1 (部分文字列の数 + 1)
@property (nonatomic, readonly) NSUInteger count;


/*********
 * 文字列 *
 *********/
// String that became the match of subject (マッチの対象になった文字列)
@property (nonatomic, readonly, strong) NSObject<OGStringProtocol> *targetOGString;
@property (nonatomic, readonly, copy) NSString *targetString;
@property (nonatomic, readonly, copy) NSAttributedString *targetAttributedString;

// Matched string \&, \0 (// マッチした文字列 \&, \0)
@property (nonatomic, readonly, strong) id<OGStringProtocol> matchedOGString;
@property (nonatomic, readonly, copy) NSString *matchedString;
@property (nonatomic, readonly, copy) NSAttributedString *matchedAttributedString;

// Index th substring \index (// index番目のsubstring \index)
//  I return nil when the index th substring does not exist. (index番目のsubstringが存在しない時には nil を返す。)
- (id<OGStringProtocol>)ogSubstringAtIndex:(NSUInteger)index;
- (NSString *)substringAtIndex:(NSUInteger)index;
- (NSAttributedString *)attributedSubstringAtIndex:(NSUInteger)index;

// Matched before the substring \` (// マッチした部分より前の文字列 \`)
@property (nonatomic, readonly, strong) id<OGStringProtocol> prematchOGString;
@property (nonatomic, readonly, copy) NSString *prematchString;
@property (nonatomic, readonly, copy) NSAttributedString *prematchAttributedString;

// Matched behind substring \' (// マッチした部分より後ろの文字列 \')
@property (nonatomic, readonly, strong) id<OGStringProtocol> postmatchOGString;
@property (nonatomic, readonly, copy) NSString *postmatchString;
@property (nonatomic, readonly, copy) NSAttributedString *postmatchAttributedString;

// Last matched substring \+ (// 最後にマッチした部分文字列 \+)
// It returns nil when it does not exist. (存在しないときには nil を返す。)
@property (nonatomic, readonly, strong) id<OGStringProtocol> lastMatchOGSubstring;
@property (nonatomic, readonly, copy) NSString *lastMatchSubstring;
@property (nonatomic, readonly, copy) NSAttributedString *lastMatchAttributedSubstring;

// Matched between the part and the matched part before one string \- (own added) (マッチした部分と一つ前にマッチした部分の間の文字列 \- (独自に追加))
@property (nonatomic, readonly, strong) id<OGStringProtocol> ogStringBetweenMatchAndLastMatch;
@property (nonatomic, readonly, copy) NSString *stringBetweenMatchAndLastMatch;
@property (nonatomic, readonly, copy) NSAttributedString *attributedStringBetweenMatchAndLastMatch;


/*******
 * 範囲 *
 *******/
// Range of matched string (マッチした文字列の範囲)
@property (nonatomic, readonly) NSRange rangeOfMatchedString;

// range of index th substring (index番目のsubstringの範囲)
// when the index th substring does not exist I return {-1, 0}. (index番目のsubstringが存在しない時には {-1, 0} を返す。)
- (NSRange)rangeOfSubstringAtIndex:(NSUInteger)index;

// range of matched before the string than the portion (マッチした部分より前の文字列の範囲)
@property (nonatomic, readonly) NSRange rangeOfPrematchString;

// range than the matched part of the back of the string (マッチした部分より後ろの文字列の範囲)
@property (nonatomic, readonly) NSRange rangeOfPostmatchString;

// Finally range of matched substring (最後にマッチした部分文字列の範囲)
// When it does not exist it returns {-1, 0}. (存在しないときには {-1,0} を返す。)
@property (nonatomic, readonly) NSRange rangeOfLastMatchSubstring;

// Range of string between the matched part and matched part before one (マッチした部分と一つ前にマッチした部分の間の文字列の範囲)
@property (nonatomic, readonly) NSRange rangeOfStringBetweenMatchAndLastMatch;


/***************************************************************
 * named group関連 (OgreCaptureGroupOptionを指定したときに使用可能) *
 ***************************************************************/
// Substring of the name (label) is name (名前(ラベル)がnameの部分文字列)
// I return nil if the name does not exist. (存在しない名前の場合は nil を返す。)
// If there is more than one substring with the same name can raise an exception. (同一の名前を持つ部分文字列が複数ある場合は例外を発生させる。)
- (id<OGStringProtocol>)ogSubstringNamed:(NSString *)name;
- (NSString *)substringNamed:(NSString *)name;
- (NSAttributedString *)attributedSubstringNamed:(NSString *)name;

// Range name is a substring of the name (名前がnameの部分文字列の範囲)
// In the case of a name that does not exist I return the {-1, 0}. (存在しない名前の場合は {-1, 0} を返す。)
// If there is more than one substring with the same name can raise an exception. (同一の名前を持つ部分文字列が複数ある場合は例外を発生させる。)
- (NSRange)rangeOfSubstringNamed:(NSString *)name;

// Index name is a substring of the name (名前がnameの部分文字列のindex)
// I return -1 in the case of a name that does not exist. (存在しない名前の場合は -1 を返す。)
// If there is more than one substring with the same name can raise an exception. (同一の名前を持つ部分文字列が複数ある場合は例外を発生させる。)
- (NSInteger)indexOfSubstringNamed:(NSString *)name;

// The name of the index th substring (index番目の部分文字列の名前)
// I return nil if the name does not exist. (存在しない名前の場合は nil を返す。)
- (NSString *)nameOfSubstringAtIndex:(NSUInteger)index;

/***********************
* マッチした部分文字列を得る *
************************/
// (regEx1) | (regEx2) | ... a regular expression like, is useful when you want to conditional branch depending on whether you match any regEx *. ((regEx1)|(regEx2)|... のような正規表現で、どのregEx*にマッチしたかによって条件分岐する場合に便利。)
/* 使用例: 
	OGRegularExpression *regEx = [OGRegularExpression regularExpressionWithString:@"([0-9]+)|([a-zA-Z]+)"];
	NSEnumerator	*matchEnum = [regEx matchEnumeratorInString:@"123abc"];
	OGRegularExpressionMatch	*match;
	while ((match = [matchEnum nextObject]) != nil) {
		switch ([match indexOfFirstMatchedSubstring]) {
			case 1:
				NSLog(@"numbers");
				break;
			case 2:
				NSLog(@"alphabets");
				break;
		}
	}
*/
// Matched part one group number of the string is at a minimum (returns 0 if no) (マッチした部分文字列のうちグループ番号が最小のもの (ない場合は0を返す))
- (NSUInteger)indexOfFirstMatchedSubstring;
- (NSUInteger)indexOfFirstMatchedSubstringBeforeIndex:(NSUInteger)anIndex;
- (NSUInteger)indexOfFirstMatchedSubstringAfterIndex:(NSUInteger)anIndex;
- (NSUInteger)indexOfFirstMatchedSubstringInRange:(NSRange)aRange;
// That name (その名前)
@property (nonatomic, readonly, copy) NSString *nameOfFirstMatchedSubstring;
- (NSString *)nameOfFirstMatchedSubstringBeforeIndex:(NSUInteger)anIndex;
- (NSString *)nameOfFirstMatchedSubstringAfterIndex:(NSUInteger)anIndex;
- (NSString *)nameOfFirstMatchedSubstringInRange:(NSRange)aRange;

// Matched part group number of the string is a maximum of one (return 0 if no) (マッチした部分文字列のうちグループ番号が最大のもの (ない場合は0を返す))
@property (nonatomic, readonly) NSUInteger indexOfLastMatchedSubstring;
- (NSUInteger)indexOfLastMatchedSubstringBeforeIndex:(NSUInteger)anIndex;
- (NSUInteger)indexOfLastMatchedSubstringAfterIndex:(NSUInteger)anIndex;
- (NSUInteger)indexOfLastMatchedSubstringInRange:(NSRange)aRange;
// That name (その名前)
@property (nonatomic, readonly, copy) NSString *nameOfLastMatchedSubstring;
- (NSString *)nameOfLastMatchedSubstringBeforeIndex:(NSUInteger)anIndex;
- (NSString *)nameOfLastMatchedSubstringAfterIndex:(NSUInteger)anIndex;
- (NSString *)nameOfLastMatchedSubstringInRange:(NSRange)aRange;

// Matched the longest ones of the substring (if not it returns 0. If more than one of the same length, small ones are priority of numbers) (マッチした部分文字列のうち最長のもの (ない場合は0を返す。同じ長さの物が複数あれば、番号の小さい物が優先される))
@property (nonatomic, readonly) NSUInteger indexOfLongestSubstring;
- (NSUInteger)indexOfLongestSubstringBeforeIndex:(NSUInteger)anIndex;
- (NSUInteger)indexOfLongestSubstringAfterIndex:(NSUInteger)anIndex;
- (NSUInteger)indexOfLongestSubstringInRange:(NSRange)aRange;
// That name (その名前)
@property (nonatomic, readonly, copy) NSString *nameOfLongestSubstring;
- (NSString *)nameOfLongestSubstringBeforeIndex:(NSUInteger)anIndex;
- (NSString *)nameOfLongestSubstringAfterIndex:(NSUInteger)anIndex;
- (NSString *)nameOfLongestSubstringInRange:(NSRange)aRange;

// Matched shortest ones of the substring (if not it returns 0. If more than one of the same length, small ones are priority of numbers) (マッチした部分文字列のうち最短のもの (ない場合は0を返す。同じ長さの物が複数あれば、番号の小さい物が優先される))
@property (nonatomic, readonly) NSUInteger indexOfShortestSubstring;
- (NSUInteger)indexOfShortestSubstringBeforeIndex:(NSUInteger)anIndex;
- (NSUInteger)indexOfShortestSubstringAfterIndex:(NSUInteger)anIndex;
- (NSUInteger)indexOfShortestSubstringInRange:(NSRange)aRange;
// That name (その名前)
@property (nonatomic, readonly, copy) NSString *nameOfShortestSubstring;
- (NSString *)nameOfShortestSubstringBeforeIndex:(NSUInteger)anIndex;
- (NSString *)nameOfShortestSubstringAfterIndex:(NSUInteger)anIndex;
- (NSString *)nameOfShortestSubstringInRange:(NSRange)aRange;

/******************
* Capture History *
*******************/
/*例:
	NSString					*target = @"abc de";
	OGRegularExpression			*regEx = [OGRegularExpression regularExpressionWithString:@"(?@[a-z])+"];
	OGRegularExpressionMatch	*match;
    OGRegularExpressionCapture  *capture;
	NSEnumerator				*matchEnumerator = [regEx matchEnumeratorInString:target];
	NSUInteger					i;
	
	while ((match = [matchEnumerator nextObject]) != nil) {
		capture = [match captureHistory];
		NSLog(@"number of capture history: %lu", (long unsigned)[capture numberOfChildren]);
		for (i = 0; i < [capture numberOfChildren]; i++) 
            NSLog(@" %@", [[capture childAtIndex:i] string]);
	}
	
ログ:
number of capture history: 3
 a
 b
 c
number of capture history: 2
 d
 e
 */

// Capture history (捕獲履歴)
// I return nil if there is no history. (履歴がない場合はnilを返す。)
@property (nonatomic, readonly, copy) OGRegularExpressionCapture *captureHistory;

@end

// I get the length of UTF16 string (UTF16文字列の長さを得る)
inline size_t Ogre_UTF16strlen(unichar *const aUTF16string, unichar *const end);
