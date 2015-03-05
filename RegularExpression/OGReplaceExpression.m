/*
 * Name: OGReplaceExpression.m
 * Project: OgreKit
 *
 * Creation Date: Sep 22 2003
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
#import <OgreKit/OGReplaceExpression.h>
#import <OgreKit/OGReplaceExpressionPrivate.h>
#import <OgreKit/OGString.h>
#import <OgreKit/OGMutableString.h>
#import <OgreKit/OGPlainString.h>
#import <OgreKit/OGAttributedString.h>
#import <stdlib.h>
#import <limits.h>

// exception name
NSString	* const OgreReplaceException = @"OGReplaceExpressionException";
// Key for encoding/decoding itself (自身をencoding/decodingするためのkey)
static NSString	* const OgreCompiledReplaceStringKey     = @"OgreReplaceCompiledReplaceString";
static NSString	* const OgreCompiledReplaceStringTypeKey = @"OgreReplaceCompiledReplaceStringType";
static NSString	* const OgreNameArrayKey                 = @"OgreReplaceNameArray";
static NSString	* const OgreReplaceOptionsKey            = @"OgreReplaceOptions";
// 
static OGRegularExpression  *gReplaceRegex = nil;

// \+, \-, \`, \'
#define OgreEscapePlus					(-1)
#define OgreEscapeMinus					(-2)
#define OgreEscapeBackquote				(-3)
#define OgreEscapeQuote					(-4)
#define OgreEscapeNamedGroup			(-5)
#define OgreEscapeControlCode			(-6)
#define OgreEscapeNormalCharacters		(-8)
#define OgreNonEscapedNormalCharacters	(-9)


@implementation OGReplaceExpression

+ (void)initialize
{
#ifdef DEBUG_OGRE
	NSLog(@"+initialize of %@", [self className]);
#endif
	gReplaceRegex = [[OGRegularExpression alloc] 
		initWithString:[NSString stringWithFormat:
		@"([^\\\\]+)|(?:\\\\x\\{(?@[0-9a-fA-F]{1,4})\\}){1,%d}|(?:\\\\(?:([0-9])|(&)|(\\+)|(`)|(')|(\\-)|(?:g<([0-9]+)>)|(?:g<([_a-zA-Z][_0-9a-zA-Z]*)>)|(t)|(n)|(r)|(\\\\)|(.?)))", ONIG_MAX_CAPTURE_HISTORY_GROUP] 
		/*1						2                                        3		 4   5	   6   7   8          9               10                         11  12  13  14     15    */
		options:(OgreCaptureGroupOption) 
		syntax:OgreRubySyntax 
		escapeCharacter:OgreBackslashCharacter];
}

