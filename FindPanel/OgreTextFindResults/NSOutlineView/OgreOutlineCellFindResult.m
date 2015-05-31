/*
 * Name: OgreOutlineCellFindResult.m
 * Project: OgreKit
 *
 * Creation Date: Jun 06 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OGRegularExpressionMatch.h>

#import <OgreKit/OgreOutlineView.h>
#import <OgreKit/OgreOutlineItemFindResult.h>
#import <OgreKit/OgreOutlineCellFindResult.h>
#import <OgreKit/OgreOutlineCellMatchFindResult.h>
#import <OgreKit/OgreTextFindResult.h>

#import <OgreKit/OgreOutlineColumn.h>

@implementation OgreOutlineCellFindResult

- (id)initWithOutlineColumn:(OgreOutlineColumn *)outlineColumn item:(id)item
{
    self = [super init];
    if (self != nil) {
        _outlineColumn = outlineColumn;
        _item = item;
        _matchRangeArray = [[NSMutableArray alloc] init];
        _matchComponents = [[NSMutableArray alloc] init];
    }
    return self;
}


- (void)addMatch:(OGRegularExpressionMatch *)aMatch 
{
    NSUInteger  i, n = [aMatch count];
    
    NSMutableArray  *rangeArray = [NSMutableArray arrayWithCapacity:n];
    for (i = 0; i < n; i++) [rangeArray addObject:[NSValue valueWithRange:[aMatch rangeOfSubstringAtIndex:i]]];
    
    [_matchRangeArray addObject:rangeArray];
    OgreOutlineCellMatchFindResult   *child = [[OgreOutlineCellMatchFindResult alloc] init];
    [child setIndex:[_matchRangeArray count] - 1];
    [child setParentNoRetain:self];
    [_matchComponents addObject:child];
}

- (void)endAddition
{
    /* simplify */
    [(OgreOutlineItemFindResult *)[self parent] mergeFindResult:self];
}

- (NSArray *)children
{
    return _matchComponents;
}


- (id)name 
{
    if (_outlineColumn == nil || _item == nil) return [[self textFindResult] missingString];
    
    OgreOutlineView *outlineView = (OgreOutlineView *)[_outlineColumn tableView];
    return [(OgreOutlineColumn *)[outlineView outlineTableColumn] ogreObjectValueForItem:_item];
}

- (id)outline 
{
    if (_outlineColumn == nil || _item == nil) return [[self textFindResult] missingString];
    return [[self textFindResult] messageOfStringsFound:[_matchRangeArray count]];
}

- (NSUInteger)numberOfChildrenInSelection:(BOOL)inSelection
{
    return [_matchComponents count];
}

- (id)childAtIndex:(NSUInteger)index inSelection:(BOOL)inSelection
{
    return _matchComponents[index];
}

- (NSEnumerator *)componetEnumeratorInSelection:(BOOL)inSelection 
{
    return [_matchComponents objectEnumerator]; 
}

// line number that matched string for the index (index番目にマッチした文字列のある行番号)
- (id)nameOfMatchedStringAtIndex:(NSUInteger)index
{
    return [self name];
}

// matched string for the index (index番目にマッチした文字列)
- (NSAttributedString *)matchedStringAtIndex:(NSUInteger)index
{
    if (_outlineColumn == nil || _item == nil) return [[self textFindResult] missingString];
    
    NSCell                          *dataCell = [_outlineColumn dataCell];
    id                              anObject = nil;
    NSString                        *fullString = nil;
    
    if ([dataCell type] == NSTextCellType) {
        anObject = [_outlineColumn ogreObjectValueForItem:_item];
        [dataCell setObjectValue:anObject];
        fullString = [dataCell stringValue];
    }
   
    return [[self textFindResult] highlightedStringInRange:_matchRangeArray[index] ofString:fullString];
}

// I want to select and display the matched string for the index (index番目にマッチした文字列を選択・表示する)
- (BOOL)showMatchedStringAtIndex:(NSUInteger)index
{
    if (_outlineColumn == nil || _item == nil) return NO;
    OgreOutlineView *outlineView = (OgreOutlineView *)[_outlineColumn tableView];
    
    [[outlineView window] makeKeyAndOrderFront:self];
    return [self selectMatchedStringAtIndex:index];
}

// I choose the matched string for the index (index番目にマッチした文字列を選択する)
- (BOOL)selectMatchedStringAtIndex:(NSUInteger)index
{
    if (_outlineColumn == nil || _item == nil) return NO;
    OgreOutlineView *outlineView = (OgreOutlineView *)[_outlineColumn tableView];
    
    if ([outlineView allowsColumnSelection]) {
        NSInteger columnIndex = [outlineView columnWithIdentifier:[_outlineColumn identifier]];
        if (columnIndex != -1) {
            [outlineView scrollColumnToVisible:columnIndex];
        } else {
            [self targetIsMissing];
            return NO;
        }
    }
    
    [(OgreOutlineItemFindResult *)[self parent] expandItemEnclosingItem:_item];
    NSInteger rowIndex = [outlineView rowForItem:_item];
    if (rowIndex != -1) {
        [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
        [outlineView scrollRowToVisible:rowIndex];
        
        [outlineView ogreSetSelectedColumn:[outlineView columnWithIdentifier:[_outlineColumn identifier]]];
        [outlineView ogreSetSelectedItem:_item];
        NSRange matchRange = [_matchRangeArray[index][0] rangeValue];
        [outlineView ogreSetSelectedRange:matchRange];
    } else {
        _item = nil;
    }
    
    return (rowIndex != -1);
}

- (void)targetIsMissing
{
    _outlineColumn = nil;
    _item = nil;
}

- (id)target
{
    return _item;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len
{
	return [_matchComponents countByEnumeratingWithState:state objects:buffer count:len];
}

@end
