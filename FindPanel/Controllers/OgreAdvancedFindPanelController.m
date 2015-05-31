/*
 * Name: OgreAdvancedFindPanelController.m
 * Project: OgreKit
 *
 * Creation Date: Sep 14 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreAdvancedFindPanelController.h>
#import <OgreKit/OgreTextFinder.h>
#import <OgreKit/OgreTextFindResult.h>
#import <OgreKit/OgreAFPCEscapeCharacterFormatter.h>
#import <OgreKit/OgreFindResultWindowController.h>
#import <OgreKit/OgreAttachableWindowMediator.h>

// Various settings (諸設定)
static const NSInteger  OgreAFPCMaximumLeftMargin = 30;   // The maximum number of characters in the search results left (I prevent the match result is hidden) (検索結果の左側の最大文字数 (マッチ結果が隠れてしまうことを防ぐ))
static const NSInteger  OgreAFPCMaximumMatchedStringLength = 250; // The maximum number of characters in search results (検索結果の最大文字数)

// Localization using OgreAPFCLocalizable.strings (OgreAPFCLocalizable.stringsを使用したローカライズ)
#define OgreAPFCLocalizedString(key)	[[OgreTextFinder ogreKitBundle] localizedStringForKey:(key) value:(key) table:@"OgreAPFCLocalizable"]

// Exception name (例外名)
NSString	*OgreAFPCException = @"OgreAdvancedFindPanelControllerException";

// Key to be used for the history of encode/decode (historyのencode/decodeに使用するKey)
static NSString	*OgreAFPCFindHistoryKey              = @"AFPC Find History";
static NSString	*OgreAFPCReplaceHistoryKey           = @"AFPC Replace History";
static NSString	*OgreAFPCOptionsKey                  = @"AFPC Options";
static NSString	*OgreAFPCSyntaxKey                   = @"AFPC Syntax";
static NSString	*OgreAFPCEscapeCharacterKey          = @"AFPC Escape Character Tag";
static NSString	*OgreAFPCHighlightColorKey           = @"AFPC Highlight Color";
static NSString	*OgreAFPCOriginKey                   = @"AFPC Origin";
static NSString	*OgreAFPCScopeKey                    = @"AFPC Scope";
static NSString	*OgreAFPCWrapKey                     = @"AFPC Wrap";
static NSString	*OgreAFPCCloseWhenDoneKey            = @"AFPC Close Process Sheet When Done";
static NSString	*OgreAFPCMaxNumOfFindHistoryKey      = @"AFPC Maximum Number of Find History";
static NSString	*OgreAFPCMaxNumOfReplaceHistoryKey   = @"AFPC Maximum Number of Replace History";
static NSString	*OgreAFPCEnableStyleOptionsKey       = @"AFPC Enable Style Options";
static NSString	*OgreAFPCOpenProgressSheetKey        = @"AFPC Open Progress Sheet";
static NSString	*OgreAFPCAttributedFindHistoryKey    = @"AFPC Attributed Find History";
static NSString	*OgreAFPCAttributedReplaceHistoryKey = @"AFPC Attributed Replace History";

@interface OgreAdvancedFindPanelController () <OgreAFPCEscapeCharacterFormatterDelegate>

@end

@implementation OgreAdvancedFindPanelController

- (OgreSyntax)syntaxForIndex:(NSUInteger)index
{
	if (index == 0) return OgreSimpleMatchingSyntax;
	if (index == 1) return OgrePOSIXBasicSyntax;
	if (index == 2) return OgrePOSIXExtendedSyntax;
	if (index == 3) return OgreEmacsSyntax;
	if (index == 4) return OgreGrepSyntax;
	if (index == 5) return OgreGNURegexSyntax;
	if (index == 6) return OgreJavaSyntax;
	if (index == 7) return OgrePerlSyntax;
	if (index == 8) return OgreRubySyntax;
	
	[NSException raise:OgreException format:@"unknown syntax."];
	return 0;
}

- (NSInteger)indexForSyntax:(OgreSyntax)syntax
{
	if (syntax == OgreSimpleMatchingSyntax) return 0;
	if (syntax == OgrePOSIXBasicSyntax) return 1;
	if (syntax == OgrePOSIXExtendedSyntax) return 2;
	if (syntax == OgreEmacsSyntax) return 3;
	if (syntax == OgreGrepSyntax) return 4;
	if (syntax == OgreGNURegexSyntax) return 5;
	if (syntax == OgreJavaSyntax) return 6;
	if (syntax == OgrePerlSyntax) return 7;
	if (syntax == OgreRubySyntax) return 8;
	
	[NSException raise:OgreException format:@"unknown syntax."];
	return -1;	// dummy
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	// initialize
	// Set the tag to distinguish syntax (syntaxを見分けるtagを設定)
	NSInteger i;
	for (i=0; i<=8; i++) {
		[[syntaxPopUpButton itemAtIndex:i] setTag:[OGRegularExpression intValueForSyntax:[self syntaxForIndex:i]]];
	}
	
	_findHistory = [[NSMutableArray alloc] initWithCapacity:10];
	_replaceHistory = [[NSMutableArray alloc] initWithCapacity:10];
	_isAlertSheetOpen = NO;
	_findResultWindowController = nil;
	
	NSMenu		*menu;
	NSMenuItem	*menuItem;
	menu = [[NSMenu alloc] initWithTitle:@""];
	menuItem = [[NSMenuItem alloc] init];
	[menuItem setTitle:@""];
	[menu addItem:menuItem];
	[findPopUpButton setMenu:menu];
	
	menu = [[NSMenu alloc] initWithTitle:@""];
	menuItem = [[NSMenuItem alloc] init];
	[menuItem setTitle:@""];
	[menu addItem:menuItem];
	[replacePopUpButton setMenu:menu];
	
	// formatter of escape character (escape characterのformatter)
	_escapeCharacterFormatter = [[OgreAFPCEscapeCharacterFormatter alloc] init];
	[_escapeCharacterFormatter setDelegate:self];
	
	// default settings
	[self setIgnoreCaseOption:YES];
	[self setCaptureGroupOption:YES];
	
	[self setWrapSearchOption:YES];
	
	[self setAtTopOriginOption:NO];
	[self setInSelectionScopeOption:NO];
	
	[self setOpenSheetOption:YES];
	[self setCloseWhenDoneOption:YES];
	
	[toggleStyleOptionsButton setState:NSOffState];
    
    // disable Automatic Substitution Features
    [self disableAutomaticSubstitutions:findTextView];
    [self disableAutomaticSubstitutions:replaceTextView];
	
	// restore history
	[self restoreHistory:[self.textFinder history]];
	[self.textFinder setEscapeCharacter:[self escapeCharacter]];
	[self.textFinder setSyntax:[self syntax]];
	
	// show/hide style options
	[self toggleStyleOptions:self];
	
	// I pick up the change of max number of find / replace history (max number of find/replace historyの変更を拾う)
	[[NSNotificationCenter defaultCenter] addObserver: self 
		selector: @selector(updateMaxNumOfFindHistory:) 
		name: NSControlTextDidEndEditingNotification
		object: maxNumOfFindHistoryTextField];
	[[NSNotificationCenter defaultCenter] addObserver: self 
		selector: @selector(updateMaxNumOfReplaceHistory:) 
		name: NSControlTextDidEndEditingNotification
		object: maxNumOfReplaceHistoryTextField];
}


// disable Automatic Substitution Features
- (void)disableAutomaticSubstitutions:(NSTextView *)textView
{
    [textView setSmartInsertDeleteEnabled:NO];
    [textView setAutomaticDashSubstitutionEnabled:NO];
    [textView setAutomaticDataDetectionEnabled:NO];
    [textView setAutomaticLinkDetectionEnabled:NO];
    [textView setAutomaticQuoteSubstitutionEnabled:NO];
    [textView setAutomaticSpellingCorrectionEnabled:NO];
    [textView setAutomaticTextReplacementEnabled:NO];
}

/*- (void)notified:(NSNotification *)aNotification
{
	NSLog(@"%@", [aNotification name]);
}*/

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


