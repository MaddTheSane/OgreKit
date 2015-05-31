/*
 * Name: OGMutableAttributedString.h
 * Project: OgreKit
 *
 * Creation Date: Sep 22 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2004 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OGMutableAttributedString.h>

@implementation OGMutableAttributedString

- (id)init
{
	self = [super init];
	if (self != nil) {
		[self _setAttributedString:[[NSMutableAttributedString alloc] init]];
		_fontManager = [NSFontManager sharedFontManager];
	}
	return self;
}

- (id)initWithAttributedString:(NSAttributedString *)attributedString
{
	if (attributedString == nil) {
		[NSException raise:NSInvalidArgumentException format: @"nil string argument"];
	}
	
	self = [super init];
	if (self != nil) {
		[self _setAttributedString:[[NSMutableAttributedString alloc] initWithAttributedString:attributedString]];
		_fontManager = [NSFontManager sharedFontManager];
	}
	return self;
}

- (id)initWithString:(NSString *)string hasAttributesOfOGString:(id<OGStringProtocol>)ogString
{
	if (string == nil || ogString == nil) {
		[NSException raise:NSInvalidArgumentException format: @"nil string argument"];
	}
	
	self = [super init];
	if (self != nil) {
		[self _setAttributedString:[[NSAttributedString alloc] initWithString:string 
			attributes:[[ogString attributedString] attributesAtIndex:0 effectiveRange:NULL]]];
		_fontManager = [NSFontManager sharedFontManager];
	}
	return self;
}

- (void)_setAttributedString:(NSAttributedString *)attributedString
{
    _attrString = [attributedString mutableCopy];
}

/* OGMutableStringProtocol */
- (void)appendOGString:(id<OGStringProtocol>)string
{
	[(NSMutableAttributedString *)[self _attributedString] appendAttributedString:[string attributedString]];
}

- (void)appendAttributedString:(NSAttributedString *)string
{
	[(NSMutableAttributedString *)[self _attributedString] appendAttributedString:string];
}

- (void)appendOGStringLeaveImprint:(id<OGStringProtocol>)string
{
	NSUInteger	length = [string length];
	if (length == 0) {
		return;
	}
	
	NSAttributedString	*appendant = [string attributedString];
	[(NSMutableAttributedString *)[self _attributedString] appendAttributedString:appendant];
	_currentAttributes = [appendant attributesAtIndex:(length - 1) effectiveRange:NULL];
}

- (void)appendString:(NSString *)string 
{
	if ([string length] == 0) {
		return;
	}
	
	[(NSMutableAttributedString *)[self _attributedString] appendAttributedString:[[NSAttributedString alloc] initWithString:string attributes:_currentAttributes]];
}

- (void)appendString:(NSString *)string hasAttributesOfOGString:(id<OGStringProtocol>)ogString
{
	if ([string length] == 0) {
		return;
	}
	
	[(NSMutableAttributedString *)[self _attributedString] appendAttributedString:[[NSAttributedString alloc] initWithString:string attributes:[[ogString attributedString] attributesAtIndex:0 effectiveRange:NULL]]];
}