// Initialization (初期化)
- (instancetype)initWithOGString:(NSObject<OGStringProtocol>*)replaceString 
	options:(NSUInteger)options 
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithString: of %@", [self className]);
#endif
	self = [super init];
	if (self == nil) return nil;
	
	if ((replaceString == nil) || (character == nil) || ([character length] == 0)) {
		// If string is nil, raise an exception. (stringがnilの場合、例外を発生させる。)
		[self release];
		[NSException raise:NSInvalidArgumentException format: @"nil string (or other) argument"];
	}
	
	_options = options;
	
    NSString    *escCharacter = [NSString stringWithString:character];
	NSInteger	specialKey = 0;
	NSUInteger	matchIndex = 0;
	NSString	*controlCharacter = nil;
	NSObject<OGStringProtocol>	*compileTimeString;
	NSUInteger	numberOfMatches = 0;
	unichar		unic[ONIG_MAX_CAPTURE_HISTORY_GROUP + 1];
	NSUInteger	numberOfHistory, indexOfHistory;
	
	NSEnumerator				*matchEnumerator;
	OGRegularExpressionMatch	*match;
    OGRegularExpressionCapture  *cap;
	
	// I will compile the replacement string (置換文字列をcompileする)
	//   compile Result: NSMutableArray (compile結果: NSMutableArray)
	//   String 		NSString (文字列		NSString)
	//   Special character 		NSNumber (特殊文字		NSNumber)
	//				Correspondence table (int: special characters) (対応表(int:特殊文字))
	//				0-9: \0 - \9
	//				OgreEscapePlus: \+
	//				OgreEscapeMinus: \-
	//				OgreEscapeBackquote: \`
	//				OgreEscapeQuote: \'
	//				OgreEscapeNamedGroup: \g
	//				OgreEscapeControlCode: \t, \n, \r
	//				OgreEscapeNormalCharacters: \[^\]?
	//				OgreNonEscapedNormalCharacters: otherwise
	
	/* named group-related (named group関連) */
	_nameArray = [[NSMutableArray alloc] initWithCapacity:0];	// names that have been used in replacedString (appeared the order) (replacedStringで使用されたnames (現れた順))
	
	if (syntax == OgreSimpleMatchingSyntax) {
		_compiledReplaceString     = [[NSMutableArray alloc] initWithObjects:replaceString, nil];
		_compiledReplaceStringType = [[NSMutableArray alloc] initWithObjects:@OgreNonEscapedNormalCharacters, nil];
	} else {
		_compiledReplaceString     = [[NSMutableArray alloc] initWithCapacity:0];
		_compiledReplaceStringType = [[NSMutableArray alloc] initWithCapacity:0];
		
		if ([character isEqualToString:OgreBackslashCharacter]) {
			compileTimeString = replaceString;
		} else {
			compileTimeString = [OGRegularExpression changeEscapeCharacterInOGString:replaceString toCharacter:escCharacter];
		}
		
		matchEnumerator = [gReplaceRegex matchEnumeratorInOGString:compileTimeString
			options:OgreCaptureGroupOption 
			range:NSMakeRange(0, [[compileTimeString string] length])];
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		while ((match = [matchEnumerator nextObject]) != nil) {
			numberOfMatches++;
			
			matchIndex = [match indexOfFirstMatchedSubstring];  // Did matched to any subexpression (どの部分式にマッチしたのか)
	#ifdef DEBUG_OGRE
			NSLog(@" matchIndex: %d, %@", matchIndex, [match matchedString]);
	#endif
			switch (matchIndex) {
				case 1: // Ordinary character (通常文字)
					specialKey = OgreNonEscapedNormalCharacters;
					break;
				case 15: // \\[^\\]? 
					specialKey = OgreEscapeNormalCharacters;
					break;
				case 2: // \x{H} or \x{HH}, \x{HHH}, \x{HHHH} (H is a hexadecimal number)
					specialKey = OgreEscapeControlCode;
					cap = [match captureHistory];
					numberOfHistory = [cap numberOfChildren];
					for (indexOfHistory = 0; indexOfHistory < numberOfHistory; indexOfHistory++) {
						unic[indexOfHistory] = (unichar)strtoul([[[cap childAtIndex:indexOfHistory] string] UTF8String], NULL, 16);
					}
					unic[numberOfHistory] = 0;
					controlCharacter = [NSString stringWithCharacters:unic length:numberOfHistory];
					break;
				case 3: // \[0-9]
					specialKey = [[match substringAtIndex:matchIndex] integerValue];
					break;
				case 4: // \&
					specialKey = 0;
					break;
				case 5: // \+
					specialKey = OgreEscapePlus;
					break;
				case 6: // \`
					specialKey = OgreEscapeBackquote;
					break;
				case 7: // \'
					specialKey = OgreEscapeQuote;
					break;
				case 8: // \-
					specialKey = OgreEscapeMinus;
					break;
				case 9: // \g<number>
					specialKey = [[match substringAtIndex:matchIndex] integerValue];
					break;
				case 10: // \g<name>
					specialKey = OgreEscapeNamedGroup;
					[_nameArray addObject:[match substringAtIndex:matchIndex]];
					break;
				case 11: // \t
					specialKey = OgreEscapeControlCode;
					controlCharacter = [NSString stringWithFormat:@"\x09"];
					break;
				case 12: // \n
					specialKey = OgreEscapeControlCode;
					controlCharacter = [NSString stringWithFormat:@"\x0a"];
					break;
				case 13: // \r
					specialKey = OgreEscapeControlCode;
					controlCharacter = [NSString stringWithFormat:@"\x0d"];
					break;
				case 14: // Escape Character
					specialKey = OgreEscapeControlCode;
					controlCharacter = OgreBackslashCharacter;
					break;
				default: // error
					[NSException raise:OgreException format: @"undefined replace expression (BUG!)"];
					break;
			}
			
			if (specialKey == OgreEscapeNormalCharacters || specialKey == OgreNonEscapedNormalCharacters) {
				// Normal string (通常文字列)
				[_compiledReplaceString addObject:[compileTimeString substringWithRange:
					[match rangeOfSubstringAtIndex:matchIndex]]];
				specialKey = OgreNonEscapedNormalCharacters;
			}  else if (specialKey == OgreEscapeControlCode) {
				// Control characters (コントロール文字)
				[_compiledReplaceString addObject:[[[[compileTimeString class] alloc] 
					initWithString:controlCharacter 
					hasAttributesOfOGString:[compileTimeString substringWithRange:[match rangeOfMatchedString]]
					] autorelease]];
				specialKey = OgreNonEscapedNormalCharacters;
			} else {
				// Other (その他)
				[_compiledReplaceString addObject:[compileTimeString substringWithRange:
					[match rangeOfMatchedString]]];
			}
			[_compiledReplaceStringType addObject:@(specialKey)];
			
			if ((numberOfMatches % 100) == 0) {
				[pool release];
				pool = [[NSAutoreleasePool alloc] init];
			}
		}
		
		[pool release];
	}
	
	// As a result of compile been (compileされた結果)
