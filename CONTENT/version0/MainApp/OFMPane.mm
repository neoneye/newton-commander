/*********************************************************************
OFMPane.mm - controller for the left/right work areas in the UI

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>

TODO: rename to "Lister", this seems to be what it's named in
most other commanders I have seen. Or "Side" or "TabPanel"

TODO: get rid of the path-control view. It's IO bound and sux.

IDEA: there are an overhead of ~40 msec for every request to the
Discover program. I suspect that it's the KCDiscoverStat system
that hangs up the system somehow. If just I can figure out where 
the bottleneck are located. This would make me happy.

*********************************************************************/
#include "OFMPane.h"
#include "NSImage+QuickLook.h"
#include "OPPartialSearch.h"
#include "KCDiscover.h"
#include "KCDiscoverStatistics.h"
#include "DirCache.h"
#include "PanelTable.h"
#include "JFSizeInfoCell.h"
#include "JFDateInfoCell.h"
#include "JFPermissionInfoCell.h"
#include "NCVolumeInfo.h"
#include <vector>
#include <sys/types.h>
#include <sys/stat.h>

#import "JFActionMenu.h"

enum {
	kTableMenuSortByNameType     = 10001,
	kTableMenuSortBySizeType     = 10002,
	kTableMenuSortByName         = 10003,
	kTableMenuSortByName_Reverse = 10004,
	kTableMenuSortBySize         = 10005,
	kTableMenuSortBySize_Reverse = 10006,
	kTableMenuUnsorted           = 10007,
	kTableMenuShowHiddenFiles    = 40001,
};


// #define DONT_SHOW_INFO


@interface MyClass : NSObject {
	NSString* foo;
}
-(void)setFoo:(NSString*)s;
-(NSString*)foo;
@end

@implementation MyClass

- (id)init {
    self = [super init];
	if(self) {
		foo = nil;
	}
    return self;
}

-(void)setFoo:(NSString*)s {
	s = [s copy];
	[foo release];
	foo = s;
}

-(NSString*)foo {
	return [[foo retain] autorelease];
}

-(NSString*)description {
	return [NSString stringWithFormat:@"%@", foo];
}

-(void)dealloc {
	[foo release];
	
    [super dealloc];
}

@end


@interface OFMPane (Private)

-(void)showActionMenu;
-(BOOL)isDirForRow:(int)row;

-(int)finderLabelCPath:(NSString*)path;

-(NSAttributedString*)infoStringInfo1;

@end

@implementation OFMPane

-(id)initWithName:(NSString*)name {
    self = [super init];
	if(self) {

		m_delegate = nil;
		
		m_name = [name retain];
		
		m_tableview = nil;
		m_textview = nil;
		m_path_combobox = nil;
		m_quicklook_button = nil;
		m_tabview = nil;
		m_searchfield = nil;
		m_discover_stat_items = nil;
		
		m_path = nil;
		
		m_font_tableview = nil;
		m_font_textview = nil;
		
		m_row = 0;   
		m_active_infotab = 0;
		
		m_info = nil;                    
		m_info_attr1 = nil;
		m_info_attr2 = nil;
		
		m_wrapper = nil;
		
		m_show_hidden_files = NO;
		m_volume_info = [[NCVolumeInfo alloc] init];
		
		m_discover_stat_item = nil;
		m_time_change_path = 0;
		m_time_has_names = 0;
		m_time_has_dirinfo = 0;
		m_time_has_sizes = 0;
		
		m_size_info_cell = nil;
		m_date_info_cell = nil;
		m_permission_info_cell = nil;
		
		m_cache_item_timestamp = 0;
		
		m_transaction_id = -1;

		m_partial_search = [[OPPartialSearch alloc] initWithCapacity:100];
		[m_partial_search setIgnoreCase:YES];
		
		for(int i=0; i<ATTRIBUTES_LAST; ++i)
			m_table_attributes[i] = nil;

		for(int i=0; i<IMAGES_LAST; ++i)
			m_images[i] = nil;
		
		m_task = nil;
		m_task_output = [[NSMutableString alloc] initWithCapacity:1000];
		
		m_breadcrum_stack = [[NSMutableArray alloc] initWithCapacity:100];

		m_panel_table = [[PanelTable alloc] init];
		[m_panel_table setSortOrderString:@"tn"];
		
		m_request_is_pending = YES;

		
		[self changePath:NSHomeDirectory()];
		
		{
			NSFont* font = [NSFont systemFontOfSize:14];

			[self setTextViewFont:font];
			[self setTableViewFont:font];
			[self reloadTableAttributes];
		}

		{
			m_images[IMAGES_DIR] = [[NSImage imageNamed: @"SmallGenericFolderIcon"] retain];
			m_images[IMAGES_DIR_LINK] = [[NSImage imageNamed: @"SmallGenericFolderIconLink"] retain];
			m_images[IMAGES_FILE] = [[NSImage imageNamed: @"SmallGenericDocumentIcon"] retain];
			m_images[IMAGES_FILE_LINK] = [[NSImage imageNamed: @"SmallGenericDocumentIconLink"] retain];
			m_images[IMAGES_OTHER] = [[NSImage imageNamed: @"unknown"] retain];
			m_images[IMAGES_OTHER_LINK] = [[NSImage imageNamed: @"unknown_link"] retain];
			m_images[IMAGES_LOADING] = [[NSImage imageNamed: @"loading"] retain];
			m_images[IMAGES_PERM000] = [[NSImage imageNamed: @"permissions_000"] retain];
			m_images[IMAGES_PERM001] = [[NSImage imageNamed: @"permissions_001"] retain];
			m_images[IMAGES_PERM010] = [[NSImage imageNamed: @"permissions_010"] retain];
			m_images[IMAGES_PERM011] = [[NSImage imageNamed: @"permissions_011"] retain];
			m_images[IMAGES_PERM100] = [[NSImage imageNamed: @"permissions_100"] retain];
			m_images[IMAGES_PERM101] = [[NSImage imageNamed: @"permissions_101"] retain];
			m_images[IMAGES_PERM110] = [[NSImage imageNamed: @"permissions_110"] retain];
			m_images[IMAGES_PERM111] = [[NSImage imageNamed: @"permissions_111"] retain];
		}
		
		{
			NSString* fontname1 = @"BitstreamVeraSansMono-Roman";
			NSString* fontname2 = @"Monaco";
			float fontsize = 14;
			NSFont* font = [NSFont fontWithName:fontname1 size:fontsize];
			if(font == nil) {
				font = [NSFont fontWithName:fontname2 size:fontsize];
			}
			NSFont* font1 = font;
			
#if 1
			font1 = nil; // force non-monospaced font
#endif
			if(font1 == nil) {
				font1 = [NSFont systemFontOfSize: fontsize];
			}
			NSFont* font2 = [[[NSFontManager sharedFontManager] convertFont:font1
				toHaveTrait:NSBoldFontMask] retain];
			
			if(font2 == nil) {
				font2 = [NSFont systemFontOfSize: fontsize];
			}

			m_info_attr1 = [[NSDictionary dictionaryWithObjectsAndKeys:
				font1, NSFontAttributeName, 
				[NSColor grayColor], NSForegroundColorAttributeName, 
				nil
			] retain];
			m_info_attr2 = [[NSDictionary dictionaryWithObjectsAndKeys:
				font2, NSFontAttributeName, 
				[NSColor blackColor], NSForegroundColorAttributeName, 
				nil
			] retain];
		}
		
		{
			[m_partial_search setNormalAttributes:m_info_attr1];
			[m_partial_search setMatchAttributes:m_info_attr2];
		}

	}
    return self;
}

-(void)setDelegate:(id)delegate {
	m_delegate = delegate;
}

-(void)setWrapper:(KCDiscover*)w {
	[w retain];
	[m_wrapper autorelease];
	m_wrapper = w;
}

-(void)setTableView:(NSTableView*)tv {
	[tv retain];
	[m_tableview autorelease];
	m_tableview = tv;
}

-(void)setTextView:(NSTextView*)tv {
	[tv retain];
	[m_textview autorelease];
	m_textview = tv;
}

-(void)setPathComboBox:(NSComboBox*)pc {
	[pc retain];
	[m_path_combobox autorelease];
	m_path_combobox = pc;
}

-(void)setQuickLookButton:(NSButton*)b {
	[b retain];
	[m_quicklook_button autorelease];
	m_quicklook_button = b;
}

-(void)setTabView:(NSTabView*)tv {
	[tv retain];
	[m_tabview autorelease];
	m_tabview = tv;
}

-(void)setSearchField:(NSSearchField*)sf {
	[sf retain];
	[m_searchfield autorelease];
	m_searchfield = sf;
}

-(void)setDiscoverStatItems:(NSArrayController*)ac {
	[ac retain];
	[m_discover_stat_items autorelease];
	m_discover_stat_items = ac;
}

-(void)installCustomCells {
	// NSLog(@"%s", _cmd);
	
	NSAssert(m_size_info_cell == nil, @"m_size_info_cell must be already initialized");
	NSAssert(m_date_info_cell == nil, @"m_date_info_cell must be already initialized");
	NSAssert(m_permission_info_cell == nil, @"m_permission_info_cell must be already initialized");
	
	NSAssert(m_tableview != nil, @"table must be non-nil");

	{
		NSTableColumn* col = [m_tableview tableColumnWithIdentifier:@"filesize"];
		NSAssert(col != nil, @"no filesize column");
		m_size_info_cell = [[JFSizeInfoCell alloc] init];
		[m_size_info_cell setLayout:kJFSizeInfoCellLayoutBarLeft];
		// [m_size_info_cell setLayout:kJFSizeInfoCellLayoutBarMiddle];
		// [m_size_info_cell setLayout:kJFSizeInfoCellLayoutBarRight];
		// [m_size_info_cell setLayout:kJFSizeInfoCellLayoutSparkLeft];
		// [m_size_info_cell setLayout:kJFSizeInfoCellLayoutSparkRight];
		[col setDataCell:m_size_info_cell];
	}
	{
		NSTableColumn* col = [m_tableview tableColumnWithIdentifier:@"dates"];
		NSAssert(col != nil, @"no dates column");
		m_date_info_cell = [[JFDateInfoCell alloc] init];
		[col setDataCell:m_date_info_cell];
	}
	{
		NSTableColumn* col = [m_tableview tableColumnWithIdentifier:@"permissions"];
		NSAssert(col != nil, @"no dates column");
		m_permission_info_cell = [[JFPermissionInfoCell alloc] init];
		[col setDataCell:m_permission_info_cell];
	}
}

-(void)refreshUI {
	[self reloadTableData];
	[self refreshInfo];
}

-(void)refreshInfo {
	[[m_textview textStorage] setAttributedString:[self info]];
}

-(void)reloadTableData {
	[m_tableview reloadData];
	NSUInteger n = [m_panel_table visibleNumberOfRows];
	
	NSImage* bg = nil;
	if(m_request_is_pending) {
		bg = [NSImage imageNamed:@"info_fsbusy"];
	} else
	if(n == 0) {
		bg = [NSImage imageNamed:@"info_emptydir"];
	} else {
		// don't show any background image
		bg = nil;
	}
	[m_tableview setBackgroundImage:bg];
}

