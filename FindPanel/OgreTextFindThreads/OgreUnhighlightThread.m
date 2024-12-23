/*
 * Name: OgreUnhighlightThread.m
 * Project: OgreKit
 *
 * Creation Date: May 20 2004
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2004-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreUnhighlightThread.h>
#import <OgreKit/OgreTextFindLeaf.h>
#import <OgreKit/OgreTextFindResult.h>

@interface NSObject (priv)
- (BOOL)didEndUnhighlight:(id)anObject;
@end

@implementation OgreUnhighlightThread

/* Methods implemented by subclasses of OgreTextFindThread */
- (SEL)didEndSelectorForFindPanelController
{
    return @selector(didEndUnhighlight:);
}

- (void)willProcessFindingInLeaf:(OgreTextFindLeaf *)aLeaf;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-willProcessFindingInLeaf: of %@", [self className]);
#endif
    if ([aLeaf isHighlightable]) [aLeaf unhighlight];
}

- (BOOL)shouldContinueFindingInLeaf:(OgreTextFindLeaf *)aLeaf;
{
    return NO; // stop
}

- (void)didProcessFindingAll
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -didProcessFindingAll of %@", [self className]);
#endif
    [[self result] setType:OgreTextFindResultSuccess];
    
    [self finish];
}

@end
