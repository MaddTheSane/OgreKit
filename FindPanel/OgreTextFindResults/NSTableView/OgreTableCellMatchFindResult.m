/*
 * Name: OgreTableCellMatchFindResult.m
 * Project: OgreKit
 *
 * Creation Date: Jun 05 2004
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreTableCellMatchFindResult.h>
#import <OgreKit/OgreTableCellFindResult.h>


@implementation OgreTableCellMatchFindResult

- (id)name
{
    NSString    *name = [[(OgreTableCellFindResult *)[self parent] lineOfMatchedStringAtIndex:[self index]] stringValue];
    if ([self index] == 0) return name;
    
    return [[NSAttributedString alloc] initWithString:name attributes:@{NSForegroundColorAttributeName: [NSColor lightGrayColor]}];
}

- (id)outline
{
    return [(OgreTableCellFindResult *)[self parent] matchedStringAtIndex:[self index]]; 
}

- (BOOL)showMatchedString
{
    return [(OgreTableCellFindResult *)[self parent] showMatchedStringAtIndex:[self index]];
}

- (BOOL)selectMatchedString
{
    return [(OgreTableCellFindResult *)[self parent] selectMatchedStringAtIndex:[self index]];
}

/*- (id)target
{
    return [(OgreTableCellFindResult *)[self parent] target];
}*/

@end
