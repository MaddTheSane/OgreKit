/*
 * Name: OgreFindAllThread.m
 * Project: OgreKit
 *
 * Creation Date: May 20 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2004 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreFindAllThread.h>
#import <OgreKit/OgreFindResultLeaf.h>
#import <OgreKit/OgreFindResultBranch.h>
#import <OgreKit/OGString.h>
#import <OgreKit/OgreTextFindResult.h>
#import <OgreKit/OgreTextFindThread.h>

@interface NSObject (priv)
- (BOOL)didEndFindAll:(id)anObject;
@end

@implementation OgreFindAllThread

/* Methods implemented by subclasses of OgreTextFindThread */
- (SEL)didEndSelectorForFindPanelController
{
    return @selector(didEndFindAll:);
}


- (void)willProcessFindingAll
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -willProcessFindingAll of %@", [self className]);
#endif
    _progressMessage = OgreTextFinderLocalizedString(@"%lu string found.");
    _progressMessagePlural = OgreTextFinderLocalizedString(@"%lu strings found.");
    _remainingTimeMesssage = OgreTextFinderLocalizedString(@"(%dsec remaining)");
}

- (void)willProcessFindingInBranch:(OgreTextFindBranch*)aBranch;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -willProcessFindingInBranch: of %@", [self className]);
#endif
    [self beginGraftingToBranch:aBranch];
    _lastMatch = nil;
}

- (void)willProcessFindingInLeaf:(OgreTextFindLeaf*)aLeaf;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -willProcessFindingInLeaf: of %@", [self className]);
#endif
    NSObject<OGStringProtocol>            *string = [aLeaf ogString];
    
    if (string == nil) {
        _matchEnumerator = nil;
        _result = nil;
        return;
    }
    
    NSRange     searchRange = [aLeaf selectedRange];
	if (![self inSelection]) {
		searchRange = NSMakeRange(0, [string length]);
	}
    _searchLength = searchRange.length;
    
    OGRegularExpression *regEx = [self regularExpression];
    _matchEnumerator = [regEx matchEnumeratorInOGString:string
                                                options:[self options]
                                                  range:searchRange];
    _result = (OgreFindResultBranch <OgreFindResultCorrespondingToTextFindLeaf>*)[aLeaf findResultLeafWithThread:self];
    [self addResultLeaf:_result];
}

- (BOOL)shouldContinueFindingInLeaf:(OgreTextFindLeaf*)aLeaf;
{
    if ((_match = [_matchEnumerator nextObject]) == nil) return NO;   // stop
    
    _lastMatch = _match;
    
    [self incrementNumberOfMatches];
    [_result addMatch:_match];
    
    return YES; // continue
}

- (void)didProcessFindingInLeaf:(OgreTextFindLeaf*)aLeaf;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -didProcessFindingInLeaf: of %@", [self className]);
#endif
    [_result endAddition];
	_matchEnumerator = nil;
}

- (void)didProcessFindingInBranch:(OgreTextFindBranch*)aBranch;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -didProcessFindingInBranch: of %@", [self className]);
#endif
    [self endGrafting];
}

- (void)didProcessFindingAll
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -didProcessFindingAll of %@", [self className]);
#endif
    
    if ([self numberOfMatches] > 0) {
        [[self result] setType:OgreTextFindResultSuccess];
        [[self result] setHighlightColor:[self highlightColor] regularExpression:[self regularExpression]];
    }
    
    [self finish];
}


- (NSString*)progressMessage
{
    NSString    *message = [NSString stringWithFormat:(([self numberOfMatches] > 1)? _progressMessagePlural : _progressMessage), [self numberOfMatches]];
    
    if (_numberOfTotalLeaves > 0) {
        double  progressPercentage = [self progressPercentage] + 0.00000001;
        message = [message stringByAppendingFormat:_remainingTimeMesssage,
                   (int)ceil([self processTime] * (1.0 - progressPercentage)/progressPercentage)];
    }
    
    return message;
}

- (NSString*)doneMessage
{
	NSString	*finishedMessage, *finishedMessagePlural, 
				*cancelledMessage, *cancelledMessagePlural, 
				*notFoundMessage, *cancelledNotFoundMessage;
    
	notFoundMessage				= OgreTextFinderLocalizedString(@"Not found. (%.3fsec)");
	cancelledNotFoundMessage	= OgreTextFinderLocalizedString(@"Not found. (canceled, %.3fsec)");
    finishedMessage             = OgreTextFinderLocalizedString(@"%lu string found. (%.3fsec)");
    finishedMessagePlural       = OgreTextFinderLocalizedString(@"%lu strings found. (%.3fsec)");
    cancelledMessage            = OgreTextFinderLocalizedString(@"%lu string found. (canceled, %.3fsec)");
    cancelledMessagePlural      = OgreTextFinderLocalizedString(@"%lu strings found. (canceled, %.3fsec)");
    
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
    
    NSRange matchRange = [_lastMatch rangeOfMatchedString];
    return (double)(_numberOfDoneLeaves - 1 + (double)(NSMaxRange(matchRange) + 1)/(double)(_searchLength + 1)) / (double)_numberOfTotalLeaves;
}

- (double)donePercentage
{
    double  percentage;
    
    if ([self isTerminated]) {
        if (_numberOfMatches == 0) {
            percentage = 0;
        } else {
            if (_numberOfTotalLeaves > 0) {
                NSRange matchRange = [_lastMatch rangeOfMatchedString];
                percentage = (double)(_numberOfDoneLeaves - 1 + (double)(NSMaxRange(matchRange) + 1)/(double)(_searchLength + 1)) / (double)_numberOfTotalLeaves;
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
