/*
 * Name: OGRegularExpressionCapture.m
 * Project: OgreKit
 *
 * Creation Date: Jun 24 2004
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
#import <OgreKit/OGRegularExpressionCapture.h>
#import <OgreKit/OGRegularExpressionCapturePrivate.h>


NSString	* const OgreCaptureException = @"OGRegularExpressionCaptureException";

// Key for encoding/decoding itself (自身をencoding/decodingするためのkey)
static NSString	* const OgreIndexKey  = @"OgreCaptureIndex";
static NSString	* const OgreLevelKey  = @"OgreCaptureLevel";
static NSString	* const OgreMatchKey  = @"OgreCaptureMatch";
static NSString	* const OgreParentKey = @"OgreCaptureParent";


@implementation OGRegularExpressionCapture

/*********
 * 諸情報 *
 *********/
// Group number (グループ番号)
- (NSUInteger)groupIndex
{
    return _captureNode->group;
}

// Group Name (グループ名)
- (NSString*)groupName
{
    return [_match nameOfSubstringAtIndex:[self groupIndex]];
}

// And what number of child elements 0, 1, 2, ... (// 何番目の子要素であるか 0,1,2,...)
- (NSUInteger)index
{
    return _index;
}

// Depth (深さ)
- (NSUInteger)level
{
    return _level;
}

// The number of child elements (子要素の数)
- (NSUInteger)numberOfChildren
{
    return _captureNode->num_childs;
}

// Child elements us (子要素たち)
// return nil in the case of numberOfChildren == 0
- (NSArray*)children
{
    NSUInteger    numberOfChildren = _captureNode->num_childs;
    if (numberOfChildren == 0) return nil;
    
    NSMutableArray  *children = [NSMutableArray arrayWithCapacity:numberOfChildren];
    NSUInteger i;
    for (i = 0; i < numberOfChildren; i++) [children addObject:[self childAtIndex:i]];
    
    return children;
}


// index th child element (index番目の子要素)
- (OGRegularExpressionCapture*)childAtIndex:(NSUInteger)index
{
    if (index >= _captureNode->num_childs) {
        return nil;
    }
    
    return [[[[self class] alloc] initWithTreeNode:_captureNode->childs[index] 
        index:index 
        level:_level + 1 
        parentNode:self 
        match:_match] autorelease];
}


- (OGRegularExpressionMatch*)match
{
    return _match;
}


// description
- (NSString*)description
{
	NSDictionary	*dictionary = @{
            @"Group Index": @((NSUInteger)_captureNode->group),
			@"Index": @(_index), 
			@"Level": @(_level), 
			@"Range": @[@((NSUInteger)_captureNode->beg),
                @((NSUInteger)_captureNode->end - _captureNode->beg)],
			@"Number of Children": @((NSUInteger)_captureNode->num_childs)};
		
	return [dictionary description];
}

/*********
 * 文字列 *
 *********/
// String that became the match of subject (マッチの対象になった文字列)
- (NSString*)targetString
{
    return [_match targetString];
}

- (NSAttributedString*)targetAttributedString
{
	return [_match targetAttributedString];
}

// Matched string (マッチした文字列)
- (NSString*)string
{
	// I return nil when the index th substring does not exist (index番目のsubstringが存在しない時には nil を返す)
	if (_captureNode->beg == -1 || _captureNode->end == -1) {
		return nil;
	}
	
	return [[_match targetString] substringWithRange:NSMakeRange(_captureNode->beg / sizeof(unichar), (_captureNode->end - _captureNode->beg) / sizeof(unichar))];
}

- (NSAttributedString*)attributedString
{
	// I return nil when the index th substring does not exist (index番目のsubstringが存在しない時には nil を返す)
	if (_captureNode->beg == -1 || _captureNode->end == -1) {
		return nil;
	}
	
	return [[_match targetAttributedString] attributedSubstringFromRange:NSMakeRange(_captureNode->beg / sizeof(unichar), (_captureNode->end - _captureNode->beg) / sizeof(unichar))];
}

