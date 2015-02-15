/*
 * Name: OgreTextFindLeaf.h
 * Project: OgreKit
 *
 * Creation Date: Sep 26 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreTextFindComponent.h>
#import <OgreKit/OGString.h>

@class OgreFindResultLeaf, OgreTextFindThread;

@interface OgreTextFindLeaf : NSObject <OgreTextFindComponent>
{
    OgreTextFindBranch      *_parent;
    NSInteger               _index;
    BOOL                    _isParentRetained;
    
    BOOL                    _isTerminal;
    BOOL                    _isFirstLeaf;
    BOOL                    _isReversed;
}

- (void)beginEditing;       // begin editing
- (void)endEditing;         // end editing
- (void)beginRegisteringUndoWithCapacity:(NSUInteger)aCapacity;  // begin resistering undo oprations
- (void)endRegisteringUndo;  // end resistering undo oprations

@property (getter=isSelected, readonly) BOOL selected;
@property  NSRange selectedRange;
- (void)jumpToSelection;

@property (strong, setter=setOGString:) id<OGStringProtocol> ogString;
- (void)replaceCharactersInRange:(NSRange)aRange withOGString:(id<OGStringProtocol>)aString;

- (void)unhighlight;
- (void)highlightCharactersInRange:(NSRange)aRange color:(NSColor*)highlightColor;

- (OgreFindResultLeaf*)findResultLeafWithThread:(OgreTextFindThread*)aThread;

@property (getter=isFirstLeaf) BOOL firstLeaf;

@end
