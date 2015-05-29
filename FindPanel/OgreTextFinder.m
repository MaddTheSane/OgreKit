/*
 * Name: OgreTextFinder.m
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

#import <OgreKit/OgreTextFinder.h>

/* Foundation */
#import <OgreKit/OGReplaceExpression.h>
#import <OgreKit/OGRegularExpressionMatch.h>
#import <OgreKit/OGPlainString.h>
#import <OgreKit/OGAttributedString.h>

/* Threads */
#import <OgreKit/OgreTextFindThread.h>
// concrete implementors
#import <OgreKit/OgreFindAllThread.h>
#import <OgreKit/OgreReplaceAllThread.h>
#import <OgreKit/OgreHighlightThread.h>
#import <OgreKit/OgreUnhighlightThread.h>
#import <OgreKit/OgreFindThread.h>
#import <OgreKit/OgreReplaceAndFindThread.h>

/* Adapters */
#import <OgreKit/OgreTextFindComponent.h>
#import <OgreKit/OgreTextFindLeaf.h>
#import <OgreKit/OgreTextFindBranch.h>
// concrete implementors
// TextView
#import <OgreKit/OgreTextViewAdapter.h>
// TableView
#import <OgreKit/OgreTableViewAdapter.h>
// OutlineView
#import <OgreKit/OgreOutlineViewAdapter.h>

/* Views */
#import <OgreKit/OgreView.h>

/* Find Results */
#import <OgreKit/OgreTextFindResult.h>
#import <OgreKit/OgreFindResultLeaf.h>
#import <OgreKit/OgreFindResultBranch.h>

/* Controllers */
#import <OgreKit/OgreTextFindProgressSheet.h>
#import <OgreKit/OgreFindPanelController.h>

@interface NSObject (priv)
- (void)ogreKitShouldUseStylesInFindPanel:(OgreTextFinder *)textFinder;
- (void)ogreKitWillHackFindMenu:(OgreTextFinder *)textFinder;

@end

// singleton
static OgreTextFinder *_sharedTextFinder = nil;

// Exception name (例外名)
NSString * const OgreTextFinderException = @"OgreTextFinderException";

// Keys to be used to encode/decode (encode/decodeに使用するKey)
static NSString * const OgreTextFinderHistoryKey         = @"Find Controller History";
static NSString * const OgreTextFinderSyntaxKey          = @"Syntax";
static NSString * const OgreTextFinderEscapeCharacterKey = @"Escape Character";

@implementation OgreTextFinder

+ (NSBundle *)ogreKitBundle
{
    static NSBundle *theBundle = nil;
    
    if (theBundle == nil) {
        /* I Find OgreKit.framework bundle instance (OgreKit.framework bundle instanceを探す) */
        NSArray         *allFrameworks = [NSBundle allFrameworks];  // All framework linked (リンクされている全フレームワーク)
        NSEnumerator    *enumerator = [allFrameworks reverseObjectEnumerator];  // OgreKit should be in here. (OgreKitは後ろにある可能性が高い)
        for (NSBundle *aBundle in enumerator) {
            if ([[[aBundle bundlePath] lastPathComponent] isEqualToString:@"OgreKit.framework"]) {
#ifdef DEBUG_OGRE_FIND_PANEL
                NSLog(@"Found OgreKit: %@", [aBundle bundlePath]);
#endif
                theBundle = aBundle;
                break;
            }
        }
    }
    
    return theBundle;
}

+ (OgreTextFinder *)sharedTextFinder
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedTextFinder = [[[self class] alloc] init];
    });
    
    return _sharedTextFinder;
}

