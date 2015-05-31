/*
 * Name: OGRegularExpressionFormatter.h
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

#import <Foundation/Foundation.h>
#import <OgreKit/OGRegularExpression.h>

// Exception name
extern NSString	* const OgreFormatterException;


@interface OGRegularExpressionFormatter : NSFormatter <NSCopying, NSCoding>
{
	NSString			*_escapeCharacter;		// \ Alternate character (\の代替文字)
	OgreOption			_options;				// Compile option (コンパイルオプション)
	OgreSyntax			_syntax;				// Regular expression syntax (正規表現の構文)
}

// Required method (必須メソッド)
- (NSString *)stringForObjectValue:(id)anObject;
- (NSAttributedString *)attributedStringForObjectValue:(id)anObject 
	withDefaultAttributes:(NSDictionary *)attributes;
- (NSString *)editingStringForObjectValue:(id)anObject;

// Error determination (エラー判定)
- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string 
	errorDescription:(NSString **)error;

- (instancetype)init;
- (instancetype)initWithOptions:(OgreOption)options
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString *)character NS_DESIGNATED_INITIALIZER;

@property (nonatomic, copy) NSString *escapeCharacter;
@property (nonatomic) OgreOption options;
@property (nonatomic) OgreSyntax syntax;

@end
