//
//  NCPreferencesBookmarkController.m
//  NCCore
//
//  Created by Simon Strandgaard on 22/04/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NCPreferencesBookmarkController.h"
#import "NSImage+ImageNamedForClass.h"


// for dragndrop row reordering, inside the table
NSString* kNCPreferencesBookmarkControllerDropType = @"NCPreferencesBookmarkControllerDropType";

// for storing the menuitems in preferences (userdefualts)
NSString* kNCUserDefaultBookmarkItems = @"kNCUserDefaultBookmarkItems";


@implementation NCUserDefaultBookmarkItem
@synthesize name, path;

-(void)encodeWithCoder:(NSCoder*)coder {
	[coder encodeObject:name forKey:@"name"];
	[coder encodeObject:path forKey:@"path"];
}

-(id)initWithCoder:(NSCoder*)coder {
	if (!(self = [super init])) return nil;
	[self setName:[coder decodeObjectForKey:@"name"]];
	[self setPath:[coder decodeObjectForKey:@"path"]];
	return self;
}

+(void)saveDefaultItems:(NSArray*)items {
	NSData* data = [NSKeyedArchiver archivedDataWithRootObject:items];
	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:data forKey:kNCUserDefaultBookmarkItems];
}

+(NSArray*)loadDefaultItems {
	NSData* data = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:kNCUserDefaultBookmarkItems];
	return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

-(NSString*)description {
	return [NSString stringWithFormat:@"<name: %@  path: %@>", name, path];
}

@end


@implementation NCPreferencesBookmarkItem
@synthesize shortcut, name, path;

+(NCPreferencesBookmarkItem*)itemWithPath:(NSString*)path {	
	if(path == nil) return nil;
	NCPreferencesBookmarkItem* item = [[NCPreferencesBookmarkItem alloc] init];
	item.name = [path lastPathComponent];
	item.path = path;
	item.shortcut = @"none";
	return item;
}

+(NCPreferencesBookmarkItem*)itemWithName:(NSString*)name path:(NSString*)path {	
	NCPreferencesBookmarkItem* item = [[NCPreferencesBookmarkItem alloc] init];
	item.name = name;
	item.path = path;
	item.shortcut = @"none";
	return item;
}

@end



@interface NCPreferencesBookmarkController (Private)

-(void)updateShortcuts;

@end

@implementation NCPreferencesBookmarkController

- (void)awakeFromNib {

	/*
	when the user makes changes to the table 
	we use bindings to write the data to userdefautls
	*/
	[m_items addObserver: self
              forKeyPath: @"arrangedObjects"      
                 options: NSKeyValueObservingOptionNew
                 context: NULL];
	[m_items addObserver: self
              forKeyPath: @"arrangedObjects.name"
                 options: NSKeyValueObservingOptionNew
                 context: NULL];
	[m_items addObserver: self
              forKeyPath: @"arrangedObjects.path"
                 options: NSKeyValueObservingOptionNew
                 context: NULL];

	
	// allow reordering the rows
	[m_tableview setDelegate:self];
	[m_tableview setDataSource:self];
	[m_tableview registerForDraggedTypes:[NSArray
		arrayWithObject:kNCPreferencesBookmarkControllerDropType]];


	[self loadUserDefaults];
}


#pragma mark -
#pragma mark MBPreferencesController methods

- (NSString *)title {
	return NSLocalizedString(@"Bookmarks", @"Title of 'Bookmark' preference pane");
}

- (NSString *)identifier {
	return @"BookmarkPane";
}

- (NSImage *)image {
	return [NSImage imageNamed:@"bookmark_icon" forClass:[self class]];
}

#pragma mark -
#pragma mark Bindings / User defaults

-(void)observeValueForKeyPath:(NSString*)keyPath
                     ofObject:(id)object
                       change:(NSDictionary*)change
                      context:(void*)context
{
	// LOG_DEBUG(@"NCPreferencesMenuController %s %@", _cmd, keyPath);
	NSArray* ary = [m_items arrangedObjects];
	NSMutableArray* result = [NSMutableArray arrayWithCapacity:[ary count]];

	id thing;
	NSEnumerator* e = [ary objectEnumerator];
	while(thing = [e nextObject]) {
		if([thing isKindOfClass:[NCPreferencesBookmarkItem class]] == NO) continue;
		NCPreferencesBookmarkItem* pi = (NCPreferencesBookmarkItem*)thing;
		NCUserDefaultBookmarkItem* mi = [[NCUserDefaultBookmarkItem alloc] init];
		[mi setName:[pi name]];
		[mi setPath:[pi path]]; 
		[result addObject:mi];
	}
	
	// write items to user defaults
	[NCUserDefaultBookmarkItem saveDefaultItems:result];

	[self updateShortcuts];
}