- (instancetype)init
{
#ifdef DEBUG_OGRE_FIND_PANEL
    NSLog(@"-init of %@", [self className]);
#endif
    if (_sharedTextFinder != nil) {
        return _sharedTextFinder;
    }
    
    self = [super init];
    if (self != nil) {
        _busyTargetSet = [[NSMutableSet alloc] initWithCapacity:0]; // In use target (使用中ターゲット)
        
        NSUserDefaults  *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary    *fullHistory = [defaults dictionaryForKey:@"OgreTextFinder"];   // History, etc. (履歴等)
        
        if (fullHistory != nil) {
            _history = fullHistory[OgreTextFinderHistoryKey];
            
            id anObject = fullHistory[OgreTextFinderSyntaxKey];
            if (anObject == nil) {
                [self setSyntax:[OGRegularExpression defaultSyntax]];
            }
            else {
                _syntax = [OGRegularExpression syntaxForIntValue:[anObject intValue]];
            }
            
            _escapeCharacter = fullHistory[OgreTextFinderEscapeCharacterKey];
            if (_escapeCharacter == nil) {
                [self setEscapeCharacter:[OGRegularExpression defaultEscapeCharacter]];
            }
        }
        else {
            _history = nil;
            [self setSyntax:[OGRegularExpression defaultSyntax]];
            [self setEscapeCharacter:[OGRegularExpression defaultEscapeCharacter]];
        }
        
        _saved = NO;
        // Pick up the termination of the Application (time for history preservation) (Applicationのterminationを拾う (履歴保存のタイミング))
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appWillTerminate:)
                                                     name:NSApplicationWillTerminateNotification
                                                   object:NSApp];
        // Pick up the launch of the Application (the timing of the setting of the Find menu) (Applicationのlaunchを拾う (Findメニューの設定のタイミング))
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appDidFinishLaunching:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:NSApp];
        
        NSArray *topLevelObjects;
        BOOL didLoad =
        [[NSBundle bundleForClass:[self class]] loadNibNamed:[self findPanelNibName]
                                                       owner:self
                                             topLevelObjects:&topLevelObjects];
        if (didLoad) {
            _findPanelTopLevelObjects = topLevelObjects;
        }
        else {
            NSLog(@"Failed to load nib in %@", [self description]);
            return nil;
        }
        
        _sharedTextFinder = self;
        _shouldHackFindMenu = YES;
        _useStylesInFindPanel = YES;
        
        /* registering adapters for targets */
        _adapterClassArray = [[NSMutableArray alloc] initWithCapacity:1];
        _targetClassArray = [[NSMutableArray alloc] initWithCapacity:1];
        // NSTextView
        [self registeringAdapterClass:[OgreTextViewAdapter class] forTargetClass:[NSTextView class]];
    }
    
    return self;
}

- (void)setShouldHackFindMenu:(BOOL)hack
{
    _shouldHackFindMenu = hack;
}

- (void)setUseStylesInFindPanel:(BOOL)use
{
    _useStylesInFindPanel = use;
}

- (BOOL)useStylesInFindPanel
{
    return _useStylesInFindPanel;
}

- (void)appDidFinishLaunching:(NSNotification *)aNotification
{
#ifdef DEBUG_OGRE_FIND_PANEL
    NSLog(@"-appDidFinishLaunching: of %@", [self className]);
#endif
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSApplicationDidFinishLaunchingNotification
                                                  object:NSApp];
    
    /* send 'ogreKitWillHackFindMenu:' message to the responder chain */
    [NSApp sendAction:@selector(ogreKitWillHackFindMenu:) to:nil from:self];
    /*
        if you don't want to use OgreKit's Find Panel,
        implement the following method in the subclass or delegate of NSApplication.
        - (void)ogreKitWillHackFindMenu:(OgreTextFinder*)textFinder
        {
            [textFinder setShouldHackFindMenu:NO];
        }
     */
    
    /* send 'ogreKitShouldUseStylesInFindPanel:' message to the responder chain */
    [NSApp sendAction:@selector(ogreKitShouldUseStylesInFindPanel:) to:nil from:self];
    /*
        if you don't want to use "Replace With Styles" in the Find Panel,
        add the following method to the subclass or delegate of NSApplication.
        - (void)ogreKitShouldUseStylesInFindPanel:(OgreTextFinder*)textFinder
        {
            [textFinder setShouldUseStylesInFindPanel:NO];
        }
     */
    
    if (!_shouldHackFindMenu)  return;
    
    /* Checking the Mac OS X version */
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_0) {
        /* On a 10.0.x or earlier system */
        return; // use the default Find Panel
    }
    else if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_1) {
        /* On a 10.1 - 10.1.x system */
        return; // use the default Find Panel
    }
    else if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_2) {
        /* On a 10.2 - 10.2.x system */
        return; // use the default Find Panel
    }
    else {
        /* 10.3 or later system */
        [self hackFindMenu];
    }
}

- (void)hackFindMenu
{
    /* set up Find menu */
    if (findMenu == nil) {
        // When that did not find the Find menu in the findPanelNib (findPanelNibの中にFindメニューが見つからなかったとき)
        NSLog(@"Find Menu not found in %@.nib", [self findPanelNibName]);
    }
    else {
        // The Find menu title (Findメニューのタイトル)
        NSString *titleOfFindMenu = OgreTextFinderLocalizedString(@"Find");
        
        // Initialization of the Find menu (Findメニューの初期化)
        [findMenu setTitle:titleOfFindMenu];
        NSMenuItem  *newFindMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] init];
        [newFindMenuItem setTitle:titleOfFindMenu];
        [newFindMenuItem setSubmenu:findMenu];
        
        NSMenu *mainMenu = [NSApp mainMenu];
        
        NSMenuItem  *oldFindMenuItem = [self findMenuItemNamed:titleOfFindMenu startAt:mainMenu];
        // I swap there findMenu If Find menu is already (Findメニューが既にある場合はそこをfindMenuに入れ替える)
        // Make a Find menu fourth from the left if, there is set a findMenu. (なければ左から4番目にFindメニューを作り、そこにfindMenuをセットする。)
        if (oldFindMenuItem != nil) {
            //NSLog(@"Find found");
            NSMenu *supermenu = [oldFindMenuItem menu];
            [supermenu insertItem:newFindMenuItem atIndex:[supermenu indexOfItem:oldFindMenuItem]];
            [supermenu removeItem:oldFindMenuItem];
        }
        else {
            //NSLog(@"Find not found");
            [mainMenu insertItem:newFindMenuItem atIndex:3];
        }
        [mainMenu update];
    }
}

