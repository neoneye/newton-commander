/*********************************************************************
JFIgnorePrefController.mm - ignore list settings

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#import "JFIgnorePrefController.h"


// for dragndrop row reordering, inside the table of action items
NSString* kJFIgnorePrefControllerDropType = @"JFIgnorePrefControllerDropType";


@implementation JFIgnorePrefItem
@synthesize name;
@end


@implementation JFIgnorePrefController

- (void)awakeFromNib {
	// NSLog(@"%s observe bookmarks", _cmd);
	[m_items addObserver: self
                     forKeyPath: @"arrangedObjects"      
                        options: NSKeyValueObservingOptionNew
                        context: NULL];

	[m_items addObserver: self
                     forKeyPath: @"arrangedObjects.name"
                        options: NSKeyValueObservingOptionNew
                        context: NULL];

	// [self populateWithItemsFromBookmarkMenu];
	[self autoAddItemsAction:self];
	
	[m_tableview setDelegate:self];
	[m_tableview setDataSource:self];
	[m_tableview registerForDraggedTypes:[NSArray
		arrayWithObject:kJFIgnorePrefControllerDropType]];
}

-(void)observeValueForKeyPath:(NSString*)keyPath
                     ofObject:(id)object
                       change:(NSDictionary*)change
                      context:(void*)context
{
	// NSLog(@"%s sync %@", _cmd, keyPath);
/*	NSArray* ary = [m_items arrangedObjects];
	int n = [ary count];

	NSMutableArray* result = [NSMutableArray arrayWithCapacity:n];

	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[JFIgnorePrefItem class]] == NO) continue;
		JFIgnorePrefItem* pi = (JFIgnorePrefItem*)thing;

		JFBookmarkMenuItem* mi = [[[JFBookmarkMenuItem alloc] init] autorelease];
		[mi setName:[pi name]];
		[mi setPath:[pi path]]; 
		[result addObject:mi];
	}
	
	[[JFBookmarkMenu shared] setBookmarkItems:result];
	[[JFBookmarkMenu shared] writeDefaults];
	[[JFBookmarkMenu shared] rebuildMenu]; */
}


-(NSString*)title {
	return NSLocalizedString(@"Hidden Files", @"Title of 'Hidden Files' preference pane");
}

-(NSString*)identifier {
	return @"IgnorePane";
}

-(NSImage*)image {
	// return [NSImage imageNamed:@"FavoriteItemsIcon"];
	return [NSImage imageNamed:@"NSAdvanced"];
}

-(void)populateWithDummyItems {
	// NSLog(@"%s", _cmd);

	[[m_items content] removeAllObjects];

	{
		JFIgnorePrefItem* item = [[[JFIgnorePrefItem alloc] init] autorelease];
		item.name = @".DS_Store";
		[m_items addObject:item];
	}
	{
		JFIgnorePrefItem* item = [[[JFIgnorePrefItem alloc] init] autorelease];
		item.name = @".git";
		[m_items addObject:item];
	}
	{
		JFIgnorePrefItem* item = [[[JFIgnorePrefItem alloc] init] autorelease];
		item.name = @".svn";
		[m_items addObject:item];
	}
}

-(IBAction)addOrRemoveItem:(id)sender {
	int clickedSegment = [sender selectedSegment];
    int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
	// NSLog(@"%s %i", _cmd, clickedSegmentTag);
	
	switch(clickedSegmentTag) {
	case 1: {
		[m_items insert:self]; 
		} break;
	case 2: {
		[m_items remove:self]; 
		break; }
	}
}

-(IBAction)autoAddItemsAction:(id)sender {
	NSArray* names = [NSArray arrayWithObjects:
		@".",
		@"..",
		@".DS_Store",
		nil
	];
	int n = [names count];
	for(int i=0; i<n; ++i) {
		JFIgnorePrefItem* item = [[[JFIgnorePrefItem alloc] init] autorelease];
		item.name = [names objectAtIndex:i];
		[m_items addObject:item];
	}
}



#pragma mark -
#pragma mark NSTableView row reordering


-(BOOL)tableView:(NSTableView*)tv 
	writeRowsWithIndexes:(NSIndexSet*)indexes 
	toPasteboard:(NSPasteboard*)pb
{
	if([indexes count] != 1) return NO;
	
	NSData* data = [NSKeyedArchiver archivedDataWithRootObject:indexes];
	[pb declareTypes:[NSArray arrayWithObject:kJFIgnorePrefControllerDropType] owner:self];
	[pb setData:data forType:kJFIgnorePrefControllerDropType];
	return YES;
}

-(NSDragOperation)tableView:(NSTableView*)tv
	validateDrop:(id <NSDraggingInfo>)info 
	proposedRow:(int)row 
	proposedDropOperation:(NSTableViewDropOperation)operation
{
	if( [info draggingSource] != m_tableview ) {
		return NSDragOperationNone;
	}
	if( operation == NSTableViewDropOn )
		[tv setDropRow:row dropOperation:NSTableViewDropAbove];
 
	return NSDragOperationMove;
}

-(BOOL)tableView:(NSTableView*)tv 
	acceptDrop:(id <NSDraggingInfo>)info 
	row:(int)row 
	dropOperation:(NSTableViewDropOperation)operation
{
	NSPasteboard* pb = [info draggingPasteboard];
	NSData* data = [pb dataForType:kJFIgnorePrefControllerDropType];
	if(data == nil) return NO;

	NSIndexSet* indexes = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	if(indexes == nil) return NO;
	
	NSUInteger index = [indexes firstIndex];
	if(index == NSNotFound) return NO;

	// NSLog(@"%s %i -> %i", _cmd, index, row);
	if(index < row) row--;

	id thing = [[[m_items arrangedObjects] objectAtIndex:index] retain];
	[m_items removeObjectAtArrangedObjectIndex:index];
	[m_items insertObject:thing atArrangedObjectIndex:row]; 
	[thing release];
	
	return YES;
}

@end
