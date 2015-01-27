/*
 * Name: OgreFindPanelController.h
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

#import <Cocoa/Cocoa.h>

@class OgreTextFinder;

@interface OgreFindPanelController : NSResponder
{
	IBOutlet OgreTextFinder		*textFinder;
	IBOutlet NSPanel			*findPanel;
}

- (IBAction)showFindPanel:(id)sender;
- (void)close;

@property (nonatomic, strong) OgreTextFinder *textFinder;

@property (nonatomic, strong) NSPanel *findPanel;

- (NSDictionary*)history;

@end
