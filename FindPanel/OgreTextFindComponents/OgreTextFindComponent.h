/*
 * Name: OgreTextFindComponent.h
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

#import <Foundation/Foundation.h>
#import <AppKit/NSWindow.h>

@protocol OgreTextFindVisitor;
@class OgreTextFindLeaf, OgreTextFindBranch, OgreTextFindThread;

@protocol OgreTextFindComponent <NSObject>
- (void)acceptVisitor:(NSObject <OgreTextFindVisitor>*)aVisitor; // visitor pattern

/* Delegate methods of the OgreTextFindThread */
- (void)willProcessFinding:(NSObject <OgreTextFindVisitor>*)aVisitor;
- (void)didProcessFinding:(NSObject <OgreTextFindVisitor>*)aVisitor;
- (void)finalizeFinding;

/* Getting information */
- (id)target;               // a target (view) wrapped by a OgreTextFindComponent
- (id)name;
- (id)outline;
- (NSWindow *)window;

/* Examing behavioral attributes */
@property (readonly, getter=isEditable) BOOL editable;
@property (readonly, getter=isHighlightable) BOOL highlightable;

/* Getting and setting structural detail */
@property (readonly, getter=isLeaf) BOOL leaf;
@property (readonly, getter=isBranch) BOOL branch;
- (NSUInteger)numberOfChildrenInSelection:(BOOL)inSelection;
- (NSUInteger)numberOfDescendantsInSelection:(BOOL)inSelection;
- (id)childAtIndex:(NSUInteger)index inSelection:(BOOL)inSelection;

@property (readwrite, retain) OgreTextFindBranch *parent;
- (void)setParentNoRetain:(OgreTextFindBranch *)parent;
@property NSInteger index;
//@property (readonly) OgreTextFindLeaf *selectedLeaf;
- (OgreTextFindLeaf *)selectedLeaf;

@property (getter=isTerminal) BOOL terminal;
@property (getter=isReversed) BOOL reversed;

@end

@protocol OgreTextFindVisitor <NSObject>
- (void)visitLeaf:(OgreTextFindLeaf *)aLeaf;
- (void)visitBranch:(OgreTextFindBranch *)aBranch;
@end

@protocol OgreTextFindTargetAdapter <NSObject>
- (OgreTextFindLeaf *)buildStackForSelectedLeafInThread:(OgreTextFindThread *)aThread;
- (void)moveHomePosition;
@end
