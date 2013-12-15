//
//  NCPreferencesMenuController.m
//  NCCore
//
//  Created by Simon Strandgaard on 24/03/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NCPreferencesMenuController.h"


// for dragndrop row reordering, inside the table
NSString* kNCPreferencesMenuControllerDropType = @"NCPreferencesMenuControllerDropType";


@implementation NCUserDefaultMenuItem
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

+(void)saveDefaultItems:(NSArray*)items forKey:(NSString*)key {
	NSData* data = [NSKeyedArchiver archivedDataWithRootObject:items];
	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:data forKey:key];
}

+(NSArray*)loadDefaultItemsForKey:(NSString*)key {
	NSData* data = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:key];
	return data ? [NSKeyedUnarchiver unarchiveObjectWithData:data] : nil;
}

@end





@implementation NCPreferencesMenuItem
@synthesize name, icon, path;

+(NCPreferencesMenuItem*)itemWithPath:(NSString*)path {	
	if(path == nil) return nil;
	
	NSBundle* bundle = [NSBundle bundleWithPath:path];
	NSString* name = [bundle objectForInfoDictionaryKey:@"CFBundleName"];
	if(name == nil) {
		name = [path lastPathComponent];
	}
	
	NSImage* icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
	NCPreferencesMenuItem* item = [[NCPreferencesMenuItem alloc] init];
	item.name = name;
	item.path = path;
	item.icon = icon;
	return item;
}

@end


@interface NCPreferencesMenuController (Private)

-(void)loadUserDefaults;

@end


@implementation NCPreferencesMenuController


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

	
	// allow reordering the rows
	[m_tableview setDelegate:self];
	[m_tableview setDataSource:self];
	[m_tableview registerForDraggedTypes:[NSArray
		arrayWithObject:kNCPreferencesMenuControllerDropType]];


	[self loadUserDefaults];
}


#pragma mark -
#pragma mark MBPreferencesController methods

- (NSString *)title
{
	return NSLocalizedString(@"Menu", @"Title of 'Menu' preference pane");
}

- (NSString *)identifier
{
	return @"MenuPane";
}

- (NSImage *)image
{
	return [[NSWorkspace sharedWorkspace]
	 	iconForFileType:NSFileTypeForHFSTypeCode(kGenericApplicationIcon)];;
}

#pragma mark -
#pragma mark User defaults

-(NSString*)userDefaultIdentifier {
	return @"MenuActions";
}

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
		if([thing isKindOfClass:[NCPreferencesMenuItem class]] == NO) continue;
		NCPreferencesMenuItem* pi = (NCPreferencesMenuItem*)thing;
		NCUserDefaultMenuItem* mi = [[NCUserDefaultMenuItem alloc] init];
		[mi setName:[pi name]];
		[mi setPath:[pi path]]; 
		[result addObject:mi];
	}
	
	// write items to user defaults
	[NCUserDefaultMenuItem saveDefaultItems:result forKey:[self userDefaultIdentifier]];
}

-(void)loadUserDefaults {
	// LOG_DEBUG(@"%s", _cmd);

	// read items from user defaults
	NSArray* ary = [NCUserDefaultMenuItem loadDefaultItemsForKey:[self userDefaultIdentifier]];

	NSMutableArray* result = [NSMutableArray arrayWithCapacity:[ary count]];
	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[NCUserDefaultMenuItem class]] == NO) continue;
		NCUserDefaultMenuItem* mi = (NCUserDefaultMenuItem*)thing;
		NSString* name = [mi name];
		NSString* path = [mi path];
		NSImage* icon = [[NSWorkspace sharedWorkspace] iconForFile:path];

		NCPreferencesMenuItem* item = [[NCPreferencesMenuItem alloc] init];
		item.name = name;
		item.path = path;
		item.icon = icon;

		[result addObject:item];
	}

	[[m_items content] removeAllObjects];
	[m_items addObjects:result];
}


#pragma mark -
#pragma mark Other methods

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

	NSMutableArray* result = [NSMutableArray array];
	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		NSString* path = [ws fullPathForApplication:thing];
		NCPreferencesMenuItem* item = [NCPreferencesMenuItem itemWithPath:path];
		if(item) [result addObject:item];
	}
	[m_items addObjects:result];
}

-(IBAction)addApplicationAction:(id)sender {
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
	
	NCPreferencesMenuItem* item = [NCPreferencesMenuItem itemWithPath:[panel filename]];
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
	[pb declareTypes:[NSArray arrayWithObject:kNCPreferencesMenuControllerDropType] owner:self];
	[pb setData:data forType:kNCPreferencesMenuControllerDropType];
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
	NSData* data = [pb dataForType:kNCPreferencesMenuControllerDropType];
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


@implementation NCPreferencesLeftMenuController

- (NSString *)title {
	return NSLocalizedString(@"Left Menu", @"Title of 'LeftMenu' preference pane");
}

- (NSString *)identifier {
	return @"LeftMenuPane";
}

-(NSString*)userDefaultIdentifier {
	return @"LeftMenuActions";
}

+(NSArray*)loadDefaultItems {
	return [NCUserDefaultMenuItem loadDefaultItemsForKey:@"LeftMenuActions"];
}

@end

@implementation NCPreferencesRightMenuController

- (NSString *)title {
	return NSLocalizedString(@"Right Menu", @"Title of 'RightMenu' preference pane");
}

- (NSString *)identifier {
	return @"RightMenuPane";
}

-(NSString*)userDefaultIdentifier {
	return @"RightMenuActions";
}

+(NSArray*)loadDefaultItems {
	return [NCUserDefaultMenuItem loadDefaultItemsForKey:@"RightMenuActions"];
}

@end


