/*
 * Name: MyTableDocumentWithCocoaBinding.h
 * Project: OgreKit
 *
 * Creation Date: Sep 29 2003
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <AppKit/AppKit.h>
#import <OgreKit/OgreKit.h>

@interface MyTableDocumentWithCocoaBinding : NSDocument <OgreTextFindDataSource>
{
	IBOutlet NSTableView    *tableView;
	OgreNewlineCharacter	_newlineCharacter;	// Kind of line feed code (改行コードの種類)
    
    NSMutableArray  *_modelArray;
}

// Change of line feed code (改行コードの変更)
- (void)setNewlineCharacter:(OgreNewlineCharacter)aNewlineCharacter;

- (IBAction)dump:(id)sender;

@end