/* (re)store history */

- (void)restoreHistory:(NSDictionary *)history
{
	if (history == nil) return;
	
	NSMutableArray	*findHistory = [NSMutableArray arrayWithArray:history[OgreAFPCFindHistoryKey]];
	if ((findHistory != nil) && ([findHistory count] > 0)) {
		@autoreleasepool {
		
		_findHistory = findHistory;
		
		NSMenu			*menu = [findPopUpButton menu];
		NSMenuItem		*item;
		NSInteger	i;
		for (i = 0; i < [_findHistory count]; i++) {
			NSAttributedString	*attrString;
			id	aString = _findHistory[i];
			if (![aString isKindOfClass:[NSAttributedString class]]) {
				attrString = [[NSAttributedString alloc] initWithString:aString];
				_findHistory[i] = attrString;
			} else {
				attrString = (NSAttributedString *)aString;
			}
			
			item = [[NSMenuItem alloc] init];
			NSUInteger  start, end, contentsEnd;
			[[attrString string] getLineStart:&start
				end:&end 
				contentsEnd:&contentsEnd 
				forRange:NSMakeRange(0, 0)];
			if (start == contentsEnd) {
				[item setTitle:@""];
			} else {
				[item setAttributedTitle:[attrString attributedSubstringFromRange:NSMakeRange(start, contentsEnd - start)]];
			}
			[item setTarget:self];
			[item setAction:@selector(selectFindHistory:)];
			[menu addItem:item];
		}
		
		[self setFindString:_findHistory[0]];
		}
	} else {
		//[findTextView setString:@""];
	}
	
	NSMutableArray	*attrFindHistory = [NSMutableArray arrayWithArray:history[OgreAFPCAttributedFindHistoryKey]];
	if ((attrFindHistory != nil) && ([attrFindHistory count] > 0)) {
		@autoreleasepool {
		
		NSMenu			*menu = [findPopUpButton menu];
		NSMenuItem		*item;
		
		_findHistory = [[NSMutableArray alloc] initWithCapacity:[attrFindHistory count]];
		
		NSAttributedString	*attrString;
		NSInteger	i;
		for (i = 0; i < [attrFindHistory count]; i++) {
			attrString = [[NSAttributedString alloc] initWithRTFD:attrFindHistory[i] documentAttributes:nil];
			[_findHistory addObject:attrString];
			
			item = [[NSMenuItem alloc] init];
			NSUInteger  start, end, contentsEnd;
			[[attrString string] getLineStart:&start
				end:&end 
				contentsEnd:&contentsEnd 
				forRange:NSMakeRange(0, 0)];
			if (start == contentsEnd) {
				[item setTitle:@""];
			} else {
				[item setAttributedTitle:[attrString attributedSubstringFromRange:NSMakeRange(start, contentsEnd - start)]];
			}
			[item setTarget:self];
			[item setAction:@selector(selectFindHistory:)];
			[menu addItem:item];
			
		}
		
		[self setFindString:_findHistory[0]];
		}
	} else {
		//[findTextView setString:@""];
	}
	
	NSMutableArray	*replaceHistory = [NSMutableArray arrayWithArray:history[OgreAFPCReplaceHistoryKey]];
	if ((replaceHistory != nil) && ([replaceHistory count] > 0)) {
		@autoreleasepool {
		
		_replaceHistory = replaceHistory;
		
		NSMenu			*menu = [replacePopUpButton menu];
		NSMenuItem		*item;
		NSInteger	i;
		for (i = 0; i < [_replaceHistory count]; i++) {
			NSAttributedString	*attrString;
			id aString = _replaceHistory[i];
			if (![aString isKindOfClass:[NSAttributedString class]]) {
				attrString = [[NSAttributedString alloc] initWithString:aString];
				_replaceHistory[i] = attrString;
			} else {
				attrString = (NSAttributedString *)aString;
			}
			
			item = [[NSMenuItem alloc] init];
			NSUInteger  start, end, contentsEnd;
			[[attrString string] getLineStart:&start
				end:&end 
				contentsEnd:&contentsEnd 
				forRange:NSMakeRange(0, 0)];
			if (start == contentsEnd) {
				[item setTitle:@""];
			} else {
				[item setAttributedTitle:[attrString attributedSubstringFromRange:NSMakeRange(start, contentsEnd - start)]];
			}
			[item setTarget:self];
			[item setAction:@selector(selectReplaceHistory:)];
			[menu addItem:item];
			
		}
		
		[self setReplaceString:_replaceHistory[0]];
		}
	} else {
		//[replaceTextView setString:@""];
	}
	
	NSMutableArray	*attrReplaceHistory = [NSMutableArray arrayWithArray:history[OgreAFPCAttributedReplaceHistoryKey]];
	if ((attrReplaceHistory != nil) && ([attrReplaceHistory count] > 0)) {
		@autoreleasepool {
		
		NSMenu			*menu = [replacePopUpButton menu];
		NSMenuItem		*item;
		
		_replaceHistory = [[NSMutableArray alloc] initWithCapacity:[attrFindHistory count]];
		
		NSAttributedString	*attrString;
		NSInteger	i;
		for (i = 0; i < [attrReplaceHistory count]; i++) {
			attrString = [[NSAttributedString alloc] initWithRTFD:attrReplaceHistory[i] documentAttributes:nil];
			[_replaceHistory addObject:attrString];
			
			item = [[NSMenuItem alloc] init];
			NSUInteger  start, end, contentsEnd;
			[[attrString string] getLineStart:&start
				end:&end 
				contentsEnd:&contentsEnd 
				forRange:NSMakeRange(0, 0)];
			if (start == contentsEnd) {
				[item setTitle:@""];
			} else {
				[item setAttributedTitle:[attrString attributedSubstringFromRange:NSMakeRange(start, contentsEnd - start)]];
			}
			[item setTarget:self];
			[item setAction:@selector(selectReplaceHistory:)];
			[menu addItem:item];
			
		}
		
		[self setReplaceString:_replaceHistory[0]];
		}
	} else {
		//[replaceTextView setString:@""];
	}
	
	id	anObject = history[OgreAFPCOptionsKey];
	if (anObject != nil) {
		OgreOption	options = [anObject unsignedIntValue];
		
		[self setSingleLineOption          : ((options & OgreSingleLineOption) != 0)];
		[self setMultilineOption           : ((options & OgreMultilineOption) != 0)];
		[self setIgnoreCaseOption          : ((options & OgreIgnoreCaseOption) != 0)];
		[self setExtendOption              : ((options & OgreExtendOption) != 0)];
		[self setFindLongestOption         : ((options & OgreFindLongestOption) != 0)];
		[self setFindNotEmptyOption        : ((options & OgreFindNotEmptyOption) != 0)];
		[self setFindEmptyOption           : ((options & OgreFindEmptyOption) != 0)];
		[self setNegateSingleLineOption    : ((options & OgreNegateSingleLineOption) != 0)];
		[self setCaptureGroupOption        : ((options & OgreCaptureGroupOption) != 0)];
		[self setDontCaptureGroupOption    : ((options & OgreDontCaptureGroupOption) != 0)];
		[self setDelimitByWhitespaceOption : ((options & OgreDelimitByWhitespaceOption) != 0)];
		[self setNotBeginOfLineOption      : ((options & OgreNotBOLOption) != 0)];
		[self setNotEndOfLineOption        : ((options & OgreNotEOLOption) != 0)];
		[self setReplaceWithStylesOption   : ((options & OgreReplaceWithAttributesOption) != 0)];
		[self setReplaceFontsOption        : ((options & OgreReplaceFontsOption) != 0)];
		[self setMergeStylesOption         : ((options & OgreMergeAttributesOption) != 0)];
	}
	
	anObject = history[OgreAFPCSyntaxKey];
	if (anObject != nil) {
        OgreSyntax	syntax = [OGRegularExpression syntaxForIntValue:[anObject intValue]];
		
		[syntaxPopUpButton selectItemAtIndex:[self indexForSyntax:syntax]];
		
		[self setRegularExpressionsOption: (syntax != OgreSimpleMatchingSyntax)];
		
		NSInteger	i, syntaxValue = [OGRegularExpression intValueForSyntax:syntax];
		for (i = 0; i <= 8; i++) {
			if ([[syntaxPopUpButton itemAtIndex:i] tag] == syntaxValue) {
				[syntaxPopUpButton selectItemAtIndex:i];
				break;
			}
		}
	}
	
	anObject = history[OgreAFPCEscapeCharacterKey];
	if (anObject != nil) {
		[escapeCharacterPopUpButton selectItemAtIndex:[anObject integerValue]];
	}
	
	anObject = history[OgreAFPCHighlightColorKey];
	if (anObject != nil) {
		[highlightColorWell setColor:[NSUnarchiver unarchiveObjectWithData:anObject]];
	}
	
	anObject = history[OgreAFPCOriginKey];
	if (anObject != nil) {
		NSUInteger	origin = [anObject unsignedIntegerValue];
		[self setAtTopOriginOption: (origin == 0)];
	}
	
	anObject = history[OgreAFPCScopeKey];
	if (anObject != nil) {
		NSUInteger	scope = [anObject unsignedIntegerValue];
		[self setInSelectionScopeOption: (scope != 0)];
	}
	
	anObject = history[OgreAFPCWrapKey];
	if (anObject != nil) {
		[self setWrapSearchOption: ([anObject integerValue] == NSOnState)];
	}
	
	anObject = history[OgreAFPCCloseWhenDoneKey];
	if (anObject != nil) {
		[self setCloseWhenDoneOption: ([anObject integerValue] == NSOnState)];
	}
	
	anObject = history[OgreAFPCMaxNumOfFindHistoryKey];
	if (anObject != nil) {
		[maxNumOfFindHistoryTextField setIntegerValue:[anObject integerValue]];
	}
	
	anObject = history[OgreAFPCMaxNumOfReplaceHistoryKey];
	if (anObject != nil) {
		[maxNumOfReplaceHistoryTextField setIntegerValue:[anObject integerValue]];
	}
	
	anObject = history[OgreAFPCEnableStyleOptionsKey];
	if (anObject != nil) {
		[toggleStyleOptionsButton setState:[anObject integerValue]];
	}
	
	anObject = history[OgreAFPCOpenProgressSheetKey];
	if (anObject != nil) {
		[self setOpenSheetOption:[anObject boolValue]];
	}
}

