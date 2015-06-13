//
//  MyAppController.m
//  OgreKit
//
//  Created by Jan on 13.06.15.
//
//

#import "MyAppController.h"

#import "MyDocumentController.h"

@implementation MyAppController {
    MyDocumentController *_dc;
}

- (id)init
{
    self = [super init];
    
    if (self) {
        _dc = [[MyDocumentController alloc] init];
    }
    
    return self;
}

@end
