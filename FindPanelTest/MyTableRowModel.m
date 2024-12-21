/*
 * Name: MyTableRowModel.m
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

#import "MyTableRowModel.h"


@implementation MyTableRowModel

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _foo = @"new foo";
        _bar = @"new bar";
    }
    
    return self;
}


- (NSString *)foo
{
    return _foo;
}

- (void)setFoo:(NSString *)newFoo
{
    _foo = newFoo;
}

- (NSString *)bar
{
    return _bar;
}

- (void)setBar:(NSString *)newBar
{
    _bar = newBar;
}

- (void)dump
{
    NSLog(@"foo:%@ bar:%@", _foo, _bar);
}

@end
