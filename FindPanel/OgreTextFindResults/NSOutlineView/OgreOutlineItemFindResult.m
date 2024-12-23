/*
 * Name: OgreOutlineItemFindResult.m
 * Project: OgreKit
 *
 * Creation Date: Jun 06 2004
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OGRegularExpressionMatch.h>

#import <OgreKit/OgreOutlineItemFindResult.h>
#import <OgreKit/OgreOutlineCellFindResult.h>
#import <OgreKit/OgreOutlineCellMatchFindResult.h>
#import <OgreKit/OgreTextFindResult.h>

#import <OgreKit/OgreOutlineView.h>
#import <OgreKit/OgreOutlineColumn.h>

@implementation OgreOutlineItemFindResult

- (id)initWithOutlineColumn:(OgreOutlineColumn *)outlineColumn item:(id)item
{
    self = [super init];
    if (self != nil) {
        _outlineColumn = outlineColumn;
        _item = item;
        _components = [[NSMutableArray alloc] init];
        _simplifiedComponents = [[NSMutableArray alloc] init];
    }
    return self;
}


- (void)addComponent:(NSObject <OgreTextFindComponent>*)aFindResultComponent 
{
    [_components addObject:aFindResultComponent];
    [_simplifiedComponents addObject:aFindResultComponent];
}

- (void)endAddition
{
    NSInteger i = 0;
    while (i < [_components count]) {
        if ([_components[i] numberOfChildrenInSelection:NO] == 0) {
            [_components removeObjectAtIndex:i];
        } else {
            i++;
        }
    }
    
    i = 0;
    while (i < [_simplifiedComponents count]) {
        id <OgreTextFindComponent>  aComponent = _simplifiedComponents[i];
        if ([aComponent isBranch] && [aComponent numberOfChildrenInSelection:NO] == 0) {
            [_simplifiedComponents removeObjectAtIndex:i];
        } else {
            i++;
        }
    }
}

- (NSArray *)children
{
    return nil;
}

- (void)mergeFindResult:(OgreOutlineCellFindResult *)aBranch
{
    if ([_outlineColumn ogreIsItemExpandable:_item]) {
        NSArray     *children = [aBranch children];
        NSUInteger  count = [children count];
        if (count > 0) {
            [_simplifiedComponents replaceObjectsInRange:NSMakeRange(0, 1) withObjectsFromArray:[children subarrayWithRange:NSMakeRange(1, count - 1)]];
            _outlineDelegateLeaf = children[0];
        }
    } else {
        if ([[aBranch children] count] > 0) {
            [(OgreOutlineItemFindResult *)[self parent] replaceFindResult:self 
                withFindResultsFromArray:[aBranch children]];
        } else {
            [_simplifiedComponents removeObjectAtIndex:0];
        }
    }
}

- (void)replaceFindResult:(OgreOutlineItemFindResult *)aBranch withFindResultsFromArray:(NSArray *)resultsArray
{
    NSInteger branchIndex = [_simplifiedComponents indexOfObject:aBranch];
    [_simplifiedComponents replaceObjectsInRange:NSMakeRange(branchIndex, 1) withObjectsFromArray:resultsArray];
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
    if (_outlineDelegateLeaf != nil) return [_outlineDelegateLeaf outline];
    return [[self textFindResult] messageOfItemsFound:[_components count]]; 
}

- (NSUInteger)numberOfChildrenInSelection:(BOOL)inSelection
{
    return [_simplifiedComponents count];
}

- (id)childAtIndex:(NSUInteger)index inSelection:(BOOL)inSelection
{
    return _simplifiedComponents[index];
}

- (NSEnumerator *)componetEnumeratorInSelection:(BOOL)inSelection 
{
    return [_simplifiedComponents objectEnumerator]; 
}

// I want to select and display the matched string for the index (index番目にマッチした文字列を選択・表示する)
- (BOOL)showMatchedString
{
    if (_outlineColumn == nil || _item == nil) return NO;
    OgreOutlineView *outlineView = (OgreOutlineView *)[_outlineColumn tableView];
    
    [[outlineView window] makeKeyAndOrderFront:self];
    return [self selectMatchedString];
}

// I choose the matched string for the index (index番目にマッチした文字列を選択する)
- (BOOL)selectMatchedString
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
    
    [(OgreOutlineItemFindResult*)[self parent] expandItemEnclosingItem:_item];
    NSInteger rowIndex = [outlineView rowForItem:_item];
    if (rowIndex != -1) {
        [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
        [outlineView scrollRowToVisible:rowIndex];
    } else {
        _item = nil;
    }
    
    return (rowIndex != -1);
}


- (void)targetIsMissing
{
    _outlineColumn = nil;
    _item = nil;
    
    [_components makeObjectsPerformSelector:@selector(targetIsMissing)];
}

- (void)expandItemEnclosingItem:(id)item
{
    if (_outlineColumn == nil || _item == nil) return;
    
    [(OgreOutlineItemFindResult *)[self parent] expandItemEnclosingItem:_item];
    
    if (item != _item) {
        OgreOutlineView *outlineView = (OgreOutlineView *)[_outlineColumn tableView];
        [outlineView expandItem:_item];
    }
}

- (id)target
{
    return _item;
}

@end
