/*
 * Name: OgreTableColumnFindResult.m
 * Project: OgreKit
 *
 * Creation Date: Jun 05 2004
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreTableColumnFindResult.h>
#import <OgreKit/OgreTableCellFindResult.h>
#import <OgreKit/OgreTextFindResult.h>

#import <OgreKit/OgreTableView.h>
#import <OgreKit/OgreTableColumn.h>

@implementation OgreTableColumnFindResult

- (id)initWithTableColumn:(OgreTableColumn *)tableColumn
{
    self = [super init];
    if (self != nil) {
        _tableColumn = tableColumn;
        _components = [[NSMutableArray alloc] initWithCapacity:[[_tableColumn tableView] numberOfColumns]];
    }
    return self;
}


- (void)addComponent:(NSObject <OgreTextFindComponent>*)aFindResultComponent 
{
    [_components addObject:aFindResultComponent];
}

- (void)endAddition
{
    /* planarization */
    _flattenedComponents = [[NSMutableArray alloc] initWithCapacity:[_components count]];
    
    NSInteger rowIndex = 0;
    NSInteger i, matchCount;
    OgreTableCellFindResult  *rowFindResult;
    
    while (rowIndex < [_components count]) {
        rowFindResult = _components[rowIndex];
        matchCount = [rowFindResult numberOfChildrenInSelection:NO];
        if (matchCount > 0) {
            for (i = 0; i < matchCount; i++) [_flattenedComponents addObject:[rowFindResult childAtIndex:i inSelection:NO]];
            rowIndex++;
        } else {
            [_components removeObjectAtIndex:rowIndex];
        }
    }
}

- (id)name 
{
    if (_tableColumn == nil) return [[self textFindResult] missingString];
    return [[_tableColumn headerCell] stringValue];
}

- (id)outline 
{
    if (_tableColumn == nil) return [[self textFindResult] missingString];
    return [[self textFindResult] messageOfStringsFound:[_flattenedComponents count]]; 
}

- (NSUInteger)numberOfChildrenInSelection:(BOOL)inSelection
{
    return [_flattenedComponents count];
}

- (id)childAtIndex:(NSUInteger)index inSelection:(BOOL)inSelection
{
    return _flattenedComponents[index];
}

- (NSEnumerator *)componetEnumeratorInSelection:(BOOL)inSelection 
{
    return [_flattenedComponents objectEnumerator]; 
}

- (BOOL)showMatchedString
{
    if (_tableColumn == nil) return NO;
    OgreTableView   *tableView = (OgreTableView *)[_tableColumn tableView];
    
    [[tableView window] makeKeyAndOrderFront:self];
    return [self selectMatchedString];
}

- (BOOL)selectMatchedString
{
    if (_tableColumn == nil) return NO;
    OgreTableView   *tableView = (OgreTableView *)[_tableColumn tableView];
    
    if (![tableView allowsColumnSelection]) return YES;
    
    NSInteger columnIndex = [tableView columnWithIdentifier:[_tableColumn identifier]];
    if (columnIndex != -1) {
        [tableView selectColumnIndexes:[NSIndexSet indexSetWithIndex:columnIndex] byExtendingSelection:NO];
        [tableView scrollColumnToVisible:columnIndex];
    } else {
        [self targetIsMissing];
        return NO;
    }
    
    return (columnIndex != -1);
}

- (void)targetIsMissing
{
    _tableColumn = nil;
    [_components makeObjectsPerformSelector:@selector(targetIsMissing)];
}

@end
