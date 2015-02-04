/*
 * Name: OGReplaceExpressionPrivate.m
 * Project: OgreKit
 *
 * Creation Date: Sep 23 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OGReplaceExpression.h>
#import <OgreKit/OGReplaceExpressionPrivate.h>


@implementation OGReplaceExpression (Private)

- (void)_setCompiledReplaceString:(NSMutableArray*)compiledReplaceString
{
	_compiledReplaceString = [compiledReplaceString retain];
}

- (void)_setCompiledReplaceStringType:(NSMutableArray*)compiledReplaceStringType
{
	_compiledReplaceStringType = [compiledReplaceStringType retain];
}

- (void)_setNameArray:(NSMutableArray*)nameArray
{
	_nameArray = [nameArray retain];
}

- (void)_setOptions:(NSUInteger)options
{
	_options = options;
}

@end