-(void)refreshPathControl {
	NSString* path = [self path];
	if(path != nil) {
		[m_path_combobox setStringValue:path];
	}
}

-(void)reloadPath {
	DirCacheItem* citem = [[DirCache shared] itemForPath:m_path];
	[citem setLastUpdated:nil];
	[self changePath:m_path];
}

-(void)markCacheItems {
	// NSLog(@"%s %@", _cmd, m_name);
	NSString* s = m_path;
	for(int i=0; i<200; ++i) {
		// NSLog(@"mark: %@ %@", m_name, s);
		[[DirCache shared] markItemWithPath:s];
		NSString* s2 = [s stringByDeletingLastPathComponent];
		if([s isEqual:s2]) break;
		s = s2;
	}
}

-(void)changePath:(NSString*)path {
	m_time_change_path = CFAbsoluteTimeGetCurrent();

	m_transaction_id = -1; // invalidate all transactions
	
	m_request_is_pending = YES;
	
	NSString* old_path = m_path;

	[path retain];
	[m_path autorelease];
	m_path = path;
	

	if([m_delegate respondsToSelector:@selector(cleanupCache)]) {
		// [m_delegate cleanupCache];
		[m_delegate performSelector:@selector(cleanupCache)
		           withObject: nil
		           afterDelay: 5.f];
	}

	[m_panel_table removeAllData];

	m_cache_item_timestamp = 0;

	DirCacheItem* citem = [[DirCache shared] itemForPath:path];
	NSDate* last_updated = [citem lastUpdated];
	if(last_updated != nil) {
		NSAssert([citem isValid], @"not valid");
		NSAssert([m_panel_table isValid], @"not valid");
		// NSLog(@"%s cache hit", _cmd);
		// int nnn = [citem objectCount];
		// NSLog(@"%s nnn: %i", _cmd, nnn);
		
		// NSLog(@"%s BEFORE: %@", _cmd, m_panel_table);
		[m_panel_table setCount:[citem objectCount]];
		[m_panel_table setColumnName:[citem filenames]];
		[m_panel_table setColumnTypeVector:[citem typeVector]];
		[m_panel_table setColumnAliasVector:[citem aliasVector]];
		[m_panel_table setColumnStat64Vector:[citem stat64Vector]];
		[m_panel_table setColumnSelectTo:NO];
		[m_panel_table setColumnVisibleTo:YES];
		[m_panel_table resetIndexes];
		[m_panel_table sort];

		m_request_is_pending = NO;
		
		m_cache_item_timestamp = [last_updated timeIntervalSince1970];
		[self update];
		[self reloadTableData];
		// NSLog(@"%s AFTER: %@", _cmd, m_panel_table);

		NSAssert([m_panel_table isValid], @"not valid");
		// NSLog(@"%s cache-hit. citem: %@  paneltable: %@", _cmd, citem, m_panel_table);

	 	// [m_tableview setNeedsDisplay:YES];
		
		// NSLog(@"%s %@ %@", _cmd, self, path);
		
		// [self update];
		// [self reloadTableData];
		// NSLog(@"%s HIT: %@ -> %@\n%@", _cmd, old_path, path, self);
		return;
	}

	// NSLog(@"%s cache miss", _cmd);

	if(m_wrapper != nil) {
		
		int tid = 0; 
		if([m_delegate respondsToSelector:@selector(mkTransactionId)]) {
			tid = [m_delegate mkTransactionId];
		}
		m_transaction_id = tid;

		[m_wrapper requestPath:path transactionId:tid];
		[self wrapperRegisterRequest:path];
		// NSLog(@"%s MISS: %@ -> %@\n%@", _cmd, old_path, path, self);

		// double t1 = CFAbsoluteTimeGetCurrent();
		// double diff = t1 - m_time_change_path;
		// NSLog(@"%s self.request: %.3f", _cmd, (float)diff);

		return;
	}


	
	// NSLog(@"%s not yet ready for requests", _cmd);
}

-(NSString*)path {
	return m_path;
}

-(void)discoverDidLaunch {
	// NSLog(@"%s", _cmd);
	[self reloadPath];
}

-(void)discoverIsNowProcessingTheRequest {
	// NSLog(@"%s", _cmd);
	m_time_process_begin = CFAbsoluteTimeGetCurrent();
	double diff = m_time_process_begin - m_time_change_path;
	[m_discover_stat_item setMessage:@"hang 1"];
	[m_discover_stat_item setTime0:diff];
}

-(void)discoverHasName:(NSData*)data transactionId:(int)tid {
	if(tid != m_transaction_id) {
		NSLog(@"%s wrong transaction id (%i != %i).", _cmd, tid, m_transaction_id);
		return;
	}


	/*
	with big dirs (21000 entries ~= 700 Kb) it may take some time
	decoding the data. If it locks up the UI, we can move it to
	the thread that is calling us.
	*/
	NSString* error = nil;
	id ary = [NSPropertyListSerialization 
		propertyListFromData:data
	    mutabilityOption:NSPropertyListImmutable
	    format:NULL
	    errorDescription:&error
	];

	if(error != nil) {
		NSLog(@"%s error decoding xml. %@", _cmd, error);
		[error release];
		return;
	}
	
	// NSLog(@"%s received: %i bytes", _cmd, (int)[data length]);

	
	
	// NSLog(@"%s %@", _cmd, data);
	m_request_is_pending = NO;

	[m_panel_table setColumnName:ary];

	if([m_panel_table isCountSet] == NO) {
		[m_panel_table setCount:[ary count]];
		[m_panel_table setColumnSelectTo:NO];
		[m_panel_table setColumnVisibleTo:YES];
		[m_panel_table resetIndexes];
		[m_panel_table sort];
	}
	NSAssert([m_panel_table isValid], @"not valid");


	int number_of_names = [ary count];
	

/*	NSUInteger nr1 = [m_panel_table count];
	NSUInteger nr2 = [data count];
	if(nr1 != nr2) {
		// NSLog(@"%s - correcting number of rows: %i = %i", _cmd, (int)nr1, (int)nr2);
		[m_panel_table setCount:nr2];
		[m_panel_table setColumnSelectTo:NO];
		[self update];
		[self reloadTableData];
		// NSLog(@"%s PanelTable: %@", _cmd, m_panel_table);
	} else {
		[self update];
		[self reloadTableData];     
	}*/
  	[self update];
  	[self reloadTableData];     



	{
		DirCacheItem* citem = [[DirCache shared] itemForPath:m_path];
		[citem setFilenames:ary];
		[citem setObjectCount:number_of_names];
		NSDate* date = [NSDate date];
		[citem setLastUpdated:date];
		m_cache_item_timestamp = [date timeIntervalSince1970];

		NSAssert([citem isValid], @"not valid");
	}

	m_time_has_names = CFAbsoluteTimeGetCurrent();
	double diff = m_time_has_names - m_time_process_begin;

	[m_discover_stat_item setMessage:@"hang 2"];
	[m_discover_stat_item setTime1:diff];
	[m_discover_stat_item setCount:number_of_names];
}


-(void)discoverHasType:(NSData*)data transactionId:(int)tid {
	// NSLog(@"%s datasize: %i", _cmd, (int)[data length]);
	if(tid != m_transaction_id) {
		NSLog(@"%s wrong transaction id (%i != %i).", _cmd, tid, m_transaction_id);
		return;
	}
	// NSLog(@"%s %@", _cmd, data);
	
	[m_panel_table setColumnTypeVector:data];
	NSAssert([m_panel_table isValid], @"not valid");

	[m_panel_table sort];
	[self reloadTableData];

	{
		DirCacheItem* citem = [[DirCache shared] itemForPath:m_path];
		[citem setTypeVector:data];
		NSDate* date = [NSDate date];
		[citem setLastUpdated:date];
		m_cache_item_timestamp = [date timeIntervalSince1970];
		NSAssert([citem isValid], @"not valid");
	}

	m_time_has_dirinfo = CFAbsoluteTimeGetCurrent();
	double diff = m_time_has_dirinfo - m_time_has_names;
	
	[m_discover_stat_item setMessage:@"hang 3"];
	[m_discover_stat_item setTime2:diff];
}

-(void)discoverHasStat:(NSData*)data transactionId:(int)tid {
	if(tid != m_transaction_id) {
		NSLog(@"%s wrong transaction id (%i != %i).", _cmd, tid, m_transaction_id);
		return;
	}
	// NSLog(@"OFMPane %s %@", _cmd, data);

	[m_panel_table setColumnStat64Vector:data];
	NSAssert([m_panel_table isValid], @"not valid");
	if(0) {
		[m_panel_table setColumnVisibleTo:YES];
		[m_panel_table resetIndexes];
	}
	[m_panel_table sort];
	[self reloadTableData];

	{
		DirCacheItem* citem = [[DirCache shared] itemForPath:m_path];
		[citem setStat64Vector:data];
		NSDate* date = [NSDate date];
		[citem setLastUpdated:date];
		m_cache_item_timestamp = [date timeIntervalSince1970];
		NSAssert([citem isValid], @"not valid");
	}

	m_time_has_sizes = CFAbsoluteTimeGetCurrent();
	double diff = m_time_has_sizes - m_time_has_dirinfo;

	NSString* s = [NSString stringWithFormat:@"OK %.3f", float(m_time_has_sizes - m_time_change_path)];
	[m_discover_stat_item setMessage:s];
	[m_discover_stat_item setTime3:diff];
}

-(void)discoverHasAlias:(NSData*)data transactionId:(int)tid {
	// NSLog(@"%s datasize: %i", _cmd, (int)[data length]);
	if(tid != m_transaction_id) {
		NSLog(@"%s wrong transaction id (%i != %i).", _cmd, tid, m_transaction_id);
		return;
	}
	// NSLog(@"%s %@", _cmd, data);
	
	[m_panel_table setColumnAliasVector:data];
	NSAssert([m_panel_table isValid], @"not valid");

	[m_panel_table sort];
	[self reloadTableData];

	{
		DirCacheItem* citem = [[DirCache shared] itemForPath:m_path];
		[citem setAliasVector:data];
		NSDate* date = [NSDate date];
		[citem setLastUpdated:date];
		m_cache_item_timestamp = [date timeIntervalSince1970];
		NSAssert([citem isValid], @"not valid");
	}

	m_time_has_dirinfo = CFAbsoluteTimeGetCurrent();
	double diff = m_time_has_dirinfo - m_time_has_names;
	
/*	[m_discover_stat_item setMessage:@"hang 3"];
	[m_discover_stat_item setTime2:diff];*/
}

-(BOOL)gotoParentDir {
	NSString* s1 = [self path];
	NSString* s2 = [s1 stringByDeletingLastPathComponent];
	if([s1 isEqual:s2]) return NO;
	
	[self changePath:s2];
	return YES;
}

-(BOOL)followLink {
	if(m_row == 0) {
		return NO;
	}

	NSString* path = [self pathForRow:m_row];
	// NSLog(@"%s %@", _cmd, path);

	if([self isDirForRow:m_row]) {
		[self changePath:path];
		return YES;
	}

	return NO;
}

