/*
 * Name: OgreAttachableWindowAcceptee.h
 * Project: OgreKit
 *
 * Creation Date: Aug 31 2004
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2004-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Cocoa/Cocoa.h>

@protocol OgreAttachableWindowAcceptorProtocol;

@protocol OgreAttachableWindowAccepteeProtocol <NSObject>
@property BOOL dragging;
@property BOOL resizing;
@property NSPoint difference;
- (BOOL)isAttachableAccepteeEdge:(NSRectEdge)edge toAcceptor:(NSWindow<OgreAttachableWindowAcceptorProtocol>*)acceptor;
@end

@interface OgreAttachableWindowAcceptee : NSPanel <OgreAttachableWindowAccepteeProtocol>
{
	BOOL	_dragging;
	BOOL	_resizing;
	NSPoint	_diff;
}

@end
