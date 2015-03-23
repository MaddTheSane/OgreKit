/*
 * Name: MyTableDocumentWithCocoaBinding.m
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

#import "MyTableDocumentWithCocoaBinding.h"
#import <OgreKit/OgreKit.h>

@implementation MyTableDocumentWithCocoaBinding

// I teach be searched tableView to OgreTextFinder. (検索対象となるtableViewをOgreTextFinderに教える。)
// To set nil if you do not want to search is. (検索させたくない場合はnilをsetする。)
// If you omit the definition, first responder of main window is to adopt it if possible search. (定義を省略した場合、main windowのfirst responderが検索可能ならばそれを採用する。)
- (void)tellMeTargetToFindIn:(id)textFinder
{
	[textFinder setTargetToFindIn:tableView];
}


/* Under from here code that is not related to the search panel (ここから下は検索パネルに関係しないコード) */
- (void)awakeFromNib
{
    _modelArray = [[NSMutableArray alloc] init];
}

- (void)dealloc
{
    [_modelArray release];
    [super dealloc];
}

- (NSString*)windowNibName 
{
    return @"MyTableDocumentWithCocoaBinding";
}

- (NSData*)dataOfType:(NSString *)type error:(NSError **)outError
{
    return [NSKeyedArchiver archivedDataWithRootObject:_modelArray];
}

- (BOOL)readFromData:(NSData*)data ofType:(NSString*)type error:(NSError **)outError
{
    _modelArray = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
	return YES;
}

- (void)windowControllerDidLoadNib:(NSWindowController*)controller
{
    [super windowControllerDidLoadNib:controller];
}

- (IBAction)dump:(id)sender
{
    [_modelArray makeObjectsPerformSelector:@selector(dump)];
}

// Change of line feed code (改行コードの変更)
- (void)setNewlineCharacter:(OgreNewlineCharacter)aNewlineCharacter
{
	_newlineCharacter = aNewlineCharacter;
}

@end
