/*
 * Name: OGRegularExpressionEnumeratorPrivate.m
 * Project: OgreKit
 *
 * Creation Date: Sep 03 2003
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2020 Isao Sonobe, All rights reserved.
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

- (id) initWithOGString:(id<OGStringProtocol>)targetString 
	options:(unsigned)searchOptions 
	range:(NSRange)searchRange 
	regularExpression:(OGRegularExpression*)regex
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithOGString: of %@", [self className]);
#endif
	self = [super init];
	if (self) {
		// 検索対象文字列を保持
		// target stringをUTF16文字列に変換する。
		_targetString = [(NSObject*)targetString copy];
		NSString	*targetPlainString = [_targetString string];
        _lengthOfTargetString = [_targetString length];
        
        _UTF16TargetString = (unichar*)NSZoneMalloc([self zone], sizeof(unichar) * (_lengthOfTargetString + 4));	// +4はonigurumaのmemory access violation問題への対処療法
        if (_UTF16TargetString == NULL) {
            // メモリを確保できなかった場合、例外を発生させる。
            [self release];
            [NSException raise:NSMallocException format:@"fail to allocate a memory"];
        }
        [targetPlainString getCharacters:_UTF16TargetString range:NSMakeRange(0, _lengthOfTargetString)];
            
        /* DEBUG 
        {
            NSLog(@"TargetString: '%@'", _targetString);
            int     i, count = _lengthOfTargetString;
            unichar *utf16Chars = _UTF16TargetString;
            for (i = 0; i < count; i++) {
                NSLog(@"UTF16: %04x", *(utf16Chars + i));
            }
        }*/
        
		// 検索範囲
		_searchRange = searchRange;
		
		// 正規表現オブジェクトを保持
		_regex = [regex retain];
		
		// 検索オプション
		_searchOptions = searchOptions;
		
		/* 初期値設定 */
		// 最後にマッチした文字列の終端位置
		// 初期値 0
		// 値 >=  0 終端位置
		// 値 == -1 マッチ終了
		_terminalOfLastMatch = 0;
		
		// マッチ開始位置
		_startLocation = 0;
	
		// 前回のマッチが空文字列だったかどうか
		_isLastMatchEmpty = NO;
		
		// マッチした数
		_numberOfMatches = 0;
	}
	
	return self;
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

- (void)_setNumberOfMatches:(unsigned)aNumber
{
	_numberOfMatches = aNumber;
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
