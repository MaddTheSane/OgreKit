/*
 * Name: OgreTableCellFindResult.m
 * Project: OgreKit
 *
 * Creation Date: Jun 05 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreTextFinder.h>
#import <OgreKit/OgreTextFindResult.h>
#import <OgreKit/OgreTableCellFindResult.h>
#import <OgreKit/OgreTableCellMatchFindResult.h>

#import <OgreKit/OgreTableView.h>
#import <OgreKit/OgreTableColumn.h>

@implementation OgreTableCellFindResult

- (id)initWithTableColumn:(OgreTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    self = [super init];
    if (self != nil) {
        _tableColumn = tableColumn;
        _rowIndex = rowIndex;
        _matchRangeArray = [[NSMutableArray alloc] initWithCapacity:1];
        _childArray = [[NSMutableArray alloc] initWithCapacity:1];
    }
    return self;
}


- (void)addMatch:(OGRegularExpressionMatch *)aMatch 
{
    NSInteger     i, n = [aMatch count];
    
    NSMutableArray  *rangeArray = [NSMutableArray arrayWithCapacity:n];
    for (i = 0; i < n; i++) [rangeArray addObject:[NSValue valueWithRange:[aMatch rangeOfSubstringAtIndex:i]]];
    
    [_matchRangeArray addObject:rangeArray];
    OgreTableCellMatchFindResult    *child = [[OgreTableCellMatchFindResult alloc] init];
    [child setIndex:[_matchRangeArray count] - 1];
    [child setParentNoRetain:self];
    [_childArray addObject:child];
}

- (void)endAddition
{
    /* do nothing */ 
}

- (id)name 
{
    if (_tableColumn == nil) return [[self textFindResult] missingString];
    return [[_tableColumn dataCell] className];
}

- (id)outline 
{
    if (_tableColumn == nil || _rowIndex >= [[_tableColumn tableView] numberOfRows]) return [[self textFindResult] missingString];
    return [[self textFindResult] messageOfStringsFound:[_matchRangeArray count]];
}

- (NSUInteger)numberOfChildrenInSelection:(BOOL)inSelection
{
    return [_childArray count];
}

- (id)childAtIndex:(NSUInteger)index inSelection:(BOOL)inSelection
{
    return _childArray[index];
}

- (NSEnumerator *)componetEnumeratorInSelection:(BOOL)inSelection 
{
    return [_childArray objectEnumerator]; 
}


// line number that matched string for the index (index番目にマッチした文字列のある行番号)
- (NSNumber *)lineOfMatchedStringAtIndex:(NSUInteger)index
{
    return @(_rowIndex + 1);
}

// matched string for the index (index番目にマッチした文字列)
- (NSAttributedString *)matchedStringAtIndex:(NSUInteger)index
{
    if (_tableColumn == nil || _rowIndex >= [[_tableColumn tableView] numberOfRows]) return [[self textFindResult] missingString];
    
    NSCell          *dataCell = [_tableColumn dataCell];
    id              anObject = nil;
    NSString        *fullString = nil;
    
    if ([dataCell type] == NSTextCellType) {
        anObject = [_tableColumn ogreObjectValueForRow:_rowIndex];
        [dataCell setObjectValue:anObject];
        fullString = [dataCell stringValue];
    }
    
    return [[self textFindResult] highlightedStringInRange:_matchRangeArray[index] ofString:fullString];
}

// I want to select and display the matched string for the index (index番目にマッチした文字列を選択・表示する)
- (BOOL)showMatchedStringAtIndex:(NSUInteger)index
{
    if (_tableColumn == nil || _rowIndex >= [[_tableColumn tableView] numberOfRows]) return NO;
    OgreTableView   *tableView = (OgreTableView *)[_tableColumn tableView];
    
    [[tableView window] makeKeyAndOrderFront:self];
    return [self selectMatchedStringAtIndex:index];
}

// I choose the matched string for the index (index番目にマッチした文字列を選択する)
- (BOOL)selectMatchedStringAtIndex:(NSUInteger)index
{
    if (_tableColumn == nil || _rowIndex >= [[_tableColumn tableView] numberOfRows]) return NO;
    OgreTableView *tableView = (OgreTableView *)[_tableColumn tableView];
    
    if (![tableView allowsColumnSelection]) {
        NSInteger columnIndex = [tableView columnWithIdentifier:[_tableColumn identifier]];
        if (columnIndex != -1) {
            [tableView scrollColumnToVisible:columnIndex];
        } else {
            [self targetIsMissing];
            return NO;
        }
    }
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:_rowIndex] byExtendingSelection:NO];
    [tableView scrollRowToVisible:_rowIndex];
    
    [tableView ogreSetSelectedColumn:[tableView columnWithIdentifier:[_tableColumn identifier]]];
    [tableView ogreSetSelectedRow:_rowIndex];
    NSRange matchRange = [_matchRangeArray[index][0] rangeValue];
    [tableView ogreSetSelectedRange:matchRange];
    
    return YES;
}

- (void)targetIsMissing
{
    _tableColumn = nil;
}

/*- (id)target
{
    return [NSNumber numberWithInt:_rowIndex];
}*/

@end