-(void)changeDir:(int)action {
	// NSLog(@"%s action: %i", _cmd, action);

	// double t0 = CFAbsoluteTimeGetCurrent();


	NSRect old_rect = [[m_tableview enclosingScrollView] documentVisibleRect];
	int old_row = [self row];
	NSRange old_range = [m_tableview rowsInRect:old_rect];
	int old_row_count = [m_tableview numberOfRows];
	
	
	int rc = 0;
	
	if(action == CHANGE_DIR_FOLLOW_LINK) {
		if(old_row == 0) {
			if([self gotoParentDir]) {
				rc = -1;
			} else {
				return;
			}
		} else {
			if([self followLink]) {
				rc = 1;
			} else {
#if 0
				// cycle through the info tabs by hitting enter several times
				m_active_infotab = (m_active_infotab + 1) % 5;
				[self rebuildInfo];
				[self refreshUI];
#endif
				return;
			}
		}
		
	} else
	if(action == CHANGE_DIR_GOTO_PARENT) {
		if([self gotoParentDir]) {
			rc = -1; 
		} else {
			return;
		}
	} else {
		return;
	}
	if(rc == 0) {
		return;
	}
	
	if(rc == 1) {
		// NSLog(@"Follow Link");
		[self update];

		// NSRect frame = [m_left_tableview frame];
		// NSLog(@"%@", NSStringFromRect(frame));
		// NSLog(@"%i %i", old_range.location, old_range.length);
		
		// float h = NSHeight(frame) - NSHeight(old_rect);
		// float ofs = (h > 10) ? NSMinY(old_rect) / h : 0;
		
		int rel_row = old_row - old_range.location;
		float ofs = (old_range.length > 1) ? 
			float(rel_row) / float(old_range.length) : 0;
		
		// NSLog(@"ofs: %0.2f\ntoprow: %i", ofs, old_range.location);
		
		BreadcrumItem item;
		item.m_selected_row = old_row;
		item.m_position_y = ofs;       
		item.m_number_of_rows = old_row_count;
		[self pushBreadcrum:item];


		[self refreshUI];
		
		int row = 0;

		// NSLog(@"BEFORE: %@", self);
		[self reloadTableData];
		// NSLog(@"AFTER: %@", self);
		// return;
		
		[self setRow:row];

		{
			NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:row];
			[m_tableview selectRowIndexes:indexes byExtendingSelection:NO];
		}


		[m_tableview scrollRowToVisible:0];

		[self rebuildInfo];
		[self refreshUI];

		// double t1 = CFAbsoluteTimeGetCurrent();
		// NSLog(@"%s follow: %.3f", _cmd, (float)(t1 - t0));
		
		return;
	}
	
	if(rc == -1) {
		// NSLog(@"Go to parent dir");

		[self update];
		[self refreshUI];

		if([m_breadcrum_stack count] > 0) {
			BreadcrumItem item = [self breadcrum];
			[self popBreadcrum];

			int rows = item.m_number_of_rows;
			int row = item.m_selected_row;
			// NSLog(@"%s row: %i rows: %i", _cmd, row, rows);
			if(row > rows) {
				row = rows - 1;
			}
#if 0
			if([m_panel_table isCountSet]) {
				NSLog(@"%s count already set to: %i.. will set to %i", _cmd, [m_panel_table count], rows);
				/*
				TODO: why do we end up here?
				do we really have to set count here?
				
				*/
			}
			[m_panel_table setCount:rows];
#endif
/*			[m_panel_table removeAllData];
			[m_panel_table setCount:0];
			[m_panel_table setColumnSelectTo:NO];*/

			// NSLog(@"BEFORE: %@", self);
			[self reloadTableData];
			// NSLog(@"AFTER: %@", self);
			// return;
		
			[self setRow:row];

			{
				NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:row];
				[m_tableview selectRowIndexes:indexes byExtendingSelection:NO];
			}


			[m_tableview scrollRowToVisible:0];

			NSRect rect = [[m_tableview enclosingScrollView] documentVisibleRect];
			NSRange range = [m_tableview rowsInRect:rect];
		
			float toprow_f = row - float(range.length) * item.m_position_y;
			int toprow = floorf(toprow_f);
			// NSLog(@"toprow_f: %.2f\ntoprow: %i", toprow_f, toprow);
		
			if(toprow < 0) toprow = 0;

			[m_tableview scrollRowToVisible:rows-1];
			if(toprow < rows-1) {
				[m_tableview scrollRowToVisible:toprow];
			}
			[m_tableview scrollRowToVisible:row];

			// NSLog(@"%s toprow: %i row: %i", _cmd, toprow, row);
		

			[self rebuildInfo];
			[self refreshUI];
		} else {

			[self refreshUI];

			int row = 0;

			// NSLog(@"BEFORE: %@", self);
			[self reloadTableData];
			// NSLog(@"AFTER: %@", self);
			// return;

			[self setRow:row];

			{
				NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:row];
				[m_tableview selectRowIndexes:indexes byExtendingSelection:NO];
			}


			[m_tableview scrollRowToVisible:0];

			[self rebuildInfo];
			[self refreshUI];
			
		}

		// double t1 = CFAbsoluteTimeGetCurrent();
		// NSLog(@"%s parent: %.3f", _cmd, (float)(t1 - t0));

		return;
	}
	
	// NSLog(@"END OF %s", _cmd);
}

-(void)setTableViewFont:(NSFont*)font {
	[font retain];
	[m_font_tableview autorelease];
	m_font_tableview = font;
}

-(void)setAttributes:(NSDictionary*)attr forIndex:(int)index {
	if((index >= 0) && (index < ATTRIBUTES_LAST)) {
		[attr retain];
		[m_table_attributes[index] autorelease];
		m_table_attributes[index] = attr;
	}
}

