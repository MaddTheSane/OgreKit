/*
 * Name: OgreTextFindThread.m
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

#import <OgreKit/OgreTextFindThread.h>
#import <OgreKit/OgreTextFindResult.h>
#import <OgreKit/OgreTextFindRoot.h>
#import<OgreKit/OgreTextFindComponentEnumerator.h>

@interface NSObject (priv)
- (BOOL)didEndUnknownTextFindThread:(id)anObject;
@end

@implementation OgreTextFindThread

/* Creating and initializing */
- (instancetype)initWithComponent:(NSObject <OgreTextFindComponent, OgreTextFindTargetAdapter>*)aComponent;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-initWithComponent: of %@", [self className]);
#endif
	self = [super init];
	if (self != nil) {
		_targetAdapter = aComponent;
		_enumeratorStack = [[NSMutableArray alloc] initWithCapacity:10];
		_branchStack = [[NSMutableArray alloc] initWithCapacity:10];
		_terminated = NO;
		_exceptionRaised = NO;
		_processTime = 0;
		_asynchronous = NO;
		_shouldFinish = NO;
		_rootAdapter = [[OgreTextFindRoot alloc] initWithComponent:_targetAdapter];
		[_targetAdapter setParent:_rootAdapter];
		[_targetAdapter setIndex:0];
	}
	
	return self;
}

- (void)dealloc
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-dealloc of %@", [self className]);
#endif
	[self finalizeFindingAll];
}

- (void)finalizeFindingAll
{
	if (_leafProcessing != nil) {
		[_leafProcessing finalizeFinding];
		_leafProcessing = nil;
	} else {
		[(OgreTextFindBranch*)[_branchStack lastObject] finalizeFinding];
	}
	
	while ([self popBranch] != nil);
	_branchStack = nil;
	
	while ([self popEnumerator] != nil);
	_enumeratorStack = nil;
}

/* Running and stopping */
/* Template Methods */
- (void)detach
{
	_processTime = [[NSDate alloc] init];
	_metronome = [[NSDate alloc] init];
	
	_textFindResult = [[OgreTextFindResult alloc] initWithTarget:[_targetAdapter target] thread:self];
	
	@try {
	
		_numberOfTotalLeaves = [_rootAdapter numberOfDescendantsInSelection:_inSelection];  // NSNotFound: indeterminate
		_numberOfDoneLeaves = 0;
		
		[self willProcessFindingAll];
		if (!_shouldFinish) [self visitBranch:_rootAdapter];
		
	} @catch (NSException *localException) {
		
		_exceptionRaised =YES;
		[self exceptionRaised:localException];
		
		[self didProcessFindingAll];
		[self finishingUp:nil];
		
	}
}

- (void)willProcessFindingAll
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-willProcessFindingAll of %@", [self className]);
#endif
	/* do nothing */ 
}

- (void)didProcessFindingAll 
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-didProcessFindingAll of %@", [self className]);
#endif
	/* do nothing */ 
}

/* visitor pattern */
- (void)visitLeaf:(OgreTextFindLeaf*)aLeaf
// aLeaf == nil: resume from a break
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-visitLeaf: of %@", [self className]);
#endif
	@autoreleasepool {
	
	if (aLeaf != nil) {
		/* begin */
		_numberOfDoneLeaves++;
		_leafProcessing = aLeaf;
		[_leafProcessing willProcessFinding:self];
		[self willProcessFindingInLeaf:_leafProcessing];
	}
#ifdef DEBUG_OGRE_FIND_PANEL
	else {
		NSLog(@"RESUME of %@", [self className]);
	}
#endif
	
	@try {
	
		BOOL	shouldContinue;
		while (!_shouldFinish) {
			shouldContinue = [self shouldContinueFindingInLeaf:_leafProcessing];

			if (_asynchronous && (-[_metronome timeIntervalSinceNow] >= 1.0)) {
				/* coffee break */
				if (shouldContinue) {
					[_progressDelegate setProgress:[self progressPercentage] message:[self progressMessage]];
					[_progressDelegate setDonePerTotalMessage:[NSString stringWithFormat:@"%ld/%@", (long)_numberOfDoneLeaves, (_numberOfTotalLeaves <= 0? @"???" : [NSString stringWithFormat:@"%ld", (long)_numberOfTotalLeaves])]];
				}
				_metronome = [[NSDate alloc] init];
				
	#ifdef DEBUG_OGRE_FIND_PANEL
				NSLog(@"BREAK of %@", [self className]);
	#endif
				[self performSelector:@selector(visitLeaf:) withObject:nil afterDelay:0];

				NS_VOIDRETURN;
			}
			if (!shouldContinue) break;
		}
		
		/* end */
		[_leafProcessing didProcessFinding:self];
		[self didProcessFindingInLeaf:_leafProcessing];
		_leafProcessing = nil;
		
		if (aLeaf == nil) [self visitBranch:nil];
		
	} @catch (NSException *localException) {
		
		_exceptionRaised =YES;
		[self exceptionRaised:localException];
		
		[_leafProcessing didProcessFinding:self];
		[self didProcessFindingInLeaf:_leafProcessing];
				
		[self didProcessFindingAll];
		[self finishingUp:nil];
		
	}
	}
}

