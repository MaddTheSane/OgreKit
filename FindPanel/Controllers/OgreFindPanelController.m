/*
 * Name: OgreFindPanelController.m
 * Project: OgreKit
 *
 * Creation Date: Sep 13 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreTextFinder.h>
#import <OgreKit/OgreFindPanelController.h>

@implementation OgreFindPanelController

- (void)awakeFromNib
{
	/* Reproduce the position of the previous Find Panel (前回のFind Panelの位置を再現) */
    [[self findPanel] setFrameAutosaveName: @"Find Panel"];
    [[self findPanel] setFrameUsingName: @"Find Panel"];
    [[self findPanel] setCollectionBehavior:NSWindowCollectionBehaviorMoveToActiveSpace]; // Show Find Panel on Desktop Space currently displayed (現在表示中のDesktop SpaceにFind Panelを表示)
}

- (OgreTextFinder*)textFinder
{
	return textFinder;
}

- (void)setTextFinder:(OgreTextFinder*)aTextFinder
{
	textFinder = aTextFinder;
}


- (IBAction)showFindPanel:(id)sender
{
	[findPanel makeKeyAndOrderFront:self];
	// Add Find Panel in Windows menu (WindowsメニューにFind Panelを追加)
	[NSApp addWindowsItem:findPanel title:[findPanel title] filename:NO];
}

- (void)close
{
	[findPanel orderOut:self];
}

- (NSPanel*)findPanel
{
	return findPanel;
}

- (void)setFindPanel:(NSPanel*)aPanel
{
	[aPanel retain];
	[findPanel release];
	findPanel = aPanel;
}

// NSCoding protocols
- (NSDictionary*)history
{
	/* If you want to save the history, etc., to return in NSDictionary. (履歴等を保存したい場合は、NSDictionaryで返す。) */
	return @{};
}

@end