-(void)reloadTableAttributes {
	{
		NSDictionary* a = [NSDictionary dictionaryWithObjectsAndKeys:
			m_font_tableview, NSFontAttributeName, 
			[NSColor whiteColor], NSForegroundColorAttributeName, 
			nil
		];
		[self setAttributes:a forIndex:ATTRIBUTES_PARENTDIR];
	}
	{
		NSDictionary* a = [NSDictionary dictionaryWithObjectsAndKeys:
			m_font_tableview, NSFontAttributeName, 
			[NSColor redColor], NSForegroundColorAttributeName, 
			nil
		];
		[self setAttributes:a forIndex:ATTRIBUTES_ERROR];
	}
	{
		NSColor* color = [NSColor colorWithCalibratedWhite:0.45 alpha:1.0];
		NSDictionary* a = [NSDictionary dictionaryWithObjectsAndKeys:
			m_font_tableview, NSFontAttributeName, 
			color, NSForegroundColorAttributeName, 
			nil
		];
		[self setAttributes:a forIndex:ATTRIBUTES_EXTENSION];
	}
	{
		NSDictionary* a = [NSDictionary dictionaryWithObjectsAndKeys:
			m_font_tableview, NSFontAttributeName, 
			[NSColor redColor], NSForegroundColorAttributeName, 
			nil
		];
		[self setAttributes:a forIndex:ATTRIBUTES_EXTENSION_SELECTED];
	}
	{
		NSFont* font = m_font_tableview;
		// font = [[NSFontManager sharedFontManager] convertFont:font 
				// toHaveTrait:NSBoldFontMask];
			
		NSDictionary* a = [NSDictionary dictionaryWithObjectsAndKeys:
			font, NSFontAttributeName, 
			// color, NSForegroundColorAttributeName, 
			nil
		];
		[self setAttributes:a forIndex:ATTRIBUTES_FILENAME];
	}
	{
		NSFont* font = m_font_tableview;
		font = [[NSFontManager sharedFontManager] convertFont:font 
				toHaveTrait:NSBoldFontMask];
			
		NSDictionary* a = [NSDictionary dictionaryWithObjectsAndKeys:
			font, NSFontAttributeName, 
			[NSColor whiteColor], NSForegroundColorAttributeName, 
			nil
		];
		[self setAttributes:a forIndex:ATTRIBUTES_FILENAME_HIGHLIGHTED];
	}
	{
		NSFont* font = m_font_tableview;
		font = [[NSFontManager sharedFontManager] convertFont:font 
				toHaveTrait:NSBoldFontMask];
			
		NSDictionary* a = [NSDictionary dictionaryWithObjectsAndKeys:
			font, NSFontAttributeName, 
			[NSColor redColor], NSForegroundColorAttributeName, 
			nil
		];
		[self setAttributes:a forIndex:ATTRIBUTES_FILENAME_SELECTED];
	}
	{
		NSColor* color = [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
		NSDictionary* a = [NSDictionary dictionaryWithObjectsAndKeys:
			m_font_tableview, NSFontAttributeName, 
			color, NSForegroundColorAttributeName, 
			nil
		];
		[self setAttributes:a forIndex:ATTRIBUTES_LETTER_UNMATCHED];
	}
	{
		NSFont* font = m_font_tableview;
		font = [[NSFontManager sharedFontManager] convertFont:font 
				toHaveTrait:NSBoldFontMask];
			
		NSDictionary* a = [NSDictionary dictionaryWithObjectsAndKeys:
			font, NSFontAttributeName, 
			[NSColor blackColor], NSForegroundColorAttributeName, 
			nil
		];
		[self setAttributes:a forIndex:ATTRIBUTES_LETTER_MATCHED];
	}
}

-(void)setTextViewFont:(NSFont*)font {
	[font retain];
	[m_font_textview autorelease];
	m_font_textview = font;
}

-(void)setRow:(int)row {
	m_row = row;
}

-(int)row {
	return m_row;
}

BOOL filter_dotfiles(NSString* name, void* context) {
	// always ignore current dir and parent dir
	// IDEA: if the full path is "/." then we want to see it 
	if([name isEqual:@"."]) return NO;
	if([name isEqual:@".."]) return NO;

	// common mac files
	if([name isEqual:@".DS_Store"]) return NO;
	if([name isEqual:@".localized"]) return NO;
	if([name isEqual:@".Trashes"]) return NO;
	if([name isEqual:@".Trash"]) return NO;
	if([name isEqual:@".ssh"]) return NO;
	if([name isEqual:@".Spotlight-V100"]) return NO;
	if([name isEqual:@".journal"]) return NO;
	if([name isEqual:@".journal_info_block"]) return NO;
	if([name isEqual:@".hotfiles.btree"]) return NO;
	if([name isEqual:@".com.apple.timemachine.supported"]) return NO;
	if([name isEqual:@".fseventsd"]) return NO;
	if([name isEqual:@".vol"]) return NO;
	if([name isEqual:@".TemporaryItems"]) return NO;
	if([name isEqual:@".MacOSX"]) return NO;
	if([name isEqual:@".CFUserTextEncoding"]) return NO;

	// version control
	if([name isEqual:@".git"]) return NO;    
	if([name isEqual:@".gitk"]) return NO;
	if([name isEqual:@".gitignore"]) return NO;
	if([name isEqual:@".svn"]) return NO;
	if([name isEqual:@".subversion"]) return NO;
	if([name isEqual:@"CVS"]) return NO;
	if([name isEqual:@"CVSROOT"]) return NO;
	if([name isEqual:@".cvsignore"]) return NO;
	if([name isEqual:@".cvspass"]) return NO;
	if([name isEqual:@".hgignore"]) return NO;
	
	// misc
	if([name isEqual:@".ssh"]) return NO;
	if([name isEqual:@".gem"]) return NO;
	if([name isEqual:@".ri"]) return NO;
	if([name isEqual:@".fontconfig"]) return NO;
	if([name isEqual:@".dvdcss"]) return NO;
	if([name isEqual:@".cups"]) return NO;
	if([name isEqual:@".cpan"]) return NO;
	if([name isEqual:@".Xauthority"]) return NO;
	if([name isEqual:@".viminfo"]) return NO;
	if([name isEqual:@".profile"]) return NO;
	if([name isEqual:@".lesshst"]) return NO;
	if([name isEqual:@".irb_history"]) return NO;
	if([name isEqual:@".gdbinit"]) return NO;
	if([name isEqual:@".gdb_history"]) return NO;
	if([name isEqual:@".bash_history"]) return NO;
	if([name isEqual:@".Xcode"]) return NO;
	
	if([name hasPrefix:@"."]) return NO;
	return YES;
}

BOOL filter_partialsearch(NSString* name, void* context) {
	OPPartialSearch* ps = reinterpret_cast<OPPartialSearch*>(context);
	return [ps isEqual:name];
}

-(void)update {
	if([m_panel_table isCountSet]) {
		[m_panel_table resetIndexes];
		[m_panel_table setColumnVisibleTo:YES];
		if(m_show_hidden_files == NO) {
			[m_panel_table filterVisibleByName:filter_dotfiles
			 	context:NULL];
		}
		[m_panel_table filterVisibleByName:filter_partialsearch
		 	context:m_partial_search];
		[m_panel_table sort];
	}
}

-(id)tableNameForRow:(int)row {
	NSString* result = @"error";
	NSDictionary* attr = m_table_attributes[ATTRIBUTES_ERROR];;
	do {
		if(row == 0) {
			result = @"<parent dir>";
			attr = m_table_attributes[ATTRIBUTES_PARENTDIR];
			break;
		}
		
		NSString* s = [m_panel_table visibleNameForRow:(row-1)];

		if(s != nil) {
			result = s;
			// break;

			if([m_panel_table visibleSelectedForRow:(row-1)]) {
				NSDictionary* attr1 = m_table_attributes[ATTRIBUTES_FILENAME_SELECTED];
				NSDictionary* attr2 = m_table_attributes[ATTRIBUTES_EXTENSION_SELECTED];

				NSString* filename = [s stringByDeletingPathExtension];
			
				NSMutableAttributedString* mas = [[NSMutableAttributedString alloc] init];
				[mas setAttributedString:[[[NSAttributedString alloc] 
					initWithString:result attributes:attr2] autorelease]];
				[mas setAttributes:attr1 range:NSMakeRange(0, [filename length])];
				return [mas autorelease];
			} else
			if([[m_searchfield stringValue] length] > 0) {

				NSDictionary* attr1 = m_table_attributes[ATTRIBUTES_LETTER_MATCHED];
				NSDictionary* attr2 = m_table_attributes[ATTRIBUTES_LETTER_UNMATCHED];

				[m_partial_search setMatchAttributes:attr1];
				[m_partial_search setNormalAttributes:attr2];

				return [m_partial_search renderString:s];
			} else {

				NSDictionary* attr1 = m_table_attributes[ATTRIBUTES_FILENAME];
				NSDictionary* attr2 = m_table_attributes[ATTRIBUTES_EXTENSION];
				if(row == m_row) {
					attr1 = m_table_attributes[ATTRIBUTES_FILENAME_HIGHLIGHTED];
					attr2 = attr1;
				}

				NSString* filename = [s stringByDeletingPathExtension];
			
				NSMutableAttributedString* mas = [[NSMutableAttributedString alloc] init];
				[mas setAttributedString:[[[NSAttributedString alloc] 
					initWithString:result attributes:attr2] autorelease]];
				[mas setAttributes:attr1 range:NSMakeRange(0, [filename length])];
				return [mas autorelease];
			}
		}
	} while(0);

	NSAttributedString* as = [[NSAttributedString alloc] 
		initWithString:result 
		    attributes:attr];
	return [as autorelease];
}

-(id)tablePermissionsForRow:(int)row {
	NSImage* result = nil;
	do {
		if(row == 0) {
			break;
		}
		
		NSUInteger pmask = [m_panel_table visiblePermissionForRow:(row-1)];
		pmask >>= 6;

		result = m_images[IMAGES_PERM000 + (pmask & 7)];
	} while(0);
	return result;
}

-(id)tableIconForRow:(int)row {
	if(row == 0) return nil;
	PanelTableType pttype = [m_panel_table visibleTypeForRow:(row-1)];
	switch(pttype) {
	case kPanelTableTypeDir:      return m_images[IMAGES_DIR];         
	case kPanelTableTypeDirLink:  return m_images[IMAGES_DIR_LINK];
	case kPanelTableTypeFile:     return m_images[IMAGES_FILE];
	case kPanelTableTypeFileLink: return m_images[IMAGES_FILE_LINK];
	case kPanelTableTypeLink:     return m_images[IMAGES_OTHER_LINK];
	case kPanelTableTypeNone:     return m_images[IMAGES_LOADING];
	}
	return m_images[IMAGES_OTHER];
}

-(NSAttributedString*)info {
	if(m_info == nil) {
		[self rebuildInfo];
	}
	return m_info;
}

-(BOOL)isSelectedRow:(int)row {
	if(row == 0) return NO;
	return [m_panel_table visibleSelectedForRow:row - 1];
}

-(void)toggleSelectForRow:(int)row {
	if(row == 0) {
		// <parent dir> cannot be selected
		return;
	}
	BOOL value = [m_panel_table visibleSelectedForRow:(row-1)];
	value = !value;
	[m_panel_table setVisibleSelectedForRow:(row-1) value:value];

	[self rebuildInfo];
	[self refreshInfo];
}

-(NSString*)pathForRow:(int)row {
	if(row == 0) return nil;
	NSString* filename = [m_panel_table visibleNameForRow:(row - 1)];
	if(filename == nil) return nil;
	return [m_path stringByAppendingPathComponent:filename];
	return m_path;
}

-(BOOL)isDirForRow:(int)row {
	if(row == 0) return NO;
	PanelTableType pttype = [m_panel_table visibleTypeForRow:(row-1)];
	return ((pttype == kPanelTableTypeDir) || 
		(pttype == kPanelTableTypeDirLink) || 
		(pttype == kPanelTableTypeLink));
}

-(NSString*)pathForCurrentRow {
	return [self pathForRow:m_row];
}

-(NSString*)nameForCurrentRow {
	if(m_row == 0) return nil;

	return [m_panel_table visibleNameForRow:(m_row-1)];
}

-(NSString*)pathInFinder {
	if(m_row == 0) return m_path;
	return [self pathForRow:m_row];
}

-(NSString*)pathForReport {
	if(m_row == 0) return m_path;
	return [self pathForRow:m_row];
}

-(void)appendTo:(NSMutableAttributedString*)as string:(NSString*)s theme:(int)theme {
	NSDictionary* d = nil;
	if(theme == 1) d = m_info_attr1;
	if(theme == 2) d = m_info_attr2;
	[as appendAttributedString:[[[NSAttributedString alloc] 
		initWithString:s attributes:d] autorelease]];
}

-(NSAttributedString*)infoStringInfo1 {

	NSUInteger count_files_total = 0;
	NSUInteger count_dirs_total = 0;
	NSUInteger count_files_selected = 0;
	NSUInteger count_dirs_selected = 0;
	uint64_t size_total = 0;
	uint64_t size_selected = 0;


/*	NSIndexSet* indexes = m_fileselected_set;
	unsigned current_index = [indexes lastIndex];
    while(current_index != NSNotFound) {
		NSNumber* filetype = [m_column_type objectAtIndex:current_index];
		BOOL isdir = [filetype boolValue];
		if(isdir) {
			count_dirs += 1;
		} else {
			count_files += 1;
			NSNumber* filesize = [m_column_size objectAtIndex:current_index];
			size_of_files += [filesize unsignedLongLongValue];
		}

        current_index = [indexes indexLessThanIndex: current_index];
    }*/

	NSUInteger n = [m_panel_table visibleNumberOfRows];
	for(NSUInteger i=0; i < n; ++i) {
		BOOL is_selected = [m_panel_table visibleSelectedForRow:i];

		PanelTableType ftype = [m_panel_table visibleTypeForRow:i];
		BOOL isdir = (ftype == kPanelTableTypeDir);
		if(isdir) {
			count_dirs_total += 1;
			if(is_selected) count_dirs_selected += 1;
		} else {
			count_files_total += 1;
			uint64_t fs = [m_panel_table visibleSizeForRow:i];
			size_total += fs;
			if(is_selected) {
				size_selected += fs;
				count_files_selected += 1;
			}
		}
	}


	uint64_t size_selected_pretty = size_selected;
	const char* size_selected_suffix = NULL;
	{
		uint64_t v = size_selected;
		const char* s = "b";
		if(v > 1024 * 10) { v >>= 10; s = "k"; }
		if(v > 1024 * 10) { v >>= 10; s = "m"; }
		if(v > 1024 * 10) { v >>= 10; s = "g"; }
		if(v > 1024 * 10) { v >>= 10; s = "t"; }
		size_selected_pretty = v;
		size_selected_suffix = s;
	}

	uint64_t size_total_pretty = size_total;
	const char* size_total_suffix = NULL;
	{
		uint64_t v = size_total;
		const char* s = "b";
		if(v > 1024 * 10) { v >>= 10; s = "k"; }
		if(v > 1024 * 10) { v >>= 10; s = "m"; }
		if(v > 1024 * 10) { v >>= 10; s = "g"; }
		if(v > 1024 * 10) { v >>= 10; s = "t"; }
		size_total_pretty = v;
		size_total_suffix = s;
	}

	/*

	0 of 5 dirs, 1 of 105 files (105 MB of 142 MB)
	----------------------------------------------


	0 Folder(s), 6522 File(s), 1 Selected (2.2k / 5.5M)

	0 b / 14,3 M in 0 / 160 files, 0 / 5 dir(s)
	0 b / 343,3 k in 0 / 160 files, 0 / 5 dir(s)
	0 k / 3 210 k in 0 / 160 files
	23 k / 3 210 k in 5 / 160 files, 2 / 158 dir(s)
	23 k / 3 210 k in 5 / 160 file(s)

	0 bytes / 4,4 Mb in 0 / 17 files, 5 / 5 dirs


	23 Kb / 1 Mb in 5 / 160 files, 0 / 4 dirs

	numbers are in bold
	4 Folder, 12 File (13 MB)


	0/5 dirs, 1/105 files (105 MB/42 MB, 295/192342 blocks)

	0 of 395 kB in 0 of 16 files, 0 of 1 dir selected
	290 kB of 395 kB in 3 of 17 files selected


	Dirs:  14        Files:  18      Selected:  5

	6 items (5 directories, 1 file)
	*/

	NSMutableAttributedString* result = [[NSMutableAttributedString alloc] init];
	[result autorelease];
	
	int theme_selected = 1;
	if(count_dirs_selected + count_files_selected > 0) {
		theme_selected = 2;
	}

	[result beginEditing];
	{
		NSString* s1 = [NSString stringWithFormat:@"%i", count_dirs_selected];
		NSString* s2 = [NSString stringWithFormat:@"%i", count_dirs_total];
		[self appendTo:result string:s1 theme:theme_selected];
		[self appendTo:result string:@" of " theme:1];
		[self appendTo:result string:s2 theme:1];
		[self appendTo:result string:@" dirs     " theme:1];
	}
	{
		NSString* s1 = [NSString stringWithFormat:@"%i", count_files_selected];
		NSString* s2 = [NSString stringWithFormat:@"%i", count_files_total];
		[self appendTo:result string:s1 theme:theme_selected];
		[self appendTo:result string:@" of " theme:1];
		[self appendTo:result string:s2 theme:1];
		[self appendTo:result string:@" files     " theme:1];
	}
	{
		NSString* s1 = [NSString stringWithFormat:@"%llu %s", 
			size_selected_pretty, size_selected_suffix];
		NSString* s2 = [NSString stringWithFormat:@"%llu %s", 
			size_total_pretty, size_total_suffix];
		[self appendTo:result string:s1 theme:theme_selected];
		[self appendTo:result string:@" of " theme:1];
		[self appendTo:result string:s2 theme:1];
		[self appendTo:result string:@"\n\n\n" theme:1];
	}


/*	NSAttributedString* as = [[[NSAttributedString alloc] 
		initWithString:s attributes:m_attr2] autorelease];
	[m_result appendAttributedString:as];

	[result appendFormat:
		@"%i of %i dirs        ",
		count_dirs_selected, count_dirs_total
	];

	[result appendFormat:
		@"%i of %i files        ",
		count_files_selected, count_files_total
	];

	[result appendFormat:
		@"%qi %s of %qi %s\n\n\n",
		size_selected_pretty,
		size_selected_suffix,
		size_total_pretty,
		size_total_suffix
	];*/

	[result endEditing];

	return [result copy];
}

-(void)rebuildInfo {
#ifdef DONT_SHOW_INFO
	{
		NSAttributedString* as = [[NSAttributedString alloc] 
			initWithString:@"test"];

		[m_info autorelease];
		m_info = as;
		return;
	}/**/
#endif
	NSFileManager* fm = [NSFileManager defaultManager];
	NSWorkspace* ws = [NSWorkspace sharedWorkspace];


	NSString* path = [self pathForRow:m_row];
	
/*	int value = [self finderLabelCPath:path];
	NSLog(@"value: %i", value);/**/
	
	NSDictionary* a = [NSDictionary dictionaryWithObjectsAndKeys:
		m_font_textview, NSFontAttributeName, 
		// color, NSForegroundColorAttributeName, 
		nil
	];
	NSMutableString* result = [NSMutableString stringWithCapacity:1000];
	
	



	if(m_row == 0) {
		[result appendFormat:@"Jump to parent dir"];

	[result appendFormat:
		@"\n\nnumber of objects:\n%i", 
		(int)[m_panel_table visibleNumberOfRows]
	];

	} else
	if(m_active_infotab == 0) {
		m_info = [[self infoStringInfo1] retain];
		return;
	} else
	if(m_active_infotab == 0) {
		NSDictionary* fileAttributes = [fm fileAttributesAtPath:path traverseLink:YES];		
		
		if (fileAttributes != nil) {
		    NSNumber *fileSize;
		    NSString *fileOwner;
		    NSDate *fileModDate;
		    if (fileSize = [fileAttributes objectForKey:NSFileSize]) {
		        // NSLog(@"File size: %qi\n", [fileSize unsignedLongLongValue]);
				[result appendFormat:@"File size:\n%qi", [fileSize unsignedLongLongValue]];
		    }
		    if (fileOwner = [fileAttributes objectForKey:NSFileOwnerAccountName]) {
		        // NSLog(@"Owner: %@\n", fileOwner);
				[result appendFormat:@"\n\nOwner:\n%@", fileOwner];
		    }
		    if (fileModDate = [fileAttributes objectForKey:NSFileModificationDate]) {
		        // NSLog(@"Modification date: %@\n", fileModDate);
				[result appendFormat:@"\n\nModification date:\n%@", fileModDate];
		    }
		
			// NSLog(@"%s %@", _cmd, fileAttributes);
		}
		else {
		    // NSLog(@"Path (%@) is invalid.", path);
			[result appendFormat:@"\n\nPath (%@) is invalid.", path];
		}

	} else
	if(m_active_infotab == 1) {

		{
#if 0
			NSArray* task_args = [NSArray arrayWithObjects:
				@"-b", // brief.. don't prepend the filename
				path,
				nil
			];

			NSTask* task = [[NSTask alloc] init];
			[task setLaunchPath:@"/usr/bin/file"];
			[task setArguments:task_args];

		    [task setStandardOutput: [NSPipe pipe]];
		    [task setStandardError: [task standardOutput]];

		    [[NSNotificationCenter defaultCenter] addObserver:self 
		        selector:@selector(getData:) 
		        name: NSFileHandleReadCompletionNotification 
		        object: [[task standardOutput] fileHandleForReading]];
		    [[[task standardOutput] fileHandleForReading] readInBackgroundAndNotify];


			[m_task_output setString:@""];

			[task launch];
			[task waitUntilExit];
			sleep(0.2);
			[task terminate];
			[task release];

	  		[result appendFormat:@"magic file:\n%@\n\n", m_task_output];
#else
	  		[result appendFormat:@"magic file: disabled\n\n"];
#endif
		}
		{
#if 0
			NSArray* task_args = [NSArray arrayWithObjects:
				@"-b", // brief.. don't prepend the filename
				@"-I", // now we want to know the MIME type
				path,
				nil
			];

			NSTask* task = [[NSTask alloc] init];
			[task setLaunchPath:@"/usr/bin/file"];
			[task setArguments:task_args];

		    [task setStandardOutput: [NSPipe pipe]];
		    [task setStandardError: [task standardOutput]];

		    [[NSNotificationCenter defaultCenter] addObserver:self 
		        selector:@selector(getData:) 
		        name: NSFileHandleReadCompletionNotification 
		        object: [[task standardOutput] fileHandleForReading]];
		    [[[task standardOutput] fileHandleForReading] readInBackgroundAndNotify];


			[m_task_output setString:@""];

			[task launch];
			[task waitUntilExit];
			sleep(0.2);
			[task terminate];
			[task release];

			[result appendFormat:@"MIME:\n%@\n\n", m_task_output];
#else
	  		[result appendFormat:@"MIME: disabled\n\n"];
#endif
		}
		
	} else
	if(m_active_infotab == 2) {
		{
			NSString* appname = nil;
			NSString* filetype = nil;
			BOOL ok = [ws getInfoForFile:path application:&appname type:&filetype];
			
			if(ok) {
				appname = [[appname lastPathComponent] stringByDeletingPathExtension];
				[result appendFormat:@"default app:\n%@\n\n", appname];
				[result appendFormat:@"filetype:\n%@\n\n", filetype];
			} else {
				[result appendFormat:@"no app/filetype info available\n\n"];
			}
		}

	} else
	if(m_active_infotab == 3) {

		NSImage* icon = [ws iconForFile: path];
			
		NSTextAttachmentCell *attachmentCell = [[NSTextAttachmentCell alloc] 
		initImageCell:icon];
		NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
		[attachment setAttachmentCell: attachmentCell ];
		NSAttributedString *attributedString = [NSAttributedString 
		attributedStringWithAttachment: attachment];
		// [[textView textStorage] appendAttributedString:attributedString];			

		[m_info autorelease];
		m_info = [attributedString retain];
		return;


	} else
	if(m_active_infotab == 4) {

		NSDictionary* fileAttributes = [fm fileAttributesAtPath:path traverseLink:YES];		
		
		if (fileAttributes != nil) {
			[result appendFormat:@"%@", fileAttributes];
		}
		else {
		    // NSLog(@"Path (%@) is invalid.", path);
			[result appendFormat:@"Path (%@) is invalid.\nNo attributes available.", path];
		}

	} else {

		[result appendFormat:
			@"tab %i", m_active_infotab
		];
	}


	NSAttributedString* as = [[NSAttributedString alloc] 
		initWithString:result attributes:a];

	[m_info autorelease];
	m_info = as;
}

-(void)getData:(NSNotification*)aNotification {
    NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    if([data length]) {
        NSString* s = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		// [_result appendString:s];
		[m_task_output appendString:s];
		NSLog(@"result = %@", s);
    } else {
		// NSLog(@"no result");
	}
    [[aNotification object] readInBackgroundAndNotify];  
}


-(void)setActiveInfoPanel:(int)index {
	if(index < 0) index = 0;
	m_active_infotab = index % 5;
}

-(int)activeInfoPanel {
	return m_active_infotab;
}

-(void)cycleActiveInfoPanel {
	[self setActiveInfoPanel:[self activeInfoPanel] + 1];
	[self rebuildInfo];
	[self refreshUI];
}


-(NSString*)windowTitle {
#if 1
	// NSString* s = @"Newton Commander";
	// NSString* s = @"FTP - Read Only";
	[m_volume_info setPath:m_path];
	NSString* s = [m_volume_info info];
	// NSString* s = @"HFS+ - Read/Write - 320 GB Avail - Newton Commander";
	return s;
#else
	NSString* title = [self pathForRow:m_row];
	if(title == nil) {
		title = m_path;
	}
	return title;
#endif
}

-(void)pushBreadcrum:(BreadcrumItem)item {
	[m_breadcrum_stack addObject: 
		[NSValue value:&item withObjCType:@encode(BreadcrumItem)]];
}

-(void)popBreadcrum {
	if([m_breadcrum_stack count] > 0)
		[m_breadcrum_stack removeLastObject];
}

-(BreadcrumItem)breadcrum {
	BreadcrumItem item;
	item.m_selected_row = 0;
	item.m_position_y = 0;
	if([m_breadcrum_stack count] > 0) {
		[[m_breadcrum_stack lastObject] getValue:&item];
	}
	return item;
}

-(void)eraseBreadcrums {
	[m_breadcrum_stack removeAllObjects];
}

-(void)swapBreadcrums:(OFMPane*)other {
	NSMutableArray* tmp = other->m_breadcrum_stack;
	other->m_breadcrum_stack = m_breadcrum_stack;
	m_breadcrum_stack = tmp;
}

-(void)takeBreadcrumsFrom:(OFMPane*)other {
	m_breadcrum_stack = [other->m_breadcrum_stack mutableCopy];
}

-(int)numberOfRowsInTableView:(NSTableView*)aTableView {
	return [m_panel_table visibleNumberOfRows] + 1;
}

/*-(void)tableView:(NSTableView *)view setObjectValue:(id)obj forTableColumn:(NSTableColumn *)column row:(int)rowIndex
{
	// 
}*/

-(id)tableView:(NSTableView*)aTableView
	objectValueForTableColumn:(NSTableColumn*)aTableColumn
	row:(int)row 
{
	id ident = [aTableColumn identifier];
    if([ident isEqualToString: @"filename"]) {
		return [self tableNameForRow:row];
	} else
    if([ident isEqualToString: @"fileicon"]) {
		return [self tableIconForRow:row];
	}
	return nil;
}

-(void)tableViewTabAway:(NSNotification*)aNotification {
	// NSLog(@"%s", _cmd);
	if([m_delegate respondsToSelector:@selector(tabAwayFromPane:)]) {
		[m_delegate tabAwayFromPane:self];
	}
}

-(void)activate {
	// NSLog(@"%s", _cmd);
	[[m_tableview window] makeFirstResponder:m_tableview];
	[[m_tableview window] setTitle:[self windowTitle]]; 
	[NSCursor setHiddenUntilMouseMoves:YES];
}

-(void)tableViewHitEnter:(NSNotification*)aNotification {
	// NSLog(@"%s", _cmd);
	[self changeDir:CHANGE_DIR_FOLLOW_LINK];
	NSString* s = [self windowTitle];
	[[m_tableview window] setTitle:s]; 
	[self refreshPathControl];
	[NSCursor setHiddenUntilMouseMoves:YES];
}

-(void)tableViewSelectionDidChange:(NSNotification*)aNotification {
	int row = [m_tableview selectedRow];
	[self setRow:row];

	[self rebuildInfo];
	[self refreshInfo];

	NSString* s = [self windowTitle];
	[[m_tableview window] setTitle:s]; 

	SEL sel = @selector(selectionDidChange:);
	if([m_delegate respondsToSelector:sel]) {
		[m_delegate selectionDidChange:self];
	}
	
	[NSCursor setHiddenUntilMouseMoves:YES];
}

-(void)tableViewParentDir:(NSNotification*)aNotification {
	[self changeDir:CHANGE_DIR_GOTO_PARENT];
	[self refreshPathControl];
	[[m_tableview window] setTitle:[self windowTitle]]; 
	[NSCursor setHiddenUntilMouseMoves:YES];
}

-(void)syncWithSearchField {
	[m_partial_search setSearchText:[m_searchfield stringValue]];
	[self update];
	[self refreshUI];
}

-(void)tableViewEnterAscii:(NSNotification*)aNotification {
	// NSLog(@"%s", _cmd);

	id thing2 = [aNotification userInfo];
	thing2 = [thing2 objectForKey:@"key"];
	unichar key = [thing2 intValue];
	// NSLog(@"key: %i", (int)key);
	
	
	
	NSTableView* tv = m_tableview;
	
	// NSLog(@"%s", _cmd);
	
	NSString* s = [m_searchfield stringValue];

	if(key == 127) {
		// NSLog(@"backspace");
		int len = [s length];
		if(len == 0) {
			// NSLog(@"parentdir");
			// [self tableViewParentDir:aNotification];
			[self tableViewParentDir:aNotification];
			return;
		} else {
			// NSLog(@"before: %i %@", len, s);
			s = [s substringToIndex:len-1];
			// NSLog(@"after: %@", s);
		}
	} else {
		s = [s stringByAppendingFormat:@"%C", key];
		
	}
	[m_searchfield setStringValue:s];
	
	[self syncWithSearchField];
}

- (void)controlTextDidChange:(NSNotification *)aNotification {
	// NSLog(@"%s", _cmd);
	id thing = [aNotification object];
	if((NSSearchField*)thing == m_searchfield) {
		// NSLog(@"%s", _cmd);
		[self syncWithSearchField];
	}
}

- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
	// NSLog(@"%s", _cmd);
	
	return YES;
}

