/*
 * Name: MyFindPanelController.m
 * Project: OgreKit
 *
 * Creation Date: Nov 21 2003
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import "MyFindPanelController.h"

// Key to be used in the history of the encode/decode (履歴のencode/decodeに使用するKey)
static NSString	*MyFindHistoryKey    = @"Find History";
static NSString	*MyReplaceHistoryKey = @"Replace History";
static NSString	*MyOptionsKey		 = @"Options";
static NSString	*MySyntaxKey         = @"Syntax";
static NSString	*MyEntireScopeKey    = @"Entire Scope";

@implementation MyFindPanelController

- (void)awakeFromNib
{
	[super awakeFromNib];	// Required (必須)
	
	// Initial value (初期値)
	[[self textFinder] setEscapeCharacter: OgreBackslashCharacter];
	_findHistory = [[NSString alloc] init];
	_replaceHistory = [[NSString alloc] init];
	
	// Return of history (履歴の復帰)
	[self restoreHistory:[self.textFinder history]];
}


- (OgreOption)options
{
	OgreOption	options = OgreNoneOption;
	if ([optionIgnoreCase state] == NSOnState) options |= OgreIgnoreCaseOption;
	
	return options;
}

- (OgreSyntax)syntax
{
	if ([optionRegex state] == NSOnState) return OgreRubySyntax;
	
	return OgreSimpleMatchingSyntax;
}

- (BOOL)isEntire
{
	if ([[scopeMatrix cellAtRow:0 column:0] state] == NSOnState) return YES;
	
	return NO;
}


// actions
- (IBAction)findNext:(id)sender
{
	if (![self alertIfInvalidRegex]) return;	// Determine whether the appropriate regular expression. (適切な正規表現かどうか判定する。)
	_findHistory = [findTextField stringValue];
	
	[[self textFinder] setSyntax:[self syntax]];
	OgreTextFindResult	*result = [[self textFinder] find: _findHistory 
		options: [self options]	
		fromTop: NO
		forward: YES
		wrap: YES];

	if (![result isSuccess]) NSBeep();   // If you do not match (マッチしなかった場合)
}

- (IBAction)findPrevious:(id)sender
{
	if (![self alertIfInvalidRegex]) return;
	_findHistory = [findTextField stringValue];
	
	[[self textFinder] setSyntax:[self syntax]];
	OgreTextFindResult	*result = [[self textFinder] find: _findHistory 
		options: [self options] 
		fromTop: NO
		forward: NO
		wrap: YES];
		
	if (![result isSuccess]) NSBeep();   // If you do not match (マッチしなかった場合)
}

- (IBAction)replace:(id)sender
{
	if (![self alertIfInvalidRegex]) return;
	_findHistory = [findTextField stringValue];
	_replaceHistory = [replaceTextField stringValue];
	
	[[self textFinder] setSyntax:[self syntax]];
	OgreTextFindResult	*result = [[self textFinder] replace: _findHistory 
			withString: _replaceHistory 
			options: [self options]];
			
	if (![result isSuccess]) NSBeep();   // If you do not match (マッチしなかった場合)
}

- (IBAction)replaceAll:(id)sender
{
	if (![self alertIfInvalidRegex]) return;
	_findHistory = [findTextField stringValue];
	_replaceHistory = [replaceTextField stringValue];
		
	[[self textFinder] setSyntax:[self syntax]];
	OgreTextFindResult	*result = [[self textFinder] replaceAll: _findHistory 
		withString: _replaceHistory
		options: [self options] 
		inSelection: ![self isEntire]];
		
	if (![result isSuccess]) NSBeep();   // If you do not match (マッチしなかった場合)
}

- (BOOL)didEndReplaceAll:(id)anObject
{
	return NO;	// It is not automatically close the sheet when you are finished. (終了したら自動的にシートを閉じない。)
}

- (IBAction)replaceAndFind:(id)sender
{
	if (![self alertIfInvalidRegex]) return;
	_findHistory = [findTextField stringValue];
	_replaceHistory = [replaceTextField stringValue];
	
	[[self textFinder] setSyntax:[self syntax]];
	OgreTextFindResult	*result;
	result = [[self textFinder] replaceAndFind: _findHistory 
			withString: _replaceHistory 
			options: [self options]
            replacingOnly:NO 
            wrap:YES]; 
	
	if (![result isSuccess]) NSBeep();   // If you do not match (マッチしなかった場合)
}

- (IBAction)jumpToSelection:(id)sender
{
	if (![self.textFinder jumpToSelection]) NSBeep();
}

- (IBAction)useSelectionForFind:(id)sender
{
	NSString	*selectedString = [self.textFinder selectedString];
	if (selectedString != nil) {
		[findTextField setStringValue:selectedString];
		if (sender != self) [self showFindPanel:sender];
	} else {
		NSBeep();
	}
}

// I examine whether appropriate regular expression (適切な正規表現かどうか調べる)
- (BOOL)alertIfInvalidRegex
{
	@try {
		[OGRegularExpression regularExpressionWithString: [findTextField stringValue] 
			options: [self options] 
			syntax: [self syntax] 
			escapeCharacter: OgreBackslashCharacter];
	} @catch (NSException *localException) {
		// Exception handling (例外処理)
		if ([[localException name] isEqualToString:OgreException]) {
			NSBeep();   // If it was inappropriate regular expression (very shoddy) (不適切な正規表現だった場合 (非常に手抜き))
		} else {
			[localException raise];
		}
		return NO;
	}
	
	return YES;
}

// Save of history (contrary to [textFinder history]) (// 履歴の保存 (逆は[textFinder history]))
- (NSDictionary *)history
{
	return @{MyFindHistoryKey: _findHistory, 
			MyReplaceHistoryKey: _replaceHistory, 
			MyOptionsKey: @([self options]), 
			MySyntaxKey: @([OGRegularExpression intValueForSyntax:[self syntax]]), 
			MyEntireScopeKey: @([self isEntire])};
}

// Return of history (履歴の復帰)
- (void)restoreHistory:(NSDictionary *)history
{
	if (history == nil) return;
	
	id  anObject;
	anObject = history[MyFindHistoryKey];
	if (anObject != nil) {
		_findHistory = anObject;
		[findTextField setStringValue:_findHistory];
	}
	
	anObject = history[MyReplaceHistoryKey];
	if (anObject != nil) {
		_replaceHistory = anObject;
		[replaceTextField setStringValue:_replaceHistory];
	}
	
	anObject = history[MyOptionsKey];
	if (anObject != nil) {
		OgreOption	options = [anObject unsignedIntValue];
		[optionIgnoreCase setState:((options & OgreIgnoreCaseOption)? NSOnState : NSOffState)];
	}
	
	anObject = history[MySyntaxKey];
	if (anObject != nil) {
		NSInteger	syntax = [anObject integerValue];
		[optionRegex setState:((syntax != [OGRegularExpression intValueForSyntax:OgreSimpleMatchingSyntax])? NSOnState : NSOffState)];
	}
	
	anObject = history[MyEntireScopeKey];
	if (anObject != nil) {
		[[scopeMatrix cellAtRow:0 column:0] setState:NSOffState];
		[[scopeMatrix cellAtRow:0 column:1] setState:NSOffState];
		
		if ([anObject boolValue]) {
			// In the case of entire scope (entire scopeの場合)
			[[scopeMatrix cellAtRow:0 column:0] setState:NSOnState];
		} else {
			// In the case of selection scope (selection scopeの場合)
			[[scopeMatrix cellAtRow:0 column:1] setState:NSOnState];
		}
	}
}

@end
