/*
 * Name: MyTableDocument.h
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

#import <AppKit/AppKit.h>
#import <OgreKit/OgreKit.h>

@interface MyTableDocument : NSDocument <OgreTextFindDataSource, NSTableViewDataSource, NSTableViewDelegate>
{
	IBOutlet NSTableView    *tableView;
    NSMutableDictionary     *_dict;
    NSMutableArray          *_titleArray;
	OgreNewlineCharacter	_newlineCharacter;	// Kind of line feed code (改行コードの種類)
    NSUInteger              _numberOfColumns;
    NSRect                  _sheetPosition;
    BOOL                    _useCustomSheetPosition;
}

// Change of line feed code (改行コードの変更)
- (void)setNewlineCharacter:(OgreNewlineCharacter)aNewlineCharacter;

@property (nonatomic, readonly) NSInteger numberOfRows;

- (IBAction)addRow:(id)sender;
- (IBAction)removeRow:(id)sender;
- (IBAction)addColumn:(id)sender;
- (IBAction)removeColumn:(id)sender;

@end
