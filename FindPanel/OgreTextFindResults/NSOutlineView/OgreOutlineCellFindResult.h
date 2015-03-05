/*
 * Name: OgreOutlineCellFindResult.h
 * Project: OgreKit
 *
 * Creation Date: Jun 06 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreFindResultBranch.h>
#import <OgreKit/OgreTextFindResult.h>

@class OgreOutlineColumn;

@interface OgreOutlineCellFindResult : OgreFindResultBranch <OgreFindResultCorrespondingToTextFindLeaf> 
{
    OgreOutlineColumn   *_outlineColumn;
    id                  _item;
    
    NSMutableArray      *_matchRangeArray, *_matchComponents;
}

- (instancetype)initWithOutlineColumn:(OgreOutlineColumn*)outlineColumn item:(id)item;

// item name that matched string for the index (index番目にマッチした文字列のある項目名)
- (id)nameOfMatchedStringAtIndex:(NSUInteger)index;
// matched string at index (index番目にマッチした文字列)
- (NSAttributedString*)matchedStringAtIndex:(NSUInteger)index;
// I want to select and display the matched string for the index (index番目にマッチした文字列を選択・表示する)
- (BOOL)showMatchedStringAtIndex:(NSUInteger)index;
// I choose the matched string for the index (index番目にマッチした文字列を選択する)
- (BOOL)selectMatchedStringAtIndex:(NSUInteger)index;

- (void)targetIsMissing;
- (NSArray*)children;

@end
