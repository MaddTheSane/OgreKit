/*
 * Name: MyTableColumnSheet.h
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

#import <Cocoa/Cocoa.h>


@interface MyTableColumnSheet : NSObject 
{
    IBOutlet NSWindow       *columnSheet;
    IBOutlet NSTextField    *originalTitleField;
    IBOutlet NSTextField    *changedTitleField;
    
    NSWindow        *_parentWindow;
    NSTableColumn   *_column;
    SEL             _cancelSelector;
    SEL             _okSelector;
    id              _target;
    id              _argument;
    
    NSArray         *_sheetTopLevelObjects;
}

- (instancetype)initWithParentWindow:(NSWindow*)parentWindow tableColumn:(NSTableColumn*)aColumn OKSelector:(SEL)OKSelector CancelSelector:(SEL)CancelSelector target:(id)aTarget NS_DESIGNATED_INITIALIZER;

- (IBAction)cancel:(id)sender;
- (IBAction)ok:(id)sender;

@property (nonatomic, readonly, copy) NSString *changedTitle;
@property (nonatomic, readonly, strong) NSTableColumn *tableColumn;

@end
