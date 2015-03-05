/*
 * Name: MyObject.m
 * Project: OgreKit
 *
 * Creation Date: Sep 29 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import "MyDocument.h"


@implementation MyDocument

// I teach be searched TextView to OgreTextFinder. (検索対象となるTextViewをOgreTextFinderに教える。)
// To set nil if you do not want to search is. (検索させたくない場合はnilをsetする。)
// If you omit the definition, first responder of main window to adopt it if NSTextView. (定義を省略した場合、main windowのfirst responderがNSTextViewならばそれを採用する。)
- (void)tellMeTargetToFindIn:(id)textFinder
{
	[textFinder setTargetToFindIn:textView];
}


/* Code that is not related to the Find Panel under from here (ここから下はFind Panelに関係しないコード) */
- (NSString*)windowNibName {
    return @"MyDocument";
}

- (NSData*)dataRepresentationOfType:(NSString*)type {
	// The line feed code (if to be replaced) is replaced, you want to save. (改行コードを(置換すべきなら)置換し、保存する。)
	_tmpString = [textView string];
	if ([OGRegularExpression newlineCharacterInString:_tmpString] != _newlineCharacter) {
		_tmpString = [OGRegularExpression replaceNewlineCharactersInString:_tmpString 
			withCharacter:_newlineCharacter];
	}
	
    return [_tmpString dataUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL)loadDataRepresentation:(NSData*)data ofType:(NSString*)type {
	// I read from a file. (UTF8 decided out.) (ファイルから読み込む。(UTF8決めうち。))
	id	aString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	// I get kind of line feed code. (改行コードの種類を得る。)
	_newlineCharacter = [OGRegularExpression newlineCharacterInString:aString];
	if (_newlineCharacter == OgreNonbreakingNewlineCharacter) {
		// Is regarded as OgreUnixNewlineCharacter If there is no line breaks. (改行のない場合はOgreUnixNewlineCharacterとみなす。)
		//NSLog(@"nonbreaking");
		_newlineCharacter = OgreUnixNewlineCharacter;
	}
	
	// The line feed code (if to be replaced) is replaced. (改行コードを(置換すべきなら)置換する。)
	if (_newlineCharacter != OgreUnixNewlineCharacter) {
		_tmpString = [[OGRegularExpression replaceNewlineCharactersInString:aString 
			withCharacter:OgreUnixNewlineCharacter] retain];
	} else {
		_tmpString = [aString retain];
	}
	[aString release];
    aString = nil;
	//NSLog(@"newline character: %d (-1:Nonbreaking 0:LF(Unix) 1:CR(Mac) 2:CR+LF(Windows) 3:UnicodeLineSeparator 4:UnicodeParagraphSeparator)", _newlineCharacter, [OgreTextFinder newlineCharacterInString:_tmpString]);
	//NSLog(@"%@", [OGRegularExpression chomp:_tmpString]);
	
    return YES;
}

- (void)windowControllerDidLoadNib:(NSWindowController*)controller
{
	if (_tmpString) {
		[textView setString:_tmpString];
		[_tmpString release];
        _tmpString = nil;
	} else {
		_newlineCharacter = OgreUnixNewlineCharacter;	// The default line break code (デフォルトの改行コード)
	}
    [super windowControllerDidLoadNib:controller];
}

// Change of line feed code (改行コードの変更)
- (void)setNewlineCharacter:(OgreNewlineCharacter)aNewlineCharacter
{
	_newlineCharacter = aNewlineCharacter;
}

@end