// name the current to the starting point to look for menu item of name. (currentを起点に名前がnameのmenu itemを探す。)
- (NSMenuItem *)findMenuItemNamed:(NSString *)name startAt:(NSMenu *)current
{
    NSMenuItem  *foundMenuItem = nil;
    if (current == nil)  return nil;
    
    @autoreleasepool {
        NSInteger i, n;
        NSMutableArray *menuArray = [NSMutableArray arrayWithObject:current];
        while ([menuArray count] > 0) {
            NSMenu      *aMenu = menuArray[0];
            NSMenuItem  *aMenuItem = [aMenu itemWithTitle:name];
            if (aMenuItem != nil) {
                // 見つかった場合
                foundMenuItem = aMenuItem;
                break;
            }
            
            // 見つからなかった場合
            n = [aMenu numberOfItems];
            for (i = 0; i < n; i++) {
                aMenuItem = [aMenu itemAtIndex:i];
                //NSLog(@"%@", [aMenuItem title]);
                if ([aMenuItem hasSubmenu]) {
                    [menuArray addObject:[aMenuItem submenu]];
                }
            }
            [menuArray removeObjectAtIndex:0];
        }
    }
    
    return foundMenuItem;
}

- (void)appWillTerminate:(NSNotification *)aNotification
{
#ifdef DEBUG_OGRE_FIND_PANEL
    NSLog(@"-appWillTerminate: of %@", [self className]);
#endif
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSApplicationWillTerminateNotification
                                                  object:NSApp];
    
    // Save Search history, etc. (検索履歴等の保存)
    NSDictionary *fullHistory = @{
                                  OgreTextFinderHistoryKey: [findPanelController history],
                                  OgreTextFinderSyntaxKey: @([OGRegularExpression intValueForSyntax:_syntax]),
                                  OgreTextFinderEscapeCharacterKey: _escapeCharacter
                                  };
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:fullHistory forKey:@"OgreTextFinder"];
    [defaults synchronize];
    
    _saved = YES;
}

- (NSDictionary *)history        // Private method (非公開メソッド)
{
#ifdef DEBUG_OGRE_FIND_PANEL
    NSLog(@"-history of %@", [self className]);
#endif
    NSDictionary *history = _history;
    _history = nil;
    
    return history;
}

- (void)dealloc
{
#ifdef DEBUG_OGRE_FIND_PANEL
    NSLog(@"CAUTION! -dealloc of %@", [self className]);
#endif
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (_saved == NO) {
        [self appWillTerminate:nil];  // Saving history to save if still. (履歴の保存がまだならば保存する。)
    }
    _sharedTextFinder = nil;
}

- (IBAction)showFindPanel:(id)sender
{
    [findPanelController showFindPanel:self];
}

- (NSString *)findPanelNibName
{
    return @"OgreAdvancedFindPanel";
}

/* accessors */

- (void)setFindPanelController:(OgreFindPanelController *)aFindPanelController
{
    findPanelController = aFindPanelController;
}

- (OgreFindPanelController *)findPanelController
{
    return findPanelController;
}

- (void)setEscapeCharacter:(NSString *)character
{
    _escapeCharacter = character;
}

- (NSString *)escapeCharacter
{
    return _escapeCharacter;
}

- (void)setSyntax:(OgreSyntax)syntax
{
    //NSLog(@"%d", [OGRegularExpression intValueForSyntax:syntax]);
    _syntax = syntax;
}

- (OgreSyntax)syntax
{
    return _syntax;
}

/* Search for (検索対象) */
- (void)setTargetToFindIn:(id)target
{
#ifdef DEBUG_OGRE_FIND_PANEL
    NSLog(@"-setTargetToFindIn:\"%@\" of %@", [target className], [self className]);
#endif
    _targetToFindIn = target;
}

