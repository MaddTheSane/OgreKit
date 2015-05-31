/*
 * Name: OGAttributedString.h
 * Project: OgreKit
 *
 * Creation Date: Sep 22 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2004 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OGAttributedString.h>
#import <OgreKit/OGMutableAttributedString.h>

// Key for encoding/decoding itself (自身をencoding/decodingするためのkey)
static NSString * const	OgreAttributedStringKey = @"OgreAttributedString";

@implementation OGAttributedString

- (id)initWithString:(NSString *)string
{
	if (string == nil) {
		[NSException raise:NSInvalidArgumentException format: @"nil string argument"];
	}
	
	self = [super init];
	if (self != nil) {
		_attrString = [[NSAttributedString alloc] initWithString:string];
	}
	return self;
}

- (id)initWithAttributedString:(NSAttributedString *)attributedString
{
	if (attributedString == nil) {
		[NSException raise:NSInvalidArgumentException format: @"nil string argument"];
	}
	
	self = [super init];
	if (self != nil) {
		_attrString = attributedString;
	}
	return self;
}

- (id)initWithString:(NSString *)string hasAttributesOfOGString:(id<OGStringProtocol>)ogString
{
	if (string == nil || ogString == nil) {
		[NSException raise:NSInvalidArgumentException format: @"nil string argument"];
	}
	
	return [self initWithAttributedString:[[NSAttributedString alloc] initWithString:string 
		attributes:[[ogString attributedString] attributesAtIndex:0 effectiveRange:NULL]]];
}

+ (id)stringWithString:(NSString *)string
{
	return [[[self class] alloc] initWithString:string];
}

+ (id)stringWithAttributedString:(NSAttributedString *)attributedString
{
	return [[[self class] alloc] initWithAttributedString:attributedString];
}

+ (id)stringithString:(NSString *)string hasAttributesOfOGString:(id<OGStringProtocol>)ogString
{
	return [[[self class] alloc] initWithString:string hasAttributesOfOGString:ogString];
}

@synthesize attributedString = _attrString;

/* OGString interface */
- (NSString *)string
{
	return [_attrString string];
}

- (NSAttributedString *)attributedString
{
	return _attrString;
}

- (NSUInteger)length
{
	return [_attrString length];
}

- (id<OGStringProtocol>)substringWithRange:(NSRange)aRange
{
	return [[self class] stringWithAttributedString:[_attrString attributedSubstringFromRange:aRange]];
}

- (Class)mutableClass
{
	return [OGMutableAttributedString class];
}

/* NSCopying protocol */
- (id)copyWithZone:(NSZone *)zone
{
#ifdef DEBUG_OGRE
	NSLog(@"-copyWithZone: of %@", [self className]);
#endif
	NSAttributedString	*attrString = [(NSAttributedString *)_attrString copy];	// deep copy
	id	copy = [[[self class] allocWithZone:zone] initWithAttributedString:attrString];
	
	return copy;
}

/* NSCoding protocol */
- (void)encodeWithCoder:(NSCoder *)encoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-encodeWithCoder: of %@", [self className]);
#endif
    if ([encoder allowsKeyedCoding]) {
		[encoder encodeObject:_attrString forKey:OgreAttributedStringKey];
	} else {
		[encoder encodeObject:_attrString];
	}
}

- (id)initWithCoder:(NSCoder *)decoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithCoder: of %@", [self className]);
#endif
	
	self = [super init];
	if (self == nil) return self;
	
	BOOL			allowsKeyedCoding = [decoder allowsKeyedCoding];
	// NSString		*_string;
    if (allowsKeyedCoding) {
		_attrString = [decoder decodeObjectForKey:OgreAttributedStringKey];
	} else {
		_attrString = [decoder decodeObject];
	}
	if(_attrString == nil) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	
	return self;	
}

/* description */
- (NSString *)description
{
	return [_attrString description];
}


@end
