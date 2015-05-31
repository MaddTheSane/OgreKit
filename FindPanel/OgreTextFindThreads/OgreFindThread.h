/*
 * Name: OgreFindThread.h
 * Project: OgreKit
 *
 * Creation Date: May 20 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2004 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreTextFindThread.h>

@class OGRegularExpressionMatch, OGRegularExpressionEnumerator, OgreFindResult;
@class OgreTextFindThread;

@interface OgreFindThread : OgreTextFindThread 
{
    NSEnumerator        *_matchEnumerator;
    BOOL                _lhsPhase;
}

- (BOOL)shouldPreprocessFindingInFirstLeaf;
- (BOOL)preprocessFindingInFirstLeaf:(OgreTextFindLeaf *)aLeaf;

@property (nonatomic) BOOL wrap;        // wrapped search
@property (nonatomic) BOOL backward;    // search direction
@property (nonatomic) BOOL fromTop;     // search origin

// private methods
- (BOOL)_preprocessFindingInFirstLeaf:(OgreTextFindLeaf *)aLeaf;

@end
