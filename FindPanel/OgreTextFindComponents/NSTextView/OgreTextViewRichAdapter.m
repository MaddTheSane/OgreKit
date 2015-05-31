/*
 * Name: OgreTextViewRichAdapter.m
 * Project: OgreKit
 *
 * Creation Date: May 20 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OGAttributedString.h>

#import <OgreKit/OgreTextView.h>

#import <OgreKit/OgreTextViewPlainAdapter.h>
#import <OgreKit/OgreTextViewRichAdapter.h>
#import <OgreKit/OgreTextViewUndoer.h>


@implementation OgreTextViewRichAdapter

/* Accessor methods */
- (id<OGStringProtocol>)ogString
{
    return [[OGAttributedString alloc] initWithAttributedString:[self textStorage]];
}

- (void)setOGString:(id<OGStringProtocol>)aString
{
	NSTextStorage	*textStorage = [self textStorage];
    [textStorage setAttributedString:[aString attributedString]];
	[textStorage removeAttribute:NSAttachmentAttributeName range:NSMakeRange(0, [textStorage length])];
}

- (void)replaceCharactersInRange:(NSRange)aRange withOGString:(id<OGStringProtocol>)aString
{
	NSTextStorage	*textStorage = [self textStorage];
	NSUInteger      appendantLength = [aString length];
	
    // Registration of Undo operation (Undo操作の登録)
    if (_allowsUndo) {
        //[_textView setSelectedRange:aRange];
        [_undoer addRange:NSMakeRange(aRange.location, appendantLength) 
			attributedString:[[NSAttributedString alloc] 
				initWithAttributedString:[textStorage attributedSubstringFromRange:aRange]]];
        //NSLog(@"(%lu, %lu), %@",(unsigned long) aRange.location, (unsigned long)aRange.length, [[textStorage attributedSubstringFromRange:aRange] string]);
    }
    
    // Replacement (置換)
	[textStorage replaceCharactersInRange:aRange withAttributedString:[aString attributedString]];
	[textStorage removeAttribute:NSAttachmentAttributeName range:NSMakeRange(aRange.location, appendantLength)];
}

@end
