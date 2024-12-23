/*
 * Name: OgreFindPanelController.m
 * Project: OgreKit
 *
 * Creation Date: Sep 13 2003
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreTextFinder.h>
#import <OgreKit/OgreFindPanelController.h>

@implementation OgreFindPanelController
@synthesize textFinder;
@synthesize findPanel;

- (void)awakeFromNib
{
	/* Reproduce the position of the previous Find Panel (前回のFind Panelの位置を再現) */
    [[self findPanel] setFrameAutosaveName: @"Find Panel"];
    [[self findPanel] setFrameUsingName: @"Find Panel"];
    [[self findPanel] setCollectionBehavior:NSWindowCollectionBehaviorMoveToActiveSpace]; // Show Find Panel on Desktop Space currently displayed (現在表示中のDesktop SpaceにFind Panelを表示)
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

// NSCoding protocols
- (NSDictionary *)history
{
	/* If you want to save the history, etc., to return in NSDictionary. (履歴等を保存したい場合は、NSDictionaryで返す。) */
	return @{};
}

@end
