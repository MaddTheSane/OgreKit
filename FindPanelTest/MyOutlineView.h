/*
 * Name: MyOutlineView.h
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

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>

@protocol MyOutlineViewDelegate <NSObject>
- (void)deleteKeyDownInOutlineView:(NSOutlineView *)outlineView;
@end

@interface MyOutlineView : OgreOutlineView
{
}
@end
