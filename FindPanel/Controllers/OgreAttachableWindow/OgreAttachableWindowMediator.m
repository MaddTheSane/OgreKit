/*
 * Name: OgreAttachableWindowMediator.m
 * Project: OgreKit
 *
 * Creation Date: Aug 31 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2004 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreAttachableWindowMediator.h>

#import <tgmath.h>

static OgreAttachableWindowMediator	*gSharedInstance = nil;

static Boolean symbolCFArrayEqualCallback(const void *value1, const void *value2)
{
	return (value1 == value2);
}

static CFArrayCallBacks noRetainArrayCallbacks = {
	0,		//version
	NULL,	// no retain
	NULL,	// no release
	NULL,	// deafult
	&symbolCFArrayEqualCallback	// compare by pointer values
};

@implementation OgreAttachableWindowMediator
@synthesize tolerance = _tolerance;

+ (id)sharedMediator
{
	if (gSharedInstance == nil) {
		gSharedInstance = [[self alloc] init];
	}
	
	return gSharedInstance;
}

- (id)init
{
	if (gSharedInstance != nil) {
		return gSharedInstance;
	}
	
	self = [super init];
	if (self != nil) {
		_acceptors = (NSMutableArray *)CFBridgingRelease(CFArrayCreateMutable(kCFAllocatorDefault, 0, &noRetainArrayCallbacks));
		[self setTolerance:10];
		_processing = NO;
	}
	
	return self;
}

- (void)addAcceptor:(NSWindow<OgreAttachableWindowAcceptorProtocol>*)acceptor
{
	if (![_acceptors containsObject:acceptor]) {
		[_acceptors addObject:acceptor];
		//NSLog(@"addAcceptor:%@", [acceptor title]);
	}
}

- (void)removeAcceptor:(NSWindow<OgreAttachableWindowAcceptorProtocol>*)acceptor
{
	if ([_acceptors containsObject:acceptor]) {
		[_acceptors removeObject:acceptor];
		//NSLog(@"removeAcceptor:%@", [acceptor title]);
	}
}

- (void)attachAcceptee:(NSWindow<OgreAttachableWindowAccepteeProtocol>*)acceptee
{
	//NSLog(@"acceptee: %@", [acceptee title]);
	CGFloat	maxStrength = 0;
	NSWindow<OgreAttachableWindowAcceptorProtocol>	*acceptor = nil;
	
	NSArray			*childWindows = [acceptee childWindows];
	NSEnumerator	*acceptorEnumerator = [_acceptors objectEnumerator];
	NSWindow<OgreAttachableWindowAcceptorProtocol>	*candidate;
	NSRectEdge		accepteeEdge = 0;
	while ((candidate = [acceptorEnumerator nextObject]) != nil) {
		if ([candidate isEqual:acceptee] || [childWindows containsObject:candidate] || ![candidate isVisible]) {
			continue;
		}
		
		CGFloat	strength = [self gluingStrengthBetweenAcceptee:acceptee 
			andAcceptor:candidate
			withAccepteeEdge:&accepteeEdge];
		
		//NSLog(@" acceptor: %@(%f)", [candidate title], strength);
		
		if (strength > maxStrength) {
			maxStrength = strength;
			acceptor = candidate;
		}
	}
	
	//NSLog(@"acceptee: %@", [acceptee title]);
	[[acceptee parentWindow] removeChildWindow:acceptee];
	if (acceptor != nil) {
		//NSLog(@"acceptee: %@ acceptor: %@", [acceptee title], [acceptor title]);
		[acceptor addChildWindow:acceptee ordered:NSWindowAbove];
		[self attachAcceptee:acceptee toAcceptor:acceptor withAccepteeEdge:accepteeEdge];
	}
}

- (CGFloat)gluingStrengthBetweenAcceptee:(NSWindow<OgreAttachableWindowAccepteeProtocol>*)acceptee
	andAcceptor:(NSWindow<OgreAttachableWindowAcceptorProtocol>*)acceptor
	withAccepteeEdge:(NSRectEdge *)edge;
{
	CGFloat	strength = 0;
	CGFloat	t = [self tolerance];
	
	NSRect	ef = [acceptee frame];
	CGFloat	ex = ef.origin.x;
	CGFloat	ey = ef.origin.y;
	CGFloat	ew = ef.size.width;
	CGFloat	eh = ef.size.height;
	
	NSRect	rf = [acceptor frame];
	CGFloat	rx = rf.origin.x;
	CGFloat	ry = rf.origin.y;
	CGFloat	rw = rf.size.width;
	CGFloat	rh = rf.size.height;
	
	if ([acceptee isAttachableAccepteeEdge:NSMinXEdge toAcceptor:acceptor] && 
		[acceptor isAttachableAcceptorEdge:NSMaxXEdge toAcceptee:acceptee]) {
		
		NSRect	eLeftEdge   = NSMakeRect(ex-t,    ey+t,       2*t, eh-2*t);
		NSRect	rRightEdge  = NSMakeRect(rx+rw-t, ry+t,       2*t, rh-2*t);
		strength = NSIntersectionRect(eLeftEdge, rRightEdge).size.height;
		if (strength > 0) {
			*edge = NSMinXEdge;
			return strength;
		}
	}
	
	if ([acceptee isAttachableAccepteeEdge:NSMaxXEdge toAcceptor:acceptor] && 
		[acceptor isAttachableAcceptorEdge:NSMinXEdge toAcceptee:acceptee]) {
		
		NSRect	eRightEdge  = NSMakeRect(ex+ew-t, ey+t,       2*t, eh-2*t);
		NSRect	rLeftEdge   = NSMakeRect(rx-t,    ry+t,       2*t, rh-2*t);
		strength = NSIntersectionRect(eRightEdge, rLeftEdge).size.height;
		if (strength > 0) {
			*edge = NSMaxXEdge;
			return strength;
		}
	}
	
	if ([acceptee isAttachableAccepteeEdge:NSMaxYEdge toAcceptor:acceptor] && 
		[acceptor isAttachableAcceptorEdge:NSMinYEdge toAcceptee:acceptee]) {
		
		NSRect	eTopEdge    = NSMakeRect(ex+t,    ey+eh-t, ew-2*t, 2*t);
		NSRect	rBottomEdge = NSMakeRect(rx+t,    ry-t,    rw-2*t, 2*t);
		strength = NSIntersectionRect(eTopEdge, rBottomEdge).size.width;
		if (strength > 0) {
			*edge = NSMaxYEdge;
			return strength;
		}
	}
	
	if ([acceptee isAttachableAccepteeEdge:NSMinYEdge toAcceptor:acceptor] && 
		[acceptor isAttachableAcceptorEdge:NSMaxYEdge toAcceptee:acceptee]) {
		
		NSRect	eBottomEdge = NSMakeRect(ex+t,    ey-t,    ew-2*t, 2*t);
		NSRect	rTopEdge    = NSMakeRect(rx+t,    ry+rh-t, rw-2*t, 2*t);
		strength = NSIntersectionRect(eBottomEdge, rTopEdge).size.width;
	}
	
	*edge = NSMinYEdge;
	return strength;
}

- (void)attachAcceptee:(NSWindow<OgreAttachableWindowAccepteeProtocol>*)acceptee
	toAcceptor:(NSWindow<OgreAttachableWindowAcceptorProtocol>*)acceptor
	withAccepteeEdge:(NSRectEdge)edge;
{
	CGFloat	t = [self tolerance];
	
	NSRect	ef = [acceptee frame];
	CGFloat	ex = ef.origin.x;
	CGFloat	ey = ef.origin.y;
	CGFloat	ew = ef.size.width;
	CGFloat	eh = ef.size.height;
	
	NSRect	rf = [acceptor frame];
	CGFloat	rx = rf.origin.x;
	CGFloat	ry = rf.origin.y;
	CGFloat	rw = rf.size.width;
	CGFloat	rh = rf.size.height;
	
	NSRect	eLeftEdge, rRightEdge;
	NSRect	eRightEdge, rLeftEdge;
	NSRect	eTopEdge, rBottomEdge;
	NSRect	eBottomEdge, rTopEdge;
	
	switch (edge) {
		case NSMinXEdge:
			eLeftEdge   = NSMakeRect(ex-t,    ey+t,       2*t, eh-2*t);
			rRightEdge  = NSMakeRect(rx+rw-t, ry+t,       2*t, rh-2*t);
			if (NSIntersectsRect(eLeftEdge, rRightEdge)) {
				ef.origin.x = rx + rw;
				
				CGFloat	dty = fabs((ey + eh) - (ry + rh));
				CGFloat	dby = fabs(ey - ry);
				if (dty < 2 * t || dby < 2 * t) {
					if (dty <= dby) {
						ef.origin.y = ry + rh - eh;
					} else {
						ef.origin.y = ry;
					}
				}
				
				[acceptee setFrame:ef display:YES animate:NO];
			}
			break;
	
		case NSMaxXEdge:
			eRightEdge  = NSMakeRect(ex+ew-t, ey+t,       2*t, eh-2*t);
			rLeftEdge   = NSMakeRect(rx-t,    ry+t,       2*t, rh-2*t);
			if (NSIntersectsRect(eRightEdge, rLeftEdge)) {
				ef.origin.x = rx - ew;
				
				CGFloat	dty = fabs((ey + eh) - (ry + rh));
				CGFloat	dby = fabs(ey - ry);
				if (dty < 2 * t || dby < 2 * t) {
					if (dty <= dby) {
						ef.origin.y = ry + rh - eh;
					} else {
						ef.origin.y = ry;
					}
				}
				
				[acceptee setFrame:ef display:YES animate:NO];
			}
			break;
			
		case NSMaxYEdge:
			eTopEdge    = NSMakeRect(ex+t,    ey+eh-t, ew-2*t, 2*t);
			rBottomEdge = NSMakeRect(rx+t,    ry-t,    rw-2*t, 2*t);
			if (NSIntersectsRect(eTopEdge, rBottomEdge)) {
				ef.origin.y = ry - eh;
				
				CGFloat	drx = fabs((ex + ew) - (rx + rw));
				CGFloat	dlx = fabs(ex - rx);
				if (drx < 2 * t || dlx < 2 * t) {
					if (drx < dlx) {
						ef.origin.x = rx + rw - ew;
					} else {
						ef.origin.x = rx;
					}
				}
				
				[acceptee setFrame:ef display:YES animate:NO];
			}
			break;
		
		case NSMinYEdge:
			eBottomEdge = NSMakeRect(ex+t,    ey-t,    ew-2*t, 2*t);
			rTopEdge    = NSMakeRect(rx+t,    ry+rh-t, rw-2*t, 2*t);
			if (NSIntersectsRect(eBottomEdge, rTopEdge)) {
				ef.origin.y = ry + rh;
				
				CGFloat	drx = fabs((ex + ew) - (rx + rw));
				CGFloat	dlx = fabs(ex - rx);
				if (drx < 2 * t || dlx < 2 * t) {
					if (drx < dlx) {
						ef.origin.x = rx + rw - ew;
					} else {
						ef.origin.x = rx;
					}
				}
				
				[acceptee setFrame:ef display:YES animate:NO];
			}
			break;
	}
}

/* delegate methods of OgreAttachableWindowAcceptee */
- (void)windowWillMove:(id)notification
{
	//NSLog(@"windowWillMove:");
	NSWindow<OgreAttachableWindowAccepteeProtocol>	*acceptee = [notification object];
	[acceptee setDragging:YES];
	[acceptee setDifference:NSMakePoint(0, 0)];
}