- (void)appendOGString:(id<OGStringProtocol>)string 
	changeFont:(BOOL)changeFont 
	mergeAttributes:(BOOL)mergeAttributes 
	ofOGString:(id<OGStringProtocol>)srcString
{
	if ([string length] == 0) {
		return;
	}
	
@autoreleasepool {

    NSAttributedString			*appendant = [string attributedString];
    NSMutableAttributedString	*attrString = (NSMutableAttributedString *)[self _attributedString];
    
    NSMutableAttributedString	*aString = [[NSMutableAttributedString alloc] initWithAttributedString:appendant];
    NSUInteger		length = [appendant length];
    NSRange			effectiveRange = NSMakeRange(0, 0);
    NSFont			*srcFont, *font;
    NSString		*appendantFontFamilyName = nil, *srcFontFamilyName;
    NSFontTraitMask	appendantFontTraits, srcFontTraits, newFontTraits = 0;
    CGFloat			appendantFontWeight = 0, srcFontWeight;
    CGFloat			appendantFontPointSize = 0, srcFontPointSize;
    NSFont			*newFont;
    NSDictionary	*srcAttributes;
    NSAttributedString	*srcAttributedString = [srcString attributedString];
    
    srcAttributes = [srcAttributedString attributesAtIndex:0 effectiveRange:NULL];
    srcFont = srcAttributes[NSFontAttributeName];
    if (srcFont == nil) {
        srcFont = [NSFont systemFontOfSize:[NSFont systemFontSize]];
    }
    srcFontFamilyName = [srcFont familyName];
    srcFontTraits = [_fontManager traitsOfFont:srcFont];
    srcFontWeight = [_fontManager weightOfFont:srcFont];
    srcFontPointSize = [srcFont pointSize];
    
    if (!mergeAttributes) {
        // replace attributes
        [aString setAttributes:srcAttributes range:NSMakeRange(0, length)];
        _currentAttributes = srcAttributes;
    } else {
        // merge attributes
        NSEnumerator	*keyEnumerator = [srcAttributes keyEnumerator];
        NSString		*attrKey;
        while ((attrKey = [keyEnumerator nextObject]) != nil) {
            id	attr = srcAttributes[attrKey];
            //if (attr != nil) {
                [aString addAttribute:attrKey 
                    value:attr 
                    range:NSMakeRange(0, length)];
            //}
        }
        _currentAttributes = [aString attributesAtIndex:(length - 1) effectiveRange:NULL];
    }
    
    while (effectiveRange.location < length) {
        font = [appendant attribute:NSFontAttributeName 
            atIndex:effectiveRange.location 
            effectiveRange:&effectiveRange];
        if (font == nil) {
            font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
        }
        appendantFontFamilyName = [font familyName];
        appendantFontTraits = [_fontManager traitsOfFont:font];
        appendantFontWeight = [_fontManager weightOfFont:font];
        appendantFontPointSize = [font pointSize];
        
        if (!mergeAttributes) {
            // replace traits
            newFontTraits = srcFontTraits;
        } else {
            // merge traits
            newFontTraits = srcFontTraits | appendantFontTraits;
            if ((newFontTraits & NSBoldFontMask) != 0) { newFontTraits &= ~NSUnboldFontMask; }
            if ((newFontTraits & NSItalicFontMask) != 0) { newFontTraits &= ~NSUnitalicFontMask; }
            if ((newFontTraits & NSCondensedFontMask) != 0 && (newFontTraits & NSExpandedFontMask) != 0) {
                if ((srcFontTraits & NSCondensedFontMask) != 0) {
                    newFontTraits &= ~NSExpandedFontMask;
                } else {
                    newFontTraits &= ~NSCondensedFontMask;
                }
            }
        }
        
        if (changeFont) {
            newFont = [_fontManager fontWithFamily:srcFontFamilyName 
                traits:0 
                weight:srcFontWeight 
                size:srcFontPointSize];
        } else {
            newFont = [_fontManager fontWithFamily:appendantFontFamilyName 
                traits:0 
                weight:appendantFontWeight 
                size:appendantFontPointSize];
        }
        NSFontTraitMask	trait;
        for (trait = 1; trait <= newFontTraits; trait <<= 1) {
            if ((trait & newFontTraits) != 0 && (font = [_fontManager convertFont:newFont toHaveTrait:(trait & newFontTraits)]) != nil) {
                newFont = font;
            }
        }
        
        if (newFont != nil) {
            [aString addAttribute:NSFontAttributeName 
                value:newFont 
                range:effectiveRange];
        }
        
        effectiveRange.location = NSMaxRange(effectiveRange);
    }
    
    if (changeFont) {
        _currentFontFamilyName = srcFontFamilyName;
        _currentFontTraits = newFontTraits;
        _currentFontWeight = srcFontWeight;
        _currentFontPointSize = srcFontPointSize;
    } else if (appendantFontFamilyName != nil) {
        _currentFontFamilyName = appendantFontFamilyName;
        _currentFontTraits = newFontTraits;
        _currentFontWeight = appendantFontWeight;
        _currentFontPointSize = appendantFontPointSize;
    }
    
    [attrString appendAttributedString:aString];

}
}

