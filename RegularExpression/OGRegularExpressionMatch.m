/*
 * Name: OGRegularExpressionMatch.m
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

#ifndef NOT_RUBY
#	define NOT_RUBY
#endif
#ifndef HAVE_CONFIG_H
#	define HAVE_CONFIG_H
#endif
#import <OgreKit/oniguruma.h>

#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGRegularExpressionPrivate.h>
#import <OgreKit/OGRegularExpressionMatch.h>
#import <OgreKit/OGRegularExpressionMatchPrivate.h>
#import <OgreKit/OGRegularExpressionEnumerator.h>
#import <OgreKit/OGRegularExpressionEnumeratorPrivate.h>
#import <OgreKit/OGRegularExpressionCapture.h>
#import <OgreKit/OGRegularExpressionCapturePrivate.h>
#import <OgreKit/OGString.h>


NSString	* const OgreMatchException = @"OGRegularExpressionMatchException";

// Key for encoding/decoding itself (自身をencoding/decodingするためのkey)
static NSString	* const OgreRegionKey              = @"OgreMatchRegion";
static NSString	* const OgreEnumeratorKey          = @"OgreMatchEnumerator";
static NSString	* const OgreTerminalOfLastMatchKey = @"OgreMatchTerminalOfLastMatch";
static NSString	* const OgreIndexOfMatchKey        = @"OgreMatchIndexOfMatch";
static NSString	* const OgreCaptureHistoryKey      = @"OgreMatchCaptureHistory";


inline size_t Ogre_UTF16strlen(unichar *const aUTF16string, unichar *const end)
{
	return end - aUTF16string;
}

static NSArray *Ogre_arrayWithOnigRegion(OnigRegion *region)
{
	if (region == NULL) return nil;
	
	NSMutableArray      *regionArray = [NSMutableArray arrayWithCapacity:1];
	NSUInteger          i = 0, n = region->num_regs;
	
	for( i = 0; i < n; i++ ) {
		[regionArray addObject:@[@(region->beg[i]),
			@(region->end[i])]];
	}
	
	return regionArray;
}

static OnigRegion *Ogre_onigRegionWithArray(NSArray *regionArray)
{
	if (regionArray == nil) return NULL;
	
	OnigRegion		*region = onig_region_new();
	if (region == NULL) {
		// If it can not allocate memory, to generate an exception. (メモリを確保できなかった場合、例外を発生させる。)
		[NSException raise:NSMallocException format:@"fail to memory allocation"];
	}
	NSUInteger		i = 0, n = [regionArray count];
	NSArray			*anObject;
	NSInteger				r;
	
	r = onig_region_resize(region, (int)[regionArray count]);
	if (r != ONIG_NORMAL) {
		// If it can not allocate memory, to generate an exception. (メモリを確保できなかった場合、例外を発生させる。)
		onig_region_free(region, 1);
		[NSException raise:NSMallocException format:@"fail to memory allocation"];
	}

	for (i = 0; i < n; i++) {
        anObject = regionArray[i];
		region->beg[i] = [anObject[0] unsignedIntegerValue];
		region->end[i] = [anObject[1] unsignedIntegerValue];
	}
    
    region->history_root = NULL;
	
	return region;
}

static NSArray *Ogre_arrayWithOnigCaptureTreeNode(OnigCaptureTreeNode *cap)
{
	if (cap == NULL) return @[];
	
	unsigned            i, n = cap->num_childs;
	NSMutableArray      *children = [[NSMutableArray alloc] initWithCapacity:n];
    
    if (n > 0) {
        for(i = 0; i < n; i++) [children addObject:Ogre_arrayWithOnigCaptureTreeNode(cap->childs[i])];
    }
    
    return @[@(cap->group),
             @(cap->beg),
             @(cap->end),
             children];
}

static OnigCaptureTreeNode *Ogre_onigCaptureTreeNodeWithArray(NSArray *captureArray)
{
    if (captureArray == nil || [captureArray count] == 0) return NULL;
    
    OnigCaptureTreeNode *capture;
    
    capture = (OnigCaptureTreeNode*)malloc(sizeof(OnigCaptureTreeNode));
	if (capture == NULL) {
		// If it can not allocate memory, to generate an exception. (メモリを確保できなかった場合、例外を発生させる。)
		[NSException raise:NSMallocException format:@"fail to memory allocation"];
	}
    
    capture->group     = [captureArray[0] intValue];
    capture->beg       = [captureArray[1] intValue];
    capture->end       = [captureArray[2] intValue];
    
    
    if ([captureArray count] >= 4) {
        NSArray     *children = (NSArray*)captureArray[3];
        NSUInteger    i, n = [children count];
        capture->childs = (OnigCaptureTreeNode**)malloc(n * sizeof(OnigCaptureTreeNode*));
        if (capture->childs == NULL) {
            // If it can not allocate memory, to generate an exception. (メモリを確保できなかった場合、例外を発生させる。)
            free(capture);
            [NSException raise:NSMallocException format:@"fail to memory allocation"];
        }
        
        capture->allocated = (int)n;
        capture->num_childs = (int)n;
        for (i = 0; i < n; i++) capture->childs[i] = Ogre_onigCaptureTreeNodeWithArray(children[i]);
    } else {
        capture->allocated = 0;
        capture->num_childs = 0;
        capture->childs = NULL;
    }
    
    return capture;
}


@implementation OGRegularExpressionMatch

// matched order (マッチした順番)
- (NSUInteger)index
{
	return _index;
}

// Number of substring + 1 (部分文字列の数 + 1)
- (NSUInteger)count
{
	return _region->num_regs;
}

// Range of matched string (マッチした文字列の範囲)
- (NSRange)rangeOfMatchedString
{
	return [self rangeOfSubstringAtIndex:0];
}

// Matched string ¥&, ¥0 (マッチした文字列 ¥&, ¥0)
- (id<OGStringProtocol>)matchedOGString
{
	return [self ogSubstringAtIndex:0];
}

- (NSString*)matchedString
{
	return [self substringAtIndex:0];
}

- (NSAttributedString*)matchedAttributedString
{
	return [self attributedSubstringAtIndex:0];
}

// range of index th substring (index番目のsubstringの範囲)
- (NSRange)rangeOfSubstringAtIndex:(NSUInteger)index
{
	if ( (index >= _region->num_regs) || (_region->beg[index] == -1) ) {
		// If the index th substring does not exist (index番目のsubstringが存在しない場合)
		return NSMakeRange(NSNotFound, 0);
	}
	//NSLog(@"%d %d-%d", index, _region->beg[index], _region->end[index]);
	
	return NSMakeRange(_searchRange.location + (_region->beg[index] / sizeof(unichar)), (_region->end[index] - _region->beg[index]) / sizeof(unichar));
}

// index th substring ¥n (index番目のsubstring ¥n)
- (id<OGStringProtocol>)ogSubstringAtIndex:(NSUInteger)index
{
	// I return nil when the index th substring does not exist (index番目のsubstringが存在しない時には nil を返す)
	if ( (index >= _region->num_regs) || (_region->beg[index] == -1) ){
		return nil;
	}
	
	return [_targetString substringWithRange:NSMakeRange(_region->beg[index] / sizeof(unichar), (_region->end[index] - _region->beg[index]) / sizeof(unichar))];
}

- (NSString*)substringAtIndex:(NSUInteger)index
{
	// I return nil when the index th substring does not exist (index番目のsubstringが存在しない時には nil を返す)
	if ( (index >= _region->num_regs) || (_region->beg[index] == -1) ){
		return nil;
	}
	
	return [[_targetString string] substringWithRange:NSMakeRange(_region->beg[index] / sizeof(unichar), (_region->end[index] - _region->beg[index]) / sizeof(unichar))];
}

- (NSAttributedString*)attributedSubstringAtIndex:(NSUInteger)index
{
	// I return nil when the index th substring does not exist (index番目のsubstringが存在しない時には nil を返す)
	if ( (index >= _region->num_regs) || (_region->beg[index] == -1) ){
		return nil;
	}
	
	return [[_targetString attributedString] attributedSubstringFromRange:NSMakeRange(_region->beg[index] / sizeof(unichar), (_region->end[index] - _region->beg[index]) / sizeof(unichar))];
}

// String that became the match of subject (マッチの対象になった文字列)
- (id<OGStringProtocol>)targetOGString
{
	return _targetString;
}

- (NSString*)targetString
{
	return [_targetString string];
}

- (NSAttributedString*)targetAttributedString
{
	return [_targetString attributedString];
}

// Matched before the string than the portion ¥` (マッチした部分より前の文字列 ¥`)
- (id<OGStringProtocol>)prematchOGString
{
	if (_region->beg[0] == -1) {
		// If the match string does not exist (マッチした文字列が存在しない場合)
		return nil;
	}
	
	return [_targetString substringWithRange:NSMakeRange(0, _region->beg[0] / sizeof(unichar))];
}

- (NSString*)prematchString
{
	if (_region->beg[0] == -1) {
		// If the match string does not exist (マッチした文字列が存在しない場合)
		return nil;
	}
	
	return [[_targetString string] substringWithRange:NSMakeRange(0, _region->beg[0] / sizeof(unichar))];
}

- (NSAttributedString*)prematchAttributedString
{
	if (_region->beg[0] == -1) {
		// If the match string does not exist (マッチした文字列が存在しない場合)
		return nil;
	}
	
	return [[_targetString attributedString] attributedSubstringFromRange:NSMakeRange(0, _region->beg[0] / sizeof(unichar))];
}

// matched before the substring ¥` range of (マッチした部分より前の文字列 ¥` の範囲)
- (NSRange)rangeOfPrematchString
{
	if (_region->beg[0] == -1) {
		// If the match string does not exist (マッチした文字列が存在しない場合)
		return NSMakeRange(NSNotFound, 0);
	}

	return NSMakeRange(_searchRange.location, _region->beg[0] / sizeof(unichar));
}

// Matched behind than substring ¥' (マッチした部分より後ろの文字列 ¥')
- (id<OGStringProtocol>)postmatchOGString
{
	if (_region->beg[0] == -1) {
		// If the match was behind the string from the part does not exist (マッチした部分より後ろの文字列が存在しない場合)
		return nil;
	}
	
	return [_targetString substringWithRange:NSMakeRange(_region->end[0] / sizeof(unichar), [_targetString length] - _region->end[0] / sizeof(unichar))];
}

- (NSString*)postmatchString
{
	if (_region->beg[0] == -1) {
		// If the match was behind the string from the part does not exist (マッチした部分より後ろの文字列が存在しない場合)
		return nil;
	}
	
	return [[_targetString string] substringWithRange:NSMakeRange(_region->end[0] / sizeof(unichar), [_targetString length] - _region->end[0] / sizeof(unichar))];
}

- (NSAttributedString*)postmatchAttributedString
{
	if (_region->beg[0] == -1) {
		// If the match was behind the string from the part does not exist (マッチした部分より後ろの文字列が存在しない場合)
		return nil;
	}
	
	return [[_targetString attributedString] attributedSubstringFromRange:NSMakeRange(_region->end[0] / sizeof(unichar), [_targetString length] - _region->end[0] / sizeof(unichar))];
}

// range matched behind than the portion of the string ¥' (マッチした部分より後ろの文字列 ¥' の範囲)
- (NSRange)rangeOfPostmatchString
{
	if (_region->beg[0] == -1) {
		// If the match was behind the string from the part does not exist (マッチした部分より後ろの文字列が存在しない場合)
		return NSMakeRange(NSNotFound, 0);
	}
	
	return NSMakeRange(_searchRange.location + _region->end[0] / sizeof(unichar), [_targetString length] - _region->end[0] / sizeof(unichar));
}

// Matched between the matched string to string and one before string ¥- (マッチした文字列と一つ前にマッチした文字列の間の文字列 ¥-)
- (id<OGStringProtocol>)ogStringBetweenMatchAndLastMatch
{
	if (_region->beg[0] == -1) {
		// If the match string does not exist (マッチした文字列が存在しない場合)
		return nil;
	}
	
	return [_targetString substringWithRange:NSMakeRange(_terminalOfLastMatch, _region->beg[0] / sizeof(unichar) - _terminalOfLastMatch)];
}

- (NSString*)stringBetweenMatchAndLastMatch
{
	if (_region->beg[0] == -1) {
		// If the match string does not exist (マッチした文字列が存在しない場合)
		return nil;
	}
	
	return [[_targetString string] substringWithRange:NSMakeRange(_terminalOfLastMatch, _region->beg[0] / sizeof(unichar) - _terminalOfLastMatch)];
}

- (NSAttributedString*)attributedStringBetweenMatchAndLastMatch
{
	if (_region->beg[0] == -1) {
		// If the match string does not exist (マッチした文字列が存在しない場合)
		return nil;
	}
	
	return [[_targetString attributedString] attributedSubstringFromRange:NSMakeRange(_terminalOfLastMatch, _region->beg[0] / sizeof(unichar) - _terminalOfLastMatch)];
}

// Matched between the matched string to string and one before string ¥- range of (マッチした文字列と一つ前にマッチした文字列の間の文字列 ¥- の範囲)
- (NSRange)rangeOfStringBetweenMatchAndLastMatch
{
	if (_region->beg[0] == -1) {
		// If the match string does not exist (マッチした文字列が存在しない場合)
		return NSMakeRange(NSNotFound, 0);
	}

	return NSMakeRange(_searchRange.location + _terminalOfLastMatch, _region->beg[0] / sizeof(unichar) - _terminalOfLastMatch);
}

// Last matched substring ¥+ (最後にマッチした部分文字列 ¥+)
- (id<OGStringProtocol>)lastMatchOGSubstring
{
	NSUInteger i = [self count] - 1;
	while ( (i > 0) && (_region->beg[i] == -1) ) {
		i--;
	}
	if ( i == 0) {
		return nil;
	} else {
		return [self ogSubstringAtIndex:i];
	}
}

- (NSString*)lastMatchSubstring
{
	NSUInteger i = [self count] - 1;
	while ( (i > 0) && (_region->beg[i] == -1) ) {
		i--;
	}
	if ( i == 0) {
		return nil;
	} else {
		return [self substringAtIndex:i];
	}
}

- (NSAttributedString*)lastMatchAttributedSubstring
{
	NSUInteger i = [self count] - 1;
	while ( (i > 0) && (_region->beg[i] == -1) ) {
		i--;
	}
	if ( i == 0) {
		return nil;
	} else {
		return [self attributedSubstringAtIndex:i];
	}
}

// Last matched substring of range ¥+ (最後にマッチした部分文字列の範囲 ¥+)
- (NSRange)rangeOfLastMatchSubstring
{
	NSUInteger i = [self count] - 1;
	while ( (i > 0) && (_region->beg[i] == -1) ) {
		i--;
	}
	if ( i == 0) {
		return NSMakeRange(NSNotFound, 0);
	} else {
		return [self rangeOfSubstringAtIndex:i];
	}
}


// NSCoding protocols
- (void)encodeWithCoder:(NSCoder*)encoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-encodeWithCoder: of %@", [self className]);
#endif
	//[super encodeWithCoder:encoder]; NSObject does ont respond to method encodeWithCoder:
	
   if ([encoder allowsKeyedCoding]) {
		[encoder encodeObject: Ogre_arrayWithOnigRegion(_region) forKey: OgreRegionKey];
		[encoder encodeObject: _enumerator forKey: OgreEnumeratorKey];
		[encoder encodeObject: @(_terminalOfLastMatch) forKey: OgreTerminalOfLastMatchKey];
		[encoder encodeObject: @(_index) forKey: OgreIndexOfMatchKey];
		[encoder encodeObject: Ogre_arrayWithOnigCaptureTreeNode(_region->history_root) forKey: OgreCaptureHistoryKey];
	} else {
		[encoder encodeObject: Ogre_arrayWithOnigRegion(_region)];
		[encoder encodeObject: _enumerator];
		[encoder encodeObject: @(_terminalOfLastMatch)];
		[encoder encodeObject: @(_index)];
		[encoder encodeObject: Ogre_arrayWithOnigCaptureTreeNode(_region->history_root)];
	}
}

- (instancetype)initWithCoder:(NSCoder*)decoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithCoder: of %@", [self className]);
#endif
	self = [super init];	// NSObject does ont respond to method initWithCoder:
	if (self == nil) return nil;
	
	BOOL			allowsKeyedCoding = [decoder allowsKeyedCoding];
	
	// OnigRegion		*_region;				// match result region
	id  anObject;
	NSArray	*regionArray;
    if (allowsKeyedCoding) {
		regionArray = [decoder decodeObjectForKey: OgreRegionKey];
	} else {
		regionArray = [decoder decodeObject];
	}
	if (regionArray == nil) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
        return nil;
	}
	_region = Ogre_onigRegionWithArray(regionArray);	
	
    
	// OGRegularExpressionEnumerator*	_enumerator;	// Generation main (生成主)
    if (allowsKeyedCoding) {
		_enumerator = [decoder decodeObjectForKey: OgreEnumeratorKey];
	} else {
		_enumerator = [decoder decodeObject];
	}
	if (_enumerator == nil) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
        return nil;
	}
	
	
	// NSUInteger 	_terminalOfLastMatch; 	// End position of the matched string in the previous (_region-> end [0] / sizeof (unichar)) (前回にマッチした文字列の終端位置 (_region->end[0] / sizeof(unichar)))
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
	_terminalOfLastMatch = [anObject unsignedIntegerValue];

	
	// 	NSUInteger		_index;		// matched order (マッチした順番)
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreIndexOfMatchKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
        return nil;
	}
	_index = [anObject unsignedIntegerValue];

	
	// _region->history_root    // capture history
	NSArray	*captureArray;
    if (allowsKeyedCoding) {
		captureArray = [decoder decodeObjectForKey:OgreCaptureHistoryKey];
	} else {
		captureArray = [decoder decodeObject];
	}
	if (captureArray == nil) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
        return nil;
	}
	_region->history_root = Ogre_onigCaptureTreeNodeWithArray(captureArray);
	
    
	// Those that frequently use my cache. Retention and will not be. (頻繁に利用するものはキャッシュする。保持はしない。)
	// Search target string (検索対象文字列)
	_targetString        = [_enumerator targetString];
	// Search range (検索範囲)
	NSRange	searchRange = [_enumerator searchRange];
	_searchRange.location = searchRange.location;
	_searchRange.length   = searchRange.length;
	
	return self;
}

// NSCopying protocol
- (id)copyWithZone:(NSZone*)zone
{
#ifdef DEBUG_OGRE
	NSLog(@"-copyWithZone: of %@", [self className]);
#endif
	OnigRegion*	newRegion = onig_region_new();
	onig_region_copy(newRegion, _region);
	
	return [[[self class] allocWithZone:zone] 
		initWithRegion: newRegion 
		index:_index 
		enumerator:_enumerator
		terminalOfLastMatch:_terminalOfLastMatch];
}


// description
- (NSString*)description
{
	NSDictionary	*dictionary = @{@"Range of Substrings": Ogre_arrayWithOnigRegion(_region), 
			@"Capture History": Ogre_arrayWithOnigCaptureTreeNode(_region->history_root), 
			@"Regular Expression Enumerator": _enumerator, 
			@"Terminal of the Last Match": @(_terminalOfLastMatch), 
			@"Index": @(_index)};
		
	return [dictionary description];
}


// Can be used when the name (label) is that you specify a substring (OgreCaptureGroupOption of name (名前(ラベル)がnameの部分文字列 (OgreCaptureGroupOptionを指定したときに使用できる)
// I return nil if the name does not exist. (存在しない名前の場合は nil を返す。)
// If there is more than one substring with the same name can raise an exception. (同一の名前を持つ部分文字列が複数ある場合は例外を発生させる。)
- (id<OGStringProtocol>)ogSubstringNamed:(NSString*)name
{
	NSInteger	index = [self indexOfSubstringNamed:name];
	if (index == -1) return nil;
		
	return [self ogSubstringAtIndex:index];
}

- (NSString*)substringNamed:(NSString*)name
{
	NSInteger	index = [self indexOfSubstringNamed:name];
	if (index == -1) return nil;
		
	return [self substringAtIndex:index];
}

- (NSAttributedString*)attributedSubstringNamed:(NSString*)name
{
	NSInteger	index = [self indexOfSubstringNamed:name];
	if (index == -1) return nil;
		
	return [self attributedSubstringAtIndex:index];
}

// Range name is a substring of the name (名前がnameの部分文字列の範囲)
// In the case of a name that does not exist I return the {NSNotFound, 0}. (存在しない名前の場合は {NSNotFound, 0} を返す。)
// If there is more than one substring with the same name can raise an exception. (同一の名前を持つ部分文字列が複数ある場合は例外を発生させる。)
- (NSRange)rangeOfSubstringNamed:(NSString*)name
{
	NSInteger	index = [self indexOfSubstringNamed:name];
	if (index == -1) return NSMakeRange(NSNotFound, 0);
	
	return [self rangeOfSubstringAtIndex:index];
}

// Index name is a substring of the name (名前がnameの部分文字列のindex)
// -1 Is returned if it does not exist (存在しない場合は-1を返す)
// If there is more than one substring with the same name can raise an exception. (同一の名前を持つ部分文字列が複数ある場合は例外を発生させる。)
- (NSInteger)indexOfSubstringNamed:(NSString*)name
{
	NSInteger	index = [[_enumerator regularExpression] groupIndexForName:name];
	if (index == -2) {
		// If there is more than one substring with the same name can raise an exception. (同一の名前を持つ部分文字列が複数ある場合は例外を発生させる。)
		[NSException raise:OgreMatchException format:@"multiplex definition name <%@> call", name];
	}
	
	return index;
}

// The name of the index th substring (index番目の部分文字列の名前)
// I return nil if the name does not exist. (存在しない名前の場合は nil を返す。)
- (NSString*)nameOfSubstringAtIndex:(NSUInteger)index
{
	return [[_enumerator regularExpression] nameForGroupIndex:index];
}



// What group number is the smallest of the matched substring (マッチした部分文字列のうちグループ番号が最小のもの)
- (NSUInteger)indexOfFirstMatchedSubstringInRange:(NSRange)aRange
{
	NSUInteger	index, count = [self count];
	if (count > NSMaxRange(aRange)) count = NSMaxRange(aRange);
	
	for (index = aRange.location; index < count; index++) {
		if (_region->beg[index] != -1) return index;
	}
	
	return 0;   // If you did not match any subexpression (どの部分式にもマッチしなかった場合)
}

- (NSString*)nameOfFirstMatchedSubstringInRange:(NSRange)aRange
{
	return [self nameOfSubstringAtIndex:[self indexOfFirstMatchedSubstringInRange:aRange]];
}


// What group number is the maximum out of the matched substring (マッチした部分文字列のうちグループ番号が最大のもの)
- (NSUInteger)indexOfLastMatchedSubstringInRange:(NSRange)aRange
{
	NSUInteger	index, count = [self count];
	if (count > NSMaxRange(aRange)) count = NSMaxRange(aRange);

	for (index = count - 1; index >= aRange.location; index--) {
		if (_region->beg[index] != -1) return index;
	}
	
	return 0;   // If you did not match any subexpression (どの部分式にもマッチしなかった場合)
}

- (NSString*)nameOfLastMatchedSubstringInRange:(NSRange)aRange
{
	return [self nameOfSubstringAtIndex:[self indexOfLastMatchedSubstringInRange:aRange]];
}


// The longest of the matched substring (マッチした部分文字列のうち最長のもの)
- (NSUInteger)indexOfLongestSubstringInRange:(NSRange)aRange
{
	BOOL		matched = NO;
	NSUInteger	maxLength = 0;
	NSUInteger	maxIndex = 0, i, count = [self count];
	NSRange		range;
	if (count > NSMaxRange(aRange)) count = NSMaxRange(aRange);

	for (i = aRange.location; i < count; i++) {
		range = [self rangeOfSubstringAtIndex:i];
		if ((range.location != NSNotFound) && ((maxLength < range.length) || !matched)) {
			matched = YES;
			maxLength = range.length;
			maxIndex = i;
		}
	}
	
	return maxIndex;
}

- (NSString*)nameOfLongestSubstringInRange:(NSRange)aRange
{
	return [self nameOfSubstringAtIndex:[self indexOfLongestSubstringInRange:aRange]];
}


// The shortest of the matched substring (マッチした部分文字列のうち最短のもの)
- (NSUInteger)indexOfShortestSubstringInRange:(NSRange)aRange
{
	BOOL		matched = NO;
	NSUInteger	minLength = 0;
	NSUInteger	minIndex = 0, i, count = [self count];
	NSRange		range;
	if (count > NSMaxRange(aRange)) count = NSMaxRange(aRange);
	
	for (i = aRange.location; i < count; i++) {
		range = [self rangeOfSubstringAtIndex:i];
		if ((range.location != NSNotFound) && ((minLength > range.length) || !matched)) {
			matched = YES;
			minLength = range.length;
			minIndex = i;
		}
	}
	
	return minIndex;
}

- (NSString*)nameOfShortestSubstringInRange:(NSRange)aRange
{
	return [self nameOfSubstringAtIndex:[self indexOfShortestSubstringInRange:aRange]];
}

// Matched part one group number of the string is at a minimum (returns 0 if no) (マッチした部分文字列のうちグループ番号が最小のもの (ない場合は0を返す))
- (NSUInteger)indexOfFirstMatchedSubstring
{
	return [self indexOfFirstMatchedSubstringInRange:NSMakeRange(1, [self count] - 1)];
}

- (NSUInteger)indexOfFirstMatchedSubstringBeforeIndex:(NSUInteger)anIndex
{
	return [self indexOfFirstMatchedSubstringInRange:NSMakeRange(1, anIndex - 1)];
}

- (NSUInteger)indexOfFirstMatchedSubstringAfterIndex:(NSUInteger)anIndex
{
	return [self indexOfFirstMatchedSubstringInRange:NSMakeRange(anIndex, [self count] - anIndex)];
}

// That name (その名前)
- (NSString*)nameOfFirstMatchedSubstring
{
	return [self nameOfFirstMatchedSubstringInRange:NSMakeRange(1, [self count] - 1)];
}

- (NSString*)nameOfFirstMatchedSubstringBeforeIndex:(NSUInteger)anIndex
{
	return [self nameOfFirstMatchedSubstringInRange:NSMakeRange(1, anIndex - 1)];
}

- (NSString*)nameOfFirstMatchedSubstringAfterIndex:(NSUInteger)anIndex
{
	return [self nameOfFirstMatchedSubstringInRange:NSMakeRange(anIndex, [self count] - anIndex)];
}


// Matched part group number of the string is a maximum of one (return 0 if no) (マッチした部分文字列のうちグループ番号が最大のもの (ない場合は0を返す))
- (NSUInteger)indexOfLastMatchedSubstring
{
	return [self indexOfLastMatchedSubstringInRange:NSMakeRange(1, [self count] - 1)];
}

- (NSUInteger)indexOfLastMatchedSubstringBeforeIndex:(NSUInteger)anIndex
{
	return [self indexOfLastMatchedSubstringInRange:NSMakeRange(1, anIndex - 1)];
}

- (NSUInteger)indexOfLastMatchedSubstringAfterIndex:(NSUInteger)anIndex
{
	return [self indexOfLastMatchedSubstringInRange:NSMakeRange(anIndex, [self count] - anIndex)];
}

// That name (その名前)
- (NSString*)nameOfLastMatchedSubstring
{
	return [self nameOfLastMatchedSubstringInRange:NSMakeRange(1, [self count] - 1)];
}

- (NSString*)nameOfLastMatchedSubstringBeforeIndex:(NSUInteger)anIndex
{
	return [self nameOfLastMatchedSubstringInRange:NSMakeRange(1, anIndex - 1)];
}

- (NSString*)nameOfLastMatchedSubstringAfterIndex:(NSUInteger)anIndex
{
	return [self nameOfLastMatchedSubstringInRange:NSMakeRange(anIndex, [self count] - anIndex)];
}


// Matched the longest ones of the substring (if not it returns 0. If more than one of the same length, small ones are priority of numbers) (マッチした部分文字列のうち最長のもの (ない場合は0を返す。同じ長さの物が複数あれば、番号の小さい物が優先される))
- (NSUInteger)indexOfLongestSubstring
{
	return [self indexOfLongestSubstringInRange:NSMakeRange(1, [self count] - 1)];
}

- (NSUInteger)indexOfLongestSubstringBeforeIndex:(NSUInteger)anIndex
{
	return [self indexOfLongestSubstringInRange:NSMakeRange(1, anIndex - 1)];
}

- (NSUInteger)indexOfLongestSubstringAfterIndex:(NSUInteger)anIndex
{
	return [self indexOfLongestSubstringInRange:NSMakeRange(anIndex, [self count] - anIndex)];
}

// That name (その名前)
- (NSString*)nameOfLongestSubstring
{
	return [self nameOfLongestSubstringInRange:NSMakeRange(1, [self count] - 1)];
}

- (NSString*)nameOfLongestSubstringBeforeIndex:(NSUInteger)anIndex
{
	return [self nameOfLongestSubstringInRange:NSMakeRange(1, anIndex - 1)];
}

- (NSString*)nameOfLongestSubstringAfterIndex:(NSUInteger)anIndex
{
	return [self nameOfLongestSubstringInRange:NSMakeRange(anIndex, [self count] - anIndex)];
}


// Matched shortest ones of the substring (if not it returns 0. If more than one of the same length, small ones are priority of numbers) (マッチした部分文字列のうち最短のもの (ない場合は0を返す。同じ長さの物が複数あれば、番号の小さい物が優先される))
- (NSUInteger)indexOfShortestSubstring
{
	return [self indexOfShortestSubstringInRange:NSMakeRange(1, [self count] - 1)];
}

- (NSUInteger)indexOfShortestSubstringBeforeIndex:(NSUInteger)anIndex
{
	return [self indexOfShortestSubstringInRange:NSMakeRange(1, anIndex - 1)];
}

- (NSUInteger)indexOfShortestSubstringAfterIndex:(NSUInteger)anIndex
{
	return [self indexOfShortestSubstringInRange:NSMakeRange(anIndex, [self count] - anIndex)];
}

// That name (その名前)
- (NSString*)nameOfShortestSubstring
{
	return [self nameOfShortestSubstringInRange:NSMakeRange(1, [self count] - 1)];
}

- (NSString*)nameOfShortestSubstringBeforeIndex:(NSUInteger)anIndex
{
	return [self nameOfShortestSubstringInRange:NSMakeRange(1, anIndex - 1)];
}

- (NSString*)nameOfShortestSubstringAfterIndex:(NSUInteger)anIndex
{
	return [self nameOfShortestSubstringInRange:NSMakeRange(anIndex, [self count] - anIndex)];
}

/******************
* Capture History *
*******************/
// Capture history (捕獲履歴)
// I return nil if there is no history. (履歴がない場合はnilを返す。)
- (OGRegularExpressionCapture*)captureHistory
{
	if (_region->history_root == NULL) return nil;
	
	return [[OGRegularExpressionCapture allocWithZone:nil] 
        initWithTreeNode:_region->history_root 
        index:0 
        level:0 
        parentNode:nil 
        match:self];
}