#ifdef DEBUG_OGRE
	NSLog(@"Compiled Replace String: %@", [_compiledReplaceString description]);
	NSLog(@"Name Array: %@", [_nameArray description]);
#endif

	return self;
}


- (instancetype)initWithString:(NSString*)replaceString 
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character
{
	return [self initWithOGString:[OGPlainString stringWithString:replaceString] 
		options:OgreNoneOption 
		syntax:syntax 
		escapeCharacter:character];
}

- (instancetype)initWithString:(NSString*)replaceString 
	escapeCharacter:(NSString*)character 
{
	return [self initWithString:replaceString 
		syntax:[OGRegularExpression defaultSyntax] 
		escapeCharacter:character];
}

- (instancetype)initWithString:(NSString*)replaceString
{
	return [self initWithString:replaceString 
		syntax:[OGRegularExpression defaultSyntax] 
		escapeCharacter:[OGRegularExpression defaultEscapeCharacter]];
}


- (instancetype)initWithAttributedString:(NSAttributedString*)replaceString 
	options:(NSUInteger)options 
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character
{
	return [self initWithOGString:[OGAttributedString stringWithAttributedString:replaceString] 
		options:options 
		syntax:syntax 
		escapeCharacter:character];
}

- (instancetype)initWithAttributedString:(NSAttributedString*)replaceString 
	options:(NSUInteger)options  
{
	return [self initWithAttributedString:replaceString 
		options:options 
		syntax:[OGRegularExpression defaultSyntax] 
		escapeCharacter:[OGRegularExpression defaultEscapeCharacter]];
}

- (instancetype)initWithAttributedString:(NSAttributedString*)replaceString
{
	return [self initWithAttributedString:replaceString 
		options:OgreNoneOption 
		syntax:[OGRegularExpression defaultSyntax] 
		escapeCharacter:[OGRegularExpression defaultEscapeCharacter]];
}


+ (instancetype)replaceExpressionWithString:(NSString*)replaceString 
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character
{
	return [[[[self class] alloc] initWithString:replaceString 
		syntax:syntax 
		escapeCharacter:character] autorelease];
}

+ (instancetype)replaceExpressionWithString:(NSString*)replaceString 
	escapeCharacter:(NSString*)character
{
	return [[[[self class] alloc] initWithString:replaceString 
		syntax:[OGRegularExpression defaultSyntax] 
		escapeCharacter:character] autorelease];
}

+ (instancetype)replaceExpressionWithString:(NSString*)replaceString;
{
	return [[[[self class] alloc] initWithString:replaceString 
		syntax:[OGRegularExpression defaultSyntax] 
		escapeCharacter:[OGRegularExpression defaultEscapeCharacter]] autorelease];
}


+ (instancetype)replaceExpressionWithAttributedString:(NSAttributedString*)replaceString 
	options:(NSUInteger)options 
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character
{
	return [[[[self class] alloc] initWithAttributedString:replaceString 
		options:options 
		syntax:syntax 
		escapeCharacter:character] autorelease];
}

+ (instancetype)replaceExpressionWithAttributedString:(NSAttributedString*)replaceString 
	options:(NSUInteger)options 
{
	return [[[[self class] alloc] initWithAttributedString:replaceString 
		options:options 
		syntax:[OGRegularExpression defaultSyntax] 
		escapeCharacter:[OGRegularExpression defaultEscapeCharacter]] autorelease];
}

+ (instancetype)replaceExpressionWithAttributedString:(NSAttributedString*)replaceString;
{
	return [[[[self class] alloc] initWithAttributedString:replaceString 
		options:OgreNoneOption 
		syntax:[OGRegularExpression defaultSyntax] 
		escapeCharacter:[OGRegularExpression defaultEscapeCharacter]] autorelease];
}

