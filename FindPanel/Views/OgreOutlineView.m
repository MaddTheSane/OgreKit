/*
 * Name: OgreOutlineView.m
 * Project: OgreKit
 *
 * Creation Date: Jun 13 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreOutlineView.h>
#import <OgreKit/OgreOutlineViewAdapter.h>


@implementation OgreOutlineView

- (NSObject <OgreTextFindComponent>*)ogreAdapter
{
    return [[OgreOutlineViewAdapter alloc] initWithTarget:self];
}

- (void)awakeFromNib
{
    _ogreSelectedColumn = -1;
    _ogreSelectedItem = nil;
    _ogreSelectedRange = NSMakeRange(0, 0);
    _ogrePathComponents = nil;
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
        selector:@selector(ogreSelectionDidChange:) 
        name:NSOutlineViewSelectionDidChangeNotification 
        object:self];
}

- (void)ogreSelectionDidChange:(NSNotification *)aNotification
{
    _ogreSelectedColumn = [self selectedColumn];
    NSInteger selectedRow = [self selectedRow];
    
    if (_ogreSelectedColumn == -1 && selectedRow == -1) {
        _ogreSelectedRange = NSMakeRange(0, 0);
    } else {
        _ogreSelectedRange = NSMakeRange(NSNotFound, 0);
    }
    
    if (selectedRow != -1) {
        _ogreSelectedItem = [self itemAtRow:selectedRow];
    } else {
        _ogreSelectedItem = nil;
    }
    _ogrePathComponents = nil;
    
    //NSLog(@"column:%ld, row:%ld", (long)_ogreSelectedColumn, (long)selectedRow);
    //NSLog(@"path:%@", [[self ogrePathComponentsOfSelectedItem] description]);
}

- (NSArray *)ogrePathComponentsOfSelectedItem
{
    if (_ogrePathComponents != nil) {
        return _ogrePathComponents;
    }
    
    if (_ogreSelectedItem == nil) {
        _ogrePathComponents =  [[NSMutableArray alloc] initWithObjects:@0 /* firstItem */, @-1 /* cell */, nil];
        return _ogrePathComponents;
    }
    
    NSInteger level = [self levelForItem:_ogreSelectedItem];
    NSInteger row = [self rowForItem:_ogreSelectedItem];
    if (level == -1 || row == -1) return nil;
    
    _ogrePathComponents = [[NSMutableArray alloc] initWithCapacity:level + 1];
    
    NSInteger index = 0;
    NSInteger targetLevel;
    while (row > 0) {
        row--;
        targetLevel = [self levelForRow:row];
        if (targetLevel + 1 == level) {
            // parent level
            [_ogrePathComponents insertObject:@(index) atIndex:0];
            level = targetLevel;
            index = 0;
        } else if (targetLevel == level) {
            // same level
            index++;
        }
    } 
    // finish
    [_ogrePathComponents insertObject:@(index) atIndex:0];
    [_ogrePathComponents addObject:@-1 /* cell */];
    
    return _ogrePathComponents;
}

- (NSInteger)ogreSelectedColumn
{
    return (_ogreSelectedColumn == -1? 0 : _ogreSelectedColumn);
}

- (void)ogreSetSelectedColumn:(NSInteger)column
{
    _ogreSelectedColumn = column;
}

- (void)ogreSetSelectedItem:(id)item
{
    _ogreSelectedItem = item;
    _ogrePathComponents = nil;
}

- (NSRange)ogreSelectedRange
{
    return _ogreSelectedRange;
}

- (void)ogreSetSelectedRange:(NSRange)aRange
{
    _ogreSelectedRange = aRange;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:NSOutlineViewSelectionDidChangeNotification 
                                                  object:self];
}

@end
