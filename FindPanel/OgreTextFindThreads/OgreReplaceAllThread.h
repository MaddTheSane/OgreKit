/*
 * Name: OgreReplaceAllThread.h
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
#import <OgreKit/OGString.h>

@class OGRegularExpressionMatch, OGRegularExpressionEnumerator;
@class OgreTextFindThread, OgreFindResult;

@interface OgreReplaceAllThread : OgreTextFindThread 
{
    NSArray					*_matchArray;
    NSUInteger				_replaceAllNumberOfReplaces, _replaceAllNumberOfMatches;
    NSString				*_progressMessage, *_progressMessagePlural, *_remainingTimeMesssage;
	id<OGStringProtocol>	_replacedString;
}

@end
