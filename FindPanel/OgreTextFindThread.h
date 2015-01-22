/*
 * Name: OgreTextFindThread.h
 * Project: OgreKit
 *
 * Creation Date: Sep 26 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
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
	NSObject <OgreTextFindComponent, OgreTextFindTargetAdapter>	*_targetAdapter;
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
	
	NSObject <OgreTextFindProgressDelegate>	* __weak _progressDelegate;	// progress checker
	
	volatile BOOL		_shouldFinish;		// finish flag
	
	/* state */
	volatile BOOL		_terminated;		// two-phase termination
	BOOL				_exceptionRaised;
	unsigned			_numberOfMatches;	// number of matches
	OgreTextFindResult	*_textFindResult;	// result
	int					_numberOfDoneLeaves,
						_numberOfTotalLeaves;
	
	NSDate				*_processTime;		// process time
	NSDate				*_metronome;		// metronome
}

/* Creating and initializing */
- (instancetype)initWithComponent:(NSObject <OgreTextFindComponent>*)aComponent NS_DESIGNATED_INITIALIZER;

/* Running and stopping */
- (void)detach;
- (void)terminate;
- (void)terminate:(id)sender;
- (void)finish;

/* result */
@property (readonly, strong) OgreTextFindResult *result;
- (void)addResultLeaf:(id)aResultLeaf;
- (void)beginGraftingToBranch:(OgreTextFindBranch*)aBranch;
- (void)endGrafting;

/* Configuration */
- (void)setAsynchronous:(BOOL)asynchronou;

- (void)setDidEndSelector:(SEL)aSelector toTarget:(id)aTarget;

/* Accessors */
@property (copy) OGRegularExpression *regularExpression;
@property (copy) OGReplaceExpression *replaceExpression;
@property (copy) NSColor *highlightColor;
@property unsigned int options;
@property BOOL inSelection;
@property (weak) NSObject<OgreTextFindProgressDelegate> *progressDelegate;
@property (getter=isTerminated, readonly) BOOL terminated;
@property (readonly) NSTimeInterval processTime;

/* Protected methods */
@property (readonly) NSUInteger numberOfMatches;		 // number of matches
- (void)incrementNumberOfMatches;	// _numberofMatches++
- (void)finishingUp:(id)sender;
- (void)exceptionRaised:(NSException*)exception;

- (void)pushEnumerator:(NSEnumerator*)anEnumerator;
@property (readonly, strong) NSEnumerator *popEnumerator;
@property (readonly, strong) NSEnumerator *topEnumerator;

@property (readonly, strong) OgreTextFindBranch *rootAdapter;
@property (readonly, strong) NSObject<OgreTextFindComponent,OgreTextFindTargetAdapter> *targetAdapter;
- (void)pushBranch:(OgreTextFindBranch*)aBranch;
@property (readonly, strong) OgreTextFindBranch *popBranch;
@property (readonly, strong) OgreTextFindBranch *topBranch;

- (void)_setLeafProcessing:(OgreTextFindLeaf*)aLeaf;

/* Methods implemented by subclasses */
@property (readonly) SEL didEndSelectorForFindPanelController;

- (void)willProcessFindingAll;
- (void)willProcessFindingInBranch:(OgreTextFindBranch*)aBranch;
- (void)willProcessFindingInLeaf:(OgreTextFindLeaf*)aLeaf;
- (BOOL)shouldContinueFindingInLeaf:(OgreTextFindLeaf*)aLeaf;
- (void)didProcessFindingInLeaf:(OgreTextFindLeaf*)aLeaf;
- (void)didProcessFindingInBranch:(OgreTextFindBranch*)aBranch;
- (void)didProcessFindingAll;

- (void)finalizeFindingAll;

@property (readonly, copy) NSString *progressMessage;
@property (readonly, copy) NSString *doneMessage;
@property (readonly) double progressPercentage;   // percentage of completion
@property (readonly) double donePercentage;	   // percentage of completion

@end
