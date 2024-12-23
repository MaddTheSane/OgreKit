/*
 * Name: OgreTextFindLeaf.m
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

#import <OgreKit/OgreTextFindLeaf.h>
#import <OgreKit/OgreTextFindBranch.h>
#import <OgreKit/OgreTextFindResult.h>


@implementation OgreTextFindLeaf
@synthesize reversed = _isReversed;
@synthesize firstLeaf = _isFirstLeaf;
@synthesize terminal = _isTerminal;
@synthesize index = _index;

- (void)dealloc
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -dealloc of %@", [self className]);
#endif
    _parentStrong = nil; // Technically superfluous.
}

- (void)acceptVisitor:(NSObject <OgreTextFindVisitor>*)aVisitor // visitor pattern
{
    [aVisitor visitLeaf:self];
}


- (void)addMatch:(OGRegularExpressionMatch *)aMatch
{
#ifdef DEBUG_OGRE_FIND_PANEL
    NSLog(@" -addMatch: of %@ (BUG!!!)", [self className]);
#endif
    /* do nothing */
}

- (void)endAddition
{
    /* do nothing */
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
- (BOOL)isLeaf { return YES; }
- (BOOL)isBranch { return NO; }
- (NSUInteger)numberOfChildrenInSelection:(BOOL)inSelection { return 0; }
- (NSUInteger)numberOfDescendantsInSelection:(BOOL)inSelection { return 0; }
- (id)childAtIndex:(NSUInteger)index inSelection:(BOOL)inSelection { return nil; }

- (OgreTextFindBranch *)parent
{
#ifdef DEBUG_OGRE_FIND_PANEL
	if (_parent == nil) NSLog(@"  -parent == nil of OgreTextFindLeaf (BUG?)");
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

/* Accessor methods */
- (void)beginEditing { /* do nothing */ }
- (void)endEditing { /* do nothing */ }
- (void)beginRegisteringUndoWithCapacity:(NSUInteger)aCapacity { /* do nothing */ }
- (void)endRegisteringUndo { /* do nothing */ }

- (BOOL)isSelected
{
    return NO;
}

- (NSRange)selectedRange 
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -selectedRange of %@ (BUG?)", [self className]);
#endif
    return NSMakeRange(0, 0); 
}

- (void)setSelectedRange:(NSRange)aRange
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -setSelectedRange: of %@ (BUG?)", [self className]);
#endif
    /* do nothing */
}

- (void)jumpToSelection
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -jumpToSelection of %@ (BUG?)", [self className]);
#endif
    /* do nothing */
}


- (id<OGStringProtocol>)ogString 
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -string of %@ (BUG!!!)", [self className]);
#endif
    return nil; 
}

- (void)setOGString:(id<OGStringProtocol>)aString 
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -setOGString: of %@ (BUG?)", [self className]);
#endif
    /* do nothing */ 
}

- (void)replaceCharactersInRange:(NSRange)aRange withOGString:(id<OGStringProtocol>)aString
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -replaceCharactersInRange:withOGString: of %@ (BUG?)", [self className]);
#endif
    /* do nothing */ 
}


- (void)unhighlight
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -unhighlight of %@ (BUG?)", [self className]);
#endif
    /* do nothing */ 
}

- (void)highlightCharactersInRange:(NSRange)aRange color:(NSColor *)highlightColor
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -highlightCharactersInRange:color: of %@ (BUG?)", [self className]);
#endif
    /* do nothing */ 
}


- (id <OgreFindResultCorrespondingToTextFindLeaf>)findResultLeafWithThread:(OgreTextFindThread *)aThrea
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -findResultLeafWithThread: of %@ (BUG!!!)", [self className]);
#endif
    return nil; 
}

- (OgreTextFindLeaf *)selectedLeaf
{
    [self setFirstLeaf:YES];
    return self;
}

- (NSWindow *)window
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -window of %@ (BUG!!!)", [self className]);
#endif
    return nil;
}

- (BOOL)isTerminal
{
    return _isTerminal;
}

- (void)setTerminal:(BOOL)isTerminal
{
    if (isTerminal) _isFirstLeaf = NO;
    _isTerminal = isTerminal;
}

- (BOOL)isFirstLeaf
{
    return _isFirstLeaf;
}

- (void)setFirstLeaf:(BOOL)isFirstLeaf
{
    if (isFirstLeaf) _isTerminal = NO;
    _isFirstLeaf = isFirstLeaf;
}

- (void)finalizeFinding
{
    [self didProcessFinding:nil];
    [_parent finalizeFinding];
}

@end
