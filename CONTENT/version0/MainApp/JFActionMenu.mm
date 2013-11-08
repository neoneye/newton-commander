/*********************************************************************
JFActionMenu.mm - the popup menu accessible within the main window

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#import "JFActionMenu.h"

NSString* kJFActionMenuItems = @"JFActionMenuItems";


@implementation JFActionMenuItem
@synthesize name, app;

-(void)encodeWithCoder:(NSCoder*)coder {
	[coder encodeObject:name forKey:@"actionName"];
	[coder encodeObject:app forKey:@"pathToExecutable"];
}

-(id)initWithCoder:(NSCoder*)coder {
	[super init];
	[self setName:[coder decodeObjectForKey:@"actionName"]];
	[self setApp:[coder decodeObjectForKey:@"pathToExecutable"]];
	return self;
}

@end

@interface JFActionMenu (Private)
@end

@implementation JFActionMenu

- (id)init {
    self = [super init];
	if(self) {
		m_action_items = [[NSMutableArray arrayWithCapacity:50] retain];
	   	m_menu = nil;
	 	m_path = nil;
		m_delegate = nil;
		m_dock_apps = nil;
	}
    return self;
}

-(void)dealloc {
	[m_action_items release];
	[m_menu release];
	[m_path release];     
	[m_dock_apps release];
    [super dealloc];
}

+(JFActionMenu*)shared {
    static JFActionMenu* shared = nil;
    if(!shared) {
        shared = [[JFActionMenu allocWithZone:NULL] init];
		[shared loadDefaults];
    }
    return shared;
}

-(void)setDelegate:(id)delegate {
	m_delegate = delegate;
}

-(void)setPath:(NSString*)path {
	[path retain]; 
	[m_path release]; 
	m_path = path; 
}

-(void)populateWithDummyData {
	[m_action_items removeAllObjects];
	
	NSArray* names = [NSArray arrayWithObjects:
		@"Edit with TextMate",
		@"HexEdit",
		@"Preview",
		nil
	];
	NSArray* apps = [NSArray arrayWithObjects:
		@"TextMate",
		@"HexEdit",
		@"Preview",
		nil
	];
	NSWorkspace* ws = [NSWorkspace sharedWorkspace];
	NSAssert([apps count] == [names count], @"must be same size");
	int n = [apps count];
	for(int i=0; i<n; ++i) {
		JFActionMenuItem* mi = [[[JFActionMenuItem alloc] init] autorelease];
		[mi setName:[names objectAtIndex:i]];
		[mi setApp:[ws fullPathForApplication:[apps objectAtIndex:i]]];
		[m_action_items addObject:mi];
	}
}

-(void)setActionItems:(NSArray*)items {
	
	// verify that the items are OK before assignment
	NSAssert([items isKindOfClass:[NSArray class]], @"must be an array");
	id thing;
	NSEnumerator* en = [items objectEnumerator];
	while(thing = [en nextObject]) {
		NSAssert([thing isKindOfClass:[JFActionMenuItem class]], @"must be a JFActionMenuItem");
		JFActionMenuItem* ami = (JFActionMenuItem*)thing;
		NSAssert([[ami name] isKindOfClass:[NSString class]], @"must be a string");
		NSAssert([[ami app] isKindOfClass:[NSString class]], @"must be a string");
	}

	[m_action_items setArray:items];
	[m_menu autorelease];
	m_menu = nil;
}

-(NSArray*)actionItems {
	// NSLog(@"%s %@", _cmd, m_action_items);
	return [[m_action_items copy] autorelease];
}

-(void)loadDefaults {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSData* data = [defaults dataForKey:kJFActionMenuItems];
	NSArray* ary = nil;
	if(data != nil) {
		ary = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	}
	if(ary == nil) {
		[self populateWithDummyData];
	} else {
		[self setActionItems:ary];
	}
}

-(void)writeDefaults {
	NSData* data = [NSKeyedArchiver archivedDataWithRootObject:m_action_items];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:data forKey:kJFActionMenuItems];
}

-(void)buildMenu {
	[m_menu autorelease];
	m_menu = nil;
	
	NSMenu* menu = [[[NSMenu alloc] initWithTitle:@"Action Menu"] autorelease];

	id thing;
	NSEnumerator* en = [m_action_items objectEnumerator];
	int tag_index = 1000;
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[JFActionMenuItem class]] == NO) {
			tag_index++;
			continue;
		}
		JFActionMenuItem* ami = (JFActionMenuItem*)thing;

		NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:[ami name] action:@selector(menuAction:) keyEquivalent:@""] autorelease];
		[mi setTag:tag_index];
		[mi setTarget:self];
		[menu addItem:mi];
		
		tag_index++;
	}
	
	// 
	[menu addItem:[NSMenuItem separatorItem]];

	NSMenu* dock_menu = nil;
	{
		NSMenu* submenu = [[[NSMenu alloc] initWithTitle:@"Dock"] autorelease];
		NSMenuItem* mi = [[[NSMenuItem alloc] init] autorelease];
		[mi setTitle:@"Dock"];
		[menu addItem:mi];
		[menu setSubmenu:submenu forItem:mi];
		dock_menu = submenu;
	}
	{
		NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
		NSDictionary* dock_dict = [ud persistentDomainForName:@"com.apple.dock"];
	    NSArray* dock_persistent_apps = [dock_dict valueForKey:@"persistent-apps"];

		[m_dock_apps release];
		m_dock_apps = [[NSMutableArray alloc] initWithCapacity:100];
	
		NSUInteger index = 0;
	
		for(NSDictionary* dict in dock_persistent_apps){
			NSString* label = [[dict valueForKey:@"tile-data"] 
				valueForKey:@"file-label"];
			if(label == nil) {
				NSLog(@"%s label is nil", _cmd);
				continue;
			}
		
			NSString* app_path = [[[dict valueForKey:@"tile-data"] 
				valueForKey:@"file-data"] valueForKey:@"_CFURLString"];
			if(app_path == nil) {
				NSLog(@"%s app_path is nil", _cmd);
				continue;
			}
		
			[m_dock_apps addObject:app_path];
		
			NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:label action:@selector(menuAction:) keyEquivalent:@""] autorelease];
			[mi setTag:2000 + index];
			[mi setTarget:self];
			[dock_menu addItem:mi];
			
			index++;
		}
		// NSLog(@"%s dock apps: %@", _cmd, m_dock_apps);
	}

	// 
	[menu addItem:[NSMenuItem separatorItem]];
	{
		NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:@"Customize…" action:@selector(menuAction:) keyEquivalent:@""] autorelease];
		[mi setTag:500];
		[mi setTarget:self];
		[menu addItem:mi];
	}

	m_menu = [menu retain];
}

-(NSMenu*)menu {
	if(m_menu == nil) {
		[self buildMenu];
	}
	return m_menu;
}

-(IBAction)menuAction:(id)sender {
	int tag = [sender tag];
	
	if(tag == 500) {
		if([m_delegate respondsToSelector:@selector(customizeActionMenu)]) {
			[m_delegate customizeActionMenu];
		} else {
			NSLog(@"JFActionMenu %s - delegate doesn't implement it", _cmd);
		}
		return;
	}
	
	if(tag < 1000) {
		// do nothing
	} else
	if(tag < 2000) {
		// open via the customized action menu
		int index = tag - 1000;
		int n = [m_action_items count];
		if(index >= n) return;

		id thing = [m_action_items objectAtIndex:index];
		if([thing isKindOfClass:[JFActionMenuItem class]] == NO) {
			return;
		}
		JFActionMenuItem* ami = (JFActionMenuItem*)thing;
		NSString* app = [ami app];

		if((m_path != nil) && (app != nil)) {
			[[NSWorkspace sharedWorkspace] openFile:m_path withApplication:app];
		}
	} else
	if(tag < 3000) {
		// open via one of the applications in the dock
		int index = tag - 2000;
		int n = [m_dock_apps count];
		if(index >= n) return;

		id thing = [m_dock_apps objectAtIndex:index];
		if([thing isKindOfClass:[NSString class]] == NO) {
			return;
		}
		NSString* app = (NSString*)thing;

		if((m_path != nil) && (app != nil)) {
			[[NSWorkspace sharedWorkspace] openFile:m_path withApplication:app];
		}
	}
}


@end
