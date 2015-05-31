/*
 * Name: OgreTextFindResult.h
 * Project: OgreKit
 *
 * Creation Date: Apr 18 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGRegularExpressionMatch.h>
#import <OgreKit/OgreTextFinder.h>
#import <OgreKit/OgreFindResultLeaf.h>
#import <OgreKit/OgreFindResultBranch.h>
#import <OgreKit/OgreTextFindProgressDelegate.h>

@protocol OgreTextFindResultDelegate <NSObject>
- (void)didUpdateTextFindResult:(id)textFindResult;
@end

typedef NS_ENUM(NSInteger, OgreTextFindResultType) {
	OgreTextFindResultFailure = 0, 
	OgreTextFindResultSuccess = 1, 
	OgreTextFindResultError = 2
};

@interface OgreTextFindResult : NSObject <NSOutlineViewDelegate>
{
	OgreTextFindResultType		_resultType;
	id							_target;
    NSUInteger                  _numberOfMatches;           // number of the matches
    OGRegularExpression         *_regex;
    
    OgreFindResultBranch        *_resultTree, *_branch;
    NSMutableArray              *_branchStack;
	
    /* handling exception */
	NSException					*_exception;
	id							_alertSheet;
    
    /* display */
	NSInteger                   _maxMatchedStringLength;	// -matchedStringAtIndex: The maximum number of characters returned by (-1: unlimited) (-matchedStringAtIndex:の返す最大文字数 (-1: 無制限))
	NSInteger                   _maxLeftMargin;				// Matched maximum number of characters to the left of the string (-1: unlimited) (マッチした文字列の左側の最大文字数 (-1: 無制限))
    
    /* highlight color */
    NSMutableArray              *_highlightColorArray;   // variations
}

+ (instancetype)textFindResultWithTarget:(id)targetFindingIn thread:(OgreTextFindThread *)aThread;
- (instancetype)initWithTarget:(id)targetFindingIn thread:(OgreTextFindThread *)aThread NS_DESIGNATED_INITIALIZER;

- (void)setType:(OgreTextFindResultType)resultType;
@property (nonatomic, getter=isSuccess, readonly) BOOL success;				/* success or failure(including error) */
@property (nonatomic, readonly, strong) NSObject<OgreTextFindComponent> *result;
@property (nonatomic, readonly, copy) NSString *findString;

- (BOOL)alertIfErrorOccurred;
- (void)setAlertSheet:(id /*<OgreTextFindProgressDelegate>*/)aSheet exception:(NSException *)anException;

- (void)beginGraftingToBranch:(OgreFindResultBranch *)aBranch;
- (void)endGrafting;
- (void)addLeaf:(id)aLeaf;

@property (nonatomic) NSUInteger numberOfMatches;

@property (nonatomic, copy) NSString *title; // target window title

// Matched maximum number of characters to the left of the string (-1: unlimited) (マッチした文字列の左側の最大文字数 (-1: 無制限))
@property (nonatomic) NSInteger maximumLeftMargin;
// The maximum number of characters (-1: unlimited) However, ellipsis @ "..." I do not put in the count. (最大文字数 (-1: 無制限) ただし、省略記号@"..."はカウントに入れない。)
@property (nonatomic) NSInteger maximumMatchedStringLength;
- (void)setHighlightColor:(NSColor *)aColor regularExpression:(OGRegularExpression *)regex;
// emphasize the range of aRangeArray in aString. (aString中のaRangeArrayの範囲を強調する。)
- (NSAttributedString *)highlightedStringInRange:(NSArray *)aRangeArray ofString:(NSString *)aString;
@property (nonatomic, readonly, copy) NSAttributedString *missingString;
- (NSAttributedString *)messageOfStringsFound:(NSUInteger)numberOfMatches;
- (NSAttributedString *)messageOfItemsFound:(NSUInteger)numberOfMatches;

// delegate
@property (weak) id<OgreTextFindResultDelegate> delegate;  // Update contact (更新連絡先)
- (void)didUpdate;

// setting of result outline view
@property (readonly, copy) NSCell *nameCell;
@property (readonly) CGFloat rowHeight;
// delegate method of the find result outline view
- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item;

@end
