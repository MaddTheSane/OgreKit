/*
 * Name: OgreTextFindComponentEnumerator.h
 * Project: OgreKit
 *
 * Creation Date: Jun 05 2004
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>

@class OgreTextFindBranch;

@interface OgreTextFindComponentEnumerator : NSEnumerator
{
    OgreTextFindBranch	*_branch;
    NSUInteger			*_indexes, _count;
	NSInteger			_nextIndex;
    NSInteger			_terminalIndex;
    BOOL				_inSelection;
}

- (instancetype)initWithBranch:(OgreTextFindBranch*)aBranch inSelection:(BOOL)inSelection NS_DESIGNATED_INITIALIZER;
@property (nonatomic) NSInteger terminalIndex;
@property (nonatomic) NSInteger startIndex;

@end
