/*
 * Name: OgreOutlineView.h
 * Project: OgreKit
 *
 * Creation Date: Jun 13 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <AppKit/AppKit.h>
#import <OgreKit/OgreView.h>


@interface OgreOutlineView : NSOutlineView <OgreView>
{
    NSInteger     _ogreSelectedColumn;
    id            _ogreSelectedItem;
    NSRange       _ogreSelectedRange;
    
    NSMutableArray  *_ogrePathComponents;
}

@property (nonatomic, readonly) NSInteger ogreSelectedColumn;
- (void)ogreSetSelectedColumn:(NSInteger)column;

@property (nonatomic, readonly, copy) NSArray *ogrePathComponentsOfSelectedItem;
- (void)ogreSetSelectedItem:(id)item;

@property (nonatomic, readonly) NSRange ogreSelectedRange;
- (void)ogreSetSelectedRange:(NSRange)aRange;

@end
