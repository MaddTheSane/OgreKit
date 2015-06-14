/*
 * Name: OGRegularExpressionEnumerator.m
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
#import <OgreKit/OGRegularExpressionMatch.h>
#import <OgreKit/OGRegularExpressionEnumerator.h>
#import <OgreKit/OGRegularExpressionPrivate.h>
#import <OgreKit/OGRegularExpressionMatchPrivate.h>
#import <OgreKit/OGRegularExpressionEnumeratorPrivate.h>
#import <OgreKit/OGString.h>


// Key for encoding/decoding itself (自身をencoding/decodingするためのkey)
static NSString	* const OgreRegexKey               = @"OgreEnumeratorRegularExpression";
static NSString	* const OgreSwappedTargetStringKey = @"OgreEnumeratorSwappedTargetString";
static NSString	* const OgreStartOffsetKey         = @"OgreEnumeratorStartOffset";
static NSString	* const OgreStartLocationKey       = @"OgreEnumeratorStartLocation";
static NSString	* const OgreTerminalOfLastMatchKey = @"OgreEnumeratorTerminalOfLastMatch";
static NSString	* const OgreIsLastMatchEmptyKey    = @"OgreEnumeratorIsLastMatchEmpty";
static NSString	* const OgreOptionsKey             = @"OgreEnumeratorOptions";
static NSString	* const OgreNumberOfMatchesKey     = @"OgreEnumeratorNumberOfMatches";

NSString	* const OgreEnumeratorException = @"OGRegularExpressionEnumeratorException";

@implementation OGRegularExpressionEnumerator
@synthesize regularExpression = _regex;

// Find Next (次を検索)
- (id)nextObject
{
	OnigPosition		r;
	unichar             *start, *range, *end;
	OnigRegion			*region;
	id					match = nil;
	NSUInteger			UTF16charlen = 0;
	
	/* Scheduled to be rewritten entirely (全面的に書き直す予定) */
	if ( _terminalOfLastMatch == -1 ) {
		// Match end (マッチ終了)
		return nil;
	}
	
	start = _UTF16TargetString + _startLocation; // search start address of target string
	end = _UTF16TargetString + _lengthOfTargetString; // terminate address of target string
	range = end;	// search terminate address of target string
	if (start > range) {
		// If there is no more search range (これ以上検索範囲のない場合)
		_terminalOfLastMatch = -1;
		return nil;
	}
	
	// compile option (I deal with OgreFindNotEmptyOption separately) (compileオプション(OgreFindNotEmptyOptionを別に扱う))
	BOOL	findNotEmpty;
	if (([_regex options] & OgreFindNotEmptyOption) == 0) {
		findNotEmpty = NO;
	} else {
		findNotEmpty = YES;
	}
	
	// search option (I deal with OgreFindNotEmptyOption separately) (searchオプション(OgreFindEmptyOptionを別に扱う))
	BOOL		findEmpty;
	OgreOption	searchOptions;
	if ((_searchOptions & OgreFindEmptyOption) == 0) {
		findEmpty = NO;
		searchOptions = _searchOptions;
	} else {
		findEmpty = YES;
		searchOptions = _searchOptions & ~OgreFindEmptyOption;  // turn off OgreFindEmptyOption
	}
	
	// Creating a region (regionの作成)
	region = onig_region_new();
	if ( region == NULL ) {
		// If it can not allocate memory, to generate an exception. (メモリを確保できなかった場合、例外を発生させる。)
		[NSException raise:NSMallocException format:@"fail to create a region"];
	}
	
	/* Search (検索) */
	regex_t*	regexBuffer = [_regex patternBuffer];
	
	@autoreleasepool {
	
	if (!findNotEmpty) {
		/* If you allow the match to empty string (空文字列へのマッチを許す場合) */
		r = onig_search(regexBuffer, (unsigned char *)_UTF16TargetString, (unsigned char *)end, (unsigned char *)start, (unsigned char *)range, region, (OnigOptionType)searchOptions);
		
		// if the OgreFindEmptyOption is not specified, (OgreFindEmptyOptionが指定されていない場合で、)
		// In match other than the last empty string, when it is matched to the current empty string, attempts to again match is shifted one character. (前回空文字列以外にマッチして、今回空文字列にマッチした場合、1文字ずらしてもう1度マッチを試みる。)
		if (!findEmpty && (!_isLastMatchEmpty) && (r >= 0) && (region->beg[0] == region->end[0]) && (_startLocation > 0)) {
			if (start < range) {
				UTF16charlen = Ogre_UTF16charlen(_UTF16TargetString + _startLocation);
				_startLocation += UTF16charlen; // I advanced by one character (1文字進める)
				start = _UTF16TargetString + _startLocation;
				r = onig_search(regexBuffer, (unsigned char *)_UTF16TargetString, (unsigned char *)end, (unsigned char *)start, (unsigned char *)range, region, (OnigOptionType)searchOptions);
			} else {
				r = ONIG_MISMATCH;
			}
		}
		
	} else {
		/* If you do not allow the match to the empty string (空文字列へのマッチを許さない場合) */
		while (TRUE) {
			r = onig_search(regexBuffer, (unsigned char *)_UTF16TargetString, (unsigned char *)end, (unsigned char *)start, (unsigned char *)range, region, (OnigOptionType)searchOptions);
			if ((r >= 0) && (region->beg[0] == region->end[0]) && (start < range)) {
				// If you match the empty string (空文字列にマッチした場合)
				UTF16charlen = Ogre_UTF16charlen(_UTF16TargetString + _startLocation);
				_startLocation += UTF16charlen;	// I advanced by one character (1文字進める)
				start = _UTF16TargetString + _startLocation;
			} else {
				// If you fail to match if you match the other case, an empty string that can not proceed any more (これ以上進めない場合・空文字列以外にマッチした場合・マッチに失敗した場合)
				break;
			}
		
		}
		if ((r >= 0) && (region->beg[0] == region->end[0]) && (start >= range)) {
			// Finally if you match the empty string. I and mismatch handling. (最後に空文字列にマッチした場合。ミスマッチ扱いとする。)
			r = ONIG_MISMATCH;
		}
	}
	
	}
	
	if (r >= 0) {
        // If you match (マッチした場合)
        // Creating a match object (matchオブジェクトの作成)
		match = [[OGRegularExpressionMatch allocWithZone:nil]
				initWithRegion: region
				index: _numberOfMatches
				enumerator: self
				terminalOfLastMatch: _terminalOfLastMatch
			];
		
		_numberOfMatches++;	// And increase the number of matches (マッチ数を増加)
		
		/* End position of the matched string (マッチした文字列の終端位置) */
		if ( (r == _lengthOfTargetString * sizeof(unichar)) && (r == region->end[0]) ) {
			_terminalOfLastMatch = -1;	// If was finally matches the empty string, it does not match any more. (最後に空文字列にマッチした場合は、これ以上マッチしない。)
			_isLastMatchEmpty = YES;	// You will not need, but just to be sure. (いらないだろうが念のため。)

			return match;
		} else {
			_terminalOfLastMatch = region->end[0] / sizeof(unichar);	// End position of the last matched string (最後にマッチした文字列の終端位置)
		}

		/* I ask for the next match starting position (次回のマッチ開始位置を求める) */
		_startLocation = _terminalOfLastMatch;
		
		/* Starting position in UTF16String (UTF16Stringでの開始位置) */
		if (r == region->end[0]) {
			// If you match the empty string, to advance the next match starting position one character destination. (空文字列にマッチした場合、次回のマッチ開始位置を1文字先に進める。)
			_isLastMatchEmpty = YES;
			UTF16charlen = Ogre_UTF16charlen(_UTF16TargetString + _terminalOfLastMatch);
			_startLocation += UTF16charlen;
		} else {
			// Not proceed if it is not empty. (空でなかった場合は進めない。)
			_isLastMatchEmpty = NO;
		}
		
		return match;
	}
	
	onig_region_free(region, 1 /* free all */);	// And open the region of unmatched string. (マッチしなかった文字列のregionを開放。)
	
	if (r == ONIG_MISMATCH) {
		// If you do not match (マッチしなかった場合)
		_terminalOfLastMatch = -1;
	} else {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		unsigned char s[ONIG_MAX_ERROR_MESSAGE_LEN];
		onig_error_code_to_str(s, r);
		[NSException raise:OgreEnumeratorException format:@"%s", s];
	}
	return nil;	// If you do not match (マッチしなかった場合)
}

