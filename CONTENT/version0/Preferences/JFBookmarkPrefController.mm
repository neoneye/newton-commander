/*********************************************************************
JFBookmarkPrefController.mm - bookmark settings

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#import "JFBookmarkPrefController.h"
#import "JFBookmarkMenu.h"


// for dragndrop row reordering, inside the table of action items
NSString* kJFBookmarkPrefControllerDropType = @"JFBookmarkPrefControllerDropType";


@implementation JFBookmarkPrefItem
@synthesize name, path, shortcut;
@end


@implementation JFBookmarkPrefController

- (void)awakeFromNib {
	// NSLog(@"%s observe bookmarks", _cmd);
	[m_bookmark_items addObserver: self
                     forKeyPath: @"arrangedObjects"      
                        options: NSKeyValueObservingOptionNew
                        context: NULL];

	[m_bookmark_items addObserver: self
                     forKeyPath: @"arrangedObjects.name"
                        options: NSKeyValueObservingOptionNew
                        context: NULL];

	[m_bookmark_items addObserver: self
                     forKeyPath: @"arrangedObjects.path"
                        options: NSKeyValueObservingOptionNew
                        context: NULL];

	[self populateWithItemsFromBookmarkMenu];
	// [self autoAddBookmarksAction:self];
	
	[m_tableview setDelegate:self];
	[m_tableview setDataSource:self];
	[m_tableview registerForDraggedTypes:[NSArray
		arrayWithObject:kJFBookmarkPrefControllerDropType]];
}

-(void)observeValueForKeyPath:(NSString*)keyPath
                     ofObject:(id)object
                       change:(NSDictionary*)change
                      context:(void*)context
{
	// NSLog(@"%s sync %@", _cmd, keyPath);
	NSArray* ary = [m_bookmark_items arrangedObjects];
	int n = [ary count];

	NSMutableArray* result = [NSMutableArray arrayWithCapacity:n];

	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[JFBookmarkPrefItem class]] == NO) continue;
		JFBookmarkPrefItem* pi = (JFBookmarkPrefItem*)thing;

		JFBookmarkMenuItem* mi = [[[JFBookmarkMenuItem alloc] init] autorelease];
		[mi setName:[pi name]];
		[mi setPath:[pi path]]; 
		[result addObject:mi];
	}
	
	[[JFBookmarkMenu shared] setBookmarkItems:result];
	[[JFBookmarkMenu shared] writeDefaults];
	[[JFBookmarkMenu shared] rebuildMenu];
}


-(NSString*)title {
	return NSLocalizedString(@"Bookmarks", @"Title of 'Bookmarks' preference pane");
}

-(NSString*)identifier {
	return @"BookmarkPane";
}

-(NSImage*)image {
	// return [NSImage imageNamed:@"FavoriteItemsIcon"];
	return [NSImage imageNamed:@"NSAdvanced"];
}

-(void)reassignShortcuts {
	NSArray* ary = [m_bookmark_items arrangedObjects];
	int n = [ary count];

	NSString* shortcut_lut[] = {
		@"⌘1", @"⌘2", @"⌘3", @"⌘4", @"⌘5",
		@"⌘6", @"⌘7", @"⌘8", @"⌘9", @"⌘0",
		@"⌥⌘1", @"⌥⌘2", @"⌥⌘3", @"⌥⌘4", @"⌥⌘5",
		@"⌥⌘6", @"⌥⌘7", @"⌥⌘8", @"⌥⌘9", @"⌥⌘0",
		@"⌃⌘1", @"⌃⌘2", @"⌃⌘3", @"⌃⌘4", @"⌃⌘5",
		@"⌃⌘6", @"⌃⌘7", @"⌃⌘8", @"⌃⌘9", @"⌃⌘0",
	};
	const int lut_size = sizeof(shortcut_lut) / sizeof(NSString*);

	int index = 0;
	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[JFBookmarkPrefItem class]] == NO) {
			index++;
			continue;
		}
		JFBookmarkPrefItem* bi = (JFBookmarkPrefItem*)thing;
		
		NSString* s = @"";
		if(index < lut_size) {
			s = shortcut_lut[index];
		}
		
		[bi setShortcut:s];
		
		index++;
	}
}

-(void)populateWithItemsFromBookmarkMenu {
	// NSLog(@"%s", _cmd);

	NSArray* ary = [[JFBookmarkMenu shared] bookmarkItems];
	// NSLog(@"%s %@", _cmd, ary);

	NSMutableArray* result = [NSMutableArray arrayWithCapacity:[ary count]];

	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[JFBookmarkMenuItem class]] == NO) continue;
		JFBookmarkMenuItem* mi = (JFBookmarkMenuItem*)thing;
		// NSLog(@"%s %@", _cmd, mi);

		NSString* name = [mi name];
		NSString* path = [mi path];

		JFBookmarkPrefItem* item = [[[JFBookmarkPrefItem alloc] init] autorelease];
		item.name = name;
		item.path = path;

		[result addObject:item];
	}

	[[m_bookmark_items content] removeAllObjects];
	[m_bookmark_items addObjects:result];
	
	[self reassignShortcuts];
}

-(void)populateWithDummyItems {
	// NSLog(@"%s", _cmd);

	[[m_bookmark_items content] removeAllObjects];

	{
		JFBookmarkPrefItem* item = [[[JFBookmarkPrefItem alloc] init] autorelease];
		item.name = @"Code";
		item.path = @"/Volumes/Data/code";
		[m_bookmark_items addObject:item];
	}
	{
		JFBookmarkPrefItem* item = [[[JFBookmarkPrefItem alloc] init] autorelease];
		item.name = @"Downloads";
		item.path = @"/Users/neoneye/Downloads";
		[m_bookmark_items addObject:item];
	}
	{
		JFBookmarkPrefItem* item = [[[JFBookmarkPrefItem alloc] init] autorelease];
		item.name = @"include";
		item.path = @"/usr/include";
		[m_bookmark_items addObject:item];
	}
	[self reassignShortcuts];
}

-(IBAction)addOrRemoveBookmark:(id)sender {
	int clickedSegment = [sender selectedSegment];
    int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
	// NSLog(@"%s %i", _cmd, clickedSegmentTag);
	
	switch(clickedSegmentTag) {
	case 1: [self showOpenPanel]; break;
	case 2: {
		[m_bookmark_items remove:self]; 
		[self reassignShortcuts];
		break; }
	}
}

-(void)showOpenPanel {
	NSString* dir = NSHomeDirectory();
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	[panel setMessage:@"Choose a directory"];
	[panel setPrompt:@"Choose"];
	[panel setCanChooseDirectories:YES]; 
	[panel setCanChooseFiles:NO]; 
	[panel setCanCreateDirectories:YES]; 
	[panel setResolvesAliases:YES]; 
	[panel setAllowsMultipleSelection:NO]; 
	[panel beginSheetForDirectory: dir
	              file: nil
	             types: nil
	    modalForWindow: [[self view] window]
	     modalDelegate: self
	    didEndSelector: @selector(openPanelDidEnd:returnCode:contextInfo:)
	       contextInfo: nil
	];
}

-(void)openPanelDidEnd:(NSOpenPanel*)panel 
            returnCode:(int)rc 
           contextInfo:(void*)ctx
{
	if(rc != NSOKButton) {
		return;
	}
	NSString* path_to_folder = [panel filename];
	[self addBookmark:path_to_folder];
}

-(void)addBookmark:(NSString*)path {	
	if(path == nil) return;
	
	NSString* name = [path lastPathComponent];

	JFBookmarkPrefItem* item = [[[JFBookmarkPrefItem alloc] init] autorelease];
	item.name = name;
	item.path = path;
	[m_bookmark_items addObject:item];
	// NSLog(@"%s %@", _cmd, item);

	[self reassignShortcuts];
}

-(IBAction)autoAddBookmarksAction:(id)sender {
	/*
	IDEA: use NSSearchPathForDirectoriesInDomains
	
	NSArray *paths;
    NSFileManager *mgr = [NSFileManager defaultManager];

    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);	
	*/

	NSArray* names = [NSArray arrayWithObjects:
		@"Desktop",        
		@"Downloads",
		@"Home",
		@"Volumes",
		@"Movies",
		@"Documents",
		@"Music",
		@"Public",
		@"Pictures",
		@"Applications",
		// -----------
		@"Root",
		@"var log",
		@"usr include",
		@"Developer",
		@"Utilities",
		@"Frameworks",
		@"Library",
		@"Examples",
		@"SDKs",
		@"Documentation",
		// ------------
		@"etc",
		@"tmp",
		@"run",
		@"usr bin",
		@"usr sbin",
		@"usr local bin",
		@"usr X11 bin",
		@"bin",
		@"sbin",
		@"usr share",
		nil
	];
	NSString* home = NSHomeDirectory();
	NSArray* paths = [NSArray arrayWithObjects:
		[home stringByAppendingPathComponent:@"Desktop"],
		[home stringByAppendingPathComponent:@"Downloads"],
		home,
		@"/Volumes",
		[home stringByAppendingPathComponent:@"Movies"],
		[home stringByAppendingPathComponent:@"Documents"],
		[home stringByAppendingPathComponent:@"Music"],
		[home stringByAppendingPathComponent:@"Public"],
		[home stringByAppendingPathComponent:@"Pictures"],
		@"/Applications",
		// -----------
		@"/",
		@"/var/log",
		@"/usr/include",
		@"/Developer",
		@"/Applications/Utilities",
		@"/System/Library/Frameworks",
		@"/Library",
		@"/Developer/Examples",
		@"/Developer/SDKs",
		@"/Developer/Documentation",
		// ------------
		@"/etc",
		@"/tmp",
		@"/var/run",
		@"/usr/bin",
		@"/usr/sbin",
		@"/usr/local/bin",
		@"/usr/X11/bin",
		@"/bin",
		@"/sbin",
		@"/usr/share",
		nil
	];
	NSAssert([paths count] == [names count], @"must be same size");
	int n = [paths count];
	for(int i=0; i<n; ++i) {
		JFBookmarkPrefItem* item = [[[JFBookmarkPrefItem alloc] init] autorelease];
		item.name = [names objectAtIndex:i];
		item.path = [paths objectAtIndex:i];
		[m_bookmark_items addObject:item];
	}

	[self reassignShortcuts];
}



