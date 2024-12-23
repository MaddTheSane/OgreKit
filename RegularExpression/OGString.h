/*
 * Name: OGString.h
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

#import <Foundation/Foundation.h>

// exception name
extern NSExceptionName const OgreStringException;

@protocol OGStringProtocol <NSObject>
- (NSString*)string;
- (NSAttributedString*)attributedString;
- (NSUInteger)length;

- (id<OGStringProtocol>)substringWithRange:(NSRange)aRange;

- (Class)mutableClass;
@end
