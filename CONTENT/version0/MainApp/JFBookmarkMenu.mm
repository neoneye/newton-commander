/*********************************************************************
JFBookmarkMenu.mm - the dropdown menu accessible from the main menu

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#import "JFBookmarkMenu.h"

NSString* kJFBookmarkMenuItems = @"JFBookmarkMenuItems";


@implementation JFBookmarkMenuItem
@synthesize name, path;

-(void)encodeWithCoder:(NSCoder*)coder {
	[coder encodeObject:name forKey:@"bookmarkName"];
	[coder encodeObject:path forKey:@"bookmarkPath"];
}

-(id)initWithCoder:(NSCoder*)coder {
	[super init];
	[self setName:[coder decodeObjectForKey:@"bookmarkName"]];
	[self setPath:[coder decodeObjectForKey:@"bookmarkPath"]];
	return self;
}

@end

@interface JFBookmarkMenu (Private)
-(void)populateWithDefaultData;
@end

@implementation JFBookmarkMenu

- (id)init {
    self = [super init];
	if(self) {
		m_items = [[NSMutableArray arrayWithCapacity:50] retain];
		m_delegate = nil;
		m_menu = nil;
	}
    return self;
}

-(void)dealloc {
	[m_menu release];
	[m_items release];
    [super dealloc];
}

+(JFBookmarkMenu*)shared {
    static JFBookmarkMenu* shared = nil;
    if(!shared) {
        shared = [[JFBookmarkMenu allocWithZone:NULL] init];
		[shared loadDefaults];
		// [shared populateWithDummyData];
    }
    return shared;
}

-(void)setMenu:(NSMenu*)menu {
	[menu retain];
	[m_menu release];
	m_menu = menu;
	// NSLog(@"%s %@", _cmd, menu);
}

-(void)setDelegate:(id)delegate {
	m_delegate = delegate;
}

-(void)populateWithDefaultData {
	[m_items removeAllObjects];

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
		@"Movies",
		@"Documents",
		@"Music",
		@"Pictures",
		@"Public",
		@"Applications",
		nil
	];
	NSString* home = NSHomeDirectory();
	NSArray* paths = [NSArray arrayWithObjects:
		[home stringByAppendingPathComponent:@"Desktop"],
		[home stringByAppendingPathComponent:@"Downloads"],
		home,
		[home stringByAppendingPathComponent:@"Movies"],
		[home stringByAppendingPathComponent:@"Documents"],
		[home stringByAppendingPathComponent:@"Music"],
		[home stringByAppendingPathComponent:@"Pictures"],
		[home stringByAppendingPathComponent:@"Public"],
		@"/Applications",
		nil
	];
	NSAssert([paths count] == [names count], @"must be same size");
	int n = [paths count];
	for(int i=0; i<n; ++i) {
		JFBookmarkMenuItem* mi = [[[JFBookmarkMenuItem alloc] init] autorelease];
		[mi setName:[names objectAtIndex:i]];
		[mi setPath:[paths objectAtIndex:i]];
		[m_items addObject:mi];
	}
	
	[self rebuildMenu];
}

-(void)setBookmarkItems:(NSArray*)items {
	
	// verify that the items are OK before assignment
	NSAssert([items isKindOfClass:[NSArray class]], @"must be an array");
	id thing;
	NSEnumerator* en = [items objectEnumerator];
	while(thing = [en nextObject]) {
		NSAssert([thing isKindOfClass:[JFBookmarkMenuItem class]], @"must be a JFBookmarkMenuItem");
		JFBookmarkMenuItem* mi = (JFBookmarkMenuItem*)thing;
		NSAssert([[mi name] isKindOfClass:[NSString class]], @"must be a string");
		NSAssert([[mi path] isKindOfClass:[NSString class]], @"must be a string");
	}

	[m_items setArray:items];
	// NSLog(@"%s %@", _cmd, m_items);
}

-(NSArray*)bookmarkItems {
	// NSLog(@"%s %@", _cmd, m_items);
	return [[m_items copy] autorelease];
}

-(void)loadDefaults {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSData* data = [defaults dataForKey:kJFBookmarkMenuItems];
	NSArray* ary = nil;
	if(data != nil) {
		ary = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	}
	if(ary == nil) {
		[self populateWithDefaultData];
	} else {
		[self setBookmarkItems:ary];
	}
}

-(void)writeDefaults {
	NSData* data = [NSKeyedArchiver archivedDataWithRootObject:m_items];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:data forKey:kJFBookmarkMenuItems];
}

-(void)rebuildMenu {
	// NSLog(@"%s %@", _cmd, m_menu);
	NSMenu* menu = m_menu;

	{
		// wipe all menu items
		int count = [menu numberOfItems];
		for(int i=count-1; i>=0; --i) {
			[menu removeItemAtIndex:i];
		}
	}

	NSString* shortcut_lut[] = {
		@"1", @"2", @"3", @"4", @"5",
		@"6", @"7", @"8", @"9", @"0",
	};

	int n = [m_items count];
	for(int j=0; j<10; ++j)
	for(int i=0; i<3; ++i) {
		int index = i * 10 + j;
		if(index >= n) continue;
		// NSLog(@"%s %i", _cmd, index);

		id thing = [m_items objectAtIndex:index];
		if([thing isKindOfClass:[JFBookmarkMenuItem class]] == NO) {
			continue;
		}
		JFBookmarkMenuItem* bmi = (JFBookmarkMenuItem*)thing;

		NSString* s = shortcut_lut[j];
		NSUInteger mask = NSCommandKeyMask;
		BOOL alternate = NO;
		if(i == 1) {
			mask |= NSAlternateKeyMask;
			alternate = YES;
		} else
		if(i == 2) {
			mask |= NSControlKeyMask;
			alternate = YES;
		}

		NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:[bmi name]
			action:@selector(menuAction:) keyEquivalent:s] autorelease];
		[mi setKeyEquivalentModifierMask:mask];
		[mi setAlternate:alternate];
		[mi setTag:index + 1000];
		[mi setTarget:self];
		[menu addItem:mi];
	}
	
	[menu addItem:[NSMenuItem separatorItem]];
	{
		NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:@"Customize…" action:@selector(menuAction:) keyEquivalent:@""] autorelease];
		[mi setTag:500];
		[mi setTarget:self];
		[menu addItem:mi];
	}

	// NSLog(@"%s %@", _cmd, menu);
}

-(IBAction)menuAction:(id)sender {
	int tag = [sender tag];
	
	if(tag == 500) {
		if([m_delegate respondsToSelector:@selector(customizeBookmarkMenu)]) {
			[m_delegate customizeBookmarkMenu];
		} else {
			NSLog(@"JFBookmarkMenu %s - delegate doesn't implement it", _cmd);
		}
		return;
	}


	if(tag < 1000) return;
	int index = tag - 1000;
	int n = [m_items count];
	if(index >= n) return;

	id thing = [m_items objectAtIndex:index];
	if([thing isKindOfClass:[JFBookmarkMenuItem class]] == NO) {
		return;
	}
	JFBookmarkMenuItem* mi = (JFBookmarkMenuItem*)thing;
	NSString* path = [mi path];

	if(path == nil) {
		NSLog(@"%s path is nil", _cmd);
		return;
	}
	if([m_delegate respondsToSelector:@selector(jumpToBookmarkPath:)]) {
		[m_delegate jumpToBookmarkPath:path];
	} else {
		NSLog(@"JFBookmarkMenu jumpToBookmarkPath: - delegate doesn't implement it", _cmd);
	}
}

@end
