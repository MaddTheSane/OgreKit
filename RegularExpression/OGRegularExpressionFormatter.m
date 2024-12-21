/*
 * Name: OGRegularExpressionFormatter.m
 * Project: OgreKit
 *
 * Creation Date: Sep 05 2003
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2020 Isao Sonobe, All rights reserved.
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

@interface NSFormatter ()
- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)decoder NS_DESIGNATED_INITIALIZER;
@end

@interface OGRegularExpressionFormatter ()
- (instancetype)initWithCoder:(NSCoder *)decoder NS_DESIGNATED_INITIALIZER;
@end

@implementation OGRegularExpressionFormatter

- (NSString *)stringForObjectValue:(id)anObject
{
    if (![anObject isKindOfClass: [OGRegularExpression class]]) {
		return nil;
    }
	
	//NSLog(@"stringForObjectValue \"%@\"", [anObject expressionString]); 
	return [anObject expressionString];
}

- (NSAttributedString *)attributedStringForObjectValue:(id)anObject 
	withDefaultAttributes:(NSDictionary *)attributes
{
    if (![anObject isKindOfClass: [OGRegularExpression class]]) {
		return nil;
    }
	
	//NSLog(@"stringForObjectValue \"%@\"", [anObject expressionString]); 
	return [[NSAttributedString alloc] initWithString: [anObject expressionString] 
		attributes: attributes];
}

- (NSString *)editingStringForObjectValue:(id)anObject
{
    if (![anObject isKindOfClass: [OGRegularExpression class]]) {
		return nil;
    }
	
	//NSLog(@"editingStringForObjectValue \"%@\"", [anObject expressionString]); 
	return [anObject expressionString];
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string 
	errorDescription:(NSString  **)error
{
	BOOL	retval;
	
	//NSLog(@"getObjectValue \"%@\"", string); 
	@try {
		*obj = [OGRegularExpression regularExpressionWithString: string
			options: [self options] 
			syntax: [self syntax] 
			escapeCharacter: [self escapeCharacter] 
			];
		retval = YES;
	} @catch (NSException *localException) {
		// Exception handling (例外処理)
		NSString	*name = [localException name];
		//NSLog(@"\"%@\" caught in getObjectValue", name);
		
		if ([name isEqualToString:OgreFormatterException]) {
			NSString	*reason = [localException reason];
			//NSLog(@"reason: \"%@\"", reason);
			
			if (error != nil) {
				*error = reason;
			}
		} else {
			[localException raise];
		}
		retval = NO;
	}

	//NSLog(@"retval in getObjectValue: %d", retval);
	return retval;
}

// NSCoding protocols
- (void)encodeWithCoder:(NSCoder *)encoder
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
		[encoder encodeObject:[self escapeCharacter] forKey:OgreEscapeCharacterKey];
		[encoder encodeObject:@([self options]) forKey:OgreOptionsKey];
		[encoder encodeObject:@(syntaxType) forKey:OgreSyntaxKey];
	} else {
		[encoder encodeObject:[self escapeCharacter]];
		[encoder encodeObject:@([self options])];
		[encoder encodeObject:@(syntaxType)];
	}
}

- (instancetype)initWithCoder:(NSCoder *)decoder
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
		_escapeCharacter = [decoder decodeObjectForKey: OgreEscapeCharacterKey];
	} else {
		// NSString			*_escapeCharacter;
		_escapeCharacter = [decoder decodeObject];
	}
	if (_escapeCharacter == nil) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
        return nil;
	}

	// unsigned		_options;
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
	_options = [anObject unsignedIntValue];

	// OnigSyntaxType		*_syntax;
	// Required improvements. I can not encode If you provide your own syntax. (要改善点。独自のsyntaxを用意した場合はencodeできない。)
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreSyntaxKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
        return nil;
	}
	syntaxType = [anObject integerValue];
	if (syntaxType == -1) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
        return nil;
	}
	_syntax = [OGRegularExpression syntaxForIntValue:(int)syntaxType];

	return self;
}

// NSCopying protocol
- (id)copyWithZone:(NSZone *)zone
{
#ifdef DEBUG_OGRE
	NSLog(@"-copyWithZone: of %@", [self className]);
#endif
    return [[[self class] alloc] initWithOptions:_options
                                          syntax:_syntax
                                 escapeCharacter:_escapeCharacter];
}

- (instancetype)init
{
	return [self initWithOptions:OgreNoneOption
                          syntax:[OGRegularExpression defaultSyntax]
                 escapeCharacter:[OGRegularExpression defaultEscapeCharacter]];
}

- (instancetype)initWithOptions:(OgreOption)options syntax:(OgreSyntax)syntax escapeCharacter:(NSString *)character
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithOptions: of %@", [self className]);
#endif
	self = [super init];
	if (self) {
		_options = options;
		_syntax = syntax;
		_escapeCharacter = character;
	}
	
	return self;
}

@end