- (NSDictionary *)history
{
	NSMutableArray		*encodedFindHistory;
	NSMutableArray		*encodedReplaceHistory;
	NSEnumerator		*enumerator;
	NSAttributedString	*attrString;
	
	encodedFindHistory = [[NSMutableArray alloc] initWithCapacity:[_findHistory count]];
	enumerator = [_findHistory objectEnumerator];
	while ((attrString = [enumerator nextObject]) != nil) {
		[encodedFindHistory addObject:[attrString RTFDFromRange:NSMakeRange(0, [attrString length]) 
			documentAttributes:nil]];
	}
	
	encodedReplaceHistory = [[NSMutableArray alloc] initWithCapacity:[_replaceHistory count]];
	enumerator = [_replaceHistory objectEnumerator];
	while ((attrString = [enumerator nextObject]) != nil) {
		[encodedReplaceHistory addObject:[attrString RTFDFromRange:NSMakeRange(0, [attrString length]) 
			documentAttributes:nil]];
	}
	
	/* If you want to keep the information of search history, etc. override this method. (検索履歴等の情報を残したい場合はこのメソッドを上書きする。) */
	return @{OgreAFPCAttributedFindHistoryKey: encodedFindHistory, 
			OgreAFPCAttributedReplaceHistoryKey: encodedReplaceHistory, 
			OgreAFPCOptionsKey: @([self _options]), 
			OgreAFPCSyntaxKey: @([[syntaxPopUpButton selectedItem] tag]), 
			OgreAFPCEscapeCharacterKey: @([[escapeCharacterPopUpButton selectedItem] tag]), 
			OgreAFPCHighlightColorKey: [NSArchiver archivedDataWithRootObject:[highlightColorWell color]],
			OgreAFPCOriginKey: @([self atTopOriginOption]? 0 : 1), 
			OgreAFPCScopeKey: @([self inSelectionScopeOption]? 1 : 0), 
			OgreAFPCWrapKey: @([self wrapSearchOption]? NSOnState : NSOffState), 
			OgreAFPCCloseWhenDoneKey: @([self closeWhenDoneOption]? NSOnState : NSOffState), 
			OgreAFPCMaxNumOfFindHistoryKey: @([maxNumOfFindHistoryTextField integerValue]),
			OgreAFPCMaxNumOfReplaceHistoryKey: @([maxNumOfReplaceHistoryTextField integerValue]),
			OgreAFPCEnableStyleOptionsKey: @([toggleStyleOptionsButton state]), 
			OgreAFPCOpenProgressSheetKey: @([self openSheetOption])};
}


