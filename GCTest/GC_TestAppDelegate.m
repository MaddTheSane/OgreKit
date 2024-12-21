/*
 * Name: GC_TestAppDelegate.m
 * Project: OgreKit
 *
 * Creation Date: Mar 07 2010
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2010-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import "GC_TestAppDelegate.h"

@implementation GC_TestAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSLog(@"GC Test - start");
    
    OGRegularExpression *regEx = [OGRegularExpression regularExpressionWithString:@"a"];
    
    NSUInteger count = 0;
    NSUInteger i;
    for (i = 0; i < 1000000000; i++) {
        NSEnumerator  *matcher = [regEx matchEnumeratorInString:@"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"];
        OGRegularExpressionMatch  *match;
        while ((match = [matcher nextObject]) != nil) {
            count++;
        }
//        NSGarbageCollector *collector = [NSGarbageCollector defaultCollector];
//        [collector collectExhaustively];
    }
    
	NSLog(@"GC Test - end");
}

@end
