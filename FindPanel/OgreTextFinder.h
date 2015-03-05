/*
 * Name: OgreTextFinder.h
 * Project: OgreKit
 *
 * Creation Date: Sep 20 2003
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
#import <OgreKit/OGString.h>

// Localization of using OgreTextFinderLocalizable.strings (OgreTextFinderLocalizable.stringsを使用したローカライズ)
#define OgreTextFinderLocalizedString(key)	[[OgreTextFinder ogreKitBundle] localizedStringForKey:(key) value:(key) table:@"OgreTextFinderLocalizable"]

@class OgreTextFinder, OgreFindPanelController, OgreTextFindResult, OgreTextFindThread, OgreTextFindProgressSheet;

@protocol OgreTextFindDataSource <NSObject>
/* OgreTextFinderが検索対象を知りたいときにresponder chain経由で呼ばれる 
   document windowのdelegateがimplementすることを想定している */
- (void)tellMeTargetToFindIn:(id)sender;
@end

@interface OgreTextFinder : NSObject 
{
	IBOutlet OgreFindPanelController	*findPanelController;	// FindPanelController
    IBOutlet NSMenu						*findMenu;				// Find manu
	
	OgreSyntax		_syntax;				// Regular expression syntax (正規表現の構文)
	NSString		*_escapeCharacter;		// Escape character (エスケープ文字)
	
	id				_targetToFindIn;		// Search for (検索対象)
	Class			_adapterClassForTarget; // Search for adapter (wrapper) (検索対象のアダプタ(ラッパー))
	NSMutableArray	*_busyTargetArray;		// In use target (使用中ターゲット)

	NSDictionary	*_history;				// Search history, etc. (検索履歴等)
	BOOL			_saved;					// Whether history, etc. has been saved (履歴等が保存されたかどうか)
	BOOL			_shouldHackFindMenu;	// And whether to replace the Find menu to those of OgreKit (FindメニューをOgreKitのものに置き換えるかどうか)
	BOOL			_useStylesInFindPanel;	// Whether or not to use the Style in the search panel. (検索パネルでStyleを使用するかどうか。)
    
    NSMutableArray  *_targetClassArray,     // Sequences were met with searchable class (検索可能なクラスを収めた配列)
                    *_adapterClassArray;    // Sequences were met with adapter class to search for class (検索対象クラスのアダプタクラスを収めた配列)
}

/* OgreKit.framework bundle */
+ (NSBundle*)ogreKitBundle;

/* Shared instance */
+ (OgreTextFinder*)sharedTextFinder;

/* nib name of Find Panel/Find Panel Controller */
@property (nonatomic, readonly, copy) NSString *findPanelNibName;

/* Show Find Panel */
- (IBAction)showFindPanel:(id)sender;

/* Startup time configurations */
- (void)setShouldHackFindMenu:(BOOL)hack;
@property (nonatomic) BOOL useStylesInFindPanel;

/*************
 * Accessors *
 *************/
// target to find in
@property (nonatomic, strong) id targetToFindIn;

@property (nonatomic, strong) Class adapterClassForTargetToFindIn;

// Find Panel Controller
@property (nonatomic, strong) OgreFindPanelController *findPanelController;

// escape character
@property (nonatomic, copy) NSString *escapeCharacter;

// syntax
@property (nonatomic) OgreSyntax syntax;

/* Find/Replace/Highlight... */
- (OgreTextFindResult*)find:(NSString*)expressionString 
	options:(OgreOption)options
	fromTop:(BOOL)isTop
	forward:(BOOL)forward
	wrap:(BOOL)isWrap;

- (OgreTextFindResult*)findAll:(NSString*)expressionString 
	color:(NSColor*)highlightColor 
	options:(OgreOption)options
	inSelection:(BOOL)inSelection;

- (OgreTextFindResult*)replace:(NSString*)expressionString 
	withString:(NSString*)replaceString
	options:(OgreOption)options;
- (OgreTextFindResult*)replace:(NSString*)expressionString 
	withAttributedString:(NSAttributedString*)replaceString
	options:(OgreOption)options;
- (OgreTextFindResult*)replace:(id<OGStringProtocol>)expressionString 
	withOGString:(id<OGStringProtocol>)replaceString
	options:(OgreOption)options;

- (OgreTextFindResult*)replaceAndFind:(NSString*)expressionString 
	withString:(NSString*)replaceString
	options:(OgreOption)options 
    replacingOnly:(BOOL)replacingOnly
	wrap:(BOOL)isWrap;
- (OgreTextFindResult*)replaceAndFind:(NSString*)expressionString 
	withAttributedString:(NSAttributedString*)replaceString
	options:(OgreOption)options
    replacingOnly:(BOOL)replacingOnly 
	wrap:(BOOL)isWrap;
- (OgreTextFindResult*)replaceAndFind:(id<OGStringProtocol>)expressionString 
	withOGString:(id<OGStringProtocol>)replaceString
	options:(OgreOption)options 
    replacingOnly:(BOOL)replacingOnly
	wrap:(BOOL)isWrap;

- (OgreTextFindResult*)replaceAll:(NSString*)expressionString 
	withString:(NSString*)replaceString
	options:(OgreOption)options
	inSelection:(BOOL)inSelection;
- (OgreTextFindResult*)replaceAll:(NSString*)expressionString 
	withAttributedString:(NSAttributedString*)replaceString
	options:(OgreOption)options
	inSelection:(BOOL)inSelection;
- (OgreTextFindResult*)replaceAll:(id<OGStringProtocol>)expressionString 
	withOGString:(id<OGStringProtocol>)replaceString
	options:(OgreOption)options
	inSelection:(BOOL)inSelection;

- (OgreTextFindResult*)hightlight:(NSString*)expressionString 
	color:(NSColor*)highlightColor 
	options:(OgreOption)options
	inSelection:(BOOL)inSelection;

@property (nonatomic, readonly, strong) OgreTextFindResult *unhightlight;

@property (nonatomic, readonly, copy) NSString *selectedString;
@property (nonatomic, readonly, copy) NSAttributedString *selectedAttributedString;
@property (nonatomic, readonly, strong) id<OGStringProtocol> selectedOGString;

@property (nonatomic, getter=isSelectionEmpty, readonly) BOOL selectionEmpty;

@property (nonatomic, readonly) BOOL jumpToSelection;

/* creating an alert sheet */
- (OgreTextFindProgressSheet*)alertSheetOnTarget:(id)aTerget;

/* Getting and registering adapters for targets */
- (id)adapterForTarget:(id)aTargetToFindIn;
- (void)registeringAdapterClass:(Class)anAdapterClass forTargetClass:(Class)aTargetClass;
- (BOOL)hasAdapterClassForObject:(id)anObject;

/*******************
 * Private Methods *
 *******************/
// Last saved history (前回保存された履歴)
@property (nonatomic, readonly, copy) NSDictionary *history;
// name the current to the starting point to look for menu item of name. (currentを起点に名前がnameのmenu itemを探す。)
- (NSMenuItem*)findMenuItemNamed:(NSString*)name startAt:(NSMenu*)current;

// If the target is in use (ターゲットが使用中かどうか)
- (BOOL)isBusyTarget:(id)target;
// I want to use in (使用中にする)
- (void)makeTargetBusy:(id)target;
// To not in use (使用中でなくする)
- (void)makeTargetFree:(id)target;

/* hack Find Menu */
- (void)hackFindMenu;

- (void)didEndThread:(OgreTextFindThread*)aTextFindThread;

@end