-(void)tableViewShowMenu:(NSNotification*)aNotification {
	NSString* s = [aNotification name];
	if(s == nil) {
		NSLog(@"%s notification name is nil", _cmd);
		return;
	}
	if([s isEqualToString:@"ARROW_LEFT"]) {
		[self showActionMenu];
	} else {
		[self showMenu2];
	}
}

-(void)tableViewHitSpace:(NSNotification*)aNotification {
	// NSLog(@"%s", _cmd);

	int row = [m_tableview selectedRow];     
	int row_count = [m_tableview numberOfRows];

	if(row_count <= 0) {
		return;
	}

	if(row < 0) {
		return;
	}
	
	[self toggleSelectForRow:row];
	
	row += 1;
	if(row >= row_count) {
		/*
		HACK: We want the row to be reloaded. 
		When we hit the bottom of the tableview then we have to
		trick NSTableView into believing that the it should
		reload the row. By deselecting the row and then
		selecting it again, we make sure it gets reloaded.
		*/
		row = row_count - 1;
		[m_tableview deselectRow:row];
	}

	[m_tableview scrollRowToVisible:row];

	NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:row];
	[m_tableview selectRowIndexes:indexes byExtendingSelection:NO];

  	[self rebuildInfo];

	[NSCursor setHiddenUntilMouseMoves:YES];
}

