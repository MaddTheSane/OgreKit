/*
 * Name: OgreOutlineViewFindResult.m
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

#import <OgreKit/OgreOutlineViewFindResult.h>
#import <OgreKit/OgreTextFindResult.h>
#import <OgreKit/OgreTableColumnFindResult.h>

#import <OgreKit/OgreOutlineView.h>

@implementation OgreOutlineViewFindResult

- (id)initWithOutlineView:(OgreOutlineView *)outlineView
{
    self = [super init];
    if (self != nil) {
        _outlineView = outlineView;
        _components = [[NSMutableArray alloc] initWithCapacity:[_outlineView numberOfColumns]];
    }
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addComponent:(NSObject <OgreTextFindComponent>*)aFindResultComponent 
{
    [_components addObject:aFindResultComponent];
}

- (void)endAddition
{
	//I detect a closing window for that target. (targetのあるwindowのcloseを検出する。)
	[[NSNotificationCenter defaultCenter] addObserver: self 
		selector: @selector(windowWillClose:) 
		name: NSWindowWillCloseNotification
		object: [_outlineView window]];
}

- (id)name
{
    if (_outlineView == nil) return [[self textFindResult] missingString];
    return [_outlineView className];
}

- (id)outline
{
    if (_outlineView == nil) return [[self textFindResult] missingString];
    return [[self textFindResult] messageOfItemsFound:[_components count]];
}

- (NSUInteger)numberOfChildrenInSelection:(BOOL)inSelection
{
    return [_components count];
}

- (id)childAtIndex:(NSUInteger)index inSelection:(BOOL)inSelection
{
    return _components[index];
}

- (NSEnumerator *)componetEnumeratorInSelection:(BOOL)inSelection 
{
    return [_components objectEnumerator]; 
}

- (BOOL)showMatchedString
{
    if (_outlineView == nil) return NO;
    
	[[_outlineView window] makeKeyAndOrderFront:self];
    return YES;
}

- (BOOL)selectMatchedString
{
    return (_outlineView != nil);
}

- (void)windowWillClose:(NSNotification *)aNotification
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-windowWillClose: of %@", [self className]);
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	_outlineView = nil;
    [_components makeObjectsPerformSelector:@selector(targetIsMissing)];
    [[self textFindResult] didUpdate];
}


@end
