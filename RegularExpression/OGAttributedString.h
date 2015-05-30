/*
 * Name: OGAttributedString.h
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

@interface OGAttributedString : NSObject <OGStringProtocol, NSCopying, NSCoding>
{
	NSAttributedString	*_attrString;
}

- (instancetype)initWithString:(NSString*)string;
- (instancetype)initWithAttributedString:(NSAttributedString*)attributedString;
- (instancetype)initWithString:(NSString*)string hasAttributesOfOGString:(id<OGStringProtocol>)ogString;

+ (instancetype)stringWithString:(NSString*)string;
+ (instancetype)stringWithAttributedString:(NSAttributedString*)attributedString;
+ (instancetype)stringithString:(NSString*)string hasAttributesOfOGString:(id<OGStringProtocol>)ogString;

@property (nonatomic, copy, getter=_attributedString, setter=_setAttributedString:) NSAttributedString *attributedString;

@end