/* find/replace history */

- (void)addFindHistory:(NSAttributedString *)attrString
{
	[self loadFindStringToPasteboard];
	
	NSMenu		*menu = [findPopUpButton menu];
	NSInteger	i, n = [_findHistory count];
	NSString	*string = [attrString string];
	for (i = 0; i < n; i++) {
		if ([[_escapeCharacterFormatter stringForObjectValue:[_findHistory[i] string]]  isEqualToString:string]) {
			[_findHistory removeObjectAtIndex:i];
			[menu removeItemAtIndex:(i + 1)];
			break;
		}
	}
	
	[_findHistory insertObject:[attrString copy] atIndex:0];
	
	NSMenuItem	*item = [[NSMenuItem alloc] init];
	NSUInteger	start, end, contentsEnd;
	[string getLineStart:&start
		end:&end
		contentsEnd:&contentsEnd 
		forRange:NSMakeRange(0, 0)];
	if (start == contentsEnd) {
		[item setTitle:@""];
	} else {
		[item setAttributedTitle:[attrString attributedSubstringFromRange:NSMakeRange(start, contentsEnd - start)]];
	}
	[item setTarget:self];
	[item setAction:@selector(selectFindHistory:)];
	[menu insertItem:item atIndex:1];
	
	NSInteger	maxNumOfHistory = [maxNumOfFindHistoryTextField integerValue];
	while ([_findHistory count] > maxNumOfHistory) {
		[_findHistory removeObjectAtIndex:maxNumOfHistory];
		[menu removeItemAtIndex:(maxNumOfHistory + 1)];
	}
}

- (void)addReplaceHistory:(NSAttributedString *)string
{
	NSMenu	*menu = [replacePopUpButton menu];
	NSInteger		i, n = [_replaceHistory count];
	for (i = 0; i < n; i++) {
		if ([[_escapeCharacterFormatter attributedStringForObjectValue:_replaceHistory[i] 
				withDefaultAttributes:nil] isEqualToAttributedString:string]) {
			
			[_replaceHistory removeObjectAtIndex:i];
			[menu removeItemAtIndex:(i + 1)];
			break;
		}
	}
	
	[_replaceHistory insertObject:[string copy] atIndex:0];
	
	NSMenuItem	*item = [[NSMenuItem alloc] init];
	NSUInteger	start, end, contentsEnd;
	[[string string] getLineStart:&start
		end:&end 
		contentsEnd:&contentsEnd 
		forRange:NSMakeRange(0, 0)];
	if (start == contentsEnd) {
		[item setTitle:@""];
	} else {
		[item setAttributedTitle:[string attributedSubstringFromRange:NSMakeRange(start, contentsEnd - start)]];
	}
	[item setTarget:self];
	[item setAction:@selector(selectReplaceHistory:)];
	[menu insertItem:item atIndex:1];
	
	NSInteger	maxNumOfHistory = [maxNumOfReplaceHistoryTextField integerValue];
	while ([_replaceHistory count] > maxNumOfHistory) {
		[_replaceHistory removeObjectAtIndex:maxNumOfHistory];
		[menu removeItemAtIndex:(maxNumOfHistory + 1)];
	}
}

- (IBAction)clearFindReplaceHistories:(id)sender
{
	[findPanel makeKeyAndOrderFront:self];
    NSString *clearHistoryMessage = OgreAPFCLocalizedString(@"Do you really want to clear find/replace histories?");
	NSBeginAlertSheet(OgreAPFCLocalizedString(@"Clear"), 
		OgreAPFCLocalizedString(@"Yes"), 
		OgreAPFCLocalizedString(@"No"), 
		nil, findPanel, self, 
		@selector(clearFindPeplaceHistoriesSheetDidEnd:returnCode:contextInfo:), 
		@selector(sheetDidDismiss:returnCode:contextInfo:), nil, 
		@"%@", clearHistoryMessage);
	_isAlertSheetOpen = YES;
}

- (void)clearFindPeplaceHistoriesSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo{
	if (returnCode == NSAlertDefaultReturn) {
		_findHistory = [[NSMutableArray alloc] initWithCapacity:0];
		_replaceHistory = [[NSMutableArray alloc] initWithCapacity:0];
		[findTextView setString:@""];
		[replaceTextView setString:@""];
		
		NSMenu		*menu;
		NSMenuItem	*menuItem;
		menu = [[NSMenu alloc] initWithTitle:@""];
		menuItem = [[NSMenuItem alloc] init];
		[menuItem setTitle:@""];
		[menu addItem:menuItem];
		[findPopUpButton setMenu:menu];
		
		menu = [[NSMenu alloc] initWithTitle:@""];
		menuItem = [[NSMenuItem alloc] init];
		[menuItem setTitle:@""];
		[menu addItem:menuItem];
		[replacePopUpButton setMenu:menu];
	}
}

- (IBAction)selectFindHistory:(id)sender
{
	NSMenu				*menu = [findPopUpButton menu];
	NSInteger			selectedIndex = [menu indexOfItem:sender];
	NSAttributedString	*attrString = _findHistory[selectedIndex - 1];
	[self setFindString:attrString];
}

- (IBAction)selectReplaceHistory:(id)sender
{
	NSMenu				*menu = [replacePopUpButton menu];
	NSInteger			selectedIndex = [menu indexOfItem:sender];
	NSAttributedString	*attrString = _replaceHistory[selectedIndex - 1];
	[self setReplaceString:attrString];
}

- (void)setFindString:(NSAttributedString *)attrString
{
	NSTextStorage		*textStorage = [findTextView textStorage];
	NSAttributedString	*findString = [_escapeCharacterFormatter attributedStringForObjectValue:attrString 
		withDefaultAttributes:nil];
		
	NSRange				oldRange = NSMakeRange(0, [textStorage length]);
	// prepare to undo
	if ([findTextView allowsUndo]) {	// yet buggy
		NSRange			newRange = NSMakeRange(0, [findString length]);
		NSUndoManager	*undoManager = [findTextView undoManager];
		[undoManager beginUndoGrouping];
		[[undoManager prepareWithInvocationTarget:self] 
			undoableReplaceCharactersInRange:newRange 
			withAttributedString:[[NSAttributedString alloc] initWithAttributedString:textStorage] 
			inTarget:findTextView];
		[undoManager endUndoGrouping];
	}
	
	// replace
	[textStorage replaceCharactersInRange:oldRange withAttributedString:findString];
}