/*******
 * 範囲 *
 *******/
// Range of matched string (マッチした文字列の範囲)
- (NSRange)range
{
	if (_captureNode->beg == -1 || _captureNode->end == -1) {
		return NSMakeRange(NSNotFound, 0);
	}
	
	return NSMakeRange([_match _searchRange].location + _captureNode->beg / sizeof(unichar), (_captureNode->end - _captureNode->beg) / sizeof(unichar));
}


/************************
* adapt Visitor pattern *
*************************/
- (void)acceptVisitor:(id <OGRegularExpressionCaptureVisitor>)aVisitor 
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [aVisitor visitAtFirstCapture:self];
    
    [[self children] makeObjectsPerformSelector:@selector(acceptVisitor:) withObject:aVisitor];
    
    [aVisitor visitAtLastCapture:self];
    [pool release];
}


// NSCoding protocols
- (void)encodeWithCoder:(NSCoder*)encoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-encodeWithCoder: of %@", [self className], [self className]);
#endif
	//[super encodeWithCoder:encoder]; NSObject does ont respond to method encodeWithCoder:
	
   if ([encoder allowsKeyedCoding]) {
		[encoder encodeObject: @(_index) forKey: OgreIndexKey];
		[encoder encodeObject: @(_level) forKey: OgreLevelKey];
		[encoder encodeObject: _match forKey: OgreMatchKey];
		[encoder encodeObject: _parent forKey: OgreParentKey];
	} else {
		[encoder encodeObject: @(_index)];
		[encoder encodeObject: @(_level)];
		[encoder encodeObject: _match];
		[encoder encodeObject: _parent];
	}
}

- (id)initWithCoder:(NSCoder*)decoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithCoder: of %@", [self className], [self className]);
#endif
	self = [super init];	// NSObject does ont respond to method initWithCoder:
	if (self == nil) return nil;
	
	BOOL			allowsKeyedCoding = [decoder allowsKeyedCoding];
	
	id  anObject;
	// NSUInteger                    _index,             // matched order (マッチした順番)
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreIndexKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		[self release];
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	_index = [anObject unsignedIntValue];	
	
    // NSUInteger                   _level;             // Depth (深さ)
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreLevelKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		[self release];
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	_level = [anObject unsignedIntValue];	
	
	
	// OGRegularExpressionMatch	*_match;            // Generation Lord OGRegularExpressionMatch object (生成主のOGRegularExpressionMatchオブジェクト)
    if (allowsKeyedCoding) {
		_match = [decoder decodeObjectForKey: OgreMatchKey];
	} else {
		_match = [decoder decodeObject];
	}
	if (_match == nil) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		[self release];
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
    [_match retain];
	
	// OGRegularExpressionCapture	*_parent;           // Parent (親)
    if (allowsKeyedCoding) {
		_parent = [decoder decodeObjectForKey: OgreParentKey];
	} else {
		_parent = [decoder decodeObject];
	}
	/*if (_parent == nil) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		[self release];
		[NSException raise:OgreCaptureException format:@"fail to decode"];
	}*/
    [_parent retain];
    
    
	// OnigCaptureTreeNode         *_captureNode;      // Oniguruma capture tree node
    if (_parent == nil) {
        _captureNode = [_match _region]->history_root;
    } else {
        _captureNode = [_parent _captureNode]->childs[_index];
    }
    
	return self;
}

// NSCopying protocol
- (id)copyWithZone:(NSZone*)zone
{
#ifdef DEBUG_OGRE
	NSLog(@"-copyWithZone: of %@", [self className], [self className]);
#endif
	return [[[self class] allocWithZone:zone] 
        initWithTreeNode:_captureNode 
        index:_index 
        level:_level 
        parentNode:_parent 
        match:_match];
}


@end