#pragma mark -
#pragma mark NSTableView row reordering


-(BOOL)tableView:(NSTableView*)tv 
	writeRowsWithIndexes:(NSIndexSet*)indexes 
	toPasteboard:(NSPasteboard*)pb
{
	if([indexes count] != 1) return NO;
	
	NSData* data = [NSKeyedArchiver archivedDataWithRootObject:indexes];
	[pb declareTypes:[NSArray arrayWithObject:kJFBookmarkPrefControllerDropType] owner:self];
	[pb setData:data forType:kJFBookmarkPrefControllerDropType];
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
	NSData* data = [pb dataForType:kJFBookmarkPrefControllerDropType];
	if(data == nil) return NO;

	NSIndexSet* indexes = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	if(indexes == nil) return NO;
	
	NSUInteger index = [indexes firstIndex];
	if(index == NSNotFound) return NO;

	// NSLog(@"%s %i -> %i", _cmd, index, row);
	if(index < row) row--;

	id thing = [[[m_bookmark_items arrangedObjects] objectAtIndex:index] retain];
	[m_bookmark_items removeObjectAtArrangedObjectIndex:index];
	[m_bookmark_items insertObject:thing atArrangedObjectIndex:row]; 
	[thing release];
	
	[self reassignShortcuts];
	
	return YES;
}

@end
