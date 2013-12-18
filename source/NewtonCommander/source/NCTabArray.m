//
//  NCTabArray.m
//  Newton Commander
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "NCLog.h"
#import "NCTabArray.h"


@implementation NCTabArrayItem

@synthesize workingDir = m_working_dir;
@synthesize cursorName = m_cursor_name;

-(id)init {
	self = [super init];
    if(self) {
		[self setWorkingDir:@"/"];    
		[self setCursorName:@""];
    }
    return self;
}

-(NSString*)description { 
	return [NSString stringWithFormat:
		@"MODE=%@ WORKINGDIR=%@ CURSOR=%@", 
		@"LIST",
		m_working_dir,
		m_cursor_name
	];
}

@end


@interface NCTabArray (Private)
-(NCTabArrayItem*)currentItem;

@end

@implementation NCTabArray

@synthesize identifier = m_identifier;

-(id)init {
	self = [super init];
    if(self) {
		m_index = 0;
		m_array = [[NSMutableArray alloc] initWithCapacity:100];

		NCTabArrayItem* item = [[NCTabArrayItem alloc] init];
		[m_array addObject:item];
    }
    return self;
}

+(NCTabArray*)arrayLeft {
	NCTabArray* ary = [[NCTabArray alloc] init];
	[ary setIdentifier:@"Left"];
	return ary;
}

+(NCTabArray*)arrayRight {
	NCTabArray* ary = [[NCTabArray alloc] init];
	[ary setIdentifier:@"Right"];
	return ary;
}

-(void)dealloc {
	m_array = nil;
	
}

-(NSString*)description { 
	NSMutableString* ms = [NSMutableString stringWithCapacity:10000]; 
	[ms appendFormat:@"NCTabArray(%@)=[", m_identifier];

	NSEnumerator* enumerator = [m_array objectEnumerator];
	NCTabArrayItem* item;
	int index = -1;
	while((item = [enumerator nextObject])) {
		index++;
		if(index == 0) [ms appendString:@"\n"];
		[ms appendFormat:@"    INDEX=%02i ", index];
		
		if(index == m_index) {
			[ms appendString:@"ACTIVE=YES "];
		} else {
			[ms appendString:@"ACTIVE=NO  "];
		}
		
		[ms appendFormat:@"%@,\n", item];
	}

	[ms appendString:@"]"];
	return [ms copy];
}

-(NCTabArrayItem*)currentItem {
	if(m_index < 0) return nil;
	int n = [m_array count];
	if(m_index >= n) return nil;
	
	id thing = [m_array objectAtIndex:m_index];
	if(![thing isKindOfClass:[NCTabArrayItem class]]) return nil;
	return (NCTabArrayItem*)thing;
}

-(void)setWorkingDir:(NSString*)wdir {
	[[self currentItem] setWorkingDir:wdir];
}

-(NSString*)workingDir {
	return [[self currentItem] workingDir];
}

-(void)setCursorName:(NSString*)name {
	[[self currentItem] setCursorName:name];
}

-(NSString*)cursorName {
	return [[self currentItem] cursorName];
}

-(int)numberOfTabs {
	return [m_array count];
}

-(int)selectedIndex {
	return m_index;
}

-(void)insertNewTab {
	// LOG_DEBUG(@"BEFORE %@", self);

	NCTabArrayItem* item = [[NCTabArrayItem alloc] init];
	int n = [m_array count];
	m_index++;
	if(m_index > n) m_index = n;
	[m_array insertObject:item atIndex:m_index];

	// LOG_DEBUG(@"AFTER %@", self);
}

-(void)firstTab {
	m_index = 0;
}

-(void)nextTab {
	// LOG_DEBUG(@"BEFORE %@", self);

	int n = [m_array count];
	m_index++;
	if(m_index >= n) m_index = 0;

	// LOG_DEBUG(@"AFTER %@", self);
}

