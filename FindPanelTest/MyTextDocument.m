/*
 * Name: MyTextDocument.m
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

#import "MyTextDocument.h"


@implementation MyTextDocument

// I teach be searched TextView to OgreTextFinder. (検索対象となるTextViewをOgreTextFinderに教える。)
// To set nil if you do not want to search is. (検索させたくない場合はnilをsetする。)
// If you omit the definition, first responder of main window is to adopt it if possible search. (定義を省略した場合、main windowのfirst responderが検索可能ならばそれを採用する。)
- (void)tellMeTargetToFindIn:(id)textFinder
{
	[textFinder setTargetToFindIn:textView];
}


/* Code that is not related to the Find Panel under from here (ここから下はFind Panelに関係しないコード) */
- (NSString*)windowNibName {
    return @"MyTextDocument";
}

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
		_newlineCharacter = OgreUnixNewlineCharacter;	// The default line break code (デフォルトの改行コード)
        _string = [[NSString alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_string release];
    [super dealloc];
}

- (NSString*)string
{
    return _string;
}

- (void)setString:(NSString*)string
{
    [_string autorelease];
    _string = [string retain];
}

- (NSData*)dataOfType:(NSString *)type error:(NSError **)outError
{
	// The line feed code (if to be replaced) is replaced, you want to save. (改行コードを(置換すべきなら)置換し、保存する。)
    if ([myController isEditing]) [myController commitEditing];
    
	NSString *aString = [self string];
	if ([aString newlineCharacter] != _newlineCharacter) {
		aString = [OGRegularExpression replaceNewlineCharactersInString:aString 
			withCharacter:_newlineCharacter];
	}
	
    return [aString dataUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)type error:(NSError **)outError
{
	// I read from a file. (UTF8 decided out.) (ファイルから読み込む。(UTF8決めうち。))
	NSMutableString *aString = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	// I get kind of line feed code. (改行コードの種類を得る。)
	_newlineCharacter = [aString newlineCharacter];
	if (_newlineCharacter == OgreNonbreakingNewlineCharacter) {
		// Is regarded as OgreUnixNewlineCharacter If there is no line breaks. (改行のない場合はOgreUnixNewlineCharacterとみなす。)
		//NSLog(@"nonbreaking");
		_newlineCharacter = OgreUnixNewlineCharacter;
	}
	
	// The line feed code (if to be replaced) is replaced. (改行コードを(置換すべきなら)置換する。)
	if (_newlineCharacter != OgreUnixNewlineCharacter) {
		[aString replaceNewlineCharactersWithCharacter:OgreUnixNewlineCharacter];
	}
	//NSLog(@"newline character: %d (-1:Nonbreaking 0:LF(Unix) 1:CR(Mac) 2:CR+LF(Windows) 3:UnicodeLineSeparator 4:UnicodeParagraphSeparator)", _newlineCharacter, [OgreTextFinder newlineCharacterInString:_tmpString]);
	//NSLog(@"%@", [OGRegularExpression chomp:_tmpString]);
	
    [self setString:aString];
    
    [aString release];
    
    return YES;
}

- (void)windowControllerDidLoadNib:(NSWindowController*)controller
{
    [super windowControllerDidLoadNib:controller];
}

// Change of line feed code (改行コードの変更)
- (void)setNewlineCharacter:(OgreNewlineCharacter)aNewlineCharacter
{
	_newlineCharacter = aNewlineCharacter;
}

@end