- (id)targetToFindIn
{
#ifdef DEBUG_OGRE_FIND_PANEL
    NSLog(@"-targetToFindIn of %@", [self className]);
#endif
    id target = nil;
    [self setTargetToFindIn:nil];
    [self setAdapterClassForTargetToFindIn:Nil];
    
    /* the responder chain tellMeTargetToFindIn: I throw the (responder chainにtellMeTargetToFindIn:を投げる) */
    if ([NSApp sendAction:@selector(tellMeTargetToFindIn:) to:nil from:self]) {
        // tellMeTargetToFindIn: If there is a response to, (tellMeTargetToFindIn:に応答があった場合、)
        //NSLog(@"succeed to perform tellMeTargetToFindIn:");
        if ([self hasAdapterClassForObject:_targetToFindIn]) {
            target = _targetToFindIn;
        }
    }
    else {
        // If there is no response, first responder of main window to adopt it if NSTextView. (応答がない場合、main windowのfirst responderがNSTextViewならばそれを採用する。)
        //NSLog(@"failed to perform tellMeTargetToFindIn:");
        id anObject = [[NSApp mainWindow] firstResponder];
        if ((anObject != nil) && [self hasAdapterClassForObject:anObject]) {
            target = anObject;
        }
    }
    
    return target;
}

- (BOOL)isBusyTarget:(id)target
{
    return [_busyTargetSet containsObject:target];
}

- (void)markTargetBusy:(id)target
{
    if (target != nil) {
        [_busyTargetSet addObject:target];
    }
}

- (void)markTargetFree:(id)target
{
    if (target != nil) {
        [_busyTargetSet removeObject:target];
    }
}

/* Find/Replace/Highlight... */

- (OgreTextFindResult *)find:(NSString *)expressionString
                     options:(OgreOption)options
                     fromTop:(BOOL)isFromTop
                     forward:(BOOL)forward
                        wrap:(BOOL)isWrap
{
    id target = [self targetToFindIn];
    if ((target == nil) || [self isBusyTarget:target]) {
        return [OgreTextFindResult textFindResultWithTarget:target thread:nil];
    }
    [self markTargetBusy:target];
    
    OgreFindThread                  *thread = nil;
    OgreTextFindProgressSheet       *sheet = nil;
    OgreTextFindResult              *textFindResult = nil;
    
    @try {
        OGRegularExpression *regex =
        [OGRegularExpression regularExpressionWithString:expressionString
                                                 options:options
                                                  syntax:[self syntax]
                                         escapeCharacter:[self escapeCharacter]];
        
        /* Generation of thread (スレッドの生成) */
        id adapter = [self adapterForTarget:target];
        thread = [[OgreFindThread alloc] initWithComponent:adapter];
        [thread setRegularExpression:regex];
        [thread setOptions:options];
        [thread setWrap:isWrap];
        [thread setBackward:!forward];
        [thread setFromTop:isFromTop];
        [thread setInSelection:NO];
        [thread setAsynchronous:NO];
        
        [thread detach];
        
        [self markTargetFree:target];
        textFindResult = [thread result];
    }
    @catch (NSException *localException) {
        textFindResult = [OgreTextFindResult textFindResultWithTarget:target thread:thread];
        [textFindResult setType:OgreTextFindResultError];
        [textFindResult setAlertSheet:sheet exception:localException];
    }
    
    return textFindResult;
}

- (OgreTextFindResult *)findAll:(NSString *)expressionString
                          color:(NSColor *)highlightColor
                        options:(OgreOption)options
                    inSelection:(BOOL)inSelection
{
#ifdef DEBUG_OGRE_FIND_PANEL
    NSLog(@"-findAll:... of %@", [self className]);
#endif
    
    id target = [self targetToFindIn];
    if ((target == nil) || [self isBusyTarget:target]) {
        return [OgreTextFindResult textFindResultWithTarget:target thread:nil];
    }
    [self markTargetBusy:target];
    
    OgreTextFindThread              *thread = nil;
    OgreTextFindProgressSheet       *sheet = nil;
    OgreTextFindResult              *textFindResult = nil;
    
    @try {
        OGRegularExpression *regex =
        [OGRegularExpression regularExpressionWithString:expressionString
                                                 options:options
                                                  syntax:[self syntax]
                                         escapeCharacter:[self escapeCharacter]];
        
        /* Generation of processing status display for the seat (処理状況表示用シートの生成) */
        sheet = [[OgreTextFindProgressSheet alloc] initWithWindow:[target window]
                                                            title:OgreTextFinderLocalizedString(@"Find All")
                                                   didEndSelector:@selector(markTargetFree:)
                                                         toTarget:self
                                                       withObject:target];
        
        /* Generation of thread (スレッドの生成) */
        id adapter = [self adapterForTarget:target];
        thread = [[OgreFindAllThread alloc] initWithComponent:adapter];
        [thread setRegularExpression:regex];
        [thread setHighlightColor:highlightColor];
        [thread setOptions:options];
        [thread setInSelection:inSelection];
        [thread setDidEndSelector:@selector(didEndThread:) toTarget:self];
        [thread setProgressDelegate:sheet];
        [thread setAsynchronous:YES];
        
        [thread detach];
        
        textFindResult = [OgreTextFindResult textFindResultWithTarget:target thread:thread];
        [textFindResult setType:OgreTextFindResultSuccess];
    }
    @catch (NSException *localException) {
        textFindResult = [OgreTextFindResult textFindResultWithTarget:target thread:thread];
        [textFindResult setType:OgreTextFindResultError];
        [textFindResult setAlertSheet:sheet exception:localException];
    }
    
    return textFindResult;
}

