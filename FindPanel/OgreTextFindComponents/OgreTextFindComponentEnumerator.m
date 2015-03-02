/*
 * Name: OgreTextFindComponentEnumerator.m
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

#import <OgreKit/OgreTextFindComponentEnumerator.h>
#import <OgreKit/OgreTextFindBranch.h>


@implementation OgreTextFindComponentEnumerator

- (instancetype)initWithBranch:(OgreTextFindBranch*)aBranch inSelection:(BOOL)inSelection
{
    self = [super init];
    if (self != nil) {
        _branch = [aBranch retain];
        _count = [_branch numberOfChildrenInSelection:inSelection];
        _inSelection = inSelection;
        _nextIndex = 0;
        _terminalIndex = _count - 1;
        
        if (inSelection) {
            _indexes = (NSUInteger*)malloc(sizeof(NSUInteger) * _count);
            if (_indexes == NULL) {
                // Error
                [self release];
                return nil;
            }
            NSIndexSet  *selectedColumns = [_branch selectedIndexes];
            [selectedColumns getIndexes:_indexes maxCount:_count inIndexRange:NULL];
        } else {
            _indexes = NULL;
        }
    }
    return self;
}

#ifdef MAC_OS_X_VERSION_10_6
- (void)finalize
{
    if (_indexes != NULL) free(_indexes);
    [super finalize];
}
#endif

- (void)dealloc
{
    if (_indexes != NULL) free(_indexes);
    [_branch release];
    [super dealloc];
}

- (void)setTerminalIndex:(NSInteger)index
{
    _terminalIndex = index;
}

- (NSInteger)startIndex
{
    return _nextIndex;
}

- (void)setStartIndex:(NSInteger)index
{
    _nextIndex = index;
}

- (id)nextObject
{
    if (_nextIndex > _terminalIndex) return nil;
    NSUInteger  concreteIndex;
    
    if (_inSelection) {
        concreteIndex = *(_indexes + _nextIndex);
    } else {
        concreteIndex = _nextIndex;
    }
    
    id  anComponent = [_branch childAtIndex:concreteIndex inSelection:NO];
    _nextIndex++;
    
    return anComponent;
}

@end