- (void)setReplaceString:(NSAttributedString *)attrString
{
	NSTextStorage		*textStorage = [replaceTextView textStorage];
	NSAttributedString	*replaceString = [_escapeCharacterFormatter attributedStringForObjectValue:attrString 
											withDefaultAttributes:nil];
	
	NSRange				oldRange = NSMakeRange(0, [textStorage length]);
	
	// prepare to undo
	if ([replaceTextView allowsUndo]) {	// yet buggy
		NSRange			newRange = NSMakeRange(0, [replaceString length]);
		NSUndoManager	*undoManager = [replaceTextView undoManager];
		[undoManager beginUndoGrouping];
		[[undoManager prepareWithInvocationTarget:self] 
			undoableReplaceCharactersInRange:newRange 
			withAttributedString:[[NSAttributedString alloc] initWithAttributedString:textStorage] 
			inTarget:replaceTextView];
		[undoManager endUndoGrouping];
	}
	
	// replace
	[textStorage replaceCharactersInRange:oldRange withAttributedString:replaceString];
}

- (void)undoableReplaceCharactersInRange:(NSRange)oldRange 
	withAttributedString:(NSAttributedString *)newString 
	inTarget:(NSTextView *)aTextView 
{
	//NSLog(@"undoableReplaceCharactersInRange:(%lu, %lu) withAttributedString:%@", (unsigned long)oldRange.location, (unsigned long)oldRange.length, [newString string]);
	NSTextStorage		*textStorage = [aTextView textStorage];
	NSAttributedString	*replaceString = [_escapeCharacterFormatter attributedStringForObjectValue:newString 
											withDefaultAttributes:nil];
	
	// prepare to undo
	if ([aTextView allowsUndo]) { 
		NSRange		newRange = NSMakeRange(oldRange.location, [replaceString length]);
		[[[aTextView undoManager] prepareWithInvocationTarget:self] 
			undoableReplaceCharactersInRange:newRange 
			withAttributedString:[[NSAttributedString alloc] initWithAttributedString:[textStorage attributedSubstringFromRange:oldRange]] 
			inTarget:aTextView];
	}
	// undo
	[textStorage replaceCharactersInRange:oldRange withAttributedString:replaceString];
}


/* accessors */

- (NSString *)escapeCharacter
{
	NSInteger tag = [[escapeCharacterPopUpButton selectedItem] tag];
	// 0: ＼
	// 1: ￥
	// 2: ＼ (Convert ￥ to ＼)
	// 3: ￥ (Convert ＼ to ￥)
	
	if ((tag == 0) || (tag == 2)) {
		return OgreBackslashCharacter;
	} else {
		return OgreGUIYenCharacter;
	}
}

- (BOOL)shouldEquateYenWithBackslash
{
	NSInteger tag = [[escapeCharacterPopUpButton selectedItem] tag];
	// 0: ＼
	// 1: ￥
	// 2: ＼ (Convert ￥ to ＼)
	// 3: ￥ (Convert ＼ to ￥)
	
	if ((tag == 0) || (tag == 1)) {
		return NO;
	} else {
		return YES;
	}
}

- (OgreOption)_options
{
	OgreOption	options = OgreNoneOption;
	
	if ([self singleLineOption]) options |= OgreSingleLineOption;
	if ([self multilineOption]) options |= OgreMultilineOption;
	if ([self ignoreCaseOption]) options |= OgreIgnoreCaseOption;
	if ([self extendOption]) options |= OgreExtendOption;
	if ([self findLongestOption]) options |= OgreFindLongestOption;
	if ([self findNotEmptyOption]) options |= OgreFindNotEmptyOption;
	if ([self findEmptyOption]) options |= OgreFindEmptyOption;
	if ([self negateSingleLineOption]) options |= OgreNegateSingleLineOption;
	if ([self captureGroupOption]) options |= OgreCaptureGroupOption;
	if ([self dontCaptureGroupOption]) options |= OgreDontCaptureGroupOption;
	if ([self delimitByWhitespaceOption]) options |= OgreDelimitByWhitespaceOption;
	if ([self notBeginOfLineOption]) options |= OgreNotBOLOption;
	if ([self notEndOfLineOption]) options |= OgreNotEOLOption;
	if ([self replaceWithStylesOption]) options |= OgreReplaceWithAttributesOption;
	if ([self replaceFontsOption]) options |= OgreReplaceFontsOption;
	if ([self mergeStylesOption]) options |= OgreMergeAttributesOption;
	
	return options;
}

- (OgreOption)options
{
	OgreOption	options = [self _options];
	if ([toggleStyleOptionsButton state] == NSOffState) {
		options = OgreCompileTimeOptionMask(options) | OgreSearchTimeOptionMask(options);
	}
	
	return options;
}

- (OgreSyntax)syntax
{
    //NSLog(@"%ld", (long)[[syntaxPopUpButton selectedItem] tag]);
	return [OGRegularExpression syntaxForIntValue:(int)[[syntaxPopUpButton selectedItem] tag]];
}

- (void)avoidEmptySelection
{
	if ([[self textFinder] isSelectionEmpty]) {
		// If empty range selection, I want to force the whole search range. (空範囲選択の場合、強制的に検索範囲を全体にする。)
		[self setInSelectionScopeOption: NO];
	}
}

- (BOOL)isStartFromTop
{
	return [self atTopOriginOption];
}

- (void)setStartFromCursor
{
	[self setAtTopOriginOption: NO];
}

- (BOOL)isWrap
{
	return [self wrapSearchOption];
}

- (IBAction)toggleStyleOptions:(id)sender
{
	NSRect	textFrame = [findReplaceTextBox frame];
	NSRect	optionsFrame = [styleOptionsBox frame];
	NSSize	newSize = textFrame.size;
	if ([toggleStyleOptionsButton state] == NSOnState) {
		// show Replace Options
		newSize.width = optionsFrame.origin.x - textFrame.origin.x;
		[findReplaceTextBox setFrameSize:newSize];
		[styleOptionsBox setHidden:NO];
	} else {
		// hide Replace Options
		[styleOptionsBox setHidden:YES];
		newSize.width = optionsFrame.origin.x + optionsFrame.size.width - textFrame.origin.x;
		[findReplaceTextBox setFrameSize:newSize];
	}
	[findPanel display];
}

