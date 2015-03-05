/*
 * Name: OGRegularExpressionEnumeratorPrivate.m
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

#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGRegularExpressionPrivate.h>
#import <OgreKit/OGRegularExpressionMatch.h>
#import <OgreKit/OGRegularExpressionMatchPrivate.h>
#import <OgreKit/OGRegularExpressionEnumerator.h>
#import <OgreKit/OGRegularExpressionEnumeratorPrivate.h>
#import <OgreKit/OGString.h>


@implementation OGRegularExpressionEnumerator (Private)

- (id) initWithOGString:(NSObject<OGStringProtocol>*)targetString 
	options:(NSUInteger)searchOptions
	range:(NSRange)searchRange 
	regularExpression:(OGRegularExpression*)regex
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithOGString: of %@", [self className]);
#endif
	self = [super init];
	if (self) {
		// And hold the search string (検索対象文字列を保持)
		// I convert the target string to UTF16 string. (target stringをUTF16文字列に変換する。)
		_targetString = [targetString copy];
		NSString	*targetPlainString = [_targetString string];
        _lengthOfTargetString = [_targetString length];
        
        _UTF16TargetString = (unichar*)NSZoneMalloc([self zone], sizeof(unichar) * (_lengthOfTargetString + 4));	// Symptomatic treatment of +4 to memory access violation problem of oniguruma (+4はonigurumaのmemory access violation問題への対処療法)
        if (_UTF16TargetString == NULL) {
            // If it can not allocate memory, to generate an exception. (メモリを確保できなかった場合、例外を発生させる。)
            [self release];
            [NSException raise:NSMallocException format:@"fail to allocate a memory"];
        }
        [targetPlainString getCharacters:_UTF16TargetString range:NSMakeRange(0, _lengthOfTargetString)];
            
        /* DEBUG 
        {
            NSLog(@"TargetString: '%@'", _targetString);
            NSInteger i, count = _lengthOfTargetString;
            unichar *utf16Chars = _UTF16TargetString;
            for (i = 0; i < count; i++) {
                NSLog(@"UTF16: %04x", *(utf16Chars + i));
            }
        }*/
        
		// Search range (検索範囲)
		_searchRange = searchRange;
		
		// Keep regular expression object (正規表現オブジェクトを保持)
		_regex = [regex retain];
		
		// Search options (検索オプション)
		_searchOptions = searchOptions;
		
		/* Initial value setting (初期値設定) */
		// End position of the last matched string (最後にマッチした文字列の終端位置)
		// Initial value 0 (初期値 0)
		// Value> =   0 end position (値 >=  0 終端位置)
		// Value == -1 match end (値 == -1 マッチ終了)
		_terminalOfLastMatch = 0;
		
		// Match starting position (マッチ開始位置)
		_startLocation = 0;
	
		// Whether previous match was an empty string (前回のマッチが空文字列だったかどうか)
		_isLastMatchEmpty = NO;
		
		// Number of matches (マッチした数)
		_numberOfMatches = 0;
	}
	
	return self;
}

#ifdef MAC_OS_X_VERSION_10_6
- (void)finalize
{
#ifdef DEBUG_OGRE
	NSLog(@"-finalize of %@", [self className]);
#endif
	NSZoneFree([self zone], _UTF16TargetString);
    [super finalize];
}
#endif

- (void)dealloc
{
#ifdef DEBUG_OGRE
	NSLog(@"-dealloc of %@", [self className]);
#endif
	[_regex release];
	NSZoneFree([self zone], _UTF16TargetString);
	[_targetString release];
	
	[super dealloc];
}

/* accessors */
// private
- (void)_setTerminalOfLastMatch:(NSInteger)location
{
	_terminalOfLastMatch = location;
}

- (void)_setIsLastMatchEmpty:(BOOL)yesOrNo
{
	_isLastMatchEmpty = yesOrNo;
}

- (void)_setStartLocation:(NSUInteger)location
{
	_startLocation = location;
}

- (void)_setNumberOfMatches:(NSUInteger)aNumber
{
	_numberOfMatches = aNumber;
}

- (OGRegularExpression*)regularExpression
{
	return _regex;
}

- (void)setRegularExpression:(OGRegularExpression*)regularExpression
{
	[regularExpression retain];
	[_regex release];
	_regex = regularExpression;
}

// public?
- (NSObject<OGStringProtocol>*)targetString
{
	return _targetString;
}

- (unichar*)UTF16TargetString
{
	return _UTF16TargetString;
}

- (NSRange)searchRange
{
	return _searchRange;
}


@end
