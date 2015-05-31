/*
 * Name: OGMutablePlainString.h
 * Project: OgreKit
 *
 * Creation Date: Sep 22 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2004 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OGMutablePlainString.h>

@implementation OGMutablePlainString

- (id)init
{
	self = [super init];
	if (self != nil) {
		[self _setString:[[NSMutableString alloc] init]];
	}
	return self;
}

- (id)initWithString:(NSString *)string
{
	if (string == nil) {
		[NSException raise:NSInvalidArgumentException format: @"nil string argument"];
	}
	
	self = [super init];
	if (self != nil) {
		[self _setString:[[NSMutableString alloc] initWithString:string]];
	}
	return self;
}

/* OGMutableStringProtocol */
- (void)appendOGString:(id<OGStringProtocol>)string
{
	[(NSMutableString *)[self _string] appendString:[string string]];
}

- (void)appendString:(NSString *)string
{
	[(NSMutableString *)[self _string] appendString:string];
}

- (void)appendString:(NSString *)string hasAttributesOfOGString:(id<OGStringProtocol>)ogString
{
	[(NSMutableString *)[self _string] appendString:string];
}

- (void)appendAttributedString:(NSAttributedString *)string
{
	[(NSMutableString *)[self _string] appendString:[string string]];
}

- (void)appendOGStringLeaveImprint:(id<OGStringProtocol>)string
{
	[(NSMutableString *)[self _string] appendString:[string string]];
}

- (void)appendOGString:(id<OGStringProtocol>)string 
	changeFont:(BOOL)changeFont 
	mergeAttributes:(BOOL)mergeAttributes 
	ofOGString:(id<OGStringProtocol>)srcString
{
	[(NSMutableString *)[self _string] appendString:[string string]];
}

- (void)appendOGString:(id<OGStringProtocol>)string 
	changeFont:(BOOL)changeFont 
	mergeAttributes:(BOOL)mergeAttributes 
{
	[(NSMutableString *)[self _string] appendString:[string string]];
}

- (void)_setString:(NSString *)string
{
    _string = [string mutableCopy];
}

- (void)setAttributesOfOGString:(id<OGStringProtocol>)string atIndex:(NSUInteger)index
{
	/* do nothing */
}

@end
