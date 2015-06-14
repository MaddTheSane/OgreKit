//
//  MyDocumentController.m
//  OgreKit
//
//  Created by Jan on 13.06.15.
//
//

#import "MyDocumentController.h"

@implementation MyDocumentController

- (NSString *)defaultType
{
    NSString *type;
    if (_untitledDocumentType != nil) {
        type = _untitledDocumentType;
    } else {
        type = [super defaultType];
    }
    
    return type;
}

@end
