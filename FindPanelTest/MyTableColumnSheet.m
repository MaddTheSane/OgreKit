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

- (instancetype)initWithParentWindow:(NSWindow*)parentWindow tableColumn:(NSTableColumn*)aColumn OKSelector:(SEL)OKSelector cancelSelector:(SEL)CancelSelector endSelector:(SEL)endSelector target:(id)aTarget
{
    self = [super init];
    if (self != nil) {
        _parentWindow = parentWindow;
        _column = aColumn;
        _okSelector = OKSelector;
        _cancelSelector = CancelSelector;
        _endSelector = endSelector;
        _target = aTarget;
        
        NSArray *topLevelObjects;
        BOOL didLoad =
        [[NSBundle bundleForClass:[self class]] loadNibNamed:@"MyTableColumnSheet"
                                                       owner:self
                                             topLevelObjects:&topLevelObjects];
        if (didLoad) {
            _sheetTopLevelObjects = topLevelObjects;
        }
        else {
            NSLog(@"Failed to load nib in %@", [self description]);
            return nil;
        }
    }
    
    return self;
}

- (void)awakeFromNib
{
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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [_target performSelector:_endSelector withObject:self];
#pragma clang diagnostic pop
}


- (IBAction)cancel:(id)sender
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [_target performSelector:_cancelSelector withObject:self];
#pragma clang diagnostic pop
	[columnSheet orderOut:nil];
	[NSApp endSheet:columnSheet returnCode:0];
}

- (IBAction)ok:(id)sender
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [_target performSelector:_okSelector withObject:self];
#pragma clang diagnostic pop
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
