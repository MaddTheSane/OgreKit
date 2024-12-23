/*
 * Name: OGRegularExpressionMatchPrivate.h
 * Project: OgreKit
 *
 * Creation Date: Sep 01 2003
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>
#import <OgreKit/OGRegularExpressionMatch.h>
#import <OgreKit/OGString.h>

@interface OGRegularExpressionMatch ()

/*********
 * 初期化 *
 *********/
- (instancetype)initWithRegion:(OnigRegion*)region 
	index:(NSUInteger)anIndex
	enumerator:(OGRegularExpressionEnumerator*)enumerator
	terminalOfLastMatch:(NSUInteger)terminalOfLastMatch;

- (id<OGStringProtocol>)_targetString;
- (NSRange)_searchRange;
- (OnigRegion *)_region;

@end