-(void)loadUserDefaults {
	// LOG_DEBUG(@"%s", _cmd);

	// read items from user defaults
	NSArray* ary = [NCUserDefaultBookmarkItem loadDefaultItems];
	NSMutableArray* result = [NSMutableArray arrayWithCapacity:[ary count]];

	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[NCUserDefaultBookmarkItem class]] == NO) continue;
		NCUserDefaultBookmarkItem* mi = (NCUserDefaultBookmarkItem*)thing;
		NSString* name = [mi name];
		NSString* path = [mi path];

		NCPreferencesBookmarkItem* item = [[NCPreferencesBookmarkItem alloc] init];
		item.name = name;
		item.path = path;   
		item.shortcut = @"none";

		[result addObject:item];
	}

	[[m_items content] removeAllObjects];
	[m_items addObjects:result];
}

-(void)updateShortcuts {
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
	NSEnumerator* e = [[m_items arrangedObjects] objectEnumerator];
	while(thing = [e nextObject]) {
		if([thing isKindOfClass:[NCPreferencesBookmarkItem class]] == NO) {
			index++;
			continue;
		}
		NCPreferencesBookmarkItem* bi = (NCPreferencesBookmarkItem*)thing;
		
		NSString* s = @"";
		if(index < lut_size) {
			s = shortcut_lut[index];
		}
		
		[bi setShortcut:s];
		index++;
	}
}


#pragma mark -
#pragma mark Other methods

-(IBAction)autoAddBookmarksAction:(id)sender {
	NSString* home = NSHomeDirectory();
	NSArray* ary = [NSArray arrayWithObjects:
		[NCPreferencesBookmarkItem itemWithName:@"Desktop" 
			path:[home stringByAppendingPathComponent:@"Desktop"]],
		[NCPreferencesBookmarkItem itemWithName:@"Downloads" 
			path:[home stringByAppendingPathComponent:@"Downloads"]],
		[NCPreferencesBookmarkItem itemWithName:@"Home" path:home],
		[NCPreferencesBookmarkItem itemWithName:@"Volumes" path:@"/Volumes"],
		[NCPreferencesBookmarkItem itemWithName:@"Applications" path:@"/Applications"],
		[NCPreferencesBookmarkItem itemWithName:@"/" path:@"/"],
		[NCPreferencesBookmarkItem itemWithName:@"Movies" 
			path:[home stringByAppendingPathComponent:@"Movies"]],
		[NCPreferencesBookmarkItem itemWithName:@"Documents" 
			path:[home stringByAppendingPathComponent:@"Documents"]],
		[NCPreferencesBookmarkItem itemWithName:@"Music" 
			path:[home stringByAppendingPathComponent:@"Music"]],
		[NCPreferencesBookmarkItem itemWithName:@"Public" 
			path:[home stringByAppendingPathComponent:@"Public"]],
		[NCPreferencesBookmarkItem itemWithName:@"Pictures" 
			path:[home stringByAppendingPathComponent:@"Pictures"]],
		[NCPreferencesBookmarkItem itemWithName:@"Developer" path:@"/Developer"],
		[NCPreferencesBookmarkItem itemWithName:@"/var/log" path:@"/var/log"],
		[NCPreferencesBookmarkItem itemWithName:@"/etc" path:@"/etc"],
		[NCPreferencesBookmarkItem itemWithName:@"/tmp" path:@"/tmp"],
		[NCPreferencesBookmarkItem itemWithName:@"/var/run" path:@"/var/run"],
		nil
	];
	[m_items addObjects:ary];
}


-(IBAction)addBookmarkAction:(id)sender {
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

	NCPreferencesBookmarkItem* item = [NCPreferencesBookmarkItem itemWithPath:[panel filename]];
	if(item) [m_items addObject:item];
}


#pragma mark -
#pragma mark NSTableView row reordering


-(BOOL)tableView:(NSTableView*)tv 
	writeRowsWithIndexes:(NSIndexSet*)indexes 
	toPasteboard:(NSPasteboard*)pb
{
	if([indexes count] != 1) return NO;
	
	NSData* data = [NSKeyedArchiver archivedDataWithRootObject:indexes];
	[pb declareTypes:[NSArray arrayWithObject:kNCPreferencesBookmarkControllerDropType] owner:self];
	[pb setData:data forType:kNCPreferencesBookmarkControllerDropType];
	return YES;
}

-(NSDragOperation)tableView:(NSTableView*)tv
	validateDrop:(id <NSDraggingInfo>)info 
	proposedRow:(NSInteger)row 
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
	row:(NSInteger)row 
	dropOperation:(NSTableViewDropOperation)operation
{
	NSPasteboard* pb = [info draggingPasteboard];
	NSData* data = [pb dataForType:kNCPreferencesBookmarkControllerDropType];
	if(data == nil) return NO;

	NSIndexSet* indexes = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	if(indexes == nil) return NO;
	
	NSUInteger index = [indexes firstIndex];
	if(index == NSNotFound) return NO;

	// LOG_DEBUG(@"%s %i -> %i", _cmd, index, row);
	if(index < row) row--;

	id thing = [[m_items arrangedObjects] objectAtIndex:index];
	[m_items removeObjectAtArrangedObjectIndex:index];
	[m_items insertObject:thing atArrangedObjectIndex:row]; 

	return YES;
}

@end
