/*
 * Name: OgreTextFindThread.h
 * Project: OgreKit
 *
 * Creation Date: Sep 26 2003
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Cocoa/Cocoa.h>
#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGReplaceExpression.h>
//#import <OgreKit/OgreTextFinder.h>
#import <OgreKit/OgreTextFindProgressSheet.h>
#import <OgreKit/OgreTextFindResult.h>
#import <OgreKit/OgreTextFindComponent.h>
#import <OgreKit/OgreTextFindLeaf.h>
#import <OgreKit/OgreTextFindBranch.h>
#import <OgreKit/OgreTextFindProgressDelegate.h>


@class OgreTextFindRoot;

@interface OgreTextFindThread : NSObject <OgreTextFindVisitor>
{
	/* implementors */
	id <OgreTextFindComponent, OgreTextFindTargetAdapter>	_targetAdapter;
	OgreTextFindLeaf	*_leafProcessing;
	NSEnumerator		*_enumeratorProcessing;
	NSMutableArray		*_enumeratorStack;
	NSMutableArray		*_branchStack;
	OgreTextFindRoot	*_rootAdapter;
	
	/* Parameters */
	OGRegularExpression *_regex;			// regular expression
	OGReplaceExpression *_repex;			// replace expression
	NSColor				*_highlightColor;	// highlight color
	unsigned			_searchOptions;		// search option
	BOOL				_inSelection;		// find scope
	BOOL				_asynchronous;		// synchronous or asynchronous 
	SEL					_didEndSelector;	// selector for sending a finish message
	id					_didEndTarget;		// target for sending a finish message
	
	NSObject <OgreTextFindProgressDelegate>	*_progressDelegate;	// progress checker
	
	volatile BOOL		_shouldFinish;		// finish flag
	
	/* state */
	volatile BOOL		_terminated;		// two-phase termination
	BOOL				_exceptionRaised;
	NSUInteger			_numberOfMatches;	// number of matches
	OgreTextFindResult	*_textFindResult;	// result
	NSInteger           _numberOfDoneLeaves,
						_numberOfTotalLeaves;
	
	NSDate				*_processTime;		// process time
	NSDate				*_metronome;		// metronome
}

/* Creating and initializing */
- (id)initWithComponent:(id<OgreTextFindComponent, OgreTextFindTargetAdapter>)aComponent;

/* Running and stopping */
- (void)detach;
- (void)terminate;
- (void)terminate:(id)sender;
- (void)finish;

/* result */
- (OgreTextFindResult*)result;
- (void)addResultLeaf:(id)aResultLeaf;
- (void)beginGraftingToBranch:(OgreTextFindBranch*)aBranch;
- (void)endGrafting;

/* Configuration */
- (void)setRegularExpression:(OGRegularExpression*)regex;
- (void)setReplaceExpression:(OGReplaceExpression*)repex;
- (void)setHighlightColor:(NSColor*)highlightColor;
- (void)setOptions:(OgreOptions)options;
- (void)setInSelection:(BOOL)inSelection;
- (void)setAsynchronous:(BOOL)asynchronou;

- (void)setDidEndSelector:(SEL)aSelector toTarget:(id)aTarget;
- (void)setProgressDelegate:(id<OgreTextFindProgressDelegate>)aDelegate;

/* Accessors */
@property (retain) OGRegularExpression* regularExpression;
@property (retain) OGReplaceExpression* replaceExpression;
@property (retain) NSColor* highlightColor;
@property OgreOptions options;
@property BOOL inSelection;
@property (nonatomic, assign) id<OgreTextFindProgressDelegate> progressDelegate;
@property (readonly, getter=isTerminated) BOOL terminated;
- (NSTimeInterval)processTime;

/* Protected methods */
@property (readonly) NSUInteger numberOfMatches;		 // number of matches
- (void)incrementNumberOfMatches;	// _numberofMatches++
- (void)finishingUp:(id)sender;
- (void)exceptionRaised:(NSException*)exception;

- (void)pushEnumerator:(NSEnumerator*)anEnumerator;
- (NSEnumerator*)popEnumerator;
- (NSEnumerator*)topEnumerator;

@property (readonly, retain) OgreTextFindBranch* rootAdapter;
@property (readonly, retain) id<OgreTextFindComponent, OgreTextFindTargetAdapter> targetAdapter;
- (void)pushBranch:(OgreTextFindBranch*)aBranch;
- (OgreTextFindBranch*)popBranch;
- (OgreTextFindBranch*)topBranch;

- (void)_setLeafProcessing:(OgreTextFindLeaf*)aLeaf;

/* Methods implemented by subclasses */
- (SEL)didEndSelectorForFindPanelController;

- (void)willProcessFindingAll;
- (void)willProcessFindingInBranch:(OgreTextFindBranch*)aBranch;
- (void)willProcessFindingInLeaf:(OgreTextFindLeaf*)aLeaf;
- (BOOL)shouldContinueFindingInLeaf:(OgreTextFindLeaf*)aLeaf;
- (void)didProcessFindingInLeaf:(OgreTextFindLeaf*)aLeaf;
- (void)didProcessFindingInBranch:(OgreTextFindBranch*)aBranch;
- (void)didProcessFindingAll;

- (void)finalizeFindingAll;

- (NSString*)progressMessage;
- (NSString*)doneMessage;
- (double)progressPercentage;   // percentage of completion
- (double)donePercentage;	   // percentage of completion

@end