#pragma mark - Private methods
/* Private method (非公開メソッド) */
- (id)initWithRegion:(OnigRegion*)region
			   index:(NSUInteger)anIndex
		  enumerator:(OGRegularExpressionEnumerator*)enumerator
	terminalOfLastMatch:(NSUInteger)terminalOfLastMatch
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithRegion: of %@", [self className]);
#endif
	self = [super init];
	if (self) {
		// match result region
		_region = region;	// retain
		
		// Generation main (生成主)
		_enumerator = enumerator;
		
		// End position of the last matched string (最後にマッチした文字列の終端位置)
		_terminalOfLastMatch = terminalOfLastMatch;
		// Matched order (マッチした順番)
		_index = anIndex;
		
		// Those that frequently use my cache. Retention and will not be. (頻繁に利用するものはキャッシュする。保持はしない。)
		// Search target string (検索対象文字列)
		_targetString     = [_enumerator targetString];
		// Search range (検索範囲)
		NSRange	searchRange = [_enumerator searchRange];
		_searchRange.location = searchRange.location;
		_searchRange.length   = searchRange.length;
	}
	
	return self;
}

- (void)dealloc
{
#ifdef DEBUG_OGRE
	NSLog(@"-dealloc of %@", [self className]);
#endif
	
	if (_region != NULL) {
		onig_region_free(_region, 1 /* free self */);
	}
	
}

- (id<OGStringProtocol>)_targetString
{
	return _targetString;
}

- (NSRange)_searchRange
{
	return _searchRange;
}

- (OnigRegion*)_region
{
	return _region;
}

@end
