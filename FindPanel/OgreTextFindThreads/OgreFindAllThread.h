/*
 * Name: OgreFindAllThread.h
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
#import <OgreKit/OgreTextFindLeaf.h>
#import <OgreKit/OgreFindResultBranch.h>

@class OGRegularExpressionMatch, OGRegularExpressionEnumerator, OgreFindResult;

@interface OgreFindAllThread : OgreTextFindThread
{
    OGRegularExpressionMatch        *match, *lastMatch;
    NSEnumerator                    *matchEnumerator;
    OgreFindResultBranch <OgreFindResultCorrespondingToTextFindLeaf>    *result;
    NSUInteger                      searchLength;
    
    NSString                        *_progressMessage, *_progressMessagePlural, *_remainingTimeMesssage;
}

@end