- (IBAction)showFindPanel:(id)sender
{
    //if (![findPanel isVisible]) [self loadFindStringFromPasteboard];
    
	if (![self.textFinder useStylesInFindPanel]) {
		if ([toggleStyleOptionsButton state] != NSOffState) {
			[toggleStyleOptionsButton setState:NSOffState];
			[self toggleStyleOptions:self];
		}
		[toggleStyleOptionsButton setHidden:YES];
	} else {
		[toggleStyleOptionsButton setHidden:NO];
	}
	
	[findPanel makeFirstResponder:findTextView];
	
	// Next three lines by Koch, May 17 2005
	NSRange    myRange;
	myRange.location = 0; myRange.length = [[findTextView string] length];
	[findTextView setSelectedRange: myRange];
	
	[super showFindPanel:self];
}

/* update settings */

- (IBAction)updateEscapeCharacter:(id)sender
{
	[self.textFinder setEscapeCharacter:[self escapeCharacter]];
	[self setFindString:[findTextView textStorage]];	// update contents
	[self setReplaceString:[replaceTextView textStorage]];	// update contents
}

- (IBAction)updateOptions:(id)sender
{
	//NSLog(@"update options");
}

- (IBAction)updateSyntax:(id)sender
{
	//NSLog(@"update syntax");
	
	if (sender == syntaxPopUpButton) {
		[self setRegularExpressionsOption:([[syntaxPopUpButton selectedItem] tag] != [OGRegularExpression intValueForSyntax:OgreSimpleMatchingSyntax])];
	} else {
		if ([self regularExpressionsOption]) {
			NSInteger	i, syntaxValue = [OGRegularExpression intValueForSyntax:OgreRubySyntax];
			for (i = 0; i <= 8; i++) {
				if ([[syntaxPopUpButton itemAtIndex:i] tag] == syntaxValue) {
					[syntaxPopUpButton selectItemAtIndex:i];
					break;
				}
			}
		} else {
			NSInteger	i, syntaxValue = [OGRegularExpression intValueForSyntax:OgreSimpleMatchingSyntax];
			for (i = 0; i <= 8; i++) {
				if ([[syntaxPopUpButton itemAtIndex:i] tag] == syntaxValue) {
					[syntaxPopUpButton selectItemAtIndex:i];
					break;
				}
			}
		}
	}
	
	OgreSyntax	syntax = [self syntax];
	[self.textFinder setSyntax:syntax];
}

- (void)updateMaxNumOfFindHistory:(NSNotification *)aNotification
{
	NSMenu	*menu = [findPopUpButton menu];
	NSUInteger	maxNumOfHistory = [maxNumOfFindHistoryTextField integerValue];
	while ([_findHistory count] > maxNumOfHistory) {
		[_findHistory removeObjectAtIndex:maxNumOfHistory];
		[menu removeItemAtIndex:(maxNumOfHistory + 1)];
	}
}

- (void)updateMaxNumOfReplaceHistory:(NSNotification *)aNotification
{
	NSMenu	*menu = [replacePopUpButton menu];
	NSUInteger	maxNumOfHistory = [maxNumOfReplaceHistoryTextField integerValue];
	while ([_replaceHistory count] > maxNumOfHistory) {
		[_replaceHistory removeObjectAtIndex:maxNumOfHistory];
		[menu removeItemAtIndex:(maxNumOfHistory + 1)];
	}
}


/* show alert */
- (BOOL)alertIfInvalidRegex
{
	@try {
        [OGRegularExpression regularExpressionWithString:[findTextView string]
                                                 options:[self options]
                                                  syntax:[self syntax]
                                         escapeCharacter:[self escapeCharacter]];
	} @catch (NSException *localException) {
		// Exception handling (例外処理)
		if ([[localException name] isEqualToString:OgreException]) {
			[self showErrorAlert:OgreAPFCLocalizedString(@"Invalid Regular Expression") message:[localException reason]];
		} else {
			[localException raise];
		}
		return NO;
	}
	
	return YES;
}

- (void)showErrorAlert:(NSString *)title message:(NSString *)message
{
	NSBeep();
	[findPanel makeKeyAndOrderFront:self];
	NSBeginAlertSheet(title, OgreAPFCLocalizedString(@"OK"), nil, nil, findPanel, self, nil, @selector(sheetDidDismiss:returnCode:contextInfo:), nil, @"%@", message);
	_isAlertSheetOpen = YES;
}

- (void)sheetDidDismiss:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	//NSLog(@"sheetDidDismiss");
	[findPanel makeKeyAndOrderFront:self];
	_isAlertSheetOpen = NO;
}

/* actions */

- (IBAction)findNext:(id)sender
{
	[self findNextStrategy];
}

- (IBAction)findNextAndOrderOut:(id)sender
{
	OgreTextFindResult	*result = [self findNextStrategy];
	if ([result isSuccess]) [findPanel orderOut:self];
}

- (OgreTextFindResult *)findNextStrategy
{
	if (_isAlertSheetOpen) {
		NSBeep();
		[self showFindPanel:self];
		return [OgreTextFindResult textFindResultWithTarget:nil thread:nil];   // failure
	}
    
	if (![self alertIfInvalidRegex]) {
        return [OgreTextFindResult textFindResultWithTarget:nil thread:nil];   // failure
    }
	
	[self addFindHistory:[findTextView textStorage]];
	
    OgreTextFindResult *result = [[self textFinder] find:[findTextView string]
                                                 options:[self options]
                                                 fromTop:[self isStartFromTop]
                                                 forward:YES
                                                    wrap:[self isWrap]];

	if (![result alertIfErrorOccurred]) {
		if ([result isSuccess]) {
			[self setStartFromCursor];
		} else {
			NSBeep();
		}
	}
    
	return result;
}

- (IBAction)findPrevious:(id)sender
{
	if (_isAlertSheetOpen) {
		NSBeep();
		[self showFindPanel:self];
		return;
	}
	if (![self alertIfInvalidRegex]) return;
	
	[self addFindHistory:[findTextView textStorage]];
	
    OgreTextFindResult *result = [[self textFinder] find:[findTextView string]
                                                 options:[self options]
                                                 fromTop:[self isStartFromTop]
                                                 forward:NO
                                                    wrap:[self isWrap]];
		
	if (![result alertIfErrorOccurred]) {
		if ([result isSuccess]) {
			[self setStartFromCursor];
		} else {
			NSBeep();
		}
	}
}

- (IBAction)replace:(id)sender
{
	if (_isAlertSheetOpen) {
		NSBeep();
		[self showFindPanel:self];
		return;
	}
	if (![self alertIfInvalidRegex]) return;
	
	[self addFindHistory:[findTextView textStorage]];
	[self addReplaceHistory:[replaceTextView textStorage]];
	
	OgreTextFindResult	*result = [[self textFinder] replaceAndFind:[findTextView string] 
			withAttributedString:[replaceTextView textStorage] 
			options:[self options] 
            replacingOnly:YES 
            wrap:NO];
			
	if (![result alertIfErrorOccurred]) {
		if ([result isSuccess]) {
			[self setStartFromCursor];
		} else {
			NSBeep();
		}
	}
}