+ (instancetype)replaceExpressionWithOGString:(NSObject<OGStringProtocol>*)replaceString 
	options:(NSUInteger)options 
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character
{
	return [[[[self class] alloc] initWithOGString:replaceString 
		options:options 
		syntax:syntax 
		escapeCharacter:character] autorelease];
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
	[_compiledReplaceStringType release];
	[_compiledReplaceString release];
	[_nameArray release];
	
	[super dealloc];
}

// Replacement (置換)
- (NSString*)replaceMatchedStringOf:(OGRegularExpressionMatch*)match
{
	return [[self replaceMatchedOGStringOf:match] string];
}

- (NSAttributedString*)replaceMatchedAttributedStringOf:(OGRegularExpressionMatch*)match {
	return [[self replaceMatchedOGStringOf:match] attributedString];
}

- (NSObject<OGStringProtocol>*)replaceMatchedOGStringOf:(OGRegularExpressionMatch*)match 
{
	if (match == nil) {
		[NSException raise:NSInvalidArgumentException format: @"nil string (or other) argument"];
	}
	
	NSObject<OGStringProtocol,OGMutableStringProtocol>	*resultString;
	resultString = [[[[[match targetOGString] mutableClass] alloc] init] autorelease];	// Substitution result (置換結果)
	
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	// I replace the matched string according to compile has been the replacement string (マッチした文字列をcompileされた置換文字列に従って置換する)
	NSEnumerator	*strEnumerator = [_compiledReplaceString objectEnumerator];
	NSEnumerator	*typeEnumerator = [_compiledReplaceStringType objectEnumerator];
	NSObject<OGStringProtocol>		*string;
	NSObject<OGStringProtocol>		*substr;
	NSNumber		*type;
	
	NSString	*name;
	NSUInteger	numOfNames = 0;
	NSInteger	specialKey;
	
	BOOL		attributedReplace = ((_options & OgreReplaceWithAttributesOption) != 0);
	BOOL		replaceFonts = ((_options & OgreReplaceFontsOption) != 0);
	BOOL		mergeAttributes = ((_options & OgreMergeAttributesOption) != 0);
	
	//[resultString setAttributesOfOGString:[match targetOGString] atIndex:[match rangeOfMatchedString].location];
	NSUInteger	headIndex = [match rangeOfMatchedString].location - [match _searchRange].location;
	[resultString setAttributesOfOGString:[match targetOGString] atIndex:headIndex];
	
	while ( (string = [strEnumerator nextObject]) != nil && (type = [typeEnumerator nextObject]) != nil ) {
		specialKey = [type integerValue];
		switch (specialKey) {
			case OgreNonEscapedNormalCharacters:	// [^\]+
				if (!attributedReplace) {
					[resultString appendString:[string string]];
				} else {
					[resultString appendOGString:string 
						changeFont:replaceFonts 
						mergeAttributes:mergeAttributes];
				}
				break;
			case OgreEscapePlus:			// \+
				// Last matched substring (最後にマッチした部分文字)
				substr = [match lastMatchOGSubstring];
				if (substr != nil) {
					if (!attributedReplace) {
						[resultString appendOGStringLeaveImprint:substr];
					} else {
						[resultString appendOGString:substr 
							changeFont:replaceFonts 
							mergeAttributes:mergeAttributes 
							ofOGString:string];
					}
				}
				break;
			case OgreEscapeBackquote:	// \`
				// Before of the character than the matched substring (マッチした部分よりも前の文字)
				substr = [match prematchOGString];
				if (!attributedReplace) {
					[resultString appendOGStringLeaveImprint:substr];
				} else {
					[resultString appendOGString:substr 
						changeFont:replaceFonts 
						mergeAttributes:mergeAttributes 
						ofOGString:string];
				}
				break;
			case OgreEscapeQuote:		// \'
				// Back of the character than the matched substring (マッチした部分よりも後ろの文字)
				substr = [match postmatchOGString];
				if (!attributedReplace) {
					[resultString appendOGStringLeaveImprint:substr];
				} else {
					[resultString appendOGString:substr 
						changeFont:replaceFonts 
						mergeAttributes:mergeAttributes 
						ofOGString:string];
				}
				break;
			case OgreEscapeMinus:		// \-
				// Characters between the matched part and matched part before one (マッチした部分と一つ前にマッチした部分の間の文字)
				substr = [match ogStringBetweenMatchAndLastMatch];
				if (!attributedReplace) {
					[resultString appendOGStringLeaveImprint:substr];
				} else {
					[resultString appendOGString:substr 
						changeFont:replaceFonts 
						mergeAttributes:mergeAttributes 
						ofOGString:string];
				}
				break;
			case OgreEscapeNamedGroup:	// \g<name>
				name = _nameArray[numOfNames];
				substr = [match ogSubstringNamed:name];
				numOfNames++;
				if (substr != nil) {
					if (!attributedReplace) {
						[resultString appendOGStringLeaveImprint:substr];
					} else {
						[resultString appendOGString:substr 
							changeFont:replaceFonts 
							mergeAttributes:mergeAttributes 
							ofOGString:string];
					}
				}
				break;
			default:	// \0 - \9, \&, \g<index>
				substr = [match ogSubstringAtIndex:specialKey];
				if (substr != nil) {
					if (!attributedReplace) {
						[resultString appendOGStringLeaveImprint:substr];
					} else {
						[resultString appendOGString:substr 
							changeFont:replaceFonts 
							mergeAttributes:mergeAttributes 
							ofOGString:string];
					}
				}
				break;
		}
	}
	
	[pool release];
	
	return resultString;
}