- (OgreTextFindResult *)replace:(NSString *)expressionString
                     withString:(NSString *)replaceString
                        options:(OgreOption)options
{
    return [self replaceAndFind:expressionString
                     withString:replaceString
                        options:options
                  replacingOnly:YES
                           wrap:NO];
}

- (OgreTextFindResult *)replace:(NSString *)expressionString
           withAttributedString:(NSAttributedString *)replaceString
                        options:(OgreOption)options
{
    return [self replaceAndFind:[OGPlainString stringWithString:expressionString]
                   withOGString:[OGAttributedString stringWithAttributedString:replaceString]
                        options:options
                  replacingOnly:YES
                           wrap:NO];
}

- (OgreTextFindResult *)replace:(id <OGStringProtocol>)expressionString
                   withOGString:(id <OGStringProtocol>)replaceString
                        options:(OgreOption)options
{
    return [self replaceAndFind:expressionString
                   withOGString:replaceString
                        options:options
                  replacingOnly:YES
                           wrap:NO];
}

- (OgreTextFindResult *)replaceAndFind:(NSString *)expressionString
                            withString:(NSString *)replaceString
                               options:(OgreOption)options
                         replacingOnly:(BOOL)replacingOnly
                                  wrap:(BOOL)isWrap
{
    return [self replaceAndFind:[OGPlainString stringWithString:expressionString]
                   withOGString:[OGPlainString stringWithString:replaceString]
                        options:options
                  replacingOnly:replacingOnly
                           wrap:isWrap];
}

- (OgreTextFindResult *)replaceAndFind:(NSString *)expressionString
                  withAttributedString:(NSAttributedString *)replaceString
                               options:(OgreOption)options
                         replacingOnly:(BOOL)replacingOnly
                                  wrap:(BOOL)isWrap
{
    return [self replaceAndFind:[OGPlainString stringWithString:expressionString]
                   withOGString:[OGAttributedString stringWithAttributedString:replaceString]
                        options:options
                  replacingOnly:replacingOnly
                           wrap:isWrap];
}

- (OgreTextFindResult *)replaceAndFind:(id <OGStringProtocol>)expressionString
                          withOGString:(id <OGStringProtocol>)replaceString
                               options:(OgreOption)options
                         replacingOnly:(BOOL)replacingOnly
                                  wrap:(BOOL)isWrap
{
#ifdef DEBUG_OGRE_FIND_PANEL
    NSLog(@"-replaceAndFind:... of %@", [self className]);
#endif
    
    id target = [self targetToFindIn];
    if ((target == nil) || [self isBusyTarget:target] /*|| ![target isEditable]*/) {
        return [OgreTextFindResult textFindResultWithTarget:target thread:nil];
    }
    [self markTargetBusy:target];
    
    OgreReplaceAndFindThread        *thread = nil;
    OgreTextFindProgressSheet       *sheet = nil;
    OgreTextFindResult              *textFindResult = nil;
    
    @try {
        OGRegularExpression *regex =
        [OGRegularExpression regularExpressionWithString:[expressionString string]
                                                 options:options
                                                  syntax:[self syntax]
                                         escapeCharacter:[self escapeCharacter]];
        
        OGReplaceExpression *repex =
        [OGReplaceExpression replaceExpressionWithOGString:replaceString
                                                   options:options
                                                    syntax:[self syntax]
                                           escapeCharacter:[self escapeCharacter]];
        
        // Generation of thread (スレッドの生成)
        id adapter = [self adapterForTarget:target];
        thread = [[OgreReplaceAndFindThread alloc] initWithComponent:adapter];
        [thread setRegularExpression:regex];
        [thread setReplaceExpression:repex];
        [thread setOptions:options];
        [thread setInSelection:NO];
        [thread setAsynchronous:NO];
        [thread setReplacingOnly:replacingOnly];
        [thread setWrap:isWrap];
        
        [thread detach];
        
        [self markTargetFree:target];
        textFindResult = [thread result];
    }
    @catch (NSException *localException) {
        textFindResult = [OgreTextFindResult textFindResultWithTarget:target thread:thread];
        [textFindResult setType:OgreTextFindResultError];
        [textFindResult setAlertSheet:sheet exception:localException];
    }
    
    return textFindResult;
}

