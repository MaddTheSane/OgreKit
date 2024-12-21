/*
 * Name: OGAttributedString.h
 * Project: OgreKit
 *
 * Creation Date: Sep 22 2004
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2004-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OGString.h>

@interface OGAttributedString : NSObject <OGStringProtocol, NSCopying, NSCoding>
{
	NSAttributedString	*_attrString;
}

- (id)initWithString:(NSString*)string;
- (id)initWithAttributedString:(NSAttributedString*)attributedString;
- (id)initWithString:(NSString*)string hasAttributesOfOGString:(id<OGStringProtocol>)ogString;

+ (id)stringWithString:(NSString*)string;
+ (id)stringWithAttributedString:(NSAttributedString*)attributedString;
+ (id)stringithString:(NSString*)string hasAttributesOfOGString:(id<OGStringProtocol>)ogString;

- (NSAttributedString*)_attributedString;
- (void)_setAttributedString:(NSAttributedString*)attributedString;

@end