- (NSArray *)allObjects
{	
#ifdef DEBUG_OGRE
	NSLog(@"-allObjects of %@", [self className]);
#endif

	NSMutableArray	*matchArray = [NSMutableArray arrayWithCapacity:10];

	NSInteger	orgTerminalOfLastMatch = _terminalOfLastMatch;
	BOOL		orgIsLastMatchEmpty = _isLastMatchEmpty;
	NSUInteger	orgStartLocation = _startLocation;
	NSUInteger	orgNumberOfMatches = _numberOfMatches;
	
	_terminalOfLastMatch = 0;
	_isLastMatchEmpty = NO;
	_startLocation = 0;
	_numberOfMatches = 0;
	
	@autoreleasepool {
	OGRegularExpressionMatch	*match;
	NSInteger                   matches = 0;
	while ( (match = [self nextObject]) != nil ) {
		[matchArray addObject:match];
		matches++;
	}
	
	_terminalOfLastMatch = orgTerminalOfLastMatch;
	_isLastMatchEmpty = orgIsLastMatchEmpty;
	_startLocation = orgStartLocation;
	_numberOfMatches = orgNumberOfMatches;

	if (matches == 0) {
		// not found
		return nil;
	} else {
		// found something
		return matchArray;
	}
	}
}

// NSCoding protocols
- (void)encodeWithCoder:(NSCoder *)encoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-encodeWithCoder: of %@", [self className]);
#endif
	// [super encodeWithCoder:encoder]; NSObject doesn’t respond to method encodeWithCoder:)
	
	//OGRegularExpression	*_regex;							// Regular expression object (正規表現オブジェクト)
	//NSString				*_TargetString;				// Search target string (検索対象文字列)
	//NSRange				_searchRange;						// Search range (検索範囲)
	//NSUInteger            _searchOptions;						// Search options (検索オプション)
	//int					_terminalOfLastMatch;               // End position of the matched string in the previous (_region->end[0] / sizeof (unichar)) (前回にマッチした文字列の終端位置 (_region->end[0] / sizeof(unichar)))
	//NSUInteger            _startLocation;						// Match starting position (マッチ開始位置)
	//BOOL					_isLastMatchEmpty;					// Whether previous match was an empty string (前回のマッチが空文字列だったかどうか)
    //NSUInteger            _numberOfMatches;                   // Number of matches (マッチした数)
    
    if ([encoder allowsKeyedCoding]) {
		[encoder encodeObject: _regex forKey: OgreRegexKey];
		[encoder encodeObject: _targetString forKey: OgreSwappedTargetStringKey];
		[encoder encodeInteger: _searchRange.location forKey: OgreStartOffsetKey];
		[encoder encodeObject: @(_searchOptions) forKey: OgreOptionsKey];
		[encoder encodeObject: @(_terminalOfLastMatch) forKey: OgreTerminalOfLastMatchKey];
		[encoder encodeObject: @(_startLocation) forKey: OgreStartLocationKey];
		[encoder encodeObject: @(_isLastMatchEmpty) forKey: OgreIsLastMatchEmptyKey];
		[encoder encodeObject: @(_numberOfMatches) forKey: OgreNumberOfMatchesKey];
	} else {
		[encoder encodeObject: _regex];
		[encoder encodeObject: _targetString];
		[encoder encodeObject: @(_searchRange.location)];
		[encoder encodeObject: @(_searchOptions)];
		[encoder encodeObject: @(_terminalOfLastMatch)];
		[encoder encodeObject: @(_startLocation)];
		[encoder encodeObject: @(_isLastMatchEmpty)];
		[encoder encodeObject: @(_numberOfMatches)];
	}
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithCoder: of %@", [self className]);
#endif
	self = [super init];	// NSObject does ont respond to method initWithCoder:
	if (self == nil) return nil;
	
	id		anObject;	
	BOOL	allowsKeyedCoding = [decoder allowsKeyedCoding];


	//OGRegularExpression	*_regex;							// Regular expression object (正規表現オブジェクト)
    if (allowsKeyedCoding) {
		_regex = [decoder decodeObjectForKey: OgreRegexKey];
	} else {
		_regex = [decoder decodeObject];
	}
	if (_regex == nil) {
        // Error. I raise an exception. (エラー。例外を発生させる。)
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
        return nil;
	}
	
	
	//NSString			*_targetString;				// Search target string. ¥ is reversed (things there) Caution (検索対象文字列。¥が入れ替わっている(事がある)ので注意)
	//unichar           *_UTF16TargetString;			// Search for a string in UTF16 (UTF16での検索対象文字列)
	//NSUInteger        _lengthOfTargetString;       // [_targetString length]
    if (allowsKeyedCoding) {
		_targetString = [decoder decodeObjectForKey: OgreSwappedTargetStringKey];	// Not a [self targetString]. ([self targetString]ではない。)
	} else {
		_targetString = [decoder decodeObject];
	}
	if (_targetString == nil) {
        // Error. I raise an exception. (エラー。例外を発生させる。)
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
        return nil;
	}
	NSString	*targetPlainString = [_targetString string];
	_lengthOfTargetString = [targetPlainString length];
    
	_UTF16TargetString = (unichar *)malloc(sizeof(unichar) * _lengthOfTargetString);
    if (_UTF16TargetString == NULL) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
        [NSException raise:NSInvalidUnarchiveOperationException format:@"fail to allocate a memory"];
        return nil;
    }
    [targetPlainString getCharacters:_UTF16TargetString range:NSMakeRange(0, _lengthOfTargetString)];
	
	// NSRange				_searchRange;						// Search range (検索範囲)
    if (allowsKeyedCoding) {
		_searchRange.location = [decoder decodeIntegerForKey: OgreStartOffsetKey];
	} else {
		anObject = [decoder decodeObject];
        if (anObject == nil) {
            // Error. I raise an exception. (エラー。例外を発生させる。)
            [NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
            return nil;
        }
        _searchRange.location = [anObject unsignedIntegerValue];
	}
	_searchRange.length = _lengthOfTargetString;
	
	
	
	// 	_searchOptions;			// Search options (検索オプション)
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreOptionsKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
        return nil;
	}
	_searchOptions = [anObject unsignedIntValue];
	
	
	// int	_terminalOfLastMatch;	// End position of the matched string in the previous (_region->end[0] / sizeof (unichar)) (前回にマッチした文字列の終端位置 (_region->end[0] / sizeof(unichar)))
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreTerminalOfLastMatchKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
        return nil;
	}
	_terminalOfLastMatch = [anObject integerValue];
	
	
	//			_startLocation;						// Match starting position (マッチ開始位置)
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreStartLocationKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
        return nil;
	}
	_startLocation = [anObject unsignedIntegerValue];
    	

	//BOOL				_isLastMatchEmpty;					// Whether previous match was an empty string (前回のマッチが空文字列だったかどうか)
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreIsLastMatchEmptyKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
        return nil;
	}
	_isLastMatchEmpty = [anObject boolValue];
	
	
	//	unsigned			_numberOfMatches;					// Number of matches (マッチした数)
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreNumberOfMatchesKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
        return nil;
	}
	_numberOfMatches = [anObject unsignedIntegerValue];
	
	
	return self;
}