- (OgreTextFindResult *)replaceAll:(NSString *)expressionString
                        withString:(NSString *)replaceString
                           options:(OgreOption)options
                       inSelection:(BOOL)inSelection
{
    return [self replaceAll:[OGPlainString stringWithString:expressionString]
               withOGString:[OGPlainString stringWithString:replaceString]
                    options:options
                inSelection:inSelection];
}

- (OgreTextFindResult *)replaceAll:(NSString *)expressionString
              withAttributedString:(NSAttributedString *)replaceString
                           options:(OgreOption)options
                       inSelection:(BOOL)inSelection
{
    return [self replaceAll:[OGPlainString stringWithString:expressionString]
               withOGString:[OGAttributedString stringWithAttributedString:replaceString]
                    options:options
                inSelection:inSelection];
}

- (OgreTextFindResult *)replaceAll:(id <OGStringProtocol>)expressionString
                      withOGString:(id <OGStringProtocol>)replaceString
                           options:(OgreOption)options
                       inSelection:(BOOL)inSelection
{
#ifdef DEBUG_OGRE_FIND_PANEL
    NSLog(@"-replaceAll:... of %@", [self className]);
#endif
    
    id target = [self targetToFindIn];
    if ((target == nil) || [self isBusyTarget:target] /*|| ![target isEditable]*/) {
        return [OgreTextFindResult textFindResultWithTarget:target thread:nil];
    }
    [self markTargetBusy:target];
    
    OgreTextFindThread              *thread = nil;
    OgreTextFindProgressSheet       *sheet = nil;
    OgreTextFindResult              *textFindResult = nil;
    
    @try {
        OGRegularExpression *regex =
        [OGRegularExpression regularExpressionWithString:[expressionString string]
                                                 options:options
                                                  syntax:[self syntax]
                                         escapeCharacter:[self escapeCharacter]];
        
        OGReplaceExpression *repex =
        [OGReplaceExpression replaceExpressionWithOGString:replaceString
                                                   options:options
                                                    syntax:[self syntax]
                                           escapeCharacter:[self escapeCharacter]];
        
        /* Generation of processing status display for the seat (処理状況表示用シートの生成) */
        sheet = [[OgreTextFindProgressSheet alloc] initWithWindow:[target window]
                                                            title:OgreTextFinderLocalizedString(@"Replace All")
                                                   didEndSelector:@selector(markTargetFree:)
                                                         toTarget:self
                                                       withObject:target];
        
        /* Generation of thread (スレッドの生成) */
        id adapter = [self adapterForTarget:target];
        thread = [[OgreReplaceAllThread alloc] initWithComponent:adapter];
        [thread setRegularExpression:regex];
        [thread setReplaceExpression:repex];
        [thread setOptions:options];
        [thread setInSelection:inSelection];
        [thread setDidEndSelector:@selector(didEndThread:) toTarget:self];
        [thread setProgressDelegate:sheet];
        [thread setAsynchronous:YES];
        
        [thread detach];
        
        textFindResult = [OgreTextFindResult textFindResultWithTarget:target thread:thread];
        [textFindResult setType:OgreTextFindResultSuccess];
    }
    @catch (NSException *localException) {
        textFindResult = [OgreTextFindResult textFindResultWithTarget:target thread:thread];
        [textFindResult setType:OgreTextFindResultError];
        [textFindResult setAlertSheet:sheet exception:localException];
    }
    
    return textFindResult;
}

- (OgreTextFindResult *)unhightlight
{
#ifdef DEBUG_OGRE_FIND_PANEL
    NSLog(@"-unhightlight:... of %@", [self className]);
#endif
    
    id target = [self targetToFindIn];
    if ((target == nil) || [self isBusyTarget:target]) {
        return [OgreTextFindResult textFindResultWithTarget:target thread:nil];
    }
    [self markTargetBusy:target];
    
    OgreTextFindThread *thread = nil;
    OgreTextFindResult *textFindResult = nil;
    
    @try {
        /* Generation of thread (スレッドの生成) */
        id adapter = [self adapterForTarget:target];
        thread = [[OgreUnhighlightThread alloc] initWithComponent:adapter];
        [thread setAsynchronous:NO];
        
        [thread detach];
        
        [self markTargetFree:target];
        textFindResult = [thread result];
    }
    @catch (NSException *localException) {
        textFindResult = [OgreTextFindResult textFindResultWithTarget:target thread:thread];
        [textFindResult setType:OgreTextFindResultError];
        [textFindResult setAlertSheet:nil exception:localException];
    }
    
    return textFindResult;
}

