/*********************************************************************
JFActionPrefController.mm - UI allowing you to customize the action menu

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#import "JFActionPrefController.h"
#import "JFActionMenu.h"


// for dragndrop row reordering, inside the table of action items
NSString* kJFActionPrefControllerDropType = @"JFActionPrefControllerDropType";


@implementation JFActionPrefItem
@synthesize name, icon, path;
@end


@interface JFActionPrefController (Private)
-(void)populateWithItemsFromActionMenu;
-(void)showOpenPanel;
-(void)addApplication:(NSString*)path;
@end

@implementation JFActionPrefController

- (void)awakeFromNib {

	[m_action_items addObserver: self
                     forKeyPath: @"arrangedObjects"      
                        options: NSKeyValueObservingOptionNew
                        context: NULL];

	[m_action_items addObserver: self
                     forKeyPath: @"arrangedObjects.name"
                        options: NSKeyValueObservingOptionNew
                        context: NULL];

	[self populateWithItemsFromActionMenu];
	
	[m_tableview setDelegate:self];
	[m_tableview setDataSource:self];
	[m_tableview registerForDraggedTypes:[NSArray
		arrayWithObject:kJFActionPrefControllerDropType]];
}

#pragma mark -
#pragma mark MBPreferencesController methods

-(NSString*)title {
	return NSLocalizedString(@"Action Menu", @"Title of 'Action Menu' preference pane");
}

-(NSString*)identifier {
	return @"ActionPane";
}

-(NSImage*)image {
	// return [NSImage imageNamed:@"NSAdvanced"];
	return [[NSWorkspace sharedWorkspace]
	 	iconForFileType:NSFileTypeForHFSTypeCode(kGenericApplicationIcon)];;
}


#pragma mark -
#pragma mark Misc methods

-(void)observeValueForKeyPath:(NSString*)keyPath
                     ofObject:(id)object
                       change:(NSDictionary*)change
                      context:(void*)context
{
	// NSLog(@"%s %@", _cmd, keyPath);
	
	NSArray* ary = [m_action_items arrangedObjects];
	int n = [ary count];

	NSMutableArray* result = [NSMutableArray arrayWithCapacity:n];

	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[JFActionPrefItem class]] == NO) continue;
		JFActionPrefItem* pi = (JFActionPrefItem*)thing;

		JFActionMenuItem* mi = [[[JFActionMenuItem alloc] init] autorelease];
		[mi setName:[pi name]];
		[mi setApp:[pi path]]; 
		[result addObject:mi];
	}
	
	[[JFActionMenu shared] setActionItems:result];
	[[JFActionMenu shared] writeDefaults];
	[[JFActionMenu shared] menu]; // rebuild the menu, so it's ready
}

-(void)populateWithItemsFromActionMenu {
	// NSLog(@"%s", _cmd);

	[[m_action_items content] removeAllObjects];
	
	NSArray* ary = [[JFActionMenu shared] actionItems];
	// NSLog(@"%s %@", _cmd, ary);

	NSMutableArray* result = [NSMutableArray arrayWithCapacity:[ary count]];

	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[JFActionMenuItem class]] == NO) continue;
		JFActionMenuItem* mi = (JFActionMenuItem*)thing;
		// NSLog(@"%s %@", _cmd, mi);

		NSString* name = [mi name];
		NSString* path = [mi app];

		NSImage* icon = [[NSWorkspace sharedWorkspace] iconForFile:path];

		JFActionPrefItem* item = [[[JFActionPrefItem alloc] init] autorelease];
		item.name = name;
		item.path = path;
		item.icon = icon;

		[result addObject:item];
	}

	[[m_action_items content] removeAllObjects];
	[m_action_items addObjects:result];
}

-(IBAction)addOrRemoveAction:(id)sender {
	int clickedSegment = [sender selectedSegment];
    int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
	// NSLog(@"%s %i", _cmd, clickedSegmentTag);
	
	switch(clickedSegmentTag) {
	case 1: [self showOpenPanel]; break;
	case 2: [m_action_items remove:self]; break;
	}
}

-(void)showOpenPanel {
	NSString* dir = @"/Applications";
	NSArray* types = [NSArray arrayWithObjects:@"public.executable",@"app",nil];
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	[panel setMessage:@"Choose an application or an executable"];
	[panel setPrompt:@"Choose"];
	[panel beginSheetForDirectory: dir
	              file: nil
	             types: types
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
	[self addApplication:[panel filename]];
}
	
	
-(void)addApplication:(NSString*)path {	
	if(path == nil) return;
	
	NSBundle* bundle = [NSBundle bundleWithPath:path];
	NSString* name = [bundle objectForInfoDictionaryKey:@"CFBundleName"];
	if(name == nil) {
		name = [path lastPathComponent];
	}
	
	NSImage* icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
	JFActionPrefItem* item = [[[JFActionPrefItem alloc] init] autorelease];
	item.name = name;
	item.path = path;
	item.icon = icon;
	[m_action_items addObject:item];
	// NSLog(@"%s %@", _cmd, item);
}

-(IBAction)autoAddApplicationsAction:(id)sender {
	NSWorkspace* ws = [NSWorkspace sharedWorkspace];
	NSArray* ary = [NSArray arrayWithObjects:
		// text editors
		@"TextMate",
		@"TextWrangler",
		
		// hex editors
		@"Hex Fiend",
		@"Hexedit",
		
		// compressed files
		@"The Unarchiver",
		
		// graphics
		@"Preview",
		@"Flickr Uploadr",
		@"VLC",
		@"NicePlayer",
		@"QuickTime Player",
		@"Paintbrush",
		@"Acorn",
		@"Pixelmator",
		@"Gimp",
		nil
	];

	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		[self addApplication:[ws fullPathForApplication:thing]];
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
	[pb declareTypes:[NSArray arrayWithObject:kJFActionPrefControllerDropType] owner:self];
	[pb setData:data forType:kJFActionPrefControllerDropType];
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
	NSData* data = [pb dataForType:kJFActionPrefControllerDropType];
	if(data == nil) return NO;

	NSIndexSet* indexes = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	if(indexes == nil) return NO;
	
	NSUInteger index = [indexes firstIndex];
	if(index == NSNotFound) return NO;

	// NSLog(@"%s %i -> %i", _cmd, index, row);
	if(index < row) row--;

	id thing = [[[m_action_items arrangedObjects] objectAtIndex:index] retain];
	[m_action_items removeObjectAtArrangedObjectIndex:index];
	[m_action_items insertObject:thing atArrangedObjectIndex:row]; 
	[thing release];
	
	return YES;
}

@end
