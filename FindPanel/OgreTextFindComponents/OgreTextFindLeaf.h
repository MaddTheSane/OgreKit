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

#import <Foundation/Foundation.h>

#import <OgreKit/OgreTextFindComponent.h>

#import <OgreKit/OGRegularExpressionMatch.h>

@protocol OgreFindResultCorrespondingToTextFindLeaf
- (void)addMatch:(OGRegularExpressionMatch*)aMatch;
- (void)endAddition;
@end

@interface OgreTextFindLeaf : NSObject <OgreTextFindComponent, OgreFindResultCorrespondingToTextFindLeaf>
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

- (BOOL)isSelected;
- (NSRange)selectedRange;
- (void)setSelectedRange:(NSRange)aRange;
- (void)jumpToSelection;

- (NSObject<OGStringProtocol>*)ogString;
- (void)setOGString:(NSObject<OGStringProtocol>*)aString;
- (void)replaceCharactersInRange:(NSRange)aRange withOGString:(NSObject<OGStringProtocol>*)aString;

- (void)unhighlight;
- (void)highlightCharactersInRange:(NSRange)aRange color:(NSColor*)highlightColor;

- (id <OgreFindResultCorrespondingToTextFindLeaf>)findResultLeafWithThread:(OgreTextFindThread*)aThread;

- (BOOL)isFirstLeaf;
- (void)setFirstLeaf:(BOOL)isFirstLeaf;

@end
