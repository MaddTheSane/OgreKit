/*
 * Name: OgreAttachableWindowMediator.h
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
#import <OgreKit/OgreAttachableWindowAcceptor.h>
#import <OgreKit/OgreAttachableWindowAcceptee.h>

@interface OgreAttachableWindowMediator : NSObject
{
	NSMutableArray	*_acceptors;
	CGFloat			_tolerance;
	BOOL			_processing;
}

+ (instancetype)sharedMediator;
@property CGFloat tolerance;

- (void)addAcceptor:(NSWindow<OgreAttachableWindowAcceptorProtocol>*)acceptor;
- (void)removeAcceptor:(NSWindow<OgreAttachableWindowAcceptorProtocol>*)acceptor;

- (void)attachAcceptee:(NSWindow<OgreAttachableWindowAccepteeProtocol>*)acceptee;

/* private methods */
- (CGFloat)gluingStrengthBetweenAcceptee:(NSWindow<OgreAttachableWindowAccepteeProtocol>*)acceptee
	andAcceptor:(NSWindow<OgreAttachableWindowAcceptorProtocol>*)acceptor
	withAccepteeEdge:(NSRectEdge *)edge;
- (void)attachAcceptee:(NSWindow<OgreAttachableWindowAccepteeProtocol>*)acceptee
	toAcceptor:(NSWindow<OgreAttachableWindowAcceptorProtocol>*)acceptor
	withAccepteeEdge:(NSRectEdge)edge;

/* delegate methods of OgreAttachableWindowAcceptee */
- (void)windowWillMove:(id)notification;
- (void)windowDidMove:(id)notification;
- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)proposedFrameSize;

@end
