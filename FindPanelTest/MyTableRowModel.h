/*
 * Name: MyTableRowModel.h
 * Project: OgreKit
 *
 * Creation Date: Jun 18 2004
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>


@interface MyTableRowModel : NSObject 
{
    NSString    *_foo;
    NSString    *_bar;
}

@property (nonatomic, copy) NSString *foo;
@property (nonatomic, copy) NSString *bar;

- (void)dump;

@end