// NSCopying protocol
- (id)copyWithZone:(NSZone *)zone
{
#ifdef DEBUG_OGRE
	NSLog(@"-copyWithZone: of %@", [self className]);
#endif
	id	newObject = [[[self class] allocWithZone:zone] 
			initWithOGString: _targetString 
			options: _searchOptions
			range: _searchRange 
			regularExpression: _regex];
			
	// Set of values (値のセット)
	[newObject _setTerminalOfLastMatch: _terminalOfLastMatch];
	[newObject _setStartLocation: _startLocation];
	[newObject _setIsLastMatchEmpty: _isLastMatchEmpty];
	[newObject _setNumberOfMatches: _numberOfMatches];

	return newObject;
}

// description
- (NSString *)description
{
	NSDictionary	*dictionary = @{
            @"Regular Expression": _regex,
            @"Target String": _targetString,
			@"Search Range": [NSString stringWithFormat:@"(%lu, %lu)", (unsigned long)_searchRange.location, (unsigned long)_searchRange.length], 
			@"Options": [[_regex class] stringsForOptions:_searchOptions], 
			@"Terminal of the Last Match": @(_terminalOfLastMatch), 
			@"Start Location of the Next Search": @(_startLocation), 
			@"Was the Last Match Empty": (_isLastMatchEmpty? @"YES" : @"NO"), 
			@"Number Of Matches": @(_numberOfMatches)};
		
	return [dictionary description];
}

