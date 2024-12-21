/*
 * Name: OgreReplaceAllThread.m
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

#import <OgreKit/OgreReplaceAllThread.h>
#import <OgreKit/OGString.h>
#import <OgreKit/OgreTextFindResult.h>

@interface NSObject (endReplace)
- (BOOL)didEndReplaceAll:(id)anObject;

@end

@implementation OgreReplaceAllThread

/* Methods implemented by subclasses of OgreTextFindThread */
- (SEL)didEndSelectorForFindPanelController
{
    return @selector(didEndReplaceAll:);
}


- (void)willProcessFindingAll
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -willProcessFindingAll of %@", [self className]);
#endif
    progressMessage = OgreTextFinderLocalizedString(@"%lu string replaced.");
    progressMessagePlural = OgreTextFinderLocalizedString(@"%lu strings replaced.");
    remainingTimeMesssage = OgreTextFinderLocalizedString(@"(%dsec remaining)");
}

- (void)willProcessFindingInBranch:(OgreTextFindBranch *)aBranch;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -willProcessFindingInBranch: of %@", [self className]);
#endif
    //_replaceExpression = [self replaceExpression]; // redundant.
}

- (void)willProcessFindingInLeaf:(OgreTextFindLeaf *)aLeaf;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -willProcessFindingInLeaf: of %@", [self className]);
#endif
    NSObject<OGStringProtocol>    *string = [aLeaf ogString];
    
    if (![aLeaf isEditable] || (string == nil)) {
        aNumberOfMatches = 0;  // stop
        return;
    }
    
    NSUInteger  stringLength = [string length];
    
    NSRange     selectedRange = [aLeaf selectedRange];
	if (![self inSelection]) {
		selectedRange = NSMakeRange(0, stringLength);
	}
    
    matchArray = [[self regularExpression] allMatchesInOGString:string
			options: [self options] 
			range: selectedRange];
    aNumberOfMatches = [matchArray count];
    aNumberOfReplaces = 0;
    
    if (aNumberOfMatches != 0) {
        [aLeaf beginRegisteringUndoWithCapacity:aNumberOfMatches];
        [aLeaf beginEditing];
    }
}

- (BOOL)shouldContinueFindingInLeaf:(OgreTextFindLeaf *)aLeaf;
{
    if (aNumberOfReplaces >= aNumberOfMatches) return NO;   // stop
    
    aNumberOfReplaces++;
    [self incrementNumberOfMatches];
    
    OGRegularExpressionMatch        *_match;
    NSRange                         matchRange;
    _match = matchArray[(aNumberOfMatches - aNumberOfReplaces)];
    matchRange = [_match rangeOfMatchedString];
    replacedString = [_replaceExpression replaceMatchedOGStringOf:_match];
    [aLeaf replaceCharactersInRange:matchRange withOGString:replacedString];
    
    return YES; // continue
}

- (void)didProcessFindingInLeaf:(OgreTextFindLeaf*)aLeaf;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -didProcessFindingInLeaf: of %@", [self className]);
#endif
    if (aNumberOfMatches != 0) {
        [aLeaf endEditing];
        [aLeaf endRegisteringUndo];
    }
}

- (void)didProcessFindingInBranch:(OgreTextFindBranch*)aBranch;
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



- (NSString*)progressMessage
{
    NSString    *message = [NSString stringWithFormat:(([self numberOfMatches] > 1)? progressMessagePlural : progressMessage), [self numberOfMatches]];
    
    if (_numberOfTotalLeaves > 0) {
        double  progressPercentage = [self progressPercentage] + 0.00000001;
        message = [message stringByAppendingFormat:remainingTimeMesssage, (int)ceil([self processTime] * (1.0 - progressPercentage)/progressPercentage)];
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
    finishedMessage             = OgreTextFinderLocalizedString(@"%lu string replaced. (%.3fsec)");
    finishedMessagePlural       = OgreTextFinderLocalizedString(@"%lu strings replaced. (%.3fsec)");
    cancelledMessage            = OgreTextFinderLocalizedString(@"%lu string replaced. (canceled, %.3fsec)");
    cancelledMessagePlural      = OgreTextFinderLocalizedString(@"%lu strings replaced. (canceled, %.3fsec)");
    
    NSString    *message;
    NSUInteger  count = [self numberOfMatches];
	if ([self isTerminated]) {
		if (count == 0) {
			NSBeep();
			message = [NSString stringWithFormat:cancelledNotFoundMessage, 
				[self processTime] + 0.0005 /* 四捨五入 */];
		} else {
			message = [NSString stringWithFormat:((count > 1)? cancelledMessagePlural : cancelledMessage), 
				(unsigned long)count,
				[self processTime] + 0.0005 /* 四捨五入 */];
		}
	} else {
		if (count == 0) {
			NSBeep();
			message = [NSString stringWithFormat:notFoundMessage, 
				[self processTime] + 0.0005 /* 四捨五入 */];
		} else {
			message = [NSString stringWithFormat:((count > 1)? finishedMessagePlural : finishedMessage), 
				(unsigned long)count,
				[self processTime] + 0.0005 /* 四捨五入 */];
		}
	}
    
    return message;
}

- (double)progressPercentage
{
    if (_numberOfTotalLeaves <= 0 ) return -1;
    
    return (double)(_numberOfDoneLeaves - 1 + (double)aNumberOfReplaces/(double)aNumberOfMatches) / (double)_numberOfTotalLeaves;
}

- (double)donePercentage
{
    if ([self isTerminated]) {
        if (_numberOfTotalLeaves <= 0 ) return -1;
        
        return (double)(_numberOfDoneLeaves - 1 + (double)aNumberOfReplaces/(double)aNumberOfMatches) / (double)_numberOfTotalLeaves;
    }
    
    return 1;
    
    //return (double)_replaceAllNumberOfReplaces/(double)_replaceAllNumberOfMatches;
}

@end
