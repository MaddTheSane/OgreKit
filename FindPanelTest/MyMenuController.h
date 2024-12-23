/*
 * Name: MyMenuController.h
 * Project: OgreKit
 *
 * Creation Date: Oct 16 2003
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Cocoa/Cocoa.h>

@interface MyMenuController : NSObject <NSApplicationDelegate>
{
}
- (IBAction)selectCr:(id)sender;
- (IBAction)selectCrLf:(id)sender;
- (IBAction)selectLf:(id)sender;

- (IBAction)newTextDocument:(id)sender;
- (IBAction)newRTFDocument:(id)sender;
- (IBAction)newTableDocument:(id)sender;
- (IBAction)newOutlineDocument:(id)sender;

- (IBAction)newTableDocumentWithCocoaBinding:(id)sender;

@end