- (IBAction)replaceAndFind:(id)sender
{
	if (_isAlertSheetOpen) {
		NSBeep();
		[self showFindPanel:self];
		return;
	}
	if (![self alertIfInvalidRegex]) return;
	
	[self addFindHistory:[findTextView textStorage]];
	[self addReplaceHistory:[replaceTextView textStorage]];
	
	OgreTextFindResult	*result = [[self textFinder] replaceAndFind:[findTextView string] 
			withAttributedString:[replaceTextView textStorage] 
			options:[self options] 
            replacingOnly:NO 
            wrap:[self isWrap]];
			
	if (![result alertIfErrorOccurred]) {
		if ([result isSuccess]) {
			[self setStartFromCursor];
		} else {
			NSBeep();
		}
	}
}


- (IBAction)replaceAll:(id)sender
{
	if (_isAlertSheetOpen) {
		NSBeep();
		[self showFindPanel:self];
		return;
	}
	if (![self alertIfInvalidRegex]) return;
	
	[self addFindHistory:[findTextView textStorage]];
	[self addReplaceHistory:[replaceTextView textStorage]];
	
#if 0
	NSLog(@"Find: %@", [findTextView string]);
	NSLog(@"Replace: %@", [replaceTextView string]);
	NSLog(@"Options: %@", [[OGRegularExpression stringsForOptions:[self options]] description]);
	NSLog(@"inSelection: %@", ([self inSelectionScopeOption]? @"YES" : @"NO"));
	NSLog(@"inWrap: %@", ([self isWrap]? @"YES" : @"NO"));
	NSLog(@"atTop: %@", ([self isStartFromTop]? @"YES" : @"NO"));
#endif
    
    //[self avoidEmptySelection];
    
    OgreTextFindResult *result = [[self textFinder] replaceAll:[findTextView string]
                                          withAttributedString:[replaceTextView textStorage]
                                                       options:[self options]
                                                   inSelection:[self inSelectionScopeOption]];
		
	if ([result alertIfErrorOccurred]) return;  // error
	if (![result isSuccess]) NSBeep();
}

- (BOOL)didEndReplaceAll:(id)anObject
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-didEndReplaceAll: of %@", [self className]);
#endif
	BOOL	closeProgressWindow;
	OgreTextFindResult	*textFindResult = (OgreTextFindResult *)anObject;
	
	if ([textFindResult alertIfErrorOccurred]) {
		// error
		closeProgressWindow = NO;
	} else {
		// success or failure
        //NSLog(@"didEndReplaceAll: %lu", (unsigned long)[textFindResult numberOfMatches]);
		closeProgressWindow = [self closeWhenDoneOption];
	}
	
	return closeProgressWindow;
}


- (IBAction)highlight:(id)sender
{
	if (_isAlertSheetOpen) {
		NSBeep();
		[self showFindPanel:self];
		return;
	}
	if (![self alertIfInvalidRegex]) return;
	
	[self addFindHistory:[findTextView textStorage]];
	//[self avoidEmptySelection];
	OgreTextFindResult	*result = [[self textFinder] hightlight:[findTextView string] 
		color: [highlightColorWell color] 
		options: [self options] 
		inSelection: [self inSelectionScopeOption]];
	
	if ([result alertIfErrorOccurred]) return;  // error
	if (![result isSuccess]) NSBeep();
}

- (BOOL)didEndHighlight:(id)anObject
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-didEndHighlight: of %@", [self className]);
#endif
	BOOL	closeProgressWindow;
	OgreTextFindResult	*textFindResult = (OgreTextFindResult *)anObject;
	
	if ([textFindResult alertIfErrorOccurred]) {
		// error
		closeProgressWindow = NO;
	} else {
		// success or failure
        //NSLog(@"didEndHighlight: %lu", (unsigned long)[textFindResult numberOfMatches]);
		closeProgressWindow =  [self closeWhenDoneOption];
	}
	
	return closeProgressWindow;
}

- (IBAction)unhighlight:(id)sender
{
	OgreTextFindResult	*result = [[self textFinder] unhightlight];
	
	if (![result alertIfErrorOccurred]) {
		if (![result isSuccess]) NSBeep();
	}
}

- (IBAction)findAll:(id)sender
{
	if (_isAlertSheetOpen) {
		NSBeep();
		[self showFindPanel:self];
		return;
	}
	if (![self alertIfInvalidRegex]) return;
	
	[self addFindHistory:[findTextView textStorage]];
	
	//[self avoidEmptySelection];
	OgreTextFindResult	*result = [[self textFinder] findAll:[findTextView string]  
		color: [highlightColorWell color] 
		options: [self options] 
		inSelection: [self inSelectionScopeOption]];
		
	if ([result alertIfErrorOccurred]) return;  // error
	if (![result isSuccess]) NSBeep();
}

- (BOOL)didEndFindAll:(id)anObject
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-didEndFindAll: of %@", [self className]);
#endif
	
	BOOL	closeProgressWindow = YES;	// Close always If you can find (発見できた場合は常に閉じる)
	OgreTextFindResult	*textFindResult = (OgreTextFindResult *)anObject;
	
	if ([textFindResult alertIfErrorOccurred]) {
		// error
		closeProgressWindow = NO;
	} else {
		if ([textFindResult isSuccess]) {
			// success
			[textFindResult setMaximumLeftMargin:OgreAFPCMaximumLeftMargin];  // The maximum number of characters in the search results left (検索結果の左側の最大文字数)
			[textFindResult setMaximumMatchedStringLength:OgreAFPCMaximumMatchedStringLength];  // The maximum number of characters in search results (検索結果の最大文字数)
			if (_findResultWindowController == nil) {
				_findResultWindowController = [[OgreFindResultWindowController alloc] initWithTextFindResult:textFindResult liveUpdate:NO];
				NSWindow	*findResultWindow = [_findResultWindowController window];
				NSRect		frame = [findResultWindow frame];
				frame.origin.x = [findPanel frame].origin.x;
				frame.origin.y = [findPanel frame].origin.y - frame.size.height;
				frame.size.width = [findPanel frame].size.width;
				[findResultWindow setFrame:frame display:NO animate:NO];
				[findPanel addChildWindow:findResultWindow ordered:NSWindowAbove];
            } else {
				[_findResultWindowController setTextFindResult:textFindResult];
			}
			
			[self showFindPanel:self];
            [_findResultWindowController show];
		} else {
			// failure
			closeProgressWindow = [self closeWhenDoneOption];
		}
	}
	
	return closeProgressWindow;
}

- (IBAction)findSelectedText:(id)sender
{
	[self useSelectionForFind:self];
	[self findNext:self];
}

