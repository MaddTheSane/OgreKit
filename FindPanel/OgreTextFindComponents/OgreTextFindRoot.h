/*
 * Name: OgreTextFindRoot.h
 * Project: OgreKit
 *
 * Creation Date: Sep 26 2003
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>
#import <OgreKit/OgreTextFindBranch.h>

@interface OgreTextFindRoot : OgreTextFindBranch
{
    id <OgreTextFindComponent>    _component;
}

- (instancetype)initWithComponent:(id <OgreTextFindComponent>)aComponent;

@end
