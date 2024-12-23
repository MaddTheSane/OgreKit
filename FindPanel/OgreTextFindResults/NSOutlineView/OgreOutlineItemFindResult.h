/*
 * Name: OgreOutlineItemFindResult.h
 * Project: OgreKit
 *
 * Creation Date: Jun 06 2004
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreFindResultBranch.h>

@class OgreOutlineCellMatchFindResult, OgreOutlineCellFindResult, OgreOutlineColumn;

@interface OgreOutlineItemFindResult : OgreFindResultBranch 
{
    OgreOutlineColumn   *_outlineColumn;
    id                  _item;
    
    NSMutableArray                  *_components, *_simplifiedComponents;
    OgreOutlineCellMatchFindResult  *_outlineDelegateLeaf;
}

- (instancetype)initWithOutlineColumn:(OgreOutlineColumn *)outlineColumn item:(id)item;

- (void)targetIsMissing;
- (void)expandItemEnclosingItem:(id)item;

- (void)mergeFindResult:(OgreOutlineCellFindResult *)aBranch;
- (void)replaceFindResult:(OgreOutlineItemFindResult *)aBranch withFindResultsFromArray:(NSArray *)resultsArray;

@end