-(void)prevTab {
	// LOG_DEBUG(@"BEFORE %@", self);

	int n = [m_array count];
	m_index--;
	if(m_index < 0) m_index = n - 1;

	// LOG_DEBUG(@"AFTER %@", self);
}

-(void)closeTab {
	// LOG_DEBUG(@"BEFORE %@", self);

	int n = [m_array count];
	if(n >= 2) {
		if((m_index < 0) || (m_index >= n)) return;
	
		[m_array removeObjectAtIndex:m_index];
		m_index--;
		if((m_index < 0) || (m_index >= n)) m_index = 0;            
	}

	// LOG_DEBUG(@"AFTER %@", self);
}



-(void)save {

	{
		NSMutableArray* ary = [NSMutableArray arrayWithCapacity:[m_array count]];
		NSEnumerator* enumerator = [m_array objectEnumerator];
		NCTabArrayItem* item;
		while((item = [enumerator nextObject])) {
			NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:5];
			{
				NSString* s = [item workingDir];
				if(![s isKindOfClass:[NSString class]]) s = @"/";
				[dict setObject:s forKey:@"Path"];
			}
			{
				NSString* s = [item cursorName];
				if(![s isKindOfClass:[NSString class]]) s = @"";
				[dict setObject:s forKey:@"Cursor"];
			}
			// [dict setValue:[item workingDir] forKey:@"path"];          
			// [dict setValue:[item scrollX] forKey:@"scroll-x"];
			// [dict setValue:[item scrollY] forKey:@"scroll-y"];
			[ary addObject:dict];
		}

		NSString* key = [NSString stringWithFormat:@"NCTabStates %@", m_identifier];
		[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:ary forKey:key];
	}

	{
		id obj = [NSNumber numberWithInt:m_index];
		NSString* key = [NSString stringWithFormat:@"NCTabIndex %@", m_identifier];
		[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:obj forKey:key];
	}
}

-(void)load {
	// LOG_DEBUG(@"NCTabArray loading user defaults for identifier: %@", m_identifier);
	m_index = 0;
	[m_array removeAllObjects];
	
	{
		NSString* key = [NSString stringWithFormat:@"NCTabIndex %@", m_identifier];
		id thing = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:key];

		if([thing isKindOfClass:[NSNumber class]]) {
			m_index = [(NSNumber*)thing intValue];
		}
	}
	
	do {
		NSString* key = [NSString stringWithFormat:@"NCTabStates %@", m_identifier];
		id thing = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:key];

		if(![thing isKindOfClass:[NSArray class]]) {
			break;
		}
		NSEnumerator* enumerator = [(NSArray*)thing objectEnumerator];
		while((thing = [enumerator nextObject])) {

			NCTabArrayItem* item = [[NCTabArrayItem alloc] init];
			[item setWorkingDir:@"/"];
			[item setCursorName:@""];
			[m_array addObject:item];
			

			if(![thing isKindOfClass:[NSDictionary class]]) {
				continue;
			}
			NSDictionary* dict = (NSDictionary*)thing;
			
			thing = [dict objectForKey:@"Path"];
			if([thing isKindOfClass:[NSString class]]) {
				NSString* s = (NSString*)thing;
				[item setWorkingDir:s];
			}

			thing = [dict objectForKey:@"Cursor"];
			if([thing isKindOfClass:[NSString class]]) {
				NSString* s = (NSString*)thing;
				[item setCursorName:s];
			}

		}
		
	} while(0);

	if([m_array count] < 1) {
		LOG_DEBUG(@"load didn't find any NCTabStates, inserting blank state");
		NCTabArrayItem* item = [[NCTabArrayItem alloc] init];
		[item setWorkingDir:@"/"];
		[item setCursorName:@""];
		[m_array addObject:item];
	}

	if(m_index < 0) m_index = 0;
	if(m_index > [m_array count]) m_index = 0;
	
	// LOG_DEBUG(@"load completed. self=%@", self);
}

@end
