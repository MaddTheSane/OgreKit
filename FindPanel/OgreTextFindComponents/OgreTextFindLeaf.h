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

@protocol OgreFindResultCorrespondingToTextFindLeaf <NSObject>
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

@property (nonatomic, getter=isSelected, readonly) BOOL selected;
@property (nonatomic) NSRange selectedRange;
- (void)jumpToSelection;

@property (nonatomic, strong, setter=setOGString:) id<OGStringProtocol> ogString;
- (void)replaceCharactersInRange:(NSRange)aRange withOGString:(id<OGStringProtocol>)aString;

- (void)unhighlight;
- (void)highlightCharactersInRange:(NSRange)aRange color:(NSColor*)highlightColor;

- (id <OgreFindResultCorrespondingToTextFindLeaf>)findResultLeafWithThread:(OgreTextFindThread*)aThread;

@property (nonatomic, getter=isFirstLeaf) BOOL firstLeaf;

@end
