/*
 * Name: MyOutlineDocument.m
 * Project: OgreKit
 *
 * Creation Date: Sep 29 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import "MyOutlineDocument.h"
#import "MyFileWrapper.h"

@implementation MyOutlineDocument

// I teach be searched TextView to OgreTextFinder. (検索対象となるTextViewをOgreTextFinderに教える。)
// To set nil if you do not want to search is. (検索させたくない場合はnilをsetする。)
// If you omit the definition, first responder of main window is to adopt it if possible search. (定義を省略した場合、main windowのfirst responderが検索可能ならばそれを採用する。)
- (void)tellMeTargetToFindIn:(id)textFinder
{
	[textFinder setTargetToFindIn:myOutlineView];
}


/* Code that is not related to the Find Panel under from here (ここから下はFind Panelに関係しないコード) */
- (NSString*)windowNibName {
    return @"MyOutlineDocument";
}

- (NSData*)dataRepresentationOfType:(NSString*)type 
{
    return nil;
}

- (BOOL)loadDataRepresentation:(NSData*)data ofType:(NSString*)type 
{
    return YES;
}

- (void)windowControllerDidLoadNib:(NSWindowController*)controller
{
	if (_fileWrapper != nil) {
        [myOutlineView reloadData];
	} else {
		//_newlineCharacter = OgreUnixNewlineCharacter;	// The default line break code (デフォルトの改行コード)
        
        NSInteger   result;
        NSOpenPanel *openPanel;
        
        openPanel = [NSOpenPanel openPanel];
        [openPanel setCanChooseDirectories:YES];
        [openPanel setDirectoryURL:[NSURL fileURLWithPath:NSHomeDirectory() isDirectory:YES]];
        result = [openPanel runModal];
        if(result == NSOKButton) {
            NSURL    *url = [openPanel URL];
            //NSLog(@"%@", path);
            _fileWrapper = [[MyFileWrapper alloc] initWithName:[url lastPathComponent] path:[url absoluteString] parent:self];
            //NSLog(@"%@", [_fileWrapper description]);
        }
        [myOutlineView reloadData];
        if (_fileWrapper != nil) [myOutlineView expandItem:_fileWrapper];
    }
    
    [super windowControllerDidLoadNib:controller];
}

- (void)awakeFromNib
{
    NSBrowserCell   *dataCell = [[[NSBrowserCell alloc] init] autorelease];
    [dataCell setEditable:NO];
    [dataCell setLeaf:YES];
    [[myOutlineView tableColumnWithIdentifier:@"name"] setDataCell:dataCell];
    
    [myOutlineView registerForDraggedTypes:@[NSFilenamesPboardType]];
}

- (void)dealloc
{
    [_fileWrapper release];
    [super dealloc];
}

// Change of line feed code (改行コードの変更)
- (void)setNewlineCharacter:(OgreNewlineCharacter)aNewlineCharacter
{
	_newlineCharacter = aNewlineCharacter;
}

/* NSOutlineViewDataSource methods */
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if (_fileWrapper == nil) return NO;
    //NSLog(@"isItemExpandable:%@", [item name]);

    if (item == nil) return YES;    // root
    
    return [item isDirectory];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (_fileWrapper == nil) return 0;
    //NSLog(@"numberOfChildrenOfItem:%@", [item name]);
    
    if (item == nil) return 1;    // root
    
    return [item numberOfComponents];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if (_fileWrapper == nil) return nil;
    //NSLog(@"child:%d ofItem:%@", index, [item name]);
    
    if (item == nil) return _fileWrapper;    // root
    
    return [item componentAtIndex:index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if (_fileWrapper == nil) return nil;
	
	id	identifier = [tableColumn identifier];
    //NSLog(@"objectValueForTableColumn:%@ byItem:%@", identifier, [item name]);
    
    if (item == nil) item = _fileWrapper;    // root
    
    return [item valueForKey:identifier];
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	id	identifier = [tableColumn identifier];
    [item takeValue:object forKey:identifier];
}

/* displaying cell */
- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    id	identifier = [tableColumn identifier];
    if ([identifier isEqualToString:@"name"]) {
        [cell setImage:[item icon]];
    }
}

/* drop */
- (NSUInteger)outlineView:(NSOutlineView*)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)childIndex
{
    NSPasteboard    *pboard = [info draggingPasteboard];
    if ([pboard availableTypeFromArray:@[NSFilenamesPboardType]] != nil) {
        [outlineView setDropItem:nil dropChildIndex:NSOutlineViewDropOnItemIndex];
        return NSDragOperationGeneric;
    }
    
    return NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView*)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)targetItem childIndex:(NSInteger)childIndex
{
    NSPasteboard    *pboard = [info draggingPasteboard];
    if ([pboard availableTypeFromArray:@[NSFilenamesPboardType]] != nil) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        [_fileWrapper release];
        NSString    *path = files[0];
        _fileWrapper = [[MyFileWrapper alloc] initWithName:[path lastPathComponent] path:path parent:self];
        [myOutlineView reloadData];
        [myOutlineView expandItem:_fileWrapper];
        
        return YES;
    }
    
    return NO;
}

- (void)deleteKeyDownInOutlineView:(NSOutlineView*)outlineView
{
    NSIndexSet  *selectedRowIndexes = [myOutlineView selectedRowIndexes];
    NSUInteger  count = [selectedRowIndexes count], i;
    if (count == 0) return;
    
    NSUInteger  *rowIndexes = (NSUInteger*)NSZoneMalloc([self zone], sizeof(NSUInteger) * count);
    if (rowIndexes == NULL) {
        // Error
        return;
    }
    [selectedRowIndexes getIndexes:rowIndexes maxCount:count inIndexRange:NULL];
    for (i = 0; i < count; i++) {
        id  item = [myOutlineView itemAtRow:*(rowIndexes + i)];
        [item remove];
    }
    NSZoneFree([self zone], rowIndexes);
    [myOutlineView reloadData];
}

- (void)removeComponent:(id)aComponent
{
    if (aComponent == _fileWrapper) {
        [_fileWrapper release];
        _fileWrapper = nil;
    }
}


@end