// NSCoding protocols
- (void)encodeWithCoder:(NSCoder*)encoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-encodeWithCoder: of %@", [self className]);
#endif
	if ([encoder allowsKeyedCoding]) {
		[encoder encodeObject: _compiledReplaceString forKey: OgreCompiledReplaceStringKey];
		[encoder encodeObject: _compiledReplaceStringType forKey: OgreCompiledReplaceStringTypeKey];
		[encoder encodeObject: _nameArray forKey: OgreNameArrayKey];
		[encoder encodeObject: @(_options) forKey: OgreReplaceOptionsKey];
	} else {
		[encoder encodeObject: _compiledReplaceString];
		[encoder encodeObject: _compiledReplaceStringType];
		[encoder encodeObject: _nameArray];
		[encoder encodeObject: @(_options)];
	}
}

- (id)initWithCoder:(NSCoder*)decoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithCoder: of %@", [self className]);
#endif
	self = [super init];
	if (self == nil) return nil;
	
	BOOL			allowsKeyedCoding = [decoder allowsKeyedCoding];
	
    if (allowsKeyedCoding) {
		_compiledReplaceString = [[decoder decodeObjectForKey:OgreCompiledReplaceStringKey] retain];
	} else {
		_compiledReplaceString = [[decoder decodeObject] retain];
	}
	if (_compiledReplaceString == nil) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		[self release];
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	
    if (allowsKeyedCoding) {
		_compiledReplaceStringType = [[decoder decodeObjectForKey:OgreCompiledReplaceStringTypeKey] retain];
	} else {
		_compiledReplaceStringType = [[decoder decodeObject] retain];
	}
	if (_compiledReplaceStringType == nil) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		[self release];
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	
    if (allowsKeyedCoding) {
		_nameArray = [[decoder decodeObjectForKey:OgreNameArrayKey] retain];
	} else {
		_nameArray = [[decoder decodeObject] retain];
	}
	if (_nameArray == nil) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		[self release];
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	
	NSNumber	*aNumber;
    if (allowsKeyedCoding) {
		aNumber = [decoder decodeObjectForKey:OgreReplaceOptionsKey];
	} else {
		aNumber = [decoder decodeObject];
	}
	if (aNumber == nil) {
		// Error. I raise an exception. (エラー。例外を発生させる。)
		[self release];
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	_options = [aNumber unsignedIntegerValue];
	
	return self;
}

// NSCopying protocol
- (id)copyWithZone:(NSZone*)zone
{
#ifdef DEBUG_OGRE
	NSLog(@"-copyWithZone: of %@", [self className]);
#endif
	id	newObject = [[[self class] allocWithZone:zone] init];
	if (newObject != nil) {
		[newObject _setCompiledReplaceString:_compiledReplaceString];
		[newObject _setCompiledReplaceStringType:_compiledReplaceStringType];
		[newObject _setNameArray:_nameArray];
		[newObject _setOptions:_options];
	}
	
	return newObject;
}

// description
- (NSString*)description
{
	return [@{@"Compiled Replace String": _compiledReplaceString, 
			@"Compiled Replace String Type": _compiledReplaceStringType, 
			@"Names": _nameArray,
			@"Replace Options": [OGRegularExpression stringsForOptions:OgreReplaceTimeOptionMask(_options)]} description];
}

@end
