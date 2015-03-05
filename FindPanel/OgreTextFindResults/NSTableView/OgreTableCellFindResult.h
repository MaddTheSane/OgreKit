/*
 * Name: OgreTableCellFindResult.h
 * Project: OgreKit
 *
 * Creation Date: Jun 05 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreFindResultBranch.h>
#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OgreTextFindResult.h>

@class OgreTableColumn;

@interface OgreTableCellFindResult : OgreFindResultBranch <OgreFindResultCorrespondingToTextFindLeaf>
{
    OgreTableColumn *_tableColumn;
    NSMutableArray  *_matchRangeArray, *_childArray;
    NSInteger       _rowIndex;
}

- (id)initWithTableColumn:(OgreTableColumn*)tableColumn row:(NSInteger)rowIndex;

// line number that matched string for the index (index番目にマッチした文字列のある行番号)
- (NSNumber*)lineOfMatchedStringAtIndex:(NSUInteger)index;
// matched string for the index (index番目にマッチした文字列)
- (NSAttributedString*)matchedStringAtIndex:(NSUInteger)index;
// I want to select and display the matched string for the index (index番目にマッチした文字列を選択・表示する)
- (BOOL)showMatchedStringAtIndex:(NSUInteger)index;
// I choose the matched string for the index (index番目にマッチした文字列を選択する)
- (BOOL)selectMatchedStringAtIndex:(NSUInteger)index;

- (void)targetIsMissing;

@end