-(void)editFilename {
	// NSLog(@"%s", _cmd);

	NSTableView* tv = m_tableview;
	NSString* path = [self pathForCurrentRow];
	int row = [self row];

	if(path == nil) {
		return;
	}
	
	path = [path lastPathComponent];
	NSString* filename_no_suffix = [path stringByDeletingPathExtension];

	int row_count = [tv numberOfRows];
	if(row_count < 1) return;

	[tv editColumn:[tv columnWithIdentifier:@"filename"] row:row withEvent:nil select:YES];

	NSText* txt = [tv currentEditor];
	// NSLog(@"NSText: %@", txt);
	[txt setRichText:NO];

	[txt setString:path];
	[txt setSelectedRange:NSMakeRange(0, [filename_no_suffix length])];
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification {
/*	NSLog(@"%s", _cmd);
	NSLog(@"%s obj: %@", _cmd, [aNotification object]);
	NSLog(@"%s obj: %@", _cmd, [aNotification userInfo]);/**/

	if([aNotification object] == m_tableview) {
		NSTableView* tv = m_tableview;
		NSString* src_path = [self pathForCurrentRow];

		NSText* txt = [tv currentEditor];
		NSString* s = [txt string];

		NSString* dst_path = [src_path stringByDeletingLastPathComponent];
		dst_path = [dst_path stringByAppendingPathComponent:s];

		// NSLog(@"%s rename: %@ %@", _cmd, src_path, dst_path);
		
		SEL sel = @selector(pane:renameFromPath:toPath:);
		if([m_delegate respondsToSelector:sel]) {
			[m_delegate pane:self renameFromPath:src_path toPath:dst_path];
		}
	}
}

/*
traps enter and esc and edit/cancel without entering next row
*/
-(BOOL)control:(NSControl *)control 
       textView:(NSTextView *)textView 
    doCommandBySelector:(SEL)command
{
	// NSLog(@"%s", _cmd);
	if([textView methodForSelector:command] == [textView methodForSelector:@selector(insertNewline:)] ) {
		[[control window] makeFirstResponder:control];
		return YES;
	}
	if([[control window] methodForSelector:command] == [[control window] methodForSelector:@selector(_cancelKey:)] ||
		[textView methodForSelector:command] == [textView methodForSelector:@selector(complete:)] ) {
		[control abortEditing];
		[[control window] makeFirstResponder:control];

		return YES;
	}
	return NO;
}


-(void)showActionMenu {
	
	NSTableView* tv = m_tableview;
		
	NSRect rect = [tv frameOfCellAtColumn:1 row:[tv selectedRow]];
	NSPoint point = NSMakePoint(
		rect.origin.x + rect.size.width * 0.0 - 20,
		rect.origin.y + rect.size.height * 1.0 + 0
	);
	// NSLog(@"A: %.2f %.2f", point.x, point.y);
	
	NSPoint location = [tv convertPoint:point toView:nil];
	// NSLog(@"B: %.2f %.2f", location.x, location.y);

	NSEvent* event = [NSEvent otherEventWithType:NSApplicationDefined
		location:location 
		modifierFlags:0 
		timestamp:0
		windowNumber:[[tv window] windowNumber]
		context:[[tv window] graphicsContext]
		subtype:100
		data1:0
		data2:0
	];

	JFActionMenu* am = [JFActionMenu shared];
	[am setPath:[self pathForCurrentRow]];
	NSMenu* menu = [am menu];
    [NSMenu popUpContextMenu:menu withEvent:event forView:tv];
		
	[NSCursor setHiddenUntilMouseMoves:YES];
}

-(void)showMenu2 {
	
	NSTableView* tv = m_tableview;
		
	NSRect rect = [tv frameOfCellAtColumn:1 row:[tv selectedRow]];
	NSPoint point = NSMakePoint(
		rect.origin.x + rect.size.width * 0.0 - 20,
		rect.origin.y + rect.size.height * 1.0 + 0
	);
	// NSLog(@"A: %.2f %.2f", point.x, point.y);
	
	NSPoint location = [tv convertPoint:point toView:nil];
	// NSLog(@"B: %.2f %.2f", location.x, location.y);

	NSEvent* event = [NSEvent otherEventWithType:NSApplicationDefined
		location:location 
		modifierFlags:0 
		timestamp:0
		windowNumber:[[tv window] windowNumber]
		context:[[tv window] graphicsContext]
		subtype:100
		data1:0
		data2:0
	];
	
	NSMenu* menu = [[[NSMenu alloc] initWithTitle:@"Other Menu"] autorelease];


	/*************************
	build the "sort" submenu
	*************************/
	NSMenu* sort_menu = nil;
	{
		NSMenu* submenu = [[[NSMenu alloc] initWithTitle:@"Sort"] autorelease];
		NSMenuItem* mi = [[[NSMenuItem alloc] init] autorelease];
		[mi setTitle:@"Sort"];
		[menu addItem:mi];
		[menu setSubmenu:submenu forItem:mi];
		sort_menu = submenu;
	}
	{
		NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:@"Name, Type" action:@selector(tableMenuAction:) keyEquivalent:@""] autorelease];
		[mi setTag:kTableMenuSortByNameType];
		[mi setTarget:self];
		[sort_menu addItem:mi];
	}
	{
		NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:@"Size, Type" action:@selector(tableMenuAction:) keyEquivalent:@""] autorelease];
		[mi setTag:kTableMenuSortBySizeType];
		[mi setTarget:self];
		[sort_menu addItem:mi];
	}
	{
		NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:@"Name" action:@selector(tableMenuAction:) keyEquivalent:@""] autorelease];
		[mi setTag:kTableMenuSortByName];
		[mi setTarget:self];
		[sort_menu addItem:mi];
	}
	{
		NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:@"Name Rev" action:@selector(tableMenuAction:) keyEquivalent:@""] autorelease];
		[mi setTag:kTableMenuSortByName_Reverse];
		[mi setTarget:self];
		[sort_menu addItem:mi];
	}
	{
		NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:@"Size" action:@selector(tableMenuAction:) keyEquivalent:@""] autorelease];
		[mi setTag:kTableMenuSortBySize];
		[mi setTarget:self];
		[sort_menu addItem:mi];
	}
	{
		NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:@"Size Rev" action:@selector(tableMenuAction:) keyEquivalent:@""] autorelease];
		[mi setTag:kTableMenuSortBySize_Reverse];
		[mi setTarget:self];
		[sort_menu addItem:mi];
	}
	{
		NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:@"Unsorted" action:@selector(tableMenuAction:) keyEquivalent:@""] autorelease];
		[mi setTag:kTableMenuUnsorted];
		[mi setTarget:self];
		[sort_menu addItem:mi];
	}
/*	{
		NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:@"Random" action:@selector(tableMenuAction:) keyEquivalent:@""] autorelease];
		[mi setTag:10008];
		[mi setTarget:self];
		[sort_menu addItem:mi];
	}*/

