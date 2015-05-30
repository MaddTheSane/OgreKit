/*
 * Name: MyRTFDocument.m
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

#import "MyRTFDocument.h"


@implementation MyRTFDocument

// I teach be searched TextView to OgreTextFinder. (検索対象となるTextViewをOgreTextFinderに教える。)
// To set nil if you do not want to search is. (検索させたくない場合はnilをsetする。)
// If you omit the definition, first responder of main window is to adopt it if possible search. (定義を省略した場合、main windowのfirst responderが検索可能ならばそれを採用する。)
- (void)tellMeTargetToFindIn:(id)textFinder
{
	[textFinder setTargetToFindIn:textView];
}


/* Code that is not related to the Find Panel under from here (ここから下はFind Panelに関係しないコード) */
- (NSString*)windowNibName {
    return @"MyRTFDocument";
}

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
		_newlineCharacter = OgreUnixNewlineCharacter;	// The default line break code (デフォルトの改行コード)
        _RTFData = [[NSData alloc] init];
    }
    return self;
}

@synthesize rtfData = _RTFData;

- (NSData*)dataOfType:(NSString *)type error:(NSError **)outError
{
	// The line feed code (if to be replaced) is replaced, you want to save. (改行コードを(置換すべきなら)置換し、保存する。)
    if ([myController isEditing]) [myController commitEditing];
    
    return [self rtfData];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)type error:(NSError **)outError
{
    [self setRtfData:data];
    
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
