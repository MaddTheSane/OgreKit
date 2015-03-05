/*
 * Name: OgreAFPCEscapeCharacterFormatter.h
 * Project: OgreKit
 *
 * Creation Date: Feb 21 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */
 
#import <Foundation/Foundation.h>

@class OGRegularExpression, OGRegularExpressionMatch;

/* Formatter to the input string to one character's head (入力された文字列を頭の1文字にするformatter) */
@protocol OgreAFPCEscapeCharacterFormatterDelegate <NSObject>
- (NSString*)escapeCharacter;
- (BOOL)shouldEquateYenWithBackslash;
@end

@interface OgreAFPCEscapeCharacterFormatter : NSFormatter
{
	id <OgreAFPCEscapeCharacterFormatterDelegate> __unsafe_unretained _delegate;
	
	OGRegularExpression *_backslashRegex, *_yenRegex;
}

// Required method (必須メソッド)
//- (NSString*)stringForObjectValue:(id)anObject;
//- (NSAttributedString*)attributedStringForObjectValue:(id)anObject withDefaultAttributes:(NSDictionary*)attributes;
// Error determination (エラー判定)
//- (BOOL)getObjectValue:(id*)obj forString:(NSString*)string errorDescription:(NSString**)error;

// delegate
@property (unsafe_unretained) id<OgreAFPCEscapeCharacterFormatterDelegate> delegate;
// Conversion (変換)
- (NSString*)equateInString:(NSString*)string;
- (NSAttributedString*)equateInAttributedString:(NSAttributedString*)string;
- (NSString*)equateYenWithBackslash:(OGRegularExpressionMatch*)aMatch 
	contextInfo:(id)contextInfo;
- (NSAttributedString*)equateYenWithBackslashAttributed:(OGRegularExpressionMatch*)aMatch 
	contextInfo:(id)contextInfo;

@end
