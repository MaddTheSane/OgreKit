/*
 * Name: MyMenuController.m
 * Project: OgreKit
 *
 * Creation Date: Oct 16 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import "MyMenuController.h"
#import "MyDocument.h"
#import "MyDocumentController.h"

@implementation MyMenuController

/* Convey the change of line endings to the delegate of the main window (very shoddy) (改行コードの変更をmain windowのdelegateに伝える (非常に手抜き)) */
- (IBAction)selectCr:(id)sender
{
	[(MyDocument *)[[NSApp mainWindow] delegate] setNewlineCharacter:OgreCrNewlineCharacter];
}

- (IBAction)selectCrLf:(id)sender
{
	[(MyDocument *)[[NSApp mainWindow] delegate] setNewlineCharacter:OgreCrLfNewlineCharacter];
}

- (IBAction)selectLf:(id)sender
{
	[(MyDocument *)[[NSApp mainWindow] delegate] setNewlineCharacter:OgreLfNewlineCharacter];
}

/* New Document (新規ドキュメント) */
- (IBAction)newTextDocument:(id)sender
{
    MyDocumentController *dc = [NSDocumentController sharedDocumentController];
    dc.untitledDocumentType = @"MyTextDocumentType";
    [dc openUntitledDocumentAndDisplay:YES
                                 error:NULL];
}

- (IBAction)newRTFDocument:(id)sender
{
    MyDocumentController *dc = [NSDocumentController sharedDocumentController];
    dc.untitledDocumentType = @"MyRTFDocumentType";
    [dc openUntitledDocumentAndDisplay:YES
                                 error:NULL];
}

- (IBAction)newTableDocument:(id)sender
{
    MyDocumentController *dc = [NSDocumentController sharedDocumentController];
    dc.untitledDocumentType = @"MyTableDocumentType";
    [dc openUntitledDocumentAndDisplay:YES
                                 error:NULL];
}

- (IBAction)newOutlineDocument:(id)sender
{
    MyDocumentController *dc = [NSDocumentController sharedDocumentController];
    dc.untitledDocumentType = @"MyOutlineDocumentType";
    [dc openUntitledDocumentAndDisplay:YES
                                 error:NULL];
}

- (IBAction)newTableDocumentWithCocoaBinding:(id)sender
{
    MyDocumentController *dc = [NSDocumentController sharedDocumentController];
    dc.untitledDocumentType = @"MyTableDocumentWithCocoaBindingType";
    [dc openUntitledDocumentAndDisplay:YES
                                 error:NULL];
}


- (void)awakeFromNib
{
    [[NSApplication sharedApplication] setDelegate:self];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    return NO;
}

- (void)ogreKitWillHackFindMenu:(OgreTextFinder *)textFinder
{
	[textFinder setShouldHackFindMenu:YES];
}

- (void)ogreKitShouldUseStylesInFindPanel:(OgreTextFinder *)textFinder
{
	[textFinder setUseStylesInFindPanel:YES];
}

@end
