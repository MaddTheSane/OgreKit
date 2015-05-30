/*
 * Name: OGRegularExpressionEnumerator.h
 * Project: OgreKit
 *
 * Creation Date: Sep 03 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>
#import <OgreKit/OGRegularExpression.h>

NS_ASSUME_NONNULL_BEGIN

// Exception
extern NSString	* const OgreEnumeratorException;

@interface OGRegularExpressionEnumerator : NSEnumerator <NSCopying, NSCoding>
{
	OGRegularExpression	*_regex;				// Regular expression object (正規表現オブジェクト)
	NSObject<OGStringProtocol>			*_targetString;			// Search target string (検索対象文字列)
	unichar             *_UTF16TargetString;	// Search for a string in UTF16 (UTF16での検索対象文字列)
	NSUInteger			_lengthOfTargetString;	// [_targetString length]
	NSRange				_searchRange;			// Search range (検索範囲)
	OgreOption			_searchOptions;			// Search options (検索オプション)
	NSInteger 			_terminalOfLastMatch; 	// End position of the matched string in the last   (_region->end[0] / sizeof (unichar)) (前回にマッチした文字列の終端位置  (_region->end[0] / sizeof(unichar)))
	NSUInteger			_startLocation;			// Match starting position (マッチ開始位置)
	BOOL				_isLastMatchEmpty;		// Whether previous match was an empty string (前回のマッチが空文字列だったかどうか)
	
	NSUInteger			_numberOfMatches;		// Number of matches (マッチした数)
}

// I return all the match results in the array. (全マッチ結果を配列で返す。)
@property (nonatomic, readonly, copy, nullable) NSArray *allObjects;
// I return the next match result. (次のマッチ結果を返す。)
- (nullable id)nextObject;

// description
@property (nonatomic, readonly, copy) NSString *description;

@end

NS_ASSUME_NONNULL_END
