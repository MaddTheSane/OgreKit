/*
 * Name: OgreTableView.m
 * Project: OgreKit
 *
 * Creation Date: Jun 13 2004
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreTableView.h>
#import <OgreKit/OgreTableViewAdapter.h>


@implementation OgreTableView {
    BOOL _tableViewIsViewBased;
}

@synthesize ogreSelectedRange = _ogreSelectedRange;

- (void)setDelegate:(id)delegate
{
    if (delegate != nil) {
        _tableViewIsViewBased = [delegate respondsToSelector:@selector(tableView:viewForTableColumn:row:)];
    }
    
    [super setDelegate:delegate];
}

- (NSObject <OgreTextFindComponent>*)ogreAdapter
{
    return [[OgreTableViewAdapter alloc] initWithTarget:self];
}

- (NSInteger)ogreSelectedColumn
{
    return (_ogreSelectedColumn == -1? 0 : _ogreSelectedColumn);
}

- (void)ogreSetSelectedColumn:(NSInteger)column
{
    _ogreSelectedColumn = column;
}

- (NSInteger)ogreSelectedRow
{
    return (_ogreSelectedRow == -1? 0 : _ogreSelectedRow);
}

- (void)ogreSetSelectedRow:(NSInteger)row
{
    _ogreSelectedRow = row;
}

- (void)ogreHighlightTextForSelectedPosition
{
    if (!((_ogreEditedRow == _ogreSelectedRow) &&
          (_ogreEditedColumn == _ogreSelectedColumn))) {
        [self editColumn:_ogreSelectedColumn
                     row:_ogreSelectedRow
               withEvent:nil
                  select:NO];
    }
    
    NSWindow *window = self.window;
    NSText *textEditor = nil;
    if (_tableViewIsViewBased) {
        NSResponder *firstResponder = [window firstResponder];
        if ([firstResponder isKindOfClass:[NSText class]]) {
            // We would have to dig through the view hierarchy otherwise. ;)
            // FIXME: Implement an array of searchable subview paths.
            textEditor = (NSText *)firstResponder;
        }
    } else {
        textEditor = [window fieldEditor:YES
                               forObject:self];
    }
    
    if (textEditor.selectable) {
        textEditor.selectedRange = _ogreSelectedRange;
    }
}

- (void)textDidBeginEditing:(NSNotification *)notification
{
    _ogreEditedRow = _ogreSelectedRow;
    _ogreEditedColumn = _ogreSelectedColumn;
    
    [super textDidBeginEditing:notification];
}

- (void)textDidEndEditing:(NSNotification *)notification
{
    _ogreEditedRow = -1;
    _ogreEditedColumn = -1;
    
    [super textDidEndEditing:notification];
}

- (void)awakeFromNib
{
    _ogreEditedRow = -1;
    _ogreEditedColumn = -1;
    
    _ogreSelectedColumn = -1;
    _ogreSelectedRow = -1;
    _ogreSelectedRange = NSMakeRange(0, 0);
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self
                      selector:@selector(ogreSelectionDidChange:)
                          name:NSTableViewSelectionDidChangeNotification
                        object:self];
}

- (void)ogreSelectionDidChange:(NSNotification *)aNotification
{
    _ogreSelectedColumn = [self selectedColumn];
    _ogreSelectedRow = [self selectedRow];
    if (_ogreSelectedColumn == -1 && _ogreSelectedRow == -1) {
        _ogreSelectedRange = NSMakeRange(0, 0);
    } else {
        _ogreSelectedRange = NSMakeRange(NSNotFound, 0);
    }
}

- (void)dealloc
{
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver:self
                             name:NSTableViewSelectionDidChangeNotification
                           object:self];
}

@end
