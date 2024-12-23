/*
 * Name: OgreOutlineViewFindResult.h
 * Project: OgreKit
 *
 * Creation Date: Jun 06 2004
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreFindResultBranch.h>

@class OgreOutlineView;

@interface OgreOutlineViewFindResult : OgreFindResultBranch 
{
    OgreOutlineView *_outlineView;
    NSMutableArray  *_components;
}

- (instancetype)initWithOutlineView:(OgreOutlineView *)outlineView;

@end