#if 0
	/*************************
	build the "column" submenu
	*************************/
	NSMenu* column_menu = nil;
	{
		NSMenu* submenu = [[[NSMenu alloc] initWithTitle:@"Columns"] autorelease];
		NSMenuItem* mi = [[[NSMenuItem alloc] init] autorelease];
		[mi setTitle:@"Columns"];
		[menu addItem:mi];
		[menu setSubmenu:submenu forItem:mi];
		column_menu = submenu;
	}
	{
		NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:@"Type - Name - Size" action:@selector(tableMenuAction:) keyEquivalent:@""] autorelease];
		[mi setTag:20001];
		[mi setTarget:self];
		[column_menu addItem:mi];
	}
	{
		NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:@"Type - Size - Name" action:@selector(tableMenuAction:) keyEquivalent:@""] autorelease];
		[mi setTag:20002];
		[mi setTarget:self];
		[column_menu addItem:mi];
	}
	{
		NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:@"Type - Name - Permissions" action:@selector(tableMenuAction:) keyEquivalent:@""] autorelease];
		[mi setTag:20003];
		[mi setTarget:self];
		[column_menu addItem:mi];
	}
	{
		NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:@"Type - Name - Kind" action:@selector(tableMenuAction:) keyEquivalent:@""] autorelease];
		[mi setTag:20004];
		[mi setTarget:self];
		[column_menu addItem:mi];
	}
#endif

#if 0
	/*************************
	build the "show" submenu
	*************************/
	NSMenu* show_menu = nil;
	{
		NSMenu* submenu = [[[NSMenu alloc] initWithTitle:@"Show"] autorelease];
		NSMenuItem* mi = [[[NSMenuItem alloc] init] autorelease];
		[mi setTitle:@"Show"];
		[menu addItem:mi];
		[menu setSubmenu:submenu forItem:mi];
		show_menu = submenu;
	}
	{
		NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:@"Show All" action:@selector(tableMenuAction:) keyEquivalent:@""] autorelease];
		[mi setTag:30001];
		[mi setTarget:self];
		[show_menu addItem:mi];
	}
	{
		NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:@"Folders Only" action:@selector(tableMenuAction:) keyEquivalent:@""] autorelease];
		[mi setTag:30002];
		[mi setTarget:self];
		[show_menu addItem:mi];
	}
	{
		NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:@"Files Only" action:@selector(tableMenuAction:) keyEquivalent:@""] autorelease];
		[mi setTag:30003];
		[mi setTarget:self];
		[show_menu addItem:mi];
	}
	{
		NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:@"Images Only" action:@selector(tableMenuAction:) keyEquivalent:@""] autorelease];
		[mi setTag:30004];
		[mi setTarget:self];
		[show_menu addItem:mi];
	}
#endif

	/*************************
	build the "ignore" submenu
	*************************/
/*	NSMenu* hide_menu = nil;
	{
		NSMenu* submenu = [[[NSMenu alloc] initWithTitle:@"Visibility"] autorelease];
		NSMenuItem* mi = [[[NSMenuItem alloc] init] autorelease];
		[mi setTitle:@"Visibility"];
		[menu addItem:mi];
		[menu setSubmenu:submenu forItem:mi];
		hide_menu = submenu;
	}
	{
		NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:@"Show All Files" action:@selector(tableMenuAction:) keyEquivalent:@""] autorelease];
		[mi setTag:40001];
		[mi setTarget:self];
		[mi setState:NSOffState];
		[hide_menu addItem:mi];
	}
	{
		NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:@"Don't Show Hidden Files" action:@selector(tableMenuAction:) keyEquivalent:@""] autorelease];
		[mi setTag:40002];
		[mi setTarget:self];
		[mi setState:NSOnState];
		[hide_menu addItem:mi];
	}
	{
		NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:@"Customize…" action:@selector(menuAction:) keyEquivalent:@""] autorelease];
		[mi setTag:40500];
		[mi setTarget:self];
		[hide_menu addItem:mi];
	}*/

	[menu addItem:[NSMenuItem separatorItem]];
	{
		NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:@"Show Hidden Files" action:@selector(tableMenuAction:) keyEquivalent:@""] autorelease];
		[mi setTag:kTableMenuShowHiddenFiles];
		[mi setTarget:self];
		[mi setState:(m_show_hidden_files ? NSOnState : NSOffState)];
		[menu addItem:mi];
	}


    [NSMenu popUpContextMenu:menu withEvent:event forView:tv];
		
	[NSCursor setHiddenUntilMouseMoves:YES];
}

-(IBAction)tableMenuAction:(id)sender {
	int tag = [sender tag];
	// NSLog(@"%s %i", _cmd, tag);
    
	switch(tag) {
	case kTableMenuSortByNameType: {
		[m_panel_table setSortOrderString:@"tn"];
		[m_panel_table sort];
		[self reloadTableData];
		break; }
	case kTableMenuSortBySizeType: {
		[m_panel_table setSortOrderString:@"tsn"];
		[m_panel_table sort];
		[self reloadTableData];
		break; }
	case kTableMenuSortByName: {
		[m_panel_table setSortOrderString:@"n"];
		[m_panel_table sort];
		[self reloadTableData];
		break; }
	case kTableMenuSortByName_Reverse: {
		[m_panel_table setSortOrderString:@"-n"];
		[m_panel_table sort];
		[self reloadTableData];
		break; }
	case kTableMenuSortBySize: {
		[m_panel_table setSortOrderString:@"sn"];
		[m_panel_table sort];
		[self reloadTableData];
		break; }
	case kTableMenuSortBySize_Reverse: {
		[m_panel_table setSortOrderString:@"-sn"];
		[m_panel_table sort];
		[self reloadTableData];
		break; }
	case kTableMenuUnsorted: {
		[m_panel_table setSortOrderString:@"u"];
		[m_panel_table sort];
		[self reloadTableData];
		break; }
	case kTableMenuShowHiddenFiles: {
		// TODO: save to preferences... somehow. a NSCoder per tab?
		m_show_hidden_files = !m_show_hidden_files;
		[self rebuildInfo];
		[self update];
		[self refreshUI];
		break; }
	}
}

-(void)revealInFinder {
	NSString* path = [self pathInFinder];
	if(path == nil) return;
	[[NSWorkspace sharedWorkspace] 
		selectFile:path inFileViewerRootedAtPath:nil];
}

-(void)openFile {
	NSMutableArray* url_array = [NSMutableArray arrayWithCapacity:300];
	NSURL* current_url = nil;

	NSUInteger n = [m_panel_table visibleNumberOfRows];
	for(NSUInteger i=0; i < n; ++i) {
		BOOL is_current_row = (i + 1 == m_row);
		BOOL is_selected = [m_panel_table visibleSelectedForRow:i];
		
		if((is_current_row == NO) && (is_selected == NO)) {
			continue;
		}

		NSString* filename = [m_panel_table visibleNameForRow:i];
		if(filename == nil) {
			continue;
		}

		PanelTableType pttype = [m_panel_table visibleTypeForRow:i];
		BOOL isdir = (
			(pttype == kPanelTableTypeDir) || 
			(pttype == kPanelTableTypeDirLink) || 
			(pttype == kPanelTableTypeLink));
		
		NSString* path = [m_path stringByAppendingPathComponent:filename];
		if(path == nil) {
			continue;
		}

		NSURL* url = [NSURL fileURLWithPath:path isDirectory:isdir];
		if(url == nil) {
			continue;
		}
		
		if(is_selected) {
			[url_array addObject:url];
		}
		if(is_current_row) {
			current_url = url;
		}
	}
	
	if([url_array count] == 0) {
		if(current_url == nil) {
			return;
		}
		[url_array addObject:current_url];
	}
		

	NSWorkspaceLaunchOptions options = NSWorkspaceLaunchDefault;
	// options = NSWorkspaceLaunchWithoutActivation; // open in background

	BOOL ok = [[NSWorkspace sharedWorkspace]
		openURLs:url_array
	    withAppBundleIdentifier:nil
		options:options
		additionalEventParamDescriptor:nil
		launchIdentifiers:nil
	];
	if(!ok)  {
		NSLog(@"%s failed opening files: %@", _cmd, url_array);
	}
}

-(void)selectCenterRow {
	NSTableView* tv = m_tableview;
	NSRect r = [[tv enclosingScrollView] documentVisibleRect];
	NSRange range = [tv rowsInRect:r];
	int row = range.location + range.length / 2;
	NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:row];
	[tv selectRowIndexes:indexes byExtendingSelection:NO];
	[self rebuildInfo];
	[self update];
	[self refreshUI];
}

-(void)textDidChange:(NSNotification *)aNotification {
	// NSLog(@"%s", _cmd);
}

- (void)textDidEndEditing:(NSNotification *)aNotification {
	// NSLog(@"%s", _cmd);
}

