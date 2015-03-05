/*
 * Name: MyTableColumnSheet.m
 * Project: OgreKit
 *
 * Creation Date: Jun 01 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import "MyTableColumnSheet.h"


@implementation MyTableColumnSheet

- (instancetype)initWithParentWindow:(NSWindow*)parentWindow tableColumn:(NSTableColumn*)aColumn OKSelector:(SEL)OKSelector CancelSelector:(SEL)CancelSelector target:(id)aTarget
{
    self = [super init];
    if (self != nil) {
        _parentWindow = parentWindow;
        _column = [aColumn retain];
        _okSelector = OKSelector;
        _cancelSelector = CancelSelector;
        _target = aTarget;
        [NSBundle loadNibNamed:@"MyTableColumnSheet" owner:self];
    }
    
    return self;
}

- (void)awakeFromNib
{
	[self retain];
    NSString    *originalTitle = [[_column headerCell] stringValue];
    [originalTitleField setStringValue:originalTitle];
    [changedTitleField setStringValue:originalTitle];
	[NSApp beginSheet:columnSheet 
		modalForWindow:_parentWindow 
		modalDelegate:self
		didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) 
		contextInfo:nil];
}

- (void)sheetDidEnd:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
	[self release];
}

- (void)dealloc
{
    [_column release];
    [super dealloc];
}

- (IBAction)cancel:(id)sender
{
	[_target performSelector:_cancelSelector withObject:self];
	[columnSheet orderOut:nil];
	[NSApp endSheet:columnSheet returnCode:0];
}

- (IBAction)ok:(id)sender
{
	[_target performSelector:_okSelector withObject:self];
	[columnSheet orderOut:nil];
	[NSApp endSheet:columnSheet returnCode:0];
}

- (NSString*)changedTitle
{
    return [changedTitleField stringValue];
}

- (NSTableColumn*)tableColumn
{
    return _column;
}


@end
