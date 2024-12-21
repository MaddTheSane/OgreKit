/*
 * Name: OgreFindThread.h
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

#import <OgreKit/OgreTextFindThread.h>

@class OGRegularExpressionMatch, OGRegularExpressionEnumerator, OgreFindResult;
@class OgreTextFindThread;

@interface OgreFindThread : OgreTextFindThread 
{
    BOOL                _wrap;                  // wrapped search
    BOOL                _backward;              // search direction
    BOOL                _fromTop;               // search origin
    
    NSEnumerator        *matchEnumerator;
    BOOL                _lhsPhase;
}

- (BOOL)shouldPreprocessFindingInFirstLeaf;
- (BOOL)preprocessFindingInFirstLeaf:(OgreTextFindLeaf*)aLeaf;

/// wrapped search
@property BOOL wrap;
/// search direction
@property BOOL backward;
/// search origin
@property BOOL fromTop;

// private methods
- (BOOL)_preprocessFindingInFirstLeaf:(OgreTextFindLeaf*)aLeaf;

@end
