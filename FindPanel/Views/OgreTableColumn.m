/*
 * Name: OgreTableColumn.m
 * Project: OgreKit
 *
 * Creation Date: Jun 13 2004
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreTableColumn.h>

@implementation OgreTableColumn

- (void)bind:(NSString *)binding toObject:(id)observableController withKeyPath:(NSString *)keyPath options:(NSDictionary *)options
{
    //NSLog(@"bind:%@ toObject:%@ withKeyPath:%@ options:%@", binding, [observableController className], keyPath, [options description]);
    
    if ([binding isEqualToString:@"value"]) {
        _ogreObservableController = observableController; // no retain
        //[_ogreControllerKeyOfValueBinding autorelease];
        //[_ogreModelKeyPathOfValueBinding autorelease];
        
        // input
        //  keyPath: arrangedObjects.somePropaties.aModelKey
        // output
        //  _ogreControllerKeyOfValueBinding: arrangedObjects
        //  _ogreModelKeyPathOfValueBinding: somePropaties.aModelKey
        
        NSArray *keyPathComponents = [keyPath componentsSeparatedByString:@"."];
        
        _ogreControllerKeyOfValueBinding = keyPathComponents[0];
        
        _ogreModelKeyPathOfValueBinding = [[NSMutableString alloc] init];
        
        NSInteger   i, count = [keyPathComponents count];
        for (i = 1; i < count; i++) {
            if (i > 1) [_ogreModelKeyPathOfValueBinding appendString:@"."];
            [_ogreModelKeyPathOfValueBinding appendString:keyPathComponents[i]];
        }
        //NSLog(@"Controller Key:%@\nModel Key Path:%@", _ogreControllerKeyOfValueBinding, _ogreModelKeyPathOfValueBinding);
    }
    
    [super bind:binding toObject:observableController withKeyPath:keyPath options:options];
}

- (void)unbind:(NSString *)binding
{
    [super unbind:binding];
    
    if ([binding isEqualToString:@"value"]) {
        _ogreObservableController = nil;
        _ogreControllerKeyOfValueBinding = nil;
        _ogreModelKeyPathOfValueBinding = nil;
    }
}


- (NSInteger)ogreNumberOfRows
{
    id  dataSource;
    
    if ((_ogreObservableController != nil) && (_ogreControllerKeyOfValueBinding != nil) && (_ogreModelKeyPathOfValueBinding != nil)) {
        return [[_ogreObservableController valueForKeyPath:_ogreControllerKeyOfValueBinding] count];
    } else if ((dataSource = [[self tableView] dataSource]) != nil) {
        return [dataSource numberOfRowsInTableView:[self tableView]];
    }
    
    return 0;
}

- (id)ogreObjectValueForRow:(NSInteger)row
{
    if (row < 0) return nil;
    
    id  anObject = nil;
    id  dataSource;
    
    if ((_ogreObservableController != nil) && (_ogreControllerKeyOfValueBinding != nil) && (_ogreModelKeyPathOfValueBinding != nil)) {
        NSArray *array = [_ogreObservableController valueForKeyPath:_ogreControllerKeyOfValueBinding];
        anObject = [array[row] valueForKeyPath:_ogreModelKeyPathOfValueBinding];
    } else if ((dataSource = [[self tableView] dataSource]) != nil) {
        anObject = [dataSource tableView:[self tableView] objectValueForTableColumn:self row:row];
    }
    
    return anObject;
}

- (void)ogreSetObjectValue:(id)anObject forRow:(NSInteger)row
{
    if (row < 0) return;
    
    id  dataSource;
    
    if ((_ogreObservableController != nil) && (_ogreControllerKeyOfValueBinding != nil) && (_ogreModelKeyPathOfValueBinding != nil)) {
        NSArray *array = [_ogreObservableController valueForKeyPath:_ogreControllerKeyOfValueBinding];
        [array[row] setValue:anObject forKeyPath:_ogreModelKeyPathOfValueBinding];
    } else if ((dataSource = [[self tableView] dataSource]) != nil) {
        [dataSource tableView:[self tableView] setObjectValue:anObject forTableColumn:self row:row];
    }
}

@end
