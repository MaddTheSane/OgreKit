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
@synthesize terminalIndex = _terminalIndex;
@synthesize startIndex = _nextIndex;

- (instancetype)init
{
    return [self initWithBranch:nil
                    inSelection:NO];
}

- (instancetype)initWithBranch:(OgreTextFindBranch *)aBranch inSelection:(BOOL)inSelection
{
    if (aBranch == nil) {
        return nil;
    }
    
    self = [super init];
    if (self != nil) {
        _branch = aBranch;
        _count = [_branch numberOfChildrenInSelection:inSelection];
        _inSelection = inSelection;
        _nextIndex = 0;
        _terminalIndex = _count - 1;
        
        if (inSelection) {
			_indexes = (NSUInteger *)malloc(sizeof(NSUInteger) * _count);
            if (_indexes == NULL) {
                // Error
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

- (void)dealloc
{
	if (_indexes != NULL) free(_indexes);
}

- (id)nextObject
{
    if (_nextIndex > _terminalIndex) return nil;
    NSUInteger concreteIndex;
    id aComponent = nil;
    
    do {
        if (_inSelection) {
            concreteIndex = _indexes[_nextIndex];
        } else {
            concreteIndex = _nextIndex;
        }
        
        aComponent = [_branch childAtIndex:concreteIndex inSelection:NO];
        _nextIndex++;
    } while (aComponent == nil);
    
    return aComponent;
}

@end
