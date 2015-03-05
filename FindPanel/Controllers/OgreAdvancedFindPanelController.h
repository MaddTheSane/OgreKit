/*
 * Name: OgreAdvancedFindPanelController.h
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

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreTextFinder.h>
#import <OgreKit/OgreFindPanelController.h>
#import <OgreKit/OgreTextFindThread.h>

@class OgreAFPCEscapeCharacterFormatter, OgreFindResultWindowController;

@interface OgreAdvancedFindPanelController : OgreFindPanelController 
{
	IBOutlet NSTextView		*findTextView;
	IBOutlet NSTextView		*replaceTextView;

	IBOutlet NSDrawer		*moreOptionsDrawer;
	IBOutlet NSPopUpButton	*escapeCharacterPopUpButton;
	IBOutlet NSPopUpButton	*syntaxPopUpButton;
	IBOutlet NSColorWell	*highlightColorWell;
	IBOutlet NSTextField	*maxNumOfFindHistoryTextField;
	IBOutlet NSTextField	*maxNumOfReplaceHistoryTextField;
	
	IBOutlet NSView			*findReplaceTextBox;
	IBOutlet NSView			*styleOptionsBox;
	IBOutlet NSButton		*toggleStyleOptionsButton;
	
	NSMutableArray			*_findHistory;
	NSMutableArray			*_replaceHistory;
	IBOutlet NSPopUpButton	*findPopUpButton;
	IBOutlet NSPopUpButton	*replacePopUpButton;
	
	BOOL					singleLineOption;
	BOOL					multilineOption;
	BOOL					ignoreCaseOption;
	BOOL					extendOption;
	BOOL					findLongestOption;
	BOOL					findNotEmptyOption;
	BOOL					findEmptyOption;
	BOOL					negateSingleLineOption;
	BOOL					captureGroupOption;
	BOOL					dontCaptureGroupOption;
	BOOL					delimitByWhitespaceOption;
	BOOL					notBeginOfLineOption;
	BOOL					notEndOfLineOption;
	BOOL					replaceWithStylesOption;
	BOOL					replaceFontsOption;
	BOOL					mergeStylesOption;
	
	BOOL					regularExpressionsOption;
	
	BOOL					wrapSearchOption;
	
	BOOL					openSheetOption;
	BOOL					closeWhenDoneOption;
	
	BOOL					atTopOriginOption;
	BOOL					inSelectionScopeOption;
	
	BOOL					_isAlertSheetOpen;
	
	OgreAFPCEscapeCharacterFormatter	*_escapeCharacterFormatter;
	
	IBOutlet NSButton		*findNextButton;
	IBOutlet NSButton		*moreOptionsButton;
	
	OgreFindResultWindowController	*_findResultWindowController;
	
	BOOL					_altKeyDown;
	BOOL					_tmpInSelection;
}

/* find/replace/highlight actions */
- (IBAction)findAll:(id)sender;

- (IBAction)findNext:(id)sender;
- (IBAction)findNextAndOrderOut:(id)sender;
- (OgreTextFindResult*)findNextStrategy;

- (IBAction)findPrevious:(id)sender;
- (IBAction)findSelectedText:(id)sender;
- (IBAction)highlight:(id)sender;
- (IBAction)jumpToSelection:(id)sender;
- (IBAction)replace:(id)sender;
- (IBAction)replaceAll:(id)sender;
- (IBAction)replaceAndFind:(id)sender;
- (IBAction)unhighlight:(id)sender;
- (IBAction)useSelectionForFind:(id)sender;
- (IBAction)useSelectionForReplace:(id)sender;

- (IBAction)clearFindStringStyles:(id)sender;
- (IBAction)clearReplaceStringStyles:(id)sender;

/* update settings */
- (IBAction)updateEscapeCharacter:(id)sender;
- (IBAction)updateOptions:(id)sender;
- (IBAction)updateSyntax:(id)sender;
- (void)avoidEmptySelection;
- (void)setStartFromCursor;
- (IBAction)toggleStyleOptions:(id)sender;

/* delegate methods of OgreAdvancedFindPanel */
- (void)findPanelFlagsChanged:(NSEventModifierFlags)modifierFlags;
- (void)findPanelDidAddChildWindow:(NSWindow*)childWindow;
- (void)findPanelDidRemoveChildWindow:(NSWindow*)childWindow;

/* settings */
- (NSString*)escapeCharacter;
- (BOOL)shouldEquateYenWithBackslash;
@property (readonly, getter=isStartFromTop) BOOL startFromTop;
@property (readonly, getter=isWrap) BOOL wrap;
- (OgreOption)options;
- (OgreOption)_options;
- (OgreSyntax)syntax;

/* find/replace history */
- (void)addFindHistory:(NSAttributedString*)string;
- (void)addReplaceHistory:(NSAttributedString*)string;
- (IBAction)clearFindReplaceHistories:(id)sender;
- (IBAction)selectFindHistory:(id)sender;
- (IBAction)selectReplaceHistory:(id)sender;

- (void)setFindString:(NSAttributedString*)attrString;
- (void)setReplaceString:(NSAttributedString*)attrString;
- (void)undoableReplaceCharactersInRange:(NSRange)oldRange 
	withAttributedString:(NSAttributedString*)newString 
	inTarget:(NSTextView*)aTextView;

/* restore history/settings */
- (void)restoreHistory:(NSDictionary*)history;

/* show alert */
- (BOOL)alertIfInvalidRegex;
- (void)showErrorAlert:(NSString*)title message:(NSString*)message;

/* load find string to/from pasteboard */
- (void)loadFindStringFromPasteboard;
- (void)loadFindStringToPasteboard;

/* accessors */
@property BOOL singleLineOption;
@property BOOL multilineOption;
@property BOOL ignoreCaseOption;
@property BOOL extendOption;
@property BOOL findLongestOption;
@property BOOL findNotEmptyOption;
@property BOOL findEmptyOption;
@property BOOL negateSingleLineOption;
@property BOOL captureGroupOption;
@property BOOL dontCaptureGroupOption;
@property BOOL delimitByWhitespaceOption;
@property BOOL notBeginOfLineOption;
@property BOOL notEndOfLineOption;
@property BOOL replaceWithStylesOption;
@property BOOL replaceFontsOption;
@property BOOL mergeStylesOption;

@property BOOL regularExpressionsOption;

@property BOOL wrapSearchOption;

@property BOOL openSheetOption;
@property BOOL closeWhenDoneOption;

@property BOOL atTopOriginOption;
@property BOOL inSelectionScopeOption;

@end
