/*
 * Name: OgreHighlightThread.m
 * Project: OgreKit
 *
 * Creation Date: May 20 2004
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2004-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreHighlightThread.h>
#import <OgreKit/OGString.h>
#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGRegularExpressionMatch.h>

#import <OgreKit/OgreTextFindResult.h>

#import <tgmath.h>

@interface NSObject (priv)
- (BOOL)didEndHighlight:(id)anObject;
@end

@implementation OgreHighlightThread

/* Methods implemented by subclasses of OgreTextFindThread */
- (SEL)didEndSelectorForFindPanelController
{
    return @selector(didEndHighlight:);
}


- (void)willProcessFindingAll
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -willProcessFindingAll of %@", [self className]);
#endif
    _progressMessage = OgreTextFinderLocalizedString(@"%lu string highlighted.");
    _progressMessagePlural = OgreTextFinderLocalizedString(@"%lu strings highlighted.");
    _remainingTimeMesssage = OgreTextFinderLocalizedString(@"(%dsec remaining)");
}

- (void)willProcessFindingInBranch:(OgreTextFindBranch *)aBranch;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -willProcessFindingInBranch: of %@", [self className]);
#endif
}

- (void)willProcessFindingInLeaf:(OgreTextFindLeaf *)aLeaf;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -willProcessFindingInLeaf: of %@", [self className]);
#endif
    
    NSObject<OGStringProtocol>            *string = [aLeaf ogString];
    
    if (![aLeaf isHighlightable] || (string == nil)) {
        matchEnumerator = nil;  // stop
        return;
    }
    
    OGRegularExpression *regEx = [self regularExpression];
    
    /* blending highlight colors */
    CGFloat hue, saturation, brightness, alpha;
    [[[self highlightColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace] 
        getHue: &hue 
        saturation: &saturation 
        brightness: &brightness 
        alpha: &alpha];
    
    numberOfGroups = [regEx numberOfGroups];
    NSUInteger  i;
    BOOL        simple = ([regEx syntax] == OgreSimpleMatchingSyntax);
    CGFloat     dummy;
    
    _highlightColorArray = [[NSMutableArray alloc] initWithCapacity:numberOfGroups];
    for (i = 0; i <= numberOfGroups; i++) {
        [_highlightColorArray addObject:[NSColor colorWithCalibratedHue: 
            modf(hue + (simple? (CGFloat)(i - 1) : (CGFloat)i) /
                (simple? (CGFloat)numberOfGroups : (CGFloat)(numberOfGroups + 1)), &dummy)
            saturation: saturation 
            brightness: brightness 
            alpha: alpha]];
    }
    
    /* search */
    NSRange     searchRange = [aLeaf selectedRange];
	if (![self inSelection]) {
		searchRange = NSMakeRange(0, [string length]);
	}
    searchLength = searchRange.length;
    
    matchEnumerator = [regEx matchEnumeratorInOGString:string
                                                options:[self options]
                                                  range:searchRange];
    
    [aLeaf unhighlight];
}

- (BOOL)shouldContinueFindingInLeaf:(OgreTextFindLeaf *)aLeaf;
{
    if ((match = [matchEnumerator nextObject]) == nil) return NO;   // stop
    
    lastMatch = match;
    
    NSUInteger  i;
    NSRange     aRange;
    
    for(i = 0; i <= numberOfGroups; i++) {
        aRange = [match rangeOfSubstringAtIndex:i];
        if (aRange.length > 0) {
            [aLeaf highlightCharactersInRange:aRange color:_highlightColorArray[i]];
        }
    }
    
    [self incrementNumberOfMatches];
    
    return YES; // continue
}

- (void)didProcessFindingInLeaf:(OgreTextFindLeaf *)aLeaf;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -didProcessFindingInLeaf: of %@", [self className]);
#endif
}

