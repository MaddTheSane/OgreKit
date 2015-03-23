/*
 * Name: OgreFindProgressSheet.m
 * Project: OgreKit
 *
 * Creation Date: Oct 01 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreTextFindProgressSheet.h>

@implementation OgreTextFindProgressSheet

- (instancetype)initWithWindow:(NSWindow*)parentWindow title:(NSString*)aTitle didEndSelector:(SEL)aSelector toTarget:(id)aTarget withObject:(id)anObject
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-initWithWindow: of %@", [self className]);
#endif
	self = [super init];
	if (self) {
		_parentWindow = parentWindow;
		_cancelSelector = nil;
		_cancelTarget = nil;
		_cancelArgument = nil;
		_didEndSelector = aSelector;
		_didEndTarget = aTarget;
		_didEndArgument = ((anObject != self)? anObject : self);
		_shouldRelease = YES;
		_title = aTitle;
        
        NSArray *topLevelObjects;
        BOOL didLoad =
        [[NSBundle bundleForClass:[self class]] loadNibNamed:@"OgreTextFindProgressSheet"
                                                       owner:self
                                             topLevelObjects:&topLevelObjects];
        if (didLoad) {
            _progressSheetTopLevelObjects = topLevelObjects;
        }
        else {
            NSLog(@"Failed to load nib in %@", [self description]);
            return nil;
        }
	}
	
	return self;
}

-(void)awakeFromNib
{
	//[[self retain] retain]; // it is release once at the time of the close: and sheetDidEnd: (close:とsheetDidEnd:のときに一度ずつreleaseされる)
	[titleTextField setStringValue:_title];
	[button setTitle:OgreTextFinderLocalizedString(@"Cancel")];
	[NSApp beginSheet: progressWindow 
		modalForWindow: _parentWindow 
		modalDelegate: self
		didEndSelector: @selector(sheetDidEnd:returnCode:contextInfo:) 
		contextInfo: nil];
	[progressBar setUsesThreadedAnimation:YES];
	[progressBar startAnimation:self];
}

- (void)sheetDidEnd:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-sheetDidEnd: of %@", [self className]);
#endif
	[_didEndTarget performSelector:_didEndSelector withObject:_didEndArgument];
}

- (void)dealloc
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-dealloc of %@", [self className]);
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setCancelSelector:(SEL)aSelector toTarget:(id)aTarget withObject:(id)anObject
{
	_cancelSelector = aSelector;
	_cancelTarget = aTarget;
	_cancelArgument = ((anObject != self)? anObject : self);
}

- (IBAction)cancel:(id)sender
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-cancel: of %@", [self className]);
#endif
	if ([[button title] isEqualToString:OgreTextFinderLocalizedString(@"Cancel")]) {
		// Cancel
		[_cancelTarget performSelector:_cancelSelector withObject:_cancelArgument];
	} else {
		// OK
		// release and close only once (closeは一回だけ実行できるrelease)
		if (progressWindow) {
			[progressWindow close];
			[NSApp endSheet:progressWindow returnCode:0];
			progressWindow = nil;
		}
		if (_shouldRelease) {
			_shouldRelease = NO;
		}
	}
}

- (void)setReleaseWhenOKButtonClicked:(BOOL)shouldRelease
{
	_shouldRelease = shouldRelease;
}

- (void)autoclose:(id)sender
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self close:self];
}

- (void)close:(id)anObject
{
	// If the application was deactivated will be run if we become active again. (アプリケーションがinactivateな場合はactivateになったら実行する。)
	if (![NSApp isActive]) {
#ifdef DEBUG_OGRE_FIND_PANEL
		NSLog(@"request -autoclose: of OgreTextFindProgressSheet");
#endif
		// I pick up the inactivate of Application (Applicationのinactivateを拾う)
		[[NSNotificationCenter defaultCenter] addObserver: self 
			selector: @selector(autoclose:) 
			name: NSApplicationDidBecomeActiveNotification
			object: NSApp];
		return;
	}
	
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-close: of %@", [self className]);
#endif
	// release and close only once (closeは一回だけ実行できるrelease)
	if (progressWindow) {
		[progressWindow close];
		[NSApp endSheet:progressWindow returnCode:0];
		[_parentWindow flushWindow];
		progressWindow = nil;
	}
	_shouldRelease = NO;
}

- (void)setProgress:(double)progression message:(NSString*)message
{
	if (progressWindow && [NSApp isActive]) {
        if (progression >= 0) {
            [progressBar setIndeterminate:NO];
            [progressBar setDoubleValue:progression];
        } else {
            [progressBar setIndeterminate:YES];
        }
        [progressTextField setStringValue:message];
	}
}

- (void)done:(double)progression message:(NSString*)message
{
	if (progressWindow) {
        if (progression >= 0) {
            [progressBar setIndeterminate:NO];
            [progressBar setDoubleValue:progression];
        } else {
            [progressBar setIndeterminate:YES];
        }
		[progressBar stopAnimation:self];
        
        [progressTextField setStringValue:message];
		[button setTitle:OgreTextFinderLocalizedString(@"OK")];
		[button setKeyEquivalent:@"\r"];
		[button setKeyEquivalentModifierMask:0];
	}
}

- (void)setDonePerTotalMessage:(NSString*)message
{
	if (progressWindow) {
        [donePerTotalTextField setStringValue:message];
    }
}

/* show error alert */
- (void)showErrorAlert:(NSString*)title message:(NSString*)errorMessage
{
	if (progressWindow) {
		[_parentWindow makeKeyAndOrderFront:self];
		[titleTextField setStringValue:title];
        [donePerTotalTextField setStringValue:@""];
		[progressBar setHidden:YES];
		[progressTextField setStringValue:errorMessage];
		[button setTitle:OgreTextFinderLocalizedString(@"OK")];
		[button setKeyEquivalent:@"\r"];
		[button setKeyEquivalentModifierMask:0];
	}
}

@end
