/*
 * Name: OgreFindResultBranch.h
 * Project: OgreKit
 *
 * Creation Date: Apr 18 2004
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreTextFindBranch.h>

@class OgreTextFindResult;

@interface OgreFindResultBranch : OgreTextFindBranch
{
    OgreTextFindResult  *_textFindResult;
}

/* methods overridden by subclass of OgreFindResultBranch  */
- (void)addComponent:(NSObject <OgreTextFindComponent>*)aFindResultComponent;
- (void)endAddition;
@property (nonatomic, strong) OgreTextFindResult *textFindResult;

@property (nonatomic, readonly) BOOL showMatchedString;
@property (nonatomic, readonly) BOOL selectMatchedString;

@end