- (void)visitBranch:(OgreTextFindBranch*)aBranch
// aBranch == nil: resume from a break
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-visitBranch: of %@", [self className]);
#endif
	if (aBranch != nil) {
		/* begin */
		_enumeratorProcessing = [aBranch componentEnumeratorInSelection:[self inSelection]];
		[self pushEnumerator:_enumeratorProcessing];
		[self pushBranch:aBranch];
		
		[aBranch willProcessFinding:self];
		[self willProcessFindingInBranch:aBranch];
	}
	
	NSObject <OgreTextFindComponent>	*component;
	while (!_shouldFinish) {
		component = [_enumeratorProcessing nextObject];
		if (component == nil) break;
		
		[component acceptVisitor:self];
		if (_leafProcessing != nil) break;  // BREAK
	}
	
	if (_leafProcessing == nil && !_exceptionRaised) {
		/* end */
		id  processingBranch = [self topBranch];
		[processingBranch didProcessFinding:self];
		[self didProcessFindingInBranch:processingBranch];
		[self popBranch];
		
		[self popEnumerator];
		_enumeratorProcessing = [self topEnumerator];
		if (_enumeratorProcessing != nil) {
			/* continue */
			if (aBranch == nil) [self visitBranch:nil];
		} else {
			/* finish up */
			[_progressDelegate done:[self donePercentage] message:[self doneMessage]];
			[_progressDelegate setDonePerTotalMessage:[NSString stringWithFormat:@"%ld/%@", (long)_numberOfDoneLeaves, (_numberOfTotalLeaves == -1? @"???" : [NSString stringWithFormat:@"%ld", (long)_numberOfTotalLeaves])]];
			
			[self didProcessFindingAll];
			
			if (_shouldFinish) {
				if (_asynchronous) {
					[self performSelector:@selector(finishingUp:) withObject:nil afterDelay:0];
				} else {
					[self finishingUp:nil];
				}
			}
		}
	}
}

- (void)finishingUp:(id)sender
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-finishingUp: of %@", [self className]);
#endif
	_metronome = nil;
	
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"processTime: %lf", -[_processTime timeIntervalSinceNow]);
#endif
	
	_processTime = nil;
	
	[_textFindResult setNumberOfMatches:_numberOfMatches];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [_didEndTarget performSelector:_didEndSelector withObject:self];
#pragma clang diagnostic pop
}

- (void)exceptionRaised:(NSException*)exception
{
	[_textFindResult setType:OgreTextFindResultError];
	[_textFindResult setAlertSheet:_progressDelegate exception:exception];
	_shouldFinish = YES;
}

- (void)terminate
{
	[self terminate:self];
}

- (void)terminate:(id)sender
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-terminate: of %@", [self className]);
#endif
	_terminated = YES;
	_shouldFinish = YES;
}

- (void)finish
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-terminate: of %@", [self className]);
#endif
	_shouldFinish = YES;
}



/* result */
- (OgreTextFindResult*)result
{
	return _textFindResult;
}


/* Configuration */
- (void)setDidEndSelector:(SEL)aSelector toTarget:(id)aTarget
{
	_didEndSelector = aSelector;
	_didEndTarget = aTarget;
}

- (void)setProgressDelegate:(NSObject <OgreTextFindProgressDelegate>*)aDelegate
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-setProgressDelegate: of %@", [self className]);
#endif
	_progressDelegate = aDelegate;  // not retain. I get rather retain. (retain しない。むしろretainしてもらう。)
	[_progressDelegate setCancelSelector:@selector(terminate:) 
		toTarget:self // will be retained
		withObject:nil];
}

