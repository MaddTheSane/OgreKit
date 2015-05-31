/*
 * Name: OgreTextFindResult.m
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

#import <OgreKit/OgreTextFindResult.h>
#import <OgreKit/OgreTextFindProgressSheet.h>
#import <OgreKit/OgreTextFindThread.h>

#import <tgmath.h>

@implementation OgreTextFindResult
@synthesize delegate = _delegate;
@synthesize numberOfMatches = _numberOfMatches;
@synthesize title = _title;

// -matchedStringAtIndex: The maximum number of characters returned by (-1: unlimited) (-matchedStringAtIndex:の返す最大文字数 (-1: 無制限))
// -matchedStringAtIndex: at, matched maximum number of characters to the left of the string (-1: unlimited) (-matchedStringAtIndex:にて、マッチした文字列の左側の最大文字数 (-1: 無制限))
@synthesize maximumLeftMargin = _maxLeftMargin;

// Matched maximum number of characters to the left of the string (-1: unlimited) (マッチした文字列の左側の最大文字数 (-1: 無制限))
// -matchedStringAtIndex: The maximum number of characters returned by (-1: unlimited) (-matchedStringAtIndex:の返す最大文字数 (-1: 無制限))
@synthesize maximumMatchedStringLength = _maxMatchedStringLength;

+ (instancetype)textFindResultWithTarget:(id)targetFindingIn thread:(OgreTextFindThread *)aThread
{
	return [[[self class] alloc] initWithTarget:targetFindingIn thread:aThread];
}

- (instancetype)initWithTarget:(id)targetFindingIn thread:(OgreTextFindThread *)aThread
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -initWithTarget: of %@", [self className]);
#endif
	self = [super init];
	if (self != nil) {
		_target = targetFindingIn;
        _branchStack = [[NSMutableArray alloc] init];
		
		_maxLeftMargin = -1;			// Limitless (無制限)
		_maxMatchedStringLength = -1;   // Limitless (無制限)
        
        _numberOfMatches = 0;

        _regex = [aThread regularExpression];
	}
	return self;
}

- (void)setType:(OgreTextFindResultType)resultType
{
    _resultType = resultType;
}

- (BOOL)isSuccess
{
	switch(_resultType) {
		case OgreTextFindResultSuccess:
			return YES;
		case OgreTextFindResultFailure:
		case OgreTextFindResultError:
		default:
			return NO;
	}
}

- (NSString *)findString
{
    return [_regex expressionString];
}

/* result Information (OgreFindResult instance, error reason) */
- (void)setAlertSheet:(id /*<OgreTextFindProgressDelegate>*/)aSheet exception:(NSException *)anException
{
	_alertSheet = aSheet;
    
	_exception = anException;
}

- (BOOL)alertIfErrorOccurred
{
	if ((_resultType != OgreTextFindResultError) || (_exception == nil)) return NO;  // no error
	
	if (_alertSheet == nil) {
		// create an alert sheet
		_alertSheet = [[OgreTextFinder sharedTextFinder] alertSheetOnTarget:_target];
	}
	[(id <OgreTextFindProgressDelegate>)_alertSheet showErrorAlert:[_exception name] message:[_exception reason]];
	
	return YES;
}

- (void)beginGraftingToBranch:(OgreFindResultBranch *)aFindResultBranch
{
    [aFindResultBranch setTextFindResult:self];
    [aFindResultBranch setParentNoRetain:_branch];
    
    if (_branch != nil) {
        [_branch addComponent:aFindResultBranch];
        // push
        [_branchStack addObject:_branch];
        _branch = aFindResultBranch;
    } else {
        _resultTree = _branch = aFindResultBranch;
    }
}

- (void)addLeaf:(id)aLeaf
{
    [aLeaf setTextFindResult:self];
    [aLeaf setParentNoRetain:_branch];
    
    [_branch addComponent:aLeaf];
}

- (void)endGrafting
{
    [_branch endAddition];
    if ([_branchStack count] > 0) {
        // pop
        _branch = [_branchStack lastObject];
        [_branchStack removeLastObject];
    }
}

- (NSObject <OgreTextFindComponent>*)result
{
    return _resultTree;
}

- (void)setHighlightColor:(NSColor *)aColor regularExpression:(OGRegularExpression *)regex;
{
    CGFloat hue, saturation, brightness, alpha;
    CGFloat  dummy;
    
    [[aColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] 
        getHue: &hue 
        saturation: &saturation 
        brightness: &brightness 
        alpha: &alpha];
        
    BOOL    isSimple = ([regex syntax] == OgreSimpleMatchingSyntax && ([regex options] & OgreDelimitByWhitespaceOption) != 0);
    
    NSUInteger    numberOfGroups = [_regex numberOfGroups], i;
    
    _highlightColorArray = [[NSMutableArray alloc] initWithCapacity:numberOfGroups];
    for (i = 0; i <= numberOfGroups; i++) {
        [_highlightColorArray addObject:[NSColor colorWithCalibratedHue: 
            modf(hue + (isSimple? (CGFloat)(i - 1) : (CGFloat)i) / (isSimple? (CGFloat)numberOfGroups : (CGFloat)(numberOfGroups + 1)), &dummy)
            saturation: saturation 
            brightness: brightness 
            alpha: alpha]];
    }
}

