/*
 * Name: OgreTextFindBranch.m
 * Project: OgreKit
 *
 * Creation Date: Sep 26 2003
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreTextFindBranch.h>
#import <OgreKit/OgreTextFindLeaf.h>
#import <OgreKit/OgreFindResultBranch.h>


@implementation OgreTextFindBranch
@synthesize index = _index;
/*
#ifdef DEBUG_OGRE_FIND_PANEL
- (id)retain
{
	NSLog(@"-retain of %@", [self className]);
    return [super retain];
}

- (oneway void)release
{
	NSLog(@"-release of %@", [self className]);
    [super release];
}
#endif
*/

- (void)dealloc
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -dealloc of %@", [self className]);
#endif
    _parentStrong = nil; // Technically superfluous.
}

- (void)acceptVisitor:(NSObject <OgreTextFindVisitor>*)aVisitor // visitor pattern
{
    [aVisitor visitBranch:self];
}

/* Delegate methods of the OgreTextFindThread */
- (void)willProcessFinding:(NSObject <OgreTextFindVisitor>*)aVisitor 
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -willProcessFinding: of %@", [self className]);
#endif
    /* do nothing */ 
}

- (void)didProcessFinding:(NSObject <OgreTextFindVisitor>*)aVisitor
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -didProcessFinding: of %@", [self className]);
#endif
    /* do nothing */ 
}

/* Getting information */
- (id)target
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -target of %@", [self className]);
#endif
    return nil; 
}

- (id)name
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -name of %@ (BUG!!!)", [self className]);
#endif
    return nil; 
}

- (id)outline
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -outline of %@ (BUG!!!)", [self className]);
#endif
    return nil; 
}


/* Examing behavioral attributes */
- (BOOL)isEditable { return NO; }
- (BOOL)isHighlightable { return NO; }

/* Getting structural detail */
- (BOOL)isLeaf { return NO; }
- (BOOL)isBranch { return YES; }

- (NSUInteger)numberOfChildrenInSelection:(BOOL)inSelection
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -numberOfChildrenInSelection: of %@ (BUG!!!)", [self className]);
#endif
    return 0; 
}

- (NSUInteger)numberOfDescendantsInSelection:(BOOL)inSelection
{ 
    NSUInteger          numberOfDescendants = 0;
    NSEnumerator        *enumerator = (NSEnumerator *)[self componentEnumeratorInSelection:inSelection];
    OgreTextFindLeaf    *aChild;
    
    while ((aChild = [enumerator nextObject]) != nil) {
        if ([aChild isLeaf]) {
            numberOfDescendants++;
        } else {
            numberOfDescendants += [aChild numberOfDescendantsInSelection:inSelection];
        }
    }
    
    return numberOfDescendants;
}

- (id)childAtIndex:(NSUInteger)index inSelection:(BOOL)inSelection
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -childAtIndex: of %@ (BUG!!!)", [self className]);
#endif
    return nil; 
}

- (NSEnumerator *)componentEnumeratorInSelection:(BOOL)inSelection
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -componentEnumeratorInSelection: of %@ (BUG!!!)", [self className]);
#endif
    return nil; 
}

-(NSIndexSet *)selectedIndexes
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -selectedIndexes of %@ (BUG!!!)", [self className]);
#endif
    return nil; 
}

- (OgreFindResultBranch *)findResultBranchWithThread:(OgreTextFindThread *)aThread
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -findResultBranchWithThread: of %@ (BUG!!!)", [self className]);
#endif
    return nil; 
}

- (OgreTextFindBranch *)parent
{
#ifdef DEBUG_OGRE_FIND_PANEL
	if (_parent == nil) NSLog(@"  -parent == nil of OgreTextFindBranch (BUG?)");
#endif
    return _parent;
}

- (void)setParent:(OgreTextFindBranch *)parent
{
    _parent = parent;
    _parentStrong = parent;
}

- (void)setParentNoRetain:(OgreTextFindBranch *)parent
{
    _parent = parent;
    _parentStrong = nil;
}

- (OgreTextFindLeaf *)selectedLeaf
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -selectedLeaf of %@ (BUG?)", [self className]);
#endif
    return [[self childAtIndex:0 inSelection:YES] selectedLeaf];
}

- (NSWindow *)window
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -window of %@ (BUG!!!)", [self className]);
#endif
    return nil;
}

@synthesize terminal = _isTerminal;
@synthesize reversed = _isReversed;

- (void)finalizeFinding
{
    [self didProcessFinding:nil];
    [_parent finalizeFinding];
}

@end