- (NSObject <OgreTextFindProgressDelegate>*)progressDelegate
{
	return _progressDelegate;
}

/* Accessors */
@synthesize regularExpression = _regex;
@synthesize replaceExpression = _repex;
@synthesize highlightColor = _highlightColor;
@synthesize inSelection = _inSelection;
@synthesize terminated = _terminated;
@synthesize options = _searchOptions;

- (NSTimeInterval)processTime
{
	return -[_processTime timeIntervalSinceNow];
}

- (void)setAsynchronous:(BOOL)asynchronous
{
	_asynchronous = asynchronous;
}
/* Methods implemented by subclasses */
- (void)willProcessFindingInBranch:(OgreTextFindBranch*)aBranch;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-willProcessFindingInBranch: of %@ (BUG?)", [self className]);
#endif
	/* do nothing */
}

- (void)willProcessFindingInLeaf:(OgreTextFindLeaf*)aLeaf;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-willProcessFindingInLeaf: of %@ (BUG?)", [self className]);
#endif
	/* do nothing */
}

- (BOOL)shouldContinueFindingInLeaf:(OgreTextFindLeaf*)aLeaf
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-shouldContinueFindingInLeaf: of %@ (BUG?)", [self className]);
#endif
	return NO;  // stop
}

- (void)didProcessFindingInLeaf:(OgreTextFindLeaf*)aLeaf;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-didProcessFindingInLeaf: of %@ (BUG?)", [self className]);
#endif
	/* do nothing */
}

- (void)didProcessFindingInBranch:(OgreTextFindBranch*)aBranch;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-didProcessFindingInBranch: of %@ (BUG?)", [self className]);
#endif
	/* do nothing */
}


- (SEL)didEndSelectorForFindPanelController
{
	return @selector(didEndUnknownTextFindThread:);
}

- (NSString*)progressMessage
{
	return @"Illegal progress message";
}

- (NSString*)doneMessage
{
	return @"Illegal progress message";
}


/* Protected methods */
- (NSUInteger)numberOfMatches
{
	return _numberOfMatches;
}

- (void)incrementNumberOfMatches
{
	_numberOfMatches++;
}

- (double)progressPercentage
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-progressPercentage of %@ (BUG?)", [self className]);
#endif
	return 0;
}

- (double)donePercentage
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-donePercentage of %@ (BUG?)", [self className]);
#endif
	return 1;
}

- (void)pushEnumerator:(NSEnumerator*)anEnumerator
{
	_enumeratorProcessing = anEnumerator;
	[_enumeratorStack addObject:anEnumerator];
}

- (NSEnumerator*)topEnumerator
{
	return [_enumeratorStack lastObject];
}

- (NSEnumerator*)popEnumerator
{
	if ([_enumeratorStack count] == 0) return nil;
	
	NSEnumerator  *anObject = [_enumeratorStack lastObject];
	[_enumeratorStack removeLastObject];
	
	return anObject;
}

- (OgreTextFindBranch*)rootAdapter
{
	return _rootAdapter;
}

- (NSObject <OgreTextFindComponent, OgreTextFindTargetAdapter>*)targetAdapter
{
	return _targetAdapter;
}

- (void)pushBranch:(OgreTextFindBranch*)aBranch
{
	[_branchStack addObject:aBranch];
}

- (OgreTextFindBranch*)topBranch
{
	return [_branchStack lastObject];
}

- (OgreTextFindBranch*)popBranch
{
	if ([_branchStack count] == 0) return nil;
	
	OgreTextFindBranch  *anObject = [_branchStack lastObject];
	[_branchStack removeLastObject];
	
	return anObject;
}


- (void)_setLeafProcessing:(OgreTextFindLeaf*)aLeaf
{
	_leafProcessing = aLeaf;
}


- (void)addResultLeaf:(id)aResultLeaf
{
	if (aResultLeaf != nil) [_textFindResult addLeaf:aResultLeaf];
}

- (void)beginGraftingToBranch:(OgreTextFindBranch*)aBranch
{
	OgreFindResultBranch	*findResult = [aBranch findResultBranchWithThread:self];
	[_textFindResult beginGraftingToBranch:findResult];
}

- (void)endGrafting
{
	[_textFindResult endGrafting];
}

@end