- (void)didProcessFindingInBranch:(OgreTextFindBranch *)aBranch;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -didProcessFindingInBranch: of %@", [self className]);
#endif
}

- (void)didProcessFindingAll
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -didProcessFindingAll of %@", [self className]);
#endif
    
    
    if ([self numberOfMatches] > 0) [[self result] setType:OgreTextFindResultSuccess];
    
    [self finish];
}



- (NSString *)progressMessage
{
    NSString    *message = [NSString stringWithFormat:(([self numberOfMatches] > 1)? _progressMessagePlural : _progressMessage), [self numberOfMatches]];
    
    if (_numberOfTotalLeaves > 0) {
        double  progressPercentage = [self progressPercentage] + 0.00000001;
        message = [message stringByAppendingFormat:_remainingTimeMesssage, (int)ceil([self processTime] * (1.0 - progressPercentage)/progressPercentage)];
    }
    
    return message;
}

- (NSString *)doneMessage
{
	NSString	*finishedMessage, *finishedMessagePlural, 
				*cancelledMessage, *cancelledMessagePlural, 
				*notFoundMessage, *cancelledNotFoundMessage;
    
	notFoundMessage				= OgreTextFinderLocalizedString(@"Not found. (%.3fsec)");
	cancelledNotFoundMessage	= OgreTextFinderLocalizedString(@"Not found. (canceled, %.3fsec)");
    finishedMessage             = OgreTextFinderLocalizedString(@"%lu string highlighted. (%.3fsec)");
    finishedMessagePlural       = OgreTextFinderLocalizedString(@"%lu strings highlighted. (%.3fsec)");
    cancelledMessage            = OgreTextFinderLocalizedString(@"%lu string highlighted. (canceled, %.3fsec)");
    cancelledMessagePlural      = OgreTextFinderLocalizedString(@"%lu strings highlighted. (canceled, %.3fsec)");
    
    NSString    *message;
    NSUInteger  count = [self numberOfMatches];
	if ([self isTerminated]) {
		if (count == 0) {
			NSBeep();
			message = [NSString stringWithFormat:cancelledNotFoundMessage, 
				[self processTime] + 0.0005 /* Rounding (四捨五入) */];
		} else {
			message = [NSString stringWithFormat:((count > 1)? cancelledMessagePlural : cancelledMessage), 
				(unsigned long)count,
				[self processTime] + 0.0005 /* Rounding (四捨五入) */];
		}
	} else {
		if (count == 0) {
			NSBeep();
			message = [NSString stringWithFormat:notFoundMessage, 
				[self processTime] + 0.0005 /* Rounding (四捨五入) */];
		} else {
			message = [NSString stringWithFormat:((count > 1)? finishedMessagePlural : finishedMessage), 
				(unsigned long)count, 
				[self processTime] + 0.0005 /* Rounding (四捨五入) */];
		}
	}
    
    return message;
}

- (double)progressPercentage
{
    if (_numberOfTotalLeaves <= 0) return -1;
    
    NSRange matchRange = [lastMatch rangeOfMatchedString];
    return (double)(_numberOfDoneLeaves - 1 + (double)(NSMaxRange(matchRange) + 1)/(double)(searchLength + 1)) / (double)_numberOfTotalLeaves;
}

- (double)donePercentage
{
    double  percentage;
    
    if ([self isTerminated]) {
        if (_numberOfMatches == 0) {
            percentage = 0;
        } else {
            if (_numberOfTotalLeaves > 0) {
                NSRange matchRange = [lastMatch rangeOfMatchedString];
                percentage = (double)(_numberOfDoneLeaves - 1 + (double)(NSMaxRange(matchRange) + 1)/(double)(searchLength + 1)) / (double)_numberOfTotalLeaves;
            } else {
                percentage = -1;    // indeterminate
            }
        }
    } else {
        if (_numberOfMatches == 0) {
            percentage = 0;
        } else {
            percentage = 1;
        }
    }
    
    return percentage;
}



@end
