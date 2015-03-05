/*
 * Name: OGRegularExpressionFormatter.m
 * Project: OgreKit
 *
 * Creation Date: Sep 05 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OGRegularExpressionFormatter.h>

// Key required to encode/decode itself (自身をencode/decodeするのに必要なkey)
static NSString	* const OgreOptionsKey            = @"OgreFormatterOptions";
static NSString	* const OgreSyntaxKey             = @"OgreFormatterSyntax";
static NSString	* const OgreEscapeCharacterKey    = @"OgreFormatterEscapeCharacter";

NSString	* const OgreFormatterException = @"OGRegularExpressionFormatterException";


@implementation OGRegularExpressionFormatter

- (NSString*)stringForObjectValue:(id)anObject
{
    if (![anObject isKindOfClass: [OGRegularExpression class]]) {
		return nil;
    }
	
	//NSLog(@"stringForObjectValue ¥"%@¥"", [anObject expressionString]); 
	return [anObject expressionString];
}

- (NSAttributedString*)attributedStringForObjectValue:(id)anObject 
	withDefaultAttributes:(NSDictionary *)attributes
{
    if (![anObject isKindOfClass: [OGRegularExpression class]]) {
		return nil;
    }
	
	//NSLog(@"stringForObjectValue ¥"%@¥"", [anObject expressionString]); 
	return [[[NSAttributedString alloc] initWithString: [anObject expressionString] 
		attributes: attributes] autorelease];
}

- (NSString*)editingStringForObjectValue:(id)anObject
{
    if (![anObject isKindOfClass: [OGRegularExpression class]]) {
		return nil;
    }
	
	//NSLog(@"editingStringForObjectValue ¥"%@¥"", [anObject expressionString]); 
	return [anObject expressionString];
}

- (BOOL)getObjectValue:(id*)obj forString:(NSString*)string 
	errorDescription:(NSString  **)error
{
	BOOL	retval;
	
	//NSLog(@"getObjectValue ¥"%@¥"", string); 
	NS_DURING
		*obj = [OGRegularExpression regularExpressionWithString: string
			options: [self options] 
			syntax: [self syntax] 
			escapeCharacter: [self escapeCharacter] 
			];
		retval = YES;
	NS_HANDLER
		// Exception handling (例外処理)
		NSString	*name = [localException name];
		//NSLog(@"¥"%@¥" caught in getObjectValue", name);
		
		if ([name isEqualToString:OgreFormatterException]) {
			NSString	*reason = [localException reason];
			//NSLog(@"reason: ¥"%@¥"", reason); 
			
			if (error != nil) {
				*error = reason;
			}
		} else {
			[localException raise];
		}
		retval = NO;
	NS_ENDHANDLER

	//NSLog(@"retval in getObjectValue: %d", retval);
	return retval;
}

// NSCoding protocols
- (void)encodeWithCoder:(NSCoder*)encoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-encodeWithCoder: of %@", [self className]);
#endif
    [super encodeWithCoder:encoder];

	// NSString			*_escapeCharacter;
	// unsigned			_options;
	// OnigSyntaxType	*_syntax;

	NSInteger	syntaxType = [OGRegularExpression intValueForSyntax:[self syntax]];
	if (syntaxType == -1) {
		// Error. Own syntax can not encode. (エラー。独自のsyntaxはencodeできない。)
		// I raise an exception. Need of improvement (例外を発生させる。要改善)
		[NSException raise:NSInvalidArchiveOperationException format:
			@"fail to encode. (cannot encode a user defined syntax)"];
	}
	
    if ([encoder allowsKeyedCoding]) {
		[encoder encodeObject: [self escapeCharacter] forKey: OgreEscapeCharacterKey];
		[encoder encodeObject: @([self options]) forKey: OgreOptionsKey];
		[encoder encodeObject: @(syntaxType) forKey: OgreSyntaxKey];
	} else {
		[encoder encodeObject: [self escapeCharacter]];
		[encoder encodeObject: @([self options])];
		[encoder encodeObject: @(syntaxType)];
	}
}

- (id)initWithCoder:(NSCoder*)decoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithCoder: of %@", [self className]);
#endif
	self = [super initWithCoder:decoder];
	if (self == nil) return nil;
	
	NSInteger		syntaxType;
	id				anObject;
	
	BOOL			allowsKeyedCoding = [decoder allowsKeyedCoding];

    if (allowsKeyedCoding) {
		// NSString			*_escapeCharacter;
		_escapeCharacter = [[decoder decodeObjectForKey: OgreEscapeCharacterKey] retain];
	} else {
		// NSString			*_escapeCharacter;
		_escapeCharacter = [[decoder decodeObject] retain];
	}
	if(_escapeCharacter == nil) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		[self release];
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}

	// unsigned		_options;
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreOptionsKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if(anObject == nil) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		[self release];
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	_options = [anObject unsignedIntegerValue];

	// OnigSyntaxType		*_syntax;
	// Required improvements. I can not encode If you provide your own syntax. (要改善点。独自のsyntaxを用意した場合はencodeできない。)
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreSyntaxKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if(anObject == nil) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		[self release];
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	syntaxType = [anObject integerValue];
	if (syntaxType == -1) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		[self release];
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	_syntax = [OGRegularExpression syntaxForIntValue:(int)syntaxType];

	return self;
}

// NSCopying protocol
- (id)copyWithZone:(NSZone*)zone
{
#ifdef DEBUG_OGRE
	NSLog(@"-copyWithZone: of %@", [self className]);
#endif
	return [[[self class] allocWithZone:zone]
		initWithOptions: _options 
		syntax: _syntax 
		escapeCharacter: _escapeCharacter];
}

- (instancetype)init
{
	return [self initWithOptions:OgreNoneOption syntax:[OGRegularExpression defaultSyntax] escapeCharacter:[OGRegularExpression defaultEscapeCharacter]];
}

- (instancetype)initWithOptions:(NSUInteger)options syntax:(OgreSyntax)syntax escapeCharacter:(NSString*)character
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithOptions: of %@", [self className]);
#endif
	self = [super init];
	if (self) {
		_options = options;
		_syntax = syntax;
		_escapeCharacter = [character retain];
	}
	
	return self;
}

#ifdef MAC_OS_X_VERSION_10_6
- (void)finalize
{
#ifdef DEBUG_OGRE
	NSLog(@"-finalize of %@", [self className]);
#endif
    [super finalize];
}
#endif

- (void)dealloc
{
#ifdef DEBUG_OGRE
	NSLog(@"-dealloc of %@", [self className]);
#endif
	[_escapeCharacter release];
	[super dealloc];
}

@end