- (void)appendOGString:(id<OGStringProtocol>)string 
	changeFont:(BOOL)changeFont 
	mergeAttributes:(BOOL)mergeAttributes 
{
	if ([string length] == 0) {
		return;
	}
	
@autoreleasepool {

    NSAttributedString			*appendant = [string attributedString];
    NSMutableAttributedString	*attrString = (NSMutableAttributedString *)[self _attributedString];
    
    NSMutableAttributedString	*aString = [[NSMutableAttributedString alloc] initWithAttributedString:appendant];
    NSRange			effectiveRange;
    NSUInteger		length = [appendant length];
    NSFont			*font;
    NSString		*appendantFontFamilyName = nil;
    NSFontTraitMask	appendantFontTraits, newFontTraits = 0;
    CGFloat			appendantFontWeight = 0;
    CGFloat			appendantFontPointSize = 0;
    NSFont			*newFont;
    
    if (mergeAttributes) {
        // overwrite attributes
        effectiveRange = NSMakeRange(0, 0);
        while (effectiveRange.location < length) {
            NSDictionary	*attr = [appendant attributesAtIndex:effectiveRange.location 
                effectiveRange:&effectiveRange];
            NSEnumerator	*keyEnumerator = [_currentAttributes keyEnumerator];
            NSString		*attrKey;
            while ((attrKey = [keyEnumerator nextObject]) != nil) {
                if (attr[attrKey] == nil) {
                    id	attr = _currentAttributes[attrKey];
                    //if (attr != nil) {
                        [aString addAttribute:attrKey 
                            value:attr 
                            range:effectiveRange];
                    //}
                }
            }
            effectiveRange.location = NSMaxRange(effectiveRange);
        }
        _currentAttributes = [aString attributesAtIndex:(length - 1) effectiveRange:NULL];
    }
    
    effectiveRange = NSMakeRange(0, 0);
    while (effectiveRange.location < length) {
        font = [appendant attribute:NSFontAttributeName 
            atIndex:effectiveRange.location 
            effectiveRange:&effectiveRange];
        if (font == nil) {
            font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
        }
        appendantFontFamilyName = [font familyName];
        appendantFontTraits = [_fontManager traitsOfFont:font];
        appendantFontWeight = [_fontManager weightOfFont:font];
        appendantFontPointSize = [font pointSize];
        
        if (!mergeAttributes) {
            // replace traits
            newFontTraits = appendantFontTraits;
        } else {
            // overwrite traits
            newFontTraits = _currentFontTraits | appendantFontTraits;
            if ((newFontTraits & NSBoldFontMask) != 0) { newFontTraits &= ~NSUnboldFontMask; }
            if ((newFontTraits & NSItalicFontMask) != 0) { newFontTraits &= ~NSUnitalicFontMask; }
            if ((newFontTraits & NSCondensedFontMask) != 0 && (newFontTraits & NSExpandedFontMask) != 0) {
                if ((appendantFontTraits & NSCondensedFontMask) != 0) {
                    newFontTraits &= ~NSExpandedFontMask;
                } else {
                    newFontTraits &= ~NSCondensedFontMask;
                }
            }
        }
        
        if (changeFont) {
            newFont = [_fontManager fontWithFamily:appendantFontFamilyName 
                traits:0 
                weight:appendantFontWeight 
                size:appendantFontPointSize];
        } else {
            newFont = [_fontManager fontWithFamily:_currentFontFamilyName 
                traits:0 
                weight:_currentFontWeight 
                size:_currentFontPointSize];
        }
        NSFontTraitMask	trait;
        for (trait = 1; trait <= newFontTraits; trait <<= 1) {
            if ((trait & newFontTraits) != 0 && (font = [_fontManager convertFont:newFont toHaveTrait:(trait & newFontTraits)]) != nil) {
                newFont = font;
            }
        }
        
        if (newFont != nil) {
            [aString addAttribute:NSFontAttributeName 
                value:newFont 
                range:effectiveRange];
        }
        
        effectiveRange.location = NSMaxRange(effectiveRange);
    }
    
    if (changeFont && _currentFontFamilyName != nil) {
        _currentFontFamilyName = appendantFontFamilyName;
        _currentFontTraits = newFontTraits;
        _currentFontWeight = appendantFontWeight;
        _currentFontPointSize = appendantFontPointSize;
    }
    
    [attrString appendAttributedString:aString];

}
}

- (void)setAttributesOfOGString:(id<OGStringProtocol>)string atIndex:(NSUInteger)index
{
	NSUInteger	attrIndex;
	if (index > 0) {
		attrIndex = index - 1;
	} else {
		attrIndex = index;
	}
	
	NSFont				*font;
	NSAttributedString	*attrString;
	if (attrIndex < [string length]) {
		attrString = [string attributedString];
	} else {
		attrString = [[NSAttributedString alloc] initWithString:@" "];
	}
	
	font = [attrString attribute:NSFontAttributeName atIndex:attrIndex effectiveRange:nil];
	if (font == nil) {
		font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
	}
	_currentFontFamilyName = [font familyName];
	_currentFontTraits = [_fontManager traitsOfFont:font];
	_currentFontWeight = [_fontManager weightOfFont:font];
	_currentFontPointSize = [font pointSize];
	
	_currentAttributes = [attrString attributesAtIndex:attrIndex effectiveRange:NULL];
}

@end