// emphasize the range of aRangeArray in aString. (aString中のaRangeArrayの範囲を強調する。)
- (NSAttributedString *)highlightedStringInRange:(NSArray *)aRangeArray ofString:(NSString *)aString
{
	NSInteger							i, n = [aRangeArray count], delta = 0;
	NSRange						lineRange, intersectionRange, matchRange;
	NSMutableAttributedString	*highlightedString;
    
	/* Top of a range and content of the row of matched string (マッチした文字列の先頭のある行の範囲・内容) */
	matchRange = [aRangeArray[0] rangeValue];
	if ([aString length] < NSMaxRange(matchRange)) {
		// Where a range of string of matchRange does not exist (matchRangeの範囲の文字列が存在しない場合)
		return [[NSAttributedString alloc] initWithString:OgreTextFinderLocalizedString(@"Missing.") attributes:@{NSForegroundColorAttributeName: [NSColor redColor]}];
	}
	lineRange = [aString lineRangeForRange:NSMakeRange(matchRange.location, 0)];
    
	highlightedString = [[NSMutableAttributedString alloc] initWithString:@""];
	if ((_maxLeftMargin >= 0) && (matchRange.location > lineRange.location + _maxLeftMargin)) {
		// I limit the number of characters on the left side of the MatchedString (MatchedStringの左側の文字数を制限する)
		delta = matchRange.location - (lineRange.location + _maxLeftMargin);
		lineRange.location += delta;
		lineRange.length   -= delta;
		[highlightedString appendAttributedString:[[NSAttributedString alloc] 
			initWithString:@"..." 
			attributes:@{NSForegroundColorAttributeName: [NSColor grayColor]}]];
	}
	if ((_maxMatchedStringLength >= 0) && (lineRange.length > _maxMatchedStringLength)) {
		// I limit the number of characters all (全文字数を制限する)
		lineRange.length = _maxMatchedStringLength;
		[highlightedString appendAttributedString:[[NSAttributedString alloc] 
			initWithString:[aString substringWithRange:lineRange]]];
		[highlightedString appendAttributedString:[[NSAttributedString alloc] 
			initWithString:@"..." 
			attributes:@{NSForegroundColorAttributeName: [NSColor grayColor]}]];
	} else {
		[highlightedString appendAttributedString:[[NSAttributedString alloc] 
			initWithString:[aString substringWithRange:lineRange]]];
	}
	
	/* Coloring (彩色) */
	[highlightedString beginEditing];
	for(i = 0; i < n; i++) {
		matchRange = [aRangeArray[i] rangeValue];
		intersectionRange = NSIntersectionRange(lineRange, matchRange);
		
		if (intersectionRange.length > 0) {
			[highlightedString setAttributes:
				@{NSBackgroundColorAttributeName: _highlightColorArray[i]} 
				range:NSMakeRange(intersectionRange.location - lineRange.location + ((delta == 0)? 0 : 3), intersectionRange.length)];
		}
	}
	[highlightedString endEditing];

	return highlightedString;
}

- (NSAttributedString *)missingString
{
    return [[NSAttributedString alloc] initWithString:OgreTextFinderLocalizedString(@"Missing.") attributes:@{NSForegroundColorAttributeName: [NSColor redColor]}];
}


- (void)didUpdate
{
    [_delegate didUpdateTextFindResult:self];
}

- (NSAttributedString *)messageOfStringsFound:(NSUInteger)numberOfMatches
{
    NSString        *message;
    if (numberOfMatches > 1) {
        message = OgreTextFinderLocalizedString(@"%lu strings found.");
    } else {
        message = OgreTextFinderLocalizedString(@"%lu string found.");
    }
    return [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:message, (unsigned long)numberOfMatches] attributes:@{NSForegroundColorAttributeName: [NSColor darkGrayColor]}];
}

- (NSAttributedString *)messageOfItemsFound:(NSUInteger)numberOfMatches
{
    NSString        *message;
    if (numberOfMatches > 1) {
        message = OgreTextFinderLocalizedString(@"Found in %lu items.");
    } else {
        message = OgreTextFinderLocalizedString(@"Found in %lu item.");
    }
    return [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:message, (unsigned long)numberOfMatches] attributes:@{NSForegroundColorAttributeName: [NSColor darkGrayColor]}];
}


- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if (tableColumn != [outlineView outlineTableColumn]) return;
    id  adelegate;
    if ([item target] == nil) {
        [cell setImage:nil];
        if ([cell isKindOfClass:[NSBrowserCell class]]) [cell setLeaf:YES];
        return;
    }
    
    if ([_target isKindOfClass:[NSOutlineView class]]) {
        adelegate = [_target delegate];
        if ([adelegate respondsToSelector:@selector(outlineView:willDisplayCell:forTableColumn:item:)]) {
            [adelegate outlineView:outlineView willDisplayCell:cell forTableColumn:tableColumn item:[(id <OgreTextFindComponent>)item target]];
        }
    }
}

- (NSCell *)nameCell
{
    NSCell  *nameCell;
    if ([_target isKindOfClass:[NSOutlineView class]]) {
        nameCell = [[[(NSOutlineView *)_target outlineTableColumn] dataCell] copy];
    } else {
        nameCell = [[NSTextFieldCell alloc] init];
        [nameCell setEditable:NO];
    }
    
    return nameCell;
}

- (CGFloat)rowHeight
{
    if ([_target isKindOfClass:[NSOutlineView class]]) {
        return [(NSOutlineView *)_target rowHeight];
    } else {
        return 16;
    }
}

- (NSString *)title
{
	if (_title == nil) {
		if ([_target respondsToSelector:@selector(window)]) {
			return [[_target window] title];
		} else {
			return @"Untitled Object";
		}
	}
	
	return _title;
}

@end
