/*
 * Name: OgreFindAllThread.h
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
#import <OgreKit/OgreTextFindLeaf.h>
#import <OgreKit/OgreFindResultBranch.h>

@class OGRegularExpressionMatch, OGRegularExpressionEnumerator, OgreFindResult;

@interface OgreFindAllThread : OgreTextFindThread
{
    OGRegularExpressionMatch        *_match, *_lastMatch;
    NSEnumerator                    *_matchEnumerator;
    OgreFindResultBranch <OgreFindResultCorrespondingToTextFindLeaf>    *_result;
    NSUInteger                      _searchLength;
    
    NSString                        *_progressMessage, *_progressMessagePlural, *_remainingTimeMesssage;
}

@end
