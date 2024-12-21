/*
 * Name: OgreTextViewGraphicAllowedAdapter.m
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

#import <OgreKit/OGAttributedString.h>

#import <OgreKit/OgreTextView.h>

#import <OgreKit/OgreTextViewPlainAdapter.h>
#import <OgreKit/OgreTextViewGraphicAllowedAdapter.h>
#import <OgreKit/OgreTextViewUndoer.h>


@implementation OgreTextViewGraphicAllowedAdapter

/* Accessor methods */
- (id<OGStringProtocol>)ogString
{
    return [[OGAttributedString alloc] initWithAttributedString:[self textStorage]];
}

- (void)setOGString:(id<OGStringProtocol>)aString
{
    [_textStorage setAttributedString:[aString attributedString]];
}

- (void)replaceCharactersInRange:(NSRange)aRange withOGString:(id<OGStringProtocol>)aString
{
    // Registration of Undo operation (Undo操作の登録)
    if (_allowsUndo) {
        //[_textView setSelectedRange:aRange];
        [_undoer addRange:NSMakeRange(aRange.location, [aString length]) 
			attributedString:[[NSAttributedString alloc] 
				initWithAttributedString:[[self textStorage] attributedSubstringFromRange:aRange]]];
        //NSLog(@"(%lu, %lu), %@",(unsigned long) aRange.location, (unsigned long)aRange.length, [[_textStorage attributedSubstringFromRange:aRange] string]);
    }
    
    // Replacement (置換)
	[[self textStorage] replaceCharactersInRange:aRange withAttributedString:[aString attributedString]];
}

@end
