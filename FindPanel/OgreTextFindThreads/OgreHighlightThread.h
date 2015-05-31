/*
 * Name: OgreHighlightThread.h
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

@interface OgreHighlightThread : OgreTextFindThread 
{
    OGRegularExpressionMatch    *_match, *_lastMatch;
    NSEnumerator                *_matchEnumerator;
    NSUInteger                  _numberOfGroups;
    NSUInteger                  _searchLength;

    /* highlight color */
    NSMutableArray              *_highlightColorArray;   // variations
    
    NSString                    *_progressMessage, *_progressMessagePlural, *_remainingTimeMesssage;
}

@end