- (OgreTextFindResult *)hightlight:(NSString *)expressionString
                             color:(NSColor *)highlightColor
                           options:(OgreOption)options
                       inSelection:(BOOL)inSelection
{
#ifdef DEBUG_OGRE_FIND_PANEL
    NSLog(@"-hightlight:... of %@", [self className]);
#endif
    
    id target = [self targetToFindIn];
    if ((target == nil) || [self isBusyTarget:target]) {
        return [OgreTextFindResult textFindResultWithTarget:target thread:nil];
    }
    [self markTargetBusy:target];
    
    OgreTextFindThread              *thread = nil;
    OgreTextFindProgressSheet       *sheet = nil;
    OgreTextFindResult              *textFindResult = nil;
    
    @try {
        OGRegularExpression *regex =
        [OGRegularExpression regularExpressionWithString:expressionString
                                                 options:options
                                                  syntax:[self syntax]
                                         escapeCharacter:[self escapeCharacter]];
        
        /* Generation of processing status display for the seat (処理状況表示用シートの生成) */
        sheet = [[OgreTextFindProgressSheet alloc] initWithWindow:[target window]
                                                            title:OgreTextFinderLocalizedString(@"Highlight")
                                                   didEndSelector:@selector(markTargetFree:)
                                                         toTarget:self
                                                       withObject:target];
        
        /* Generation of thread (スレッドの生成) */
        id adapter = [self adapterForTarget:target];
        thread = [[OgreHighlightThread alloc] initWithComponent:adapter];
        [thread setRegularExpression:regex];
        [thread setHighlightColor:highlightColor];
        [thread setOptions:options];
        [thread setInSelection:inSelection];
        [thread setDidEndSelector:@selector(didEndThread:) toTarget:self];
        [thread setProgressDelegate:sheet];
        [thread setAsynchronous:YES];
        
        [thread detach];
        
        textFindResult = [OgreTextFindResult textFindResultWithTarget:target thread:thread];
        [textFindResult setType:OgreTextFindResultSuccess];
    }
    @catch (NSException *localException) {
        textFindResult = [OgreTextFindResult textFindResultWithTarget:target thread:thread];
        [textFindResult setType:OgreTextFindResultError];
        [textFindResult setAlertSheet:sheet exception:localException];
    }
    
    return textFindResult;
}

/* selection */
- (NSString *)selectedString
{
    return [[self selectedOGString] string];
}

- (NSAttributedString *)selectedAttributedString
{
    return [[self selectedOGString] attributedString];
}

- (id <OGStringProtocol>)selectedOGString
{
    id target = [self targetToFindIn];
    if ((target == nil) || [self isBusyTarget:target]) {
        return nil;
    }
    
    [self markTargetBusy:target];
    OgreTextFindLeaf            *selectedLeaf = nil;
    NSObject <OGStringProtocol> *string = nil;
    OgreTextFindResult          *textFindResult = nil;
    
    @try {
        id adapter = [self adapterForTarget:target];
        selectedLeaf = [adapter selectedLeaf];
        
        [selectedLeaf willProcessFinding:nil];
        string = [[selectedLeaf ogString] substringWithRange:[selectedLeaf selectedRange]];
        [selectedLeaf finalizeFinding];
        
        [self markTargetFree:target];
    }
    @catch (NSException *localException) {
        textFindResult = [OgreTextFindResult textFindResultWithTarget:target thread:nil];
        [textFindResult setType:OgreTextFindResultError];
        [textFindResult setAlertSheet:nil exception:localException];
        [textFindResult alertIfErrorOccurred];
    }
    
    return string;
}

