/*
 * Name: OgreTableView.h
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


@interface OgreTableView : NSTableView <OgreView>
{
    NSInteger	_ogreSelectedColumn;
    NSInteger	_ogreSelectedRow;
    NSRange		_ogreSelectedRange;
}

@property (nonatomic, readonly, strong) NSObject<OgreTextFindComponent> *ogreAdapter;

@property (nonatomic, setter=ogreSetSelectedColumn:) NSInteger ogreSelectedColumn;
@property (nonatomic, setter=ogreSetSelectedRow:) NSInteger ogreSelectedRow;
@property (nonatomic, setter=ogreSetSelectedRange:) NSRange ogreSelectedRange;

@property (nonatomic) NSInteger ogreEditedColumn;
@property (nonatomic) NSInteger ogreEditedRow;

- (void)ogreHighlightTextForSelectedPosition;

@end