-(void)tableView:(NSTableView*)tableView
    didClickTableColumn:(NSTableColumn*)tableColumn
{
	NSLog(@"%s", _cmd);
    // [myTableDataArray sortUsingDescriptors:[tableView sortDescriptors]];
    // [tableView reloadData];

	// NSArray* ary1 = [NSArray arrayWithObjects:@"5", @"2", @"4", @"1", @"3", nil];
	// NSArray* ary1 = [NSArray arrayWithObjects:@"5", @"2", @"4", @"1", @"3", nil];

	NSMutableArray* ary1 = [NSMutableArray arrayWithCapacity:50];
	{
		MyClass* mc = [[[MyClass alloc] init] autorelease];
		[mc setValue:@"5" forKey:@"foo"];
		[ary1 addObject:mc];
	}
	{
		MyClass* mc = [[[MyClass alloc] init] autorelease];
		[mc setValue:@"2" forKey:@"foo"];
		[ary1 addObject:mc];
	}
	{
		MyClass* mc = [[[MyClass alloc] init] autorelease];
		[mc setValue:@"4" forKey:@"foo"];
		[ary1 addObject:mc];
	}
	{
		MyClass* mc = [[[MyClass alloc] init] autorelease];
		[mc setValue:@"1" forKey:@"foo"];
		[ary1 addObject:mc];
	}
	{
		MyClass* mc = [[[MyClass alloc] init] autorelease];
		[mc setValue:@"3" forKey:@"foo"];
		[ary1 addObject:mc];
	}

	NSSortDescriptor* sd = [[[NSSortDescriptor alloc]
              initWithKey:@"foo"
              ascending:YES
              selector:@selector(compare:)] autorelease];

	NSArray* sds = [NSArray arrayWithObjects:sd, nil];
	NSArray* ary2 = [ary1 sortedArrayUsingDescriptors:sds];
	
	NSLog(@"before: %@", ary1);
	NSLog(@"after: %@", ary2);

}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {

/*    if([[aTableColumn identifier] isEqualToString: @"filename"]) {
		if(rowIndex == 0) {
			NSColor* color = [NSColor colorWithCalibratedWhite:0.1 alpha:1.0];
			[aCell setBackgroundColor:color];
			[aCell setDrawsBackground:YES];
		} else {
			[aCell setDrawsBackground:NO];
		}
	}*/
    if([[aTableColumn identifier] isEqualToString: @"filesize"]) {
		if([aCell isKindOfClass:[JFSizeInfoCell class]] == NO) {
			return;
		}
		JFSizeInfoCell* jic = (JFSizeInfoCell*)aCell;
		
		uint64_t a = 0;
		if(rowIndex > 0) {
			a = [m_panel_table visibleSizeForRow:(rowIndex-1)];
		}
		
		[jic setSize:a];
	}
    if([[aTableColumn identifier] isEqualToString: @"dates"]) {
		if([aCell isKindOfClass:[JFDateInfoCell class]] == NO) {
			return;
		}
		JFDateInfoCell* jic = (JFDateInfoCell*)aCell;
		
		if(rowIndex == 0) {
			[jic setHidden:YES];
			[jic setError:0];
			return;
		}

		struct stat64 st;
		BOOL ok = [m_panel_table visibleStat64ForRow:(rowIndex-1) outStat64:&st];
		if(!ok) {
			[jic setHidden:NO];
			[jic setError:1];
			return;
		}

		float xa, xb, xc, xd;

		time_t time_now;
		time_now = static_cast<time_t>(m_cache_item_timestamp);

		{
			struct timespec ts = st.st_birthtimespec;
			time_t time_1 = ts.tv_sec;
			double diff = difftime(time_now, time_1);
			xa = diff;
		}
		{
			struct timespec ts = st.st_ctimespec;
			time_t time_1 = ts.tv_sec;
			double diff = difftime(time_now, time_1);
			xb = diff;
		}
		{
			struct timespec ts = st.st_mtimespec;
			time_t time_1 = ts.tv_sec;
			double diff = difftime(time_now, time_1);
			xc = diff;
		}
		{
			struct timespec ts = st.st_atimespec;
			time_t time_1 = ts.tv_sec;
			double diff = difftime(time_now, time_1);
			xd = diff;
		}

		/*
		>> 365 * 24 * 60 * 60
		=> 31536000  (seconds per year)
		*/
		float a = 1.0 - xa / 31536000.0;
		float b = 1.0 - xb / 31536000.0;
		float c = 1.0 - xc / 31536000.0;
		float d = 1.0 - xd / 31536000.0;
		
		// NSLog(@"%s %.3f %.3f", _cmd, a, b);

		// a = 0;
		// b = 0.33;
		// c = 0.66;
		// d = 1;
	
		[jic setHidden:NO];
		[jic setError:0];
		[jic setValue0:a];
		[jic setValue1:b];
		[jic setValue2:c];
		[jic setValue3:d];
	}

    if([[aTableColumn identifier] isEqualToString: @"permissions"]) {
		if([aCell isKindOfClass:[JFPermissionInfoCell class]] == NO) {
			return;
		}
		JFPermissionInfoCell* jic = (JFPermissionInfoCell*)aCell;

		int perm = 0;


		do {
			if(rowIndex == 0) {
				break;
			}

			NSUInteger pmask = [m_panel_table visiblePermissionForRow:(rowIndex-1)];
			perm = pmask;
		} while(0);

		[jic setPermissions:perm];
	}

#if 0
	return;
    if([[aTableColumn identifier] isEqualToString: @"filename"]) {
		if(rowIndex == 0) {
			[aCell setDrawsBackground:NO];
		} else
		if(((rowIndex - 1) / 3) & 1) {
		// if((rowIndex - 1) & 4) {
			NSColor* color = [NSColor colorWithCalibratedWhite:0.7 alpha:1.0];
			[aCell setBackgroundColor:color];
			[aCell setDrawsBackground:YES];
		} else {
			NSColor* color = [NSColor colorWithCalibratedWhite:0.74 alpha:1.0];
			[aCell setBackgroundColor:color];
			[aCell setDrawsBackground:YES];
		}
	} else {
		if(rowIndex == [aTableView selectedRow]) {
			[aCell setBackgroundColor:nil];
		} else
		if(rowIndex == 0) {
			[aCell setBackgroundColor:nil];
		} else
		if(((rowIndex - 1) / 3) & 1) {
		// if((rowIndex - 1) & 4) {
			NSColor* color = [NSColor colorWithCalibratedWhite:0.7 alpha:1.0];
			[aCell setBackgroundColor:color];
		} else {
			NSColor* color = [NSColor colorWithCalibratedWhite:0.74 alpha:1.0];
			[aCell setBackgroundColor:color];
		}

		if(aTableView == m_left_tableview) {
			[aCell setImage: [m_left_pane tableSizeForRow:rowIndex]];
		}
		if(aTableView == m_right_tableview) {
			[aCell setImage: [m_right_pane tableSizeForRow:rowIndex]];
		}
	}
#endif
}

#if 0
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	return [[aTableColumn identifier] isEqualToString: @"filename"];
}
#endif


-(void)wrapperRegisterRequest:(NSString*)path {
	// NSLog(@"%s", _cmd);

	double timestamp = m_time_change_path;
	int timestamp_i = (int)timestamp;
	if(timestamp_i > 0) timestamp_i = timestamp_i % 1000;
	NSString* ts = [NSString stringWithFormat:@"%03i", timestamp_i];

	KCDiscoverStatItem* item = [[[KCDiscoverStatItem alloc] init] autorelease];
	[item setTransactionId:m_transaction_id];
	[item setTimestamp:ts];                                          
/*	[item setTime0:43];
	[item setTime1:44];
	[item setTime2:45];
	[item setTime3:46];*/
	[item setModule:m_name];
	[item setPath:path];  
	[item setMessage:@"hang 0"];
	
	[m_discover_stat_item autorelease];
	m_discover_stat_item = [item retain];
	
	[m_discover_stat_items addObject:item];

	// remove old entries, so we have 10 rows of recent stats
	NSArray* ary = [m_discover_stat_items content];
	int n = [ary count];
	if(n > 10) {
		NSRange range = NSMakeRange(n - 10, 10);
		ary = [[ary subarrayWithRange:range] mutableCopy];
		// NSLog(@"%s clamp", _cmd);
		[m_discover_stat_items setContent:ary];
	}
}


-(int)finderLabelCPath:(NSString*)path {
/*	CFURLRef url;
	FSRef fsRef;
	Boolean ret;
	FSCatalogInfo cinfo;

	// Get FSRef
	url = CFURLCreateWithFileSystemPath(NULL, (CFStringRef)path, kCFURLPOSIXPathStyle, FALSE);
	if (!url)
		return 0;
	ret = CFURLGetFSRef(url, &fsRef);
	CFRelease(url);

	// Get Finder flags
	if (ret && (FSGetCatalogInfo(&fsRef, kFSCatInfoFinderInfo, &cinfo, NULL, NULL, NULL) == noErr))
		return (((FileInfo*)&cinfo.finderInfo)->finderFlags & kColor);/**/
	return 0;
}

-(void)selectAll {
	NSUInteger n = [m_panel_table visibleNumberOfRows];
	for(NSUInteger i=0; i<n; ++i) {
		[m_panel_table setVisibleSelectedForRow:i value:YES];
	}
	[self reloadTableData];
}

-(void)selectNone {
	NSUInteger n = [m_panel_table visibleNumberOfRows];
	for(NSUInteger i=0; i<n; ++i) {
		[m_panel_table setVisibleSelectedForRow:i value:NO];
	}
	[self reloadTableData];
}

-(void)selectAllOrNone {
	NSUInteger n = [m_panel_table visibleNumberOfRows];
	NSUInteger sel_count = 0;
	for(NSUInteger i=0; i<n; ++i) {
		if([m_panel_table visibleSelectedForRow:i]) sel_count++;
	}
	if(sel_count == n) {
		[self selectNone];
	} else {
		[self selectAll];
	}
}

-(void)invertSelection {
	NSUInteger n = [m_panel_table visibleNumberOfRows];
	for(NSUInteger i=0; i<n; ++i) {
		BOOL value = [m_panel_table visibleSelectedForRow:i];
		value = !value;
		[m_panel_table setVisibleSelectedForRow:i value:value];
	}
	[self reloadTableData];
}

-(void)registerForDraggedTypes {
	[m_tableview registerForDraggedTypes:
		[NSArray arrayWithObject:NSFilenamesPboardType] 
	];
}

/*
When a drag operation begins, the table sends a
tableView:writeRowsWithIndexes:toPasteboard: message 
to the data source. Your implementation of this method 
should place the data for the specified rows onto the 
provided pasteboard and return YES. If, for some 
reason, you do not want the drag operation to continue, 
your method should return NO.
*/
- (BOOL)tableView:(NSTableView *)tv 
	writeRowsWithIndexes:(NSIndexSet *)rowIndexes 
	toPasteboard:(NSPasteboard*)pb
{
	NSMutableArray* ary = [NSMutableArray arrayWithCapacity:1000];
	unsigned current_index = [rowIndexes lastIndex];
    while (current_index != NSNotFound) {  
		[ary insertObject:[self pathForRow:current_index] atIndex:0];
        current_index = [rowIndexes indexLessThanIndex: current_index];
    }
	
	[pb declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:self];
	[pb setPropertyList:ary forType:NSFilenamesPboardType];
    return YES;
}

#if 0
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
    // Add code here to validate the drop
    NSLog(@"validate Drop");
    return NSDragOperationEvery;
}
#endif

#if 0
- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info
            row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:MyPrivateTableViewDataType];
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    int dragRow = [rowIndexes firstIndex];

	NSLog(@"%s %i", _cmd, dragRow);
 
    // Move the specified row to its new location...
	return YES;
}
#endif

-(void)appToOpenPath:(NSString*)path {

	NSFileManager* fm = [NSFileManager defaultManager];
	BOOL isdir = NO;
	BOOL ok = [fm fileExistsAtPath:path isDirectory:&isdir];
	if(ok == NO) {
		NSLog(@"%s '%@' is not valid path", _cmd, path);
		return;
	}
	if(isdir) {
		// NSLog(@"%s '%@' points to a valid dir", _cmd, path);
		[self changePath:path];
		[self refreshPathControl];
		return;
	}
	// we are dealing with a file
	// NSLog(@"%s '%@' points to a valid file", _cmd, path);
	NSString* path2 = [path stringByDeletingLastPathComponent];

	ok = [fm fileExistsAtPath:path2 isDirectory:&isdir];
	if(ok && isdir) {
		[self changePath:path2];
		[self refreshPathControl];
		// idea: select the file
		return;
	}
	NSLog(@"%s '%@' is not dir, but '%@' is a valid file", _cmd, path2, path);
}

-(NSArray*)selectedNames {
	NSMutableArray* ary = [NSMutableArray arrayWithCapacity:1000];
	NSUInteger n = [m_panel_table visibleNumberOfRows];
	for(NSUInteger i=0; i<n; ++i) {
		if([m_panel_table visibleSelectedForRow:i]) {
			[ary addObject:[m_panel_table visibleNameForRow:i]];
		}
	}
	return ary;
}

-(NSString*)description {
	NSUInteger n = [m_panel_table visibleNumberOfRows];
	return [NSString stringWithFormat:
		@"OFMPane\n"
		"path: %@\n"
		"number of rows: %i",
		m_path,
		(int)n
	];
}

-(void)dealloc {
	[m_name release];

	[m_path release];
	[m_info release];

	[m_task terminate];
	[m_task release];
	[m_task_output release];
	
	[m_breadcrum_stack release];
	[m_volume_info release];
	
	[m_info_attr1 release];
	[m_info_attr2 release];

	[m_size_info_cell release];
	[m_date_info_cell release];

	[m_panel_table release];
	
    [super dealloc];
}

@end