- (BOOL)isSelectionEmpty
{
    id target = [self targetToFindIn];
    if ((target == nil) || [self isBusyTarget:target]) {
        return NO;
    }
    
    [self markTargetBusy:target];
    OgreTextFindLeaf        *selectedLeaf = nil;
    NSRange                 selectedRange = NSMakeRange(0, 0);
    OgreTextFindResult      *textFindResult = nil;
    
    @try {
        id adapter = [self adapterForTarget:target];
        selectedLeaf = [adapter selectedLeaf];
        
        [selectedLeaf willProcessFinding:nil];
        selectedRange = [selectedLeaf selectedRange];
        [selectedLeaf finalizeFinding];
        
        [self markTargetFree:target];
    }
    @catch (NSException *localException) {
        textFindResult = [OgreTextFindResult textFindResultWithTarget:target thread:nil];
        [textFindResult setType:OgreTextFindResultError];
        [textFindResult setAlertSheet:nil exception:localException];
        [textFindResult alertIfErrorOccurred];
    }
    
    if (selectedRange.length > 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)jumpToSelection
{
    id target = [self targetToFindIn];
    if ((target == nil) || [self isBusyTarget:target]) {
        return NO;
    }
    
    [self markTargetBusy:target];
    OgreTextFindLeaf        *selectedLeaf = nil;
    OgreTextFindResult      *textFindResult = nil;
    
    @try {
        id adapter = [self adapterForTarget:target];
        selectedLeaf = [adapter selectedLeaf];
        
        [selectedLeaf willProcessFinding:nil];
        [[adapter window] makeKeyAndOrderFront:self];
        [selectedLeaf jumpToSelection];
        [selectedLeaf finalizeFinding];
        
        [self markTargetFree:target];
    }
    @catch (NSException *localException) {
        textFindResult = [OgreTextFindResult textFindResultWithTarget:target thread:nil];
        [textFindResult setType:OgreTextFindResultError];
        [textFindResult setAlertSheet:nil exception:localException];
        [textFindResult alertIfErrorOccurred];
    }
    
    return YES;
}

/* notify from Thread */
- (void)didEndThread:(OgreTextFindThread *)aTextFindThread
{
#ifdef DEBUG_OGRE_FIND_PANEL
    NSLog(@"-didEndThread of %@", [self className]);
#endif
    
    BOOL shouldCloseProgressSheet = NO;
    SEL didEndSelector = [aTextFindThread didEndSelectorForFindPanelController];
    id result = [aTextFindThread result];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    shouldCloseProgressSheet = ([findPanelController performSelector:didEndSelector withObject:result] != nil);
#pragma clang diagnostic pop
    
    id sheet = [aTextFindThread progressDelegate];
    
    if (shouldCloseProgressSheet) {
        // Automatically I close. In the OK button I do not release. (自動的に閉じる。OKボタンではreleaseしないようにする。)
        [(id <OgreTextFindProgressDelegate>)sheet setReleaseWhenOKButtonClicked:NO];
        [sheet performSelector:@selector(close:) withObject:self];
    }
}

/* alert sheet */
- (OgreTextFindProgressSheet *)alertSheetOnTarget:(id)aTarget
{
    OgreTextFindProgressSheet   *sheet = nil;
    
    if ((aTarget != nil) && ![self isBusyTarget:aTarget]) {
        [self markTargetBusy:aTarget];
        sheet = [[OgreTextFindProgressSheet alloc] initWithWindow:[aTarget window]
                                                            title:@""
                                                   didEndSelector:@selector(markTargetFree:)
                                                         toTarget:self
                                                       withObject:aTarget];
    }
    
    return sheet;
}

/* Getting and registering adapters for targets */
- (id)adapterForTarget:(id)aTargetToFindIn
{
    if ([aTargetToFindIn respondsToSelector:@selector(ogreAdapter)]) {
        return [(id <OgreView>)aTargetToFindIn ogreAdapter];
    }
    
    Class anAdapterClass = [self adapterClassForTargetToFindIn];
    
    if (anAdapterClass == Nil) {
        /* Searching in the adapter-target array */
        NSInteger index, count = [_adapterClassArray count];
        for (index = count - 1; index >= 0; index--) {
            if ([aTargetToFindIn isKindOfClass:_targetClassArray[index]]) {
                anAdapterClass = _adapterClassArray[index];
                break;
            }
        }
    }
    
    return [[anAdapterClass alloc] initWithTarget:aTargetToFindIn];
}

- (void)registeringAdapterClass:(Class)anAdapterClass forTargetClass:(Class)aTargetClass
{
    [_adapterClassArray addObject:anAdapterClass];
    [_targetClassArray addObject:aTargetClass];
}

- (void)setAdapterClassForTargetToFindIn:(Class)adapterClass
{
    _adapterClassForTarget = adapterClass;
}

- (Class)adapterClassForTargetToFindIn;
{
    return _adapterClassForTarget;
}

- (BOOL)hasAdapterClassForObject:(id)anObject
{
    if (anObject == nil) {
        return NO;
    }
    
    if ([anObject respondsToSelector:@selector(ogreAdapter)]) {
        return YES;
    }
    
    NSInteger index, count = [_targetClassArray count];
    for (index = count - 1; index >= 0; index--) {
        if ([anObject isKindOfClass:_targetClassArray[index]]) {
            return YES;
            break;
        }
    }
    
    return NO;
}

@end
