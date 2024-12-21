/*
 * Name: OgreTextViewUndoer.m
 * Project: OgreKit
 *
 * Creation Date: May 20 2004
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreTextViewUndoer.h>


@implementation OgreTextViewUndoer
- (id)initWithCapacity:(NSUInteger)aCapacity
{
    self = [super init];
    if (self != nil) {
        _tail = 0;
        _count = aCapacity;
        _rangeArray = (NSRange *)malloc(sizeof(NSRange) * aCapacity);
        if (_rangeArray == NULL) {
            // ERROR!
        }
        _attributedStringArray = [[NSMutableArray alloc] initWithCapacity:aCapacity];
    }
    return self;
}

- (void)dealloc
{
    //NSLog(@"dealloc %@", self);
    free(_rangeArray);
}

- (void)addRange:(NSRange)aRange attributedString:(NSAttributedString *)anAttributedString
{
    NSAssert(_tail != _count, @"ERROR");
    _rangeArray[_tail] = aRange;
    [_attributedStringArray addObject:anAttributedString];
    _tail++;
}

/* Undo/Redo Replace */
- (void)undoTextView:(id)aTarget jumpToSelection:(BOOL)jumpToSelection invocationTarget:(id)myself
{
	if (_count == 0)  return;
    
    NSTextStorage       *textStorage = [aTarget textStorage];
    NSRange             aRange, newRange;
    NSAttributedString  *aString;
    NSUInteger          i;
    OgreTextViewUndoer    *redoArray = [[OgreTextViewUndoer alloc] initWithCapacity:_count];
    
    [textStorage beginEditing];
	
	@autoreleasepool {
		
    i = _count;
    while (i > 0) {
        i--;
        aRange = _rangeArray[i];
        aString = _attributedStringArray[i];
        //NSLog(@"(%lu, %lu), %@", (unsigned long)aRange.location, (unsigned long)aRange.length, [aString string]);
        
        newRange = NSMakeRange(aRange.location, [aString length]);
        [redoArray addRange:newRange attributedString:[[NSAttributedString alloc] initWithAttributedString:[textStorage attributedSubstringFromRange:aRange]]];
        
        // undo
        [textStorage replaceCharactersInRange:aRange withAttributedString:aString];
        if (jumpToSelection) [aTarget scrollRangeToVisible:newRange];
        
    }
    
    // redo registeration (redo　registeration)
    [[[aTarget undoManager] prepareWithInvocationTarget:redoArray] 
        undoTextView:aTarget jumpToSelection:jumpToSelection
        invocationTarget:redoArray];
        
	}
	
    [textStorage endEditing];
    [aTarget setSelectedRange:newRange];
}

@end
