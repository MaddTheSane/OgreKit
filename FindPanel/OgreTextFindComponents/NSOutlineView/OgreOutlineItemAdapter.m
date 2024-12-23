/*
 * Name: OgreOutlineItemAdapter.m
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

#import <OgreKit/OgreOutlineItemAdapter.h>
#import <OgreKit/OgreOutlineCellAdapter.h>
#import <OgreKit/OgreTextFindComponentEnumerator.h>
#import <OgreKit/OgreTextFindReverseComponentEnumerator.h>

#import <OgreKit/OgreOutlineItemFindResult.h>

#import <OgreKit/OgreOutlineView.h>
#import <OgreKit/OgreOutlineColumn.h>

@implementation OgreOutlineItemAdapter

- (id)initWithOutlineColumn:(OgreOutlineColumn *)anOutlineColumn item:(id)item
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -initWithOutlineColumn: of %@", [self className]);
#endif
    self = [super init];
    if (self != nil) {
        _outlineColumn = anOutlineColumn;
        _item = item;
    }
    return self;
}


/* Delegate methods of the OgreTextFindThread */
- (void)willProcessFinding:(NSObject <OgreTextFindVisitor>*)aVisitor 
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -willProcessFinding: of %@(%@)", [self className], [self name]);
#endif
    /* do nothing */ 
}

- (void)didProcessFinding:(NSObject <OgreTextFindVisitor>*)aVisitor
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -didProcessFinding: of %@(%@)", [self className], [self name]);
#endif
    /* do nothing */ 
}

/* Getting information */
- (id)target
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -target of %@", [self className]);
#endif
    return _item; 
}

- (id)name
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -name of %@", [self className]);
#endif
    NSCell                          *dataCell = [_outlineColumn dataCell];
    
    if ([dataCell type] == NSTextCellType) {
        id  anObject = [_outlineColumn ogreObjectValueForItem:_item];
        [dataCell setObjectValue:anObject];
        return [dataCell stringValue];
    }
    
    return nil;
}

- (id)outline
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -outline of %@", [self className]);
#endif
    return @"";
}


/* Examing behavioral attributes */
- (BOOL)isEditable { return [_outlineColumn isEditable]; }
- (BOOL)isHighlightable { return NO; }

/* Getting structural detail */
- (NSUInteger)numberOfChildrenInSelection:(BOOL)inSelection
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -numberOfChildrenInSelection: of %@", [self className]);
#endif
    NSUInteger    count = [_outlineColumn ogreNumberOfChildrenOfItem:_item];
    
    return 1 /* self cell */ + count;
}

- (id)childAtIndex:(NSUInteger)index inSelection:(BOOL)inSelection
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -childAtIndex:%lu of %@", (unsigned long)index, [self className]);
#endif
    OgreOutlineView                 *outlineView = (OgreOutlineView *)[_outlineColumn tableView];
    id <OgreTextFindComponent> adapter;
    
    if (index == 0) {
        /* self cell */
        adapter = [[OgreOutlineCellAdapter alloc] init];
    } else {
        /* child item */
        id  childItem = [_outlineColumn ogreChild:(index - 1) ofItem:_item];
        adapter = [[OgreOutlineItemAdapter alloc] initWithOutlineColumn:_outlineColumn item:childItem];
        [(OgreOutlineItemAdapter *)adapter setLevel:[self level] + 1];
        
    }
    
    if ([self isTerminal] && index == [[outlineView ogrePathComponentsOfSelectedItem][[self level] + 1] integerValue] + 1) {
        [adapter setTerminal:YES];
    }    
    [adapter setParent:self];
    [adapter setIndex:index];
    [adapter setReversed:[self isReversed]];
    
    return adapter;
}

- (NSEnumerator *)componentEnumeratorInSelection:(BOOL)inSelection
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -componentEnumeratorInSelection: of %@", [self className]);
#endif
    //unsigned count = [self numberOfChildrenInSelection:inSelection];
    
    OgreTextFindComponentEnumerator *enumerator;
    if ([self isReversed]) {
        enumerator = [[OgreTextFindReverseComponentEnumerator alloc] initWithBranch:self inSelection:(inSelection/* && (count > 0)*/)];
    } else {
        enumerator = [[OgreTextFindComponentEnumerator alloc] initWithBranch:self inSelection:(inSelection/* && (count > 0)*/)];
    }
    
    if ([self isTerminal]) {
        NSInteger terminal;
        OgreOutlineView *outlineView = (OgreOutlineView *)[_outlineColumn tableView];
        NSArray *path = [outlineView ogrePathComponentsOfSelectedItem];
        terminal = [path[[self level] + 1] integerValue] + 1;
        
        [enumerator setTerminalIndex:terminal];
    }
    
    return enumerator;
}

-(NSIndexSet *)selectedIndexes
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -selectedIndexes of %@", [self className]);
#endif
    NSUInteger count = [self numberOfChildrenInSelection:YES];
    
    return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, count)];
}

- (OgreFindResultBranch *)findResultBranchWithThread:(OgreTextFindThread *)aThread
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -findResultBranchWithThread: of %@", [self className]);
#endif
    return [[OgreOutlineItemFindResult alloc] initWithOutlineColumn:_outlineColumn item:_item];
}

- (OgreTextFindLeaf *)selectedLeaf
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -selectedLeaf of %@", [self className]);
#endif
    return [[self childAtIndex:0 inSelection:YES] selectedLeaf];
}

- (NSWindow *)window
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -window of %@", [self className]);
#endif
    return [[_outlineColumn tableView] window];
}

- (void)expandItemEnclosingItem:(id)item
{
    if (_outlineColumn == nil) return;
    
    [(OgreOutlineItemAdapter *)[self parent] expandItemEnclosingItem:_item];
    
    if (item != _item) {
        OgreOutlineView *outlineView = (OgreOutlineView *)[_outlineColumn tableView];
        [outlineView expandItem:_item];
    }
}

@end
