/*
 * Name: MyFileWrapper.h
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

#import <Foundation/Foundation.h>


@interface MyFileWrapper : NSObject 
{
    NSString        *_name;
    NSString        *_path;
    NSMutableString *_info;
    NSImage         *_icon;
    BOOL            _isDirectory;
    NSMutableArray  *_components;
    MyFileWrapper   *_parent;
}

- (instancetype)initWithName:(NSString*)name path:(NSString*)path parent:(id)parent NS_DESIGNATED_INITIALIZER;
@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly, copy) NSString *path;
@property (nonatomic, readonly, copy) NSString *info;
@property (nonatomic, readonly, copy) NSImage *icon;
@property (nonatomic, readonly, getter=isDirectory) BOOL directory;
@property (nonatomic, readonly, copy) NSArray *components;
- (id)componentAtIndex:(NSUInteger)index;
@property (nonatomic, readonly) NSUInteger numberOfComponents;
- (void)removeComponent:(id)aComponent;
- (void)remove;

- (void)initComponents;

@end