- (IBAction)jumpToSelection:(id)sender
{
	if (![self.textFinder jumpToSelection]) NSBeep();
}

- (IBAction)useSelectionForFind:(id)sender
{
	if (_isAlertSheetOpen) {
		NSBeep();
		[self showFindPanel:self];
		return;
	}
	
	NSAttributedString	*selectedAttrString = [self.textFinder selectedAttributedString];
	if (selectedAttrString != nil) {
		[[findTextView textStorage] setAttributedString:selectedAttrString];
		//if (sender != self) [self showFindPanel:sender];
	} else {
		NSBeep();
	}
}

- (IBAction)useSelectionForReplace:(id)sender
{
	if (_isAlertSheetOpen) {
		NSBeep();
		[self showFindPanel:self];
		return;
	}
	
	NSAttributedString	*selectedAttrString = [self.textFinder selectedAttributedString];
	if (selectedAttrString != nil) {
		[[replaceTextView textStorage] setAttributedString:selectedAttrString];
		//if (sender != self) [self showFindPanel:sender];
	} else {
		NSBeep();
	}
}

- (IBAction)clearFindStringStyles:(id)sender
{
	NSString			*string = [findTextView string];
	NSAttributedString	*newString = [[NSAttributedString alloc] initWithString:string];
	if ([string length] == 0) {
		[[findTextView textStorage] replaceCharactersInRange:NSMakeRange(0, 0) withString:@" "];
		[[findTextView textStorage] replaceCharactersInRange:NSMakeRange(0, 1) withAttributedString:newString];
	} else {
		[self setFindString:newString];
	}
}

- (IBAction)clearReplaceStringStyles:(id)sender
{
	NSString			*string = [replaceTextView string];
	NSAttributedString	*newString = [[NSAttributedString alloc] initWithString:string];
	if ([string length] == 0) {
		[[replaceTextView textStorage] replaceCharactersInRange:NSMakeRange(0, 0) withString:@" "];
		[[replaceTextView textStorage] replaceCharactersInRange:NSMakeRange(0, 1) withAttributedString:newString];
	} else {
		[self setReplaceString:newString];
	}
}


/* delegate method of drawers */
- (void)drawerWillClose:(NSNotification *)notification
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-drawerDidClose: of %@", [self className]);
#endif
	id	sender = [notification object];
	if (sender == moreOptionsDrawer) {
		[moreOptionsButton setTitle:OgreAPFCLocalizedString(@"More Options")];
	}
}

- (void)drawerWillOpen:(NSNotification *)notification
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-drawerWillOpen: of %@", [self className]);
#endif
	id	sender = [notification object];
	if (sender == moreOptionsDrawer) {
		[moreOptionsButton setTitle:OgreAPFCLocalizedString(@"Less Options")];
	}
}

/* load find string from/to pasteboard */
- (void)loadFindStringFromPasteboard
{
	NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
	NSString *findString = [pasteboard stringForType:NSStringPboardType];
	if ((findString != nil) && ([findString length] > 0)) [findTextView setString:findString];
}

- (void)loadFindStringToPasteboard
{
	NSString *findString = [findTextView string];
	if ((findString != nil) && ([findString length] > 0)) {
		NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
		[pasteboard declareTypes:@[NSStringPboardType] owner:nil];
		[pasteboard setString:findString forType:NSStringPboardType];
	}
}

/* delegate method of OgreAdvancedFindPanel */
- (void)findPanelFlagsChanged:(NSEventModifierFlags)modifierFlags
{
    if ((modifierFlags & NSAlternateKeyMask) != 0) {
        // alt key pressed
        if (!_altKeyDown) {
            _altKeyDown = YES;
            _tmpInSelection = [self inSelectionScopeOption];
            [self setInSelectionScopeOption:YES];
        }
    } else {
        // alt key released
        if (_altKeyDown) {
            _altKeyDown = NO;
            [self setInSelectionScopeOption:_tmpInSelection];
        }
    }
}

- (void)findPanelDidAddChildWindow:(NSWindow *)childWindow
{
	_findResultWindowController = (OgreFindResultWindowController *)[childWindow delegate];
}

- (void)findPanelDidRemoveChildWindow:(NSWindow *)childWindow
{
	_findResultWindowController = nil;
}


/* accessors */
@synthesize singleLineOption;
@synthesize multilineOption;
@synthesize ignoreCaseOption;
@synthesize extendOption;
@synthesize findLongestOption;
@synthesize findNotEmptyOption;
@synthesize findEmptyOption;
@synthesize negateSingleLineOption;
@synthesize captureGroupOption;
@synthesize dontCaptureGroupOption;
@synthesize delimitByWhitespaceOption;
@synthesize notBeginOfLineOption;
@synthesize notEndOfLineOption;
@synthesize replaceWithStylesOption;
@synthesize replaceFontsOption;
@synthesize mergeStylesOption;
@synthesize regularExpressionsOption;
@synthesize wrapSearchOption;
@synthesize openSheetOption;
@synthesize closeWhenDoneOption;
@synthesize atTopOriginOption;
@synthesize inSelectionScopeOption;

/* delegate methods of findTextView/replaceTextView */
- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
	// \ To unify if there is a need to unify and ¥. (＼と￥を統一する必要がある場合は統一する。)
	NSString   *convertedString = [_escapeCharacterFormatter stringForObjectValue:replacementString];
	if ([replacementString isEqualToString:convertedString] || (convertedString == nil)) {
		// No change (変更なし)
		return YES;
	} else {
		// \ And unified the ¥ (＼と￥を統一)
		if ([aTextView allowsUndo]) {	// yet buggy
			NSUndoManager	*undoManager = [aTextView undoManager];
			NSRange			newRange = NSMakeRange(affectedCharRange.location, [convertedString length]);
			[[undoManager prepareWithInvocationTarget:self] 
				undoableReplaceCharactersInRange:newRange 
				withAttributedString:[[NSAttributedString alloc] initWithAttributedString:[[aTextView textStorage] attributedSubstringFromRange:affectedCharRange]] 
				inTarget:aTextView];
		}
		[aTextView replaceCharactersInRange:affectedCharRange withString:convertedString];
		return NO;
	}
}

- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)aSelector
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-textView:doCommandBySelector:%@", NSStringFromSelector(aSelector));
#endif
	
	if (aSelector == @selector(insertNewline:)) {
		[findNextButton setAction:@selector(findNextAndOrderOut:)];
		[findNextButton performClick:self]; // Find Next
		[findNextButton setAction:@selector(findNext:)];
		//[self findNextAndOrderOut:self];
		return YES;
	}
	
	if (aSelector == @selector(insertTab:)) {
		[findPanel makeFirstResponder:[textView nextKeyView]];
		return YES;
	}
	
	return NO;
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
    [self findPanelFlagsChanged:0]; // release key
}


@end
