/*
 * Name: OgreTextViewUndoer.h
 * Project: OgreKit
 *
 * Creation Date: Jun 05 2004
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreTextFindBranch.h>
#import <OgreKit/OgreTextFindLeaf.h>

@class OgreTableView;

@interface OgreTableViewAdapter : OgreTextFindBranch <OgreTextFindTargetAdapter>
{
    OgreTableView   *_tableView;
}

- (instancetype)initWithTarget:(id)aTableView;

@end
