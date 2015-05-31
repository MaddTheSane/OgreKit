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
    NSArray					*matchArray;
    OGReplaceExpression		*replaceExpression;
    NSUInteger				aNumberOfReplaces, aNumberOfMatches;
    NSString				*progressMessage, *progressMessagePlural, *remainingTimeMesssage;
	id<OGStringProtocol>	replacedString;
}

@end
