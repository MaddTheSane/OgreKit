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

#import <Foundation/Foundation.h>

#import <OgreKit/OgreTextFindComponent.h>
#import <OgreKit/OgreTextFindProgressDelegate.h>
#import <OgreKit/OGRegularExpression.h>

@class OgreTextFindRoot, OgreTextFindResult;
@class OGRegularExpression, OGReplaceExpression;

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
	OgreOption			_searchOptions;		// search option
	BOOL				_inSelection;		// find scope
	BOOL				_asynchronous;		// synchronous or asynchronous 
	SEL					_didEndSelector;	// selector for sending a finish message
	id					_didEndTarget;		// target for sending a finish message
	
	NSObject <OgreTextFindProgressDelegate>	* __weak _progressDelegate;	// progress checker
	
	volatile BOOL		_shouldFinish;		// finish flag
	
	/* state */
	volatile BOOL		_terminated;		// two-phase termination
	BOOL				_exceptionRaised;
	NSUInteger			_numberOfMatches;	// number of matches
	OgreTextFindResult	*_textFindResult;	// result
	NSInteger			_numberOfDoneLeaves,
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
@property (nonatomic, readonly, strong) OgreTextFindResult *result;
- (void)addResultLeaf:(id)aResultLeaf;
- (void)beginGraftingToBranch:(OgreTextFindBranch*)aBranch;
- (void)endGrafting;

/* Configuration */
- (void)setAsynchronous:(BOOL)asynchronou;

- (void)setDidEndSelector:(SEL)aSelector toTarget:(id)aTarget;

/* Accessors */
@property (nonatomic, copy) OGRegularExpression *regularExpression;
@property (nonatomic, copy) OGReplaceExpression *replaceExpression;
@property (nonatomic, copy) NSColor *highlightColor;
@property (nonatomic) OgreOption options;
@property (nonatomic) BOOL inSelection;
@property (nonatomic, strong) NSObject<OgreTextFindProgressDelegate> *progressDelegate;
@property (nonatomic, getter=isTerminated, readonly) BOOL terminated;
@property (nonatomic, readonly) NSTimeInterval processTime;

/* Protected methods */
@property (nonatomic, readonly) NSUInteger numberOfMatches;		 // number of matches
- (void)incrementNumberOfMatches;	// _numberofMatches++
- (void)finishingUp:(id)sender;
- (void)exceptionRaised:(NSException*)exception;

- (void)pushEnumerator:(NSEnumerator*)anEnumerator;
- (NSEnumerator*)popEnumerator;
@property (nonatomic, readonly, strong) NSEnumerator *topEnumerator;

@property (nonatomic, readonly, strong) OgreTextFindBranch *rootAdapter;
@property (nonatomic, readonly, strong) NSObject<OgreTextFindComponent,OgreTextFindTargetAdapter> *targetAdapter;
- (void)pushBranch:(OgreTextFindBranch*)aBranch;
- (OgreTextFindBranch *)popBranch;
@property (nonatomic, readonly, strong) OgreTextFindBranch *topBranch;

- (void)_setLeafProcessing:(OgreTextFindLeaf*)aLeaf;

/* Methods implemented by subclasses */
@property (nonatomic, readonly) SEL didEndSelectorForFindPanelController;

- (void)willProcessFindingAll;
- (void)willProcessFindingInBranch:(OgreTextFindBranch*)aBranch;
- (void)willProcessFindingInLeaf:(OgreTextFindLeaf*)aLeaf;
- (BOOL)shouldContinueFindingInLeaf:(OgreTextFindLeaf*)aLeaf;
- (void)didProcessFindingInLeaf:(OgreTextFindLeaf*)aLeaf;
- (void)didProcessFindingInBranch:(OgreTextFindBranch*)aBranch;
- (void)didProcessFindingAll;

- (void)finalizeFindingAll;

@property (nonatomic, readonly, copy) NSString *progressMessage;
@property (nonatomic, readonly, copy) NSString *doneMessage;
@property (nonatomic, readonly) double progressPercentage;   // percentage of completion
@property (nonatomic, readonly) double donePercentage;	   // percentage of completion

@end
