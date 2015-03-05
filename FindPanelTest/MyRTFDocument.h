/*
 * Name: MyRTFDocument.h
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

@interface MyRTFDocument : NSDocument <OgreTextFindDataSource>
{
    IBOutlet NSTextView     *textView;
    IBOutlet NSController   *myController;
	NSData                  *_RTFData;
	OgreNewlineCharacter	_newlineCharacter;	// Kind of line feed code (改行コードの種類)
}

// Change of line feed code (改行コードの変更)
- (void)setNewlineCharacter:(OgreNewlineCharacter)aNewlineCharacter;

@property (nonatomic, copy) NSData *rtfData;

@end