- (id) initWithOGString:(NSObject<OGStringProtocol>*)targetString
				options:(OgreOption)searchOptions
				  range:(NSRange)searchRange
	  regularExpression:(OGRegularExpression *)regex
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
        
        _UTF16TargetString = (unichar *)malloc(sizeof(unichar) * (_lengthOfTargetString + 4));	// Symptomatic treatment of +4 to memory access violation problem of oniguruma (+4はonigurumaのmemory access violation問題への対処療法)
        if (_UTF16TargetString == NULL) {
            // If it can not allocate memory, to generate an exception. (メモリを確保できなかった場合、例外を発生させる。)
            [NSException raise:NSMallocException format:@"fail to allocate a memory"];
            return nil;
        }
        [targetPlainString getCharacters:_UTF16TargetString range:NSMakeRange(0, _lengthOfTargetString)];
        
        /* DEBUG
         {
         NSLog(@"TargetString: '%@'", _targetString);
         NSInteger i, count = _lengthOfTargetString;
         unichar *utf16Chars = _UTF16TargetString;
         for (i = 0; i < count; i++) {
         NSLog(@"UTF16: %04x", utf16Chars[i]);
         }
         }*/
        
        // Search range (検索範囲)
        _searchRange = searchRange;
        
        // Keep regular expression object (正規表現オブジェクトを保持)
        _regex = regex;
        
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

- (void)dealloc
{
#ifdef DEBUG_OGRE
	NSLog(@"-dealloc of %@", [self className]);
#endif
	free(_UTF16TargetString);
}

#pragma mark - private functions
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

// public?
- (id<OGStringProtocol>)targetString
{
	return _targetString;
}

- (unichar *)UTF16TargetString
{
	return _UTF16TargetString;
}

- (NSRange)searchRange
{
	return _searchRange;
}

@end