- (void)windowDidMove:(id)notification
{
	NSWindow<OgreAttachableWindowAccepteeProtocol>	*acceptee = [notification object];
	
	if (![acceptee dragging] || _processing) return;
	
	_processing = YES;
	
	//NSLog(@"windowMoved:");
	
    NSRect	winFrame = [acceptee frame];
    NSPoint	origin = winFrame.origin;
    //float	winX = winFrame.origin.x;
    //float	winY = winFrame.origin.y;
    //float	winW = winFrame.size.width;
    //float	winH = winFrame.size.height;

	NSPoint	diff = [acceptee difference];
	origin.x += diff.x;
	origin.y += diff.y;
	[acceptee setFrameOrigin:origin];
	
	[self attachAcceptee:acceptee];
	
	NSPoint	newOrigin = [acceptee frame].origin;
	diff.x = origin.x - newOrigin.x;
	diff.y = origin.y - newOrigin.y;
	[acceptee setDifference:diff];
	
	_processing = NO;
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)proposedFrameSize
{
	NSWindow	*parent = [sender parentWindow];
	
	if (parent != nil) {
		CGFloat dx = [sender frame].origin.x + proposedFrameSize.width - ([parent frame].origin.x + [parent frame].size.width);
		CGFloat	t = [self tolerance];
		if (fabs(dx) < 2 * t &&
				(	(proposedFrameSize.width - dx >= [sender minSize].width) && 
					(proposedFrameSize.width - dx <= [sender maxSize].width))) {
			
			proposedFrameSize = NSMakeSize(proposedFrameSize.width - dx, proposedFrameSize.height);
		}
	}
	
	return proposedFrameSize;
}

@end
