/*
 * Name: OGMutableString.h
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

#import <Foundation/Foundation.h>
#import <OgreKit/OGString.h>

NS_ASSUME_NONNULL_BEGIN

@protocol OGMutableStringProtocol <NSObject>
- (void)appendString:(NSString*)string;
- (void)appendString:(NSString*)string 
	hasAttributesOfOGString:(id<OGStringProtocol>)ogString;

- (void)appendAttributedString:(NSAttributedString*)string;

- (void)appendOGString:(id<OGStringProtocol>)string;
- (void)appendOGStringLeaveImprint:(id<OGStringProtocol>)string;
- (void)appendOGString:(id<OGStringProtocol>)string 
	changeFont:(BOOL)changeFont 
	mergeAttributes:(BOOL)mergeAttributes;
- (void)appendOGString:(id<OGStringProtocol>)string 
	changeFont:(BOOL)changeFont 
	mergeAttributes:(BOOL)mergeAttributes 
	ofOGString:(id<OGStringProtocol>)srcString;

- (void)setAttributesOfOGString:(id<OGStringProtocol>)string
	atIndex:(NSUInteger)index;
@end

NS_ASSUME_NONNULL_END
