//
//  NCLister.m
//  NCCore
//
//  Created by Simon Strandgaard on 03/02/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


/*



  4  self
  4  nameptr
 12+ name
  4  extensionptr
  4+ extension
  8  size
 :1  is row selected
 :1  is row visible
 :7  type: file, dir, link, etc

----------------------------------
 ~50 bytes minimum
 ~80 bytes for a longer name
 ~128 bytes with overhead

50000 records
50 000 * 50  = 2 500 000 = 2.5 mb
50 000 * 128 = 6 400 000 = 6.4 mb




names1

 16  name // extension

----------------------------------
 16 bytes

50000 records
50 000 * 16 = 800 000 = 800 kb



*/

#import "NCLog.h"                                                  
#import "NCCommon.h"                                                  
#import "NCLister.h"                                                  
#import "NCListerTableView.h"
#import "NCListerScroller.h"
#import "NCListerTableTextCell.h"
#import "NCImageAndTextCell.h"
#import "NCPermissionCell.h"
#import "NCDateCell.h"
#import "NCListerBreadcrumb.h"
#import "NCListerItem.h"
#import "NCTableHeaderCell.h"
#import "NCTableHeaderView.h"
#import "NCFileManager.h"
#import "NCListerDataSource.h"
#import "NSImage+ImageNamedForClass.h"
#import "NCFileManager.h"
#import "NSArray+PrependPath.h"
#import "NSGradient+PredefinedGradients.h"
#import "NSTableView+ColumnLayout.h"
#import "NCTimeProfiler.h"
#import "NCImageCache.h"
#import "NCListerCell.h"
#import "NSMutableArray+Shuffling.h"


// #define IMPROVED_BACKSPACE

// #define RANDOMIZE_ITEMS



#define kNCListerPreferencesContext @"NCListerPreferencesContext"

static void* PreferencesObservationContext = (void *)kNCListerPreferencesContext;


#define kNCListerColumnIdentifierName @"Name"        
#define kNCListerColumnIdentifierSize @"Size"    
#define kNCListerColumnIdentifierRsrcSize @"RsrcSize"
#define kNCListerColumnIdentifierMode @"Mode"
#define kNCListerColumnIdentifierOwner @"Owner"       
#define kNCListerColumnIdentifierGroup @"Group"
#define kNCListerColumnIdentifierAccessed @"Accessed"
#define kNCListerColumnIdentifierDataModified @"DataModified"
#define kNCListerColumnIdentifierStatChanged @"StatChanged"
#define kNCListerColumnIdentifierCreated @"Created"
#define kNCListerColumnIdentifierBackup @"Backup"
#define kNCListerColumnIdentifierRef @"Ref"
#define kNCListerColumnIdentifierACL @"ACL"
#define kNCListerColumnIdentifierXAttr @"XAttr"
#define kNCListerColumnIdentifierInode @"Inode"
#define kNCListerColumnIdentifierFlags @"Flags"
#define kNCListerColumnIdentifierKind @"Kind"
#define kNCListerColumnIdentifierType @"Type"

enum {
	ICON_GO_BACK = 1,
	ICON_FILE,
	ICON_DIR,
	ICON_UNKNOWN,
	ICON_LINK_TO_FILE,
	ICON_LINK_TO_DIR,
	ICON_LINK_TO_UNKNOWN,
};



typedef struct {
	float font_size;
	int row_height;
	BOOL anti_alias;
	float padding_left;
	float padding_right;
	float offset_y;
	float coretext_offset_y;
	const char* font_name;
} FontAndSize;

const FontAndSize font_and_size[] = {
	18, 23, YES, 10,  5, -1, -6, "Helvetica",
	// 12, 16, YES, 10,  5,  -1,  0, "Lucida Grande",
	// 12, 18, YES, 10,  5,  0,  0, "Lucida Grande",
	12, 20, YES, 10,  5,  1, -6, "Lucida Grande",
	15, 13,  NO, 10,  5, -5, -3, "FixedsysTTF",
	15, 16,  NO, 10,  5, -3, -4, "FixedsysTTF",
	20, 23, YES, 10,  5, -7, -5, "Menlo",
	22, 22, YES, 10,  5,  0, -5, "Consolas",
	11, 15,  NO, 10,  5, -2, -3, "Tahoma",
	13, 14,  NO, 10,  5, -6, -3, "Tahoma Negreta",
	 9,  9,  NO, 10,  5, -4, -2, "MPW",       
	12, 17, YES, 10,  5,  0,  0, "Lucida Grande",
	20, 22, YES, 10,  5, -6,  0, "Andale Mono",
	20, 22, YES, 10,  5, -8,  0, "Droid Sans Mono",
	24, 22, YES, 10,  5, -9,  0, "monofur",
	18, 22, YES, 10,  5, -5,  0, "ProFont",
	20, 22, YES, 10,  5, -4,  0, "Courier",
	18, 22, YES, 10,  5, -5,  0, "Anonymous",
	20, 22, YES, 10,  5, -3,  0, "Monaco",
	20, 22, YES, 10,  5, -8,  0, "Bitstream Vera Sans Mono",
	 9, 13, YES, 10,  5,  0,  0, "ProFont",
	10, 13, YES, 10,  5,  0,  0, "Anonymous",
	10, 13, YES, 10,  5,  0,  0, "Courier",
	10, 14, YES, 10,  5,  0,  0, "Monaco",
	 9, 13, YES, 10,  5,  0,  0, "Monaco",
	11, 14, YES, 10,  5, -2,  0, "Andale Mono",
	15, 18, YES, 10,  5, -5,  0, "Bitstream Vera Sans Mono",
	12, 15, YES, 20, 10, -3,  0, "Bitstream Vera Sans Mono",
	11, 13, YES, 10,  5,  1,  0, "Consolas",
	14, 14, YES, 10,  5,  0,  0, "Consolas",
	24, 24, YES, 10,  5,  0,  0, "Consolas",
	10, 13, YES, 10,  5, -1,  0, "Droid Sans Mono",
	16, 20, YES, 16,  8, -5,  0, "Droid Sans Mono",
	23, 28, YES, 10,  5, -5,  0, "Droid Sans Mono",
	22, 27, YES, 20, 10,  2,  0, "Share-TechMono",
	16, 20, YES, 10,  5,  0,  0, "monofur",
	 9, 12,  NO, 10,  5,  0,  0, "MPW",       
	13, 18,  NO, 10,  5,  0,  0, "Envy Code R",
	16, 20,  NO, 10,  5,  0,  0, "Dina ttf 10px",
	15, 18,  NO, 10,  5,  0,  0, "ProggyCleanTT",
	 6,  7,  NO, 10,  5,  0,  0, "New",
	 8,  9,  NO, 10,  5,  0,  0, "04b",
	11, 14, YES, 10,  5,  0,  0, "MonteCarlo",
	 9, 12, YES, 10,  5,  0,  0, "MPW",       
	14, 20, YES, 10,  5,  0,  0, "MPW",
	 8, 10, YES, 10,  5,  0,  0, "Silkscreen",
	16, 20, YES, 10,  5,  0,  0, "Share-TechMono",
	10, 17, YES, 10,  5,  0,  0, "DPCustomMono2",
	12, 18, YES, 10,  5,  0,  0, "BPMono",
	 9, 14, YES, 10,  5,  0,  0, "MPW",
	12, 16, YES, 10,  5,  0,  0, "Verily Serif Mono",
	11, 14, YES, 10,  5,  0,  0, "Aurulent Sans Mono",
};

static const int font_index = 1;



#if 0
@interface MyDebugColumn : NSTableColumn {
}
@end

@implementation MyDebugColumn
- (id)dataCellForRow:(NSInteger)row { 
	id dc = [super dataCellForRow:row];
	LOG_DEBUG(@"dataCellForRow:%i -> %@", (int)row, dc);
	return dc;
}
@end
#endif


BOOL is_the_cocoa_simulator_running() {
	Class IBDocument = NSClassFromString(@"IBDocument");
	if(IBDocument) return YES;
	return NO;
}



@interface NSTableView (NCAddColumnExtension)
-(NSTableColumn*)addColumnWithIdentifier:(NSString*)identifier;
@end

@implementation NSTableView (NCAddColumnExtension)
-(NSTableColumn*)addColumnWithIdentifier:(NSString*)identifier {
	NCTableHeaderCell* hc = [[NCTableHeaderCell alloc] initTextCell:identifier];
	[hc setPaddingCell:NO];
	NSTableColumn* col = [[NSTableColumn alloc] initWithIdentifier:identifier];
	// NSTableColumn* col = [[MyDebugColumn alloc] initWithIdentifier:identifier];
	if(!is_the_cocoa_simulator_running()) {
		/*
		TODO: crash within cocoa simulator.. _adjustFontSize method missing
		*/
		[col setHeaderCell:hc];
	}
	[col setMinWidth:50];
	[self addTableColumn:col];
	return col;
}
@end




@interface NCLister () <NCTableHeaderViewDelegate>

-(void)setup;

-(void)populateImageCacheIfNeeded;

-(void)updateCounters;

-(int)countFilesInDir:(NSString*)path;
-(void)reloadTableSetup;

- (void)inner_setWorkingDir:(NSString*)path;

-(NCListerBreadcrumb*)createBreadcrumb;
-(void)restoreFromBreadcrumb:(NCListerBreadcrumb*)crumb;

-(void)showQuickLook;

-(NSMenu*)headerMenuForColumn:(int)column_index;

-(void)reloadHeader;

-(void)reloadAndPreserve;
-(void)reloadAndReset;
-(void)reloadWithBreadcrumb:(NCListerBreadcrumb*)crumb;
-(void)reload;

-(void)robustSetItems:(NSArray*)items;

-(void)resetSelectionAndCursor;


-(NSArray*)selectedItems;
-(NSArray*)selectedItemsOrCurrentItem;
-(NCListerItem*)currentItem;

-(void)showContextMenu:(NSMenu*)menu;

-(void)navigateOut:(BOOL)clear_history;
-(void)navigateInto:(BOOL)clear_history_in_navigate_out;

-(NCListerItem*)findItemByName:(NSString*)name index:(int*)resultIindex;

-(void)rebuildIndexes;
-(void)selectRememberedItems:(NSArray*)remembered_items;
-(void)setCurrentToRememberedItem:(NCListerItem*)item otherRow:(NSUInteger)otherRow;

-(NSImage*)assignIconToItem:(NCListerItem*)item;

-(void)rebuildSortDescriptors;


@end

@implementation NCLister

#pragma mark -
#pragma mark Initialization / Teardown


@synthesize listerDataSource = m_lister_data_source;
@synthesize active = m_active;
@synthesize tableColumnName = m_tablecolumn_name;
@synthesize tableColumnSize = m_tablecolumn_size;
@synthesize tableColumnResourceForkSize = m_tablecolumn_resource_fork_size;
@synthesize tableColumnPermissions = m_tablecolumn_permissions;
@synthesize tableColumnOwner = m_tablecolumn_owner; 
@synthesize tableColumnGroup = m_tablecolumn_group; 
@synthesize tableColumnAccessed = m_tablecolumn_accessed;
@synthesize tableColumnContentModified = m_tablecolumn_content_modified;
@synthesize tableColumnAttributeModified = m_tablecolumn_attribute_modified;
@synthesize tableColumnCreated = m_tablecolumn_created;
@synthesize tableColumnBackup = m_tablecolumn_backup;
@synthesize tableColumnRefCount = m_tablecolumn_refcount;
@synthesize tableColumnAclCount = m_tablecolumn_aclcount;
@synthesize tableColumnXattrCount = m_tablecolumn_xattrcount;
@synthesize tableColumnInode = m_tablecolumn_inode;
@synthesize tableColumnFlags = m_tablecolumn_flags;
@synthesize tableColumnKind = m_tablecolumn_kind;
@synthesize tableColumnContentType = m_tablecolumn_content_type;
@synthesize tableColumnComment = m_tablecolumn_comment;
@synthesize items = m_items;
@synthesize sortedItems = m_sorted_items;
@synthesize selectedIndexes = m_selected_indexes;
@synthesize currentBreadcrumb = m_current_breadcrumb;
@synthesize breadcrumbStack = m_breadcrumb_stack;
@synthesize autoSaveName = m_auto_save_name;
@synthesize highlightedSelectedTextColor = m_highlighted_selected_text_color;
@synthesize highlightedTextColor = m_highlighted_text_color;
@synthesize selectedTextColor = m_selected_text_color;
@synthesize textColor = m_text_color;
@synthesize selectedBackgroundColor = m_selected_background_color;
@synthesize gridColor = m_grid_color;
@synthesize imageCache = m_image_cache;
@synthesize editName = m_edit_name;
@synthesize nameToIndex = m_name_to_index;
@synthesize inodeToIndex = m_inode_to_index;
@synthesize sortDescriptors = m_sort_descriptors;
@synthesize counters = m_counters;


-(id)initWithCoder:(NSCoder*)coder {
	self = [super initWithCoder:coder];
	if(self) {
		[self setup];
	}
	return self;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
		[self setup];
    }
    return self;
}



- (void)dealloc
{
	NSUserDefaultsController *sdc = [NSUserDefaultsController sharedUserDefaultsController];

	[sdc removeObserver:self forKeyPath:@"values.FontPreset"];
	
	[self setDataSource:nil];
	
}

-(void)setup {
	// LOG_DEBUG(@"self: %08x <<<<<<<<<<<<<-----------------------------!!!!!!!!!!!!!!!!!!!", (void*)self);
	
	m_binding_info = [[NSMutableDictionary alloc] init];
	
	
	m_lister_data_source = nil;

	[self setWorkingDir:@"/"];
	
	[self setBreadcrumbStack:[[NCListerBreadcrumbStack alloc] init]];
	[self setSelectedIndexes:[NSMutableIndexSet indexSet]];
	
	

	NSUserDefaultsController *sdc = [NSUserDefaultsController sharedUserDefaultsController];
	[sdc addObserver:self forKeyPath:@"values.FontPreset" options:0 context:PreferencesObservationContext];
	
	[sdc addObserver:self forKeyPath:@"values.ColorPreset" options:0 context:PreferencesObservationContext];
	
	
	m_sort_column = nil;
	m_sort_reverse = YES;


	m_need_reset_when_updating_items = YES;

	[self adjustThemeForDictionary:[NCLister whiteTheme]];
}

-(void)populateImageCacheIfNeeded {
	if(m_image_cache) return; // already initialized
	
	[self setImageCache:[[NCImageCache alloc] init]];

	{
		NSImage* img = [NSImage imageNamed:@"go_back" forClass:[self class]];
		[m_image_cache setImage:img forTag:ICON_GO_BACK];
	}
	{
		NSImage* img = [NSImage imageNamed:@"SmallGenericDocumentIcon" forClass:[self class]];
		[m_image_cache setImage:img forTag:ICON_FILE];
	}
	{
		NSImage* img = [NSImage imageNamed:@"SmallGenericFolderIcon" forClass:[self class]];
		[m_image_cache setImage:img forTag:ICON_DIR];
	}
	{
		NSImage* img = [NSImage imageNamed:@"unknown" forClass:[self class]];
		[m_image_cache setImage:img forTag:ICON_UNKNOWN];
	}
	{
		NSImage* img = [NSImage imageNamed:@"SmallGenericDocumentIconLink" forClass:[self class]];
		[m_image_cache setImage:img forTag:ICON_LINK_TO_FILE];
	}
	{
		NSImage* img = [NSImage imageNamed:@"SmallGenericFolderIconLink" forClass:[self class]];
		[m_image_cache setImage:img forTag:ICON_LINK_TO_DIR];
	}
	{
		NSImage* img = [NSImage imageNamed:@"unknown_link" forClass:[self class]];
		[m_image_cache setImage:img forTag:ICON_LINK_TO_UNKNOWN];
	}
	// LOG_DEBUG(@"image cache is now initialized");
}


#pragma mark -
#pragma mark Misc


-(IBAction)reloadAction:(id)sender { 
	// preserve the current position and current selection if possible
	[self setCurrentBreadcrumb:nil];
	[self reloadAndPreserve];
}

-(void)setDataSource:(id<NCListerDataSource>)dataSource {
	if(m_lister_data_source != dataSource) {
		m_lister_data_source = dataSource;
	}
	if(m_lister_data_source) {
		[m_lister_data_source setDelegate:self];
	}
}

-(id<NCListerDataSource>)dataSource {
	// no guarantees that we always return a data source or nil
	return m_lister_data_source;
}

-(void)fileSystemDidChange:(id<NCListerDataSource>)dataSource {
	// LOG_DEBUG(@"called");

	[self setCurrentBreadcrumb:nil];
	[self reloadAndPreserve];
}

-(void)reloadAndPreserve {
	[self reload];
}

-(void)reloadAndReset {
	m_need_reset_when_updating_items = YES;
	[self reload];
}

-(void)reloadWithBreadcrumb:(NCListerBreadcrumb*)crumb {
	m_need_reset_when_updating_items = YES;
	self.currentBreadcrumb = crumb;
	[self reload];
}

-(void)reload {
	id<NCListerDataSource> data_source = [self dataSource];
	NSAssert(data_source, @"data_source should have been initialize at this point");
	
	NSString* wdir = [self workingDir];

	[data_source setWorkingDir:wdir];
	[data_source reload];


	/*
	send out a notification that the path has been resolved
	
	at this point the path haven't yet been fully resolved.
	later the worker may contact us with a "resolvedPath" request containing
	the fully resolved path. When that happens we send out this notification again
	*/
	if([self.delegate respondsToSelector:@selector(listerWillLoad:)]) {
		[self.delegate listerWillLoad:self];
	}
}

-(void)listerDataSource:(id<NCListerDataSource>)dataSource resolvedPath:(NSString*)path {
	NSParameterAssert(dataSource);
	NSParameterAssert(path);
	
	// LOG_DEBUG(@"path: %@", path);
	[self inner_setWorkingDir:path];
	
	// send out a notification that the path has been resolved
	if([self.delegate respondsToSelector:@selector(listerDidResolveWorkingDirectory:)]) {
		[self.delegate listerDidResolveWorkingDirectory:self];
	}
}

-(void)listerDataSourceFinishedLoading:(id<NCListerDataSource>)dataSource {
	NSParameterAssert(dataSource);

	if([self.delegate respondsToSelector:@selector(listerDidLoad:)]) {
		[self.delegate listerDidLoad:self];
	}
}

-(void)listerDataSource:(id<NCListerDataSource>)dataSource 
            updateItems:(NSArray*)items 
              progress:(NSUInteger)progress
{
	// the items are "sorted" when we get them back from the worker process
	NSParameterAssert(dataSource);
	NSParameterAssert(items);
	
	// LOG_DEBUG(@"update items. progress: %i", (int)progress);
	
	//uint64_t t0, t1, t11, t2, t3, t4, t5, t6;
	
	//t0 = mach_absolute_time();
	if(!m_image_cache) {
		// LOG_DEBUG(@"populating");
		[self populateImageCacheIfNeeded];
	}

	//t1 = mach_absolute_time();

	// sort the items
	if(!m_sort_descriptors) [self rebuildSortDescriptors];
	if(m_sort_descriptors)  items = [items sortedArrayUsingDescriptors:m_sort_descriptors];

#ifdef RANDOMIZE_ITEMS
	NSMutableArray* arym = [items mutableCopy];
	[arym shuffle];
	items = [NSArray arrayWithArray:arym];
#endif

	// prepend the back to parent dir item
	NSArray* ary = [NSArray arrayWithObject:[NCListerItem backItem]];
	items = [ary arrayByAddingObjectsFromArray:items];

	//t11 = mach_absolute_time();
	
	[self robustSetItems:items];

	//t2 = mach_absolute_time();
	
	if(m_need_reset_when_updating_items) {
		m_need_reset_when_updating_items = NO;
		[self resetSelectionAndCursor];
	}
	
	//t3 = mach_absolute_time();

	//t4 = mach_absolute_time();

	[m_lister_tableview reloadData];

	//t5 = mach_absolute_time();

	[NSCursor setHiddenUntilMouseMoves:YES];
	
	[self updateCounters];

	if(m_current_breadcrumb) {
		[self restoreFromBreadcrumb:m_current_breadcrumb];
	}

	//t6 = mach_absolute_time();

	/*double elapsed0 = subtract_times(t6, t0);
	double elapsed1 = subtract_times(t1, t0);
	double elapsed2 = subtract_times(t2, t1);
	double elapsed3 = subtract_times(t3, t2);
	double elapsed4 = subtract_times(t4, t3);
	double elapsed5 = subtract_times(t5, t4);
	double elapsed6 = subtract_times(t6, t5);
	// LOG_DEBUG(@"%.6fs %.6fs %.6fs %.6fs %.6fs %.6fs %.6fs %.6fs", elapsed0, elapsed1, elapsed2, elapsed3, elapsed4, elapsed5, elapsed6);
	*/

}

// #define MEASURE_ELAPSED_TIME_IN_LISTER
#ifdef MEASURE_ELAPSED_TIME_IN_LISTER
-(void)_recursiveDisplayRectIfNeededIgnoringOpacity:(NSRect)rect 
	isVisibleRect:(BOOL)isvisible 
	rectIsVisibleRectForView:(NSView*)view 
	topView:(BOOL)istop 
{
	uint64_t t0 = mach_absolute_time();

	[super _recursiveDisplayRectIfNeededIgnoringOpacity:rect 
		isVisibleRect:isvisible 
		rectIsVisibleRectForView:view 
		topView:istop
	];

	uint64_t t1 = mach_absolute_time();

	double elapsed = subtract_times(t1, t0);
	if(elapsed > 0.01) {
		LOG_DEBUG(@"%.6fs", elapsed);
	}
}
#endif


-(NSImage*)assignIconToItem:(NCListerItem*)item {
	if(!item) {
		return nil;
	}

	NSImage* icon = [item icon];
	if(icon) {
		return icon;
	}
		
	int itemtype = [item itemType];
	switch(itemtype) {
	case kNCItemTypeGoBack:
		icon = [m_image_cache imageForTag:ICON_GO_BACK];
		break;
	case kNCItemTypeUnknown:
	case kNCItemTypeDirGuess:
	case kNCItemTypeDir:
		icon = [m_image_cache imageForTag:ICON_DIR];
		break;
	case kNCItemTypeLinkToDirGuess:
	case kNCItemTypeLinkToDir:
	case kNCItemTypeAliasToDir:
		icon = [m_image_cache imageForTag:ICON_LINK_TO_DIR];
		break;
	case kNCItemTypeFile:  
	case kNCItemTypeFileOrAlias:
		icon = [m_image_cache imageForTag:ICON_FILE];
		break;
	case kNCItemTypeLinkToFile:  
	case kNCItemTypeAliasToFile:  
		icon = [m_image_cache imageForTag:ICON_LINK_TO_FILE];
		break;
	case kNCItemTypeLinkToOther:  
	case kNCItemTypeLinkIsBroken:
	case kNCItemTypeAliasIsBroken:
		icon = [m_image_cache imageForTag:ICON_LINK_TO_UNKNOWN];
		break;
	case kNCItemTypeNone:
	case kNCItemTypeFifo:  
	case kNCItemTypeChar:  
	case kNCItemTypeBlock:  
	case kNCItemTypeSocket:  
	case kNCItemTypeWhiteout:  
	default:
		icon = [m_image_cache imageForTag:ICON_UNKNOWN];
		break;
	}
	[item setIcon:icon];
	return icon;
}

-(void)updateCounters {
	NSArray* items = m_items;
	
	int number_of_dirs = 0;
	int number_of_files = 0;
	unsigned long long size_of_items = 0;

	int number_of_selected_dirs = 0;
	int number_of_selected_files = 0;
	unsigned long long size_of_selected_items = 0;

	int i = 0;
	int n = [items count];
	for(; i < n; i++) {
		id thing = [items objectAtIndex:i];
		if(![thing isKindOfClass:[NCListerItem class]]) continue;
		NCListerItem* item = (NCListerItem*)thing;

		int add_to_dirs = 0;
		int add_to_files = 0;
		unsigned long long add_to_size = 0;
		
		if([item countsAsDirectory]) {
			add_to_dirs = 1;
		} else
		if([item countsAsFile]) {
			add_to_files = 1;
			add_to_size = [item size];
		} else {
			// ignore items such as ".."
		}
		
		number_of_dirs += add_to_dirs;
		number_of_files += add_to_files;
		size_of_items += add_to_size;
		if([m_selected_indexes containsIndex:i]) {
			number_of_selected_dirs += add_to_dirs;
			number_of_selected_files += add_to_files;
			size_of_selected_items += add_to_size;
		}
	}

	BOOL changed = NO;
	#define SET_COUNTER(a, b) if(a != b) { a = b; changed = YES; }
	
	SET_COUNTER(m_counters.number_of_directories, number_of_dirs);
	SET_COUNTER(m_counters.number_of_files, number_of_files);
	SET_COUNTER(m_counters.size_of_items, size_of_items);
	SET_COUNTER(m_counters.number_of_selected_directories, number_of_selected_dirs);
	SET_COUNTER(m_counters.number_of_selected_files, number_of_selected_files);
	SET_COUNTER(m_counters.size_of_selected_items, size_of_selected_items);

	if(changed) {
		if([self.delegate respondsToSelector:@selector(listerDidUpdateCounters:)]) {
			[self.delegate listerDidUpdateCounters:self];
		}
	}

	// LOG_DEBUG(@"counters: %i %i %llu", sum_dirs, sum_files, sum_bytes);
}

-(void)navigateToDir:(NSString*)path {
	[self setWorkingDir:path];
	[self reloadAndReset];
}

- (NSString*)workingDir {
	return m_working_dir;
}

- (void)setWorkingDir:(NSString*)path {
	if([path isEqual:m_working_dir]) {
		return;
	}
	
	self.currentBreadcrumb = nil; // TODO: find out if this line can be removed
	[self inner_setWorkingDir:path];
}

- (void)inner_setWorkingDir:(NSString*)path {
	/*
	normalize the path.. if you follow a symlink to another symlink,
	then normalize it. e.g.
	/long/dir/my.framework
	go: Resources
	/long/dir/my.framework/Versions/Current/Resources
	normalize path
	/long/dir/my.framework/Versions/A/Resources
	*/
	// TODO: resolve path using worker
	/*
	NCFileManager* ncfm = [NCFileManager shared];
	path = [ncfm resolvePath:path];
	*/
	if(!path) {
		return;
	}

    if (m_working_dir != path) {
        m_working_dir = [path copy];
    }

	if([self.delegate respondsToSelector:@selector(listerDidChangeWorkingDirectory:)]) {
		[self.delegate listerDidChangeWorkingDirectory:self];
	}
}

-(NSString*)currentName {
	return [[self currentItem] name];
}

-(void)setCurrentName:(NSString*)name {
	int n = [m_items count];
	if(n < 1) return;

	int found_row = 0;
	int i = 1;
	for(; i < n; i++) {
		id thing = [m_items objectAtIndex:i];
		if(![thing isKindOfClass:[NCListerItem class]]) continue;
		NCListerItem* item = (NCListerItem*)thing;
	
		if([name isEqual:[item name]]) {
			// LOG_DEBUG(@"match: %i  %@", i, name);
			found_row = i;
			break;
		}
	}
	
	NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:found_row];
	[m_lister_tableview selectRowIndexes:indexes byExtendingSelection:NO];

	[m_lister_tableview scrollRowToVisible:0];
	// TODO: make an attempt at restoring the scroll position
}


- (void)setValue:(id)value forKey:(NSString *)key {
	// LOG_DEBUG(@"NCLister setValue:%@ forKey:%@", value, key);
	[super setValue:value forKey:key];
}


-(int)countFilesInDir:(NSString*)path {
#if 1
	NSFileManager* fm = [NSFileManager defaultManager];

	int count = 0;
	NSDirectoryEnumerator* dirEnum = [fm enumeratorAtPath:path];
	for(NSString* name in dirEnum) {

		NSString* path2 = [path stringByAppendingPathComponent:name];

		BOOL isdir = NO;
		BOOL exists = [fm fileExistsAtPath:path2 isDirectory:&isdir];
		if(!exists) {
//			LOG_DEBUG(@"skipping: %@", path);
			continue;
		}

	    if(isdir) {
	        [dirEnum skipDescendents];
		}

		count++;
	}

#endif
	return count;
}

- (BOOL)acceptsFirstResponder {
	return NO;
}

-(void)activate {
	[[self window] makeFirstResponder:m_lister_tableview];
	[m_lister_tableview setFocusRingType:NSFocusRingTypeNone];
	m_active = YES;
	[self reloadTableSetup];
}

-(void)deactivate {
	m_active = NO;
	[self reloadTableSetup];
}

-(BOOL)isActiveTableView {
	return m_active;
}



/*- (id)initWithFrame:(NSRect)frame 
{
    self = [super initWithFrame:frame];
    if (self) 
	{
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super initWithCoder:decoder]) != nil)
	{
	}
	return self;
} */

/*- (void)viewWillMoveToSuperview:(NSView *)newSuperview {
	[super viewWillMoveToSuperview:newSuperview];
} */

-(void)adjustThemeForDictionary:(NSDictionary*)dict {
	self.highlightedSelectedTextColor = [dict objectForKey:@"highlightedSelectedTextColor"]; 
	self.highlightedTextColor = [dict objectForKey:@"highlightedTextColor"]; 
	self.selectedTextColor = [dict objectForKey:@"selectedTextColor"]; 
	self.textColor = [dict objectForKey:@"textColor"]; 
	self.selectedBackgroundColor = [dict objectForKey:@"selectedBackgroundColor"]; 
	self.gridColor = [dict objectForKey:@"gridColor"]; 
}

+(NSDictionary*)whiteTheme {
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSColor redColor],
		@"highlightedSelectedTextColor",

		[NSColor whiteColor],
		@"highlightedTextColor",

		[NSColor whiteColor],
		@"selectedTextColor",

		[NSColor blackColor],
		@"textColor",
		
		[NSColor redColor],
		@"selectedBackgroundColor",
		
		[NSColor colorWithCalibratedWhite:0.6 alpha:1.0],
		@"gridColor",
		
		nil
	];
}

+(NSDictionary*)blackTheme {
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSColor redColor],
		@"highlightedSelectedTextColor",

		[NSColor whiteColor],
		@"highlightedTextColor",

		[NSColor whiteColor],
		@"selectedTextColor",

		[NSColor whiteColor],
		@"textColor",
		
		[NSColor redColor],
		@"selectedBackgroundColor",
		
		[NSColor colorWithCalibratedWhite:0.176 alpha:1.0],
		@"gridColor",
		
		nil
	];
}

-(void)reloadTableSetup {
    NSDictionary* dict = [[NSUserDefaultsController sharedUserDefaultsController] values];

    NSString* fontpreset = [dict valueForKey:@"FontPreset"];
    NSString* colorpreset = [dict valueForKey:@"ColorPreset"];
	// LOG_DEBUG(@"fontpreset: %@", fontpreset);

	int font_index = 14;
    if ([fontpreset isEqualToString:@"Helvetica"]) {
		font_index = 0;
	} else
    if ([fontpreset isEqualToString:@"Lucida Grande"]) {
		font_index = 1;
	} else
    if ([fontpreset isEqualToString:@"Fixedsys 12"]) {
		font_index = 2;
	} else
    if ([fontpreset isEqualToString:@"Fixedsys 16"]) {
		font_index = 3;
	} else
    if ([fontpreset isEqualToString:@"Melno"]) {
		font_index = 4;
	} else
    if ([fontpreset isEqualToString:@"Consolas"]) {
		font_index = 5;
	} else
    if ([fontpreset isEqualToString:@"Tahoma"]) {
		font_index = 6;
	} else
    if ([fontpreset isEqualToString:@"Tahoma Negreta"]) {
		font_index = 7;
	} else
    if ([fontpreset isEqualToString:@"MPW"]) {
		font_index = 8;
	}

	int color_index = 0;
    if ([colorpreset isEqualToString:@"White"]) {
		color_index = 0;
	} else
    if ([colorpreset isEqualToString:@"Gray"]) {
		color_index = 1;
	} else
    if ([colorpreset isEqualToString:@"Black"]) {
		color_index = 2;
	}
	// LOG_DEBUG(@"colorpreset: %@ %i", colorpreset, color_index);



	do {
		switch(color_index) {
		default:
		
		// white
		case 0: [self adjustThemeForDictionary:[NCLister whiteTheme]]; break;
		
		// gray
		case 1: [self adjustThemeForDictionary:[NCLister whiteTheme]]; break;

		// black
		case 2: [self adjustThemeForDictionary:[NCLister blackTheme]]; break;
		}
		
	} while(0);


	{
		int row_height = font_and_size[font_index].row_height;
		[m_lister_tableview setRowHeight:row_height];
	}
	
	{
		[m_lister_tableview setGridStyleMask:NSTableViewSolidVerticalGridLineMask];
		[m_lister_tableview setIntercellSpacing:NSMakeSize(1,0)];
		[m_lister_tableview setGridColor:[NSColor whiteColor]];
	}

	
	NSCell* cell_text_column = nil;
	NSCell* cell_imagetext_column = nil;
	NSCell* cell_permission_column = nil;
	NSCell* cell_size_column = nil;
	NSCell* cell_date_column0 = nil;
	NSCell* cell_date_column1 = nil;
	NSCell* cell_date_column2 = nil;
	NSCell* cell_date_column3 = nil;
	NSCell* cell_date_column4 = nil;
	NSCell* cell_integer_column = nil;

	{
		const char *c_name = font_and_size[font_index].font_name;
		NSString* name = [NSString stringWithUTF8String:c_name];
		float size = font_and_size[font_index].font_size;
		BOOL anti_alias = font_and_size[font_index].anti_alias;
		float padding_left = font_and_size[font_index].padding_left;
		float padding_right = font_and_size[font_index].padding_right;
		float offset_y = font_and_size[font_index].offset_y;
		float coretext_offset_y = font_and_size[font_index].coretext_offset_y;
		NSFont* font = [NSFont fontWithName:name size:size];
		if(!font) {
			font = [NSFont systemFontOfSize:size];
		}
		//NSColor* text_color = [NSColor blackColor];
		NSColor* text_color2 = [NSColor colorWithCalibratedWhite:0.5 alpha:1.0];
		
		
		NSParameterAssert(font);
		NSParameterAssert(self.textColor);
		NSParameterAssert(self.selectedTextColor);
		NSParameterAssert(self.highlightedTextColor);
		NSParameterAssert(self.highlightedSelectedTextColor);
		NSParameterAssert(text_color2);

		NSDictionary* theme_dict = [NSDictionary dictionaryWithObjectsAndKeys:
			font,
			@"font",

			self.textColor,
			@"textColorNormalUnmarked",

			self.selectedTextColor,
			@"textColorNormalMarked",

			self.highlightedTextColor,
			@"textColorSelectedUnmarked",

			self.highlightedSelectedTextColor,
			@"textColorSelectedMarked",

			text_color2,
			@"textColorAlternative",

			[NSNumber numberWithBool:anti_alias],
			@"antiAlias",

			[NSNumber numberWithFloat:padding_left],
			@"paddingLeft",

			[NSNumber numberWithFloat:padding_right],
			@"paddingRight",

			[NSNumber numberWithFloat:offset_y],
			@"offsetY",

			[NSNumber numberWithFloat:coretext_offset_y],
			@"coretextOffsetY",

			nil
		];

		{
			NCListerTableTextCell* cell = [[NCListerTableTextCell alloc] initTextCell:@"general_text"];
			[cell adjustThemeForDictionary:theme_dict];
			cell_text_column = cell;
		}
		{
			NCImageAndTextCell* cell = [[NCImageAndTextCell alloc] init];
			[cell adjustThemeForDictionary:theme_dict];
			[cell setWidthOfImageBox:34];
			[cell setPaddingLeft:0];
			cell_imagetext_column = cell;
		}
		{
			NCPermissionCell* cell = [[NCPermissionCell alloc] init];
			[cell adjustThemeForDictionary:theme_dict];
			cell_permission_column = cell;
		}
		{
			NCDateCell* cell = [[NCDateCell alloc] init];
			[cell adjustThemeForDictionary:theme_dict];
			cell_date_column0 = cell;
		}
		{
			NCDateCell* cell = [[NCDateCell alloc] init];
			[cell adjustThemeForDictionary:theme_dict];
			cell_date_column1 = cell;
		}
		{
			NCDateCell* cell = [[NCDateCell alloc] init];
			[cell adjustThemeForDictionary:theme_dict];
			cell_date_column2 = cell;
		}
		{
			NCDateCell* cell = [[NCDateCell alloc] init];
			[cell adjustThemeForDictionary:theme_dict];
			cell_date_column3 = cell;
		}
		{
			NCDateCell* cell = [[NCDateCell alloc] init];
			[cell adjustThemeForDictionary:theme_dict];
			cell_date_column4 = cell;
		}

		{
			NCListerTableTextCell* cell = [[NCListerTableTextCell alloc] initTextCell:@"size_column"];
			[cell adjustThemeForDictionary:theme_dict];
			[cell setAlignment:NSRightTextAlignment];
			cell_size_column = cell;
		}

		{
			NCListerTableTextCell* cell = [[NCListerTableTextCell alloc] initTextCell:@"general_integer"];
			[cell adjustThemeForDictionary:theme_dict];
			[cell setAlignment:NSRightTextAlignment];
			cell_integer_column = cell;
		}
		
	}

	{
		[m_tablecolumn_name setDataCell:cell_imagetext_column];
 	   	[m_tablecolumn_size setDataCell:cell_size_column];
 	   	[m_tablecolumn_resource_fork_size setDataCell:cell_size_column];
		[m_tablecolumn_permissions setDataCell:cell_permission_column];
		[m_tablecolumn_owner setDataCell:cell_text_column];
		[m_tablecolumn_group setDataCell:cell_text_column];
		[m_tablecolumn_accessed setDataCell:cell_date_column0];
		[m_tablecolumn_content_modified setDataCell:cell_date_column1];
		[m_tablecolumn_attribute_modified setDataCell:cell_date_column2];
		[m_tablecolumn_created setDataCell:cell_date_column3];
		[m_tablecolumn_backup setDataCell:cell_date_column4];
		[m_tablecolumn_refcount setDataCell:cell_integer_column];
		[m_tablecolumn_aclcount setDataCell:cell_integer_column];
		[m_tablecolumn_xattrcount setDataCell:cell_integer_column];
		[m_tablecolumn_inode setDataCell:cell_integer_column];
		[m_tablecolumn_flags setDataCell:cell_integer_column];
		[m_tablecolumn_kind setDataCell:cell_text_column];
		[m_tablecolumn_content_type setDataCell:cell_text_column];
		// [m_tablecolumn_comment setDataCell:cell_text_column];
	}

	{
		[m_lister_tableview setGridColor:self.gridColor];
	}
	
	do {
		switch(color_index) {
		default:
		
		// white
		case 0: 
			[m_lister_tableview adjustThemeForDictionary:[NCListerTableView whiteTheme]];
			break;
		
		// gray
		case 1: 
			[m_lister_tableview adjustThemeForDictionary:[NCListerTableView grayTheme]];
			break;

		// black
		case 2: 
			[m_lister_tableview adjustThemeForDictionary:[NCListerTableView blackTheme]];
			break;
		}
		
	} while(0);
	
}

- (void)viewDidMoveToSuperview {
/*	{
		Class IBDocument = NSClassFromString(@"IBDocument");
		if(IBDocument) {
			LOG_DEBUG(@"cocoa simulator = YES");
		} else {
			LOG_DEBUG(@"cocoa simulator = NO");
		}
	}*/

	if(m_lister_tableview == nil) {
		//LOG_DEBUG(@"will addsubview");


		// float header_height = 17;
		float header_height = 25;

		NSRect hvr = NSMakeRect(0, 0, 400, header_height);
		NCTableHeaderView* hv = [[NCTableHeaderView alloc] initWithFrame:hvr];
		[hv setDelegate:self];

		NSView* superView = self;

		NSRect svrect = [superView bounds];
		// svrect.size.height -= 10;
		// svrect.size.height -= 1;
		// svrect.size.height /= 2;
		[self setNeedsDisplay:YES];

		
		NCListerTableView* tableView = [[NCListerTableView alloc] 
			// initWithFrame:[superView frame] 
			initWithFrame:svrect
			lister:self
		];
		[tableView setHeaderView:hv];

		// NCListerTableHeaderView* hv = [[NCListerTableHeaderView alloc] initWithFrame:NSMakeRect(0, 0, 100, 20)];
		// [tableView setHeaderView:hv];
		
		// LOG_DEBUG(@"%s after: %@", _cmd, tableView);
		// LOG_DEBUG(@"will add columns");
		[self setTableColumnName:[tableView addColumnWithIdentifier:kNCListerColumnIdentifierName]];
		[self setTableColumnSize:[tableView addColumnWithIdentifier:kNCListerColumnIdentifierSize]];
		[self setTableColumnResourceForkSize:[tableView addColumnWithIdentifier:kNCListerColumnIdentifierRsrcSize]];
		[self setTableColumnPermissions:[tableView addColumnWithIdentifier:kNCListerColumnIdentifierMode]];
		[self setTableColumnOwner:[tableView addColumnWithIdentifier:kNCListerColumnIdentifierOwner]];
		[self setTableColumnGroup:[tableView addColumnWithIdentifier:kNCListerColumnIdentifierGroup]];
		[self setTableColumnAccessed:[tableView addColumnWithIdentifier:kNCListerColumnIdentifierAccessed]];
		[self setTableColumnContentModified:[tableView addColumnWithIdentifier:kNCListerColumnIdentifierDataModified]];
		[self setTableColumnAttributeModified:[tableView addColumnWithIdentifier:kNCListerColumnIdentifierStatChanged]];
		[self setTableColumnCreated:[tableView addColumnWithIdentifier:kNCListerColumnIdentifierCreated]];
		[self setTableColumnBackup:[tableView addColumnWithIdentifier:kNCListerColumnIdentifierBackup]];
		[self setTableColumnRefCount:[tableView addColumnWithIdentifier:kNCListerColumnIdentifierRef]];
		[self setTableColumnAclCount:[tableView addColumnWithIdentifier:kNCListerColumnIdentifierACL]];
		[self setTableColumnXattrCount:[tableView addColumnWithIdentifier:kNCListerColumnIdentifierXAttr]];
		[self setTableColumnInode:[tableView addColumnWithIdentifier:kNCListerColumnIdentifierInode]];
		[self setTableColumnFlags:[tableView addColumnWithIdentifier:kNCListerColumnIdentifierFlags]];
		[self setTableColumnKind:[tableView addColumnWithIdentifier:kNCListerColumnIdentifierKind]];
		[self setTableColumnContentType:[tableView addColumnWithIdentifier:kNCListerColumnIdentifierType]];
		// [self setTableColumnComment:[tableView addColumnWithIdentifier:@"Comment"]];
		// LOG_DEBUG(@"did add columns");
		
		
		{
			/*id hcell = [m_tablecolumn_name headerCell];
			if([hcell isKindOfClass:[NCTableHeaderCell class]]) {
				NCTableHeaderCell* hcell1 = (NCTableHeaderCell*)hcell;
				// [hcell1 setPaddingLeft:35];
			}*/

			[m_tablecolumn_name setMinWidth:120];
		}

		{
			id hcell = [m_tablecolumn_size headerCell];
			if([hcell isKindOfClass:[NCTableHeaderCell class]]) {
				NCTableHeaderCell* hcell1 = (NCTableHeaderCell*)hcell;
				[hcell1 setAlignment:NSRightTextAlignment];
			}
		}

		{
			id hcell = [m_tablecolumn_resource_fork_size headerCell];
			if([hcell isKindOfClass:[NCTableHeaderCell class]]) {
				NCTableHeaderCell* hcell1 = (NCTableHeaderCell*)hcell;
				[hcell1 setAlignment:NSRightTextAlignment];
			}
		}

		{
			id hcell = [m_tablecolumn_refcount headerCell];
			if([hcell isKindOfClass:[NCTableHeaderCell class]]) {
				NCTableHeaderCell* hcell1 = (NCTableHeaderCell*)hcell;
				[hcell1 setAlignment:NSRightTextAlignment];
			}
		}

		{
			id hcell = [m_tablecolumn_xattrcount headerCell];
			if([hcell isKindOfClass:[NCTableHeaderCell class]]) {
				NCTableHeaderCell* hcell1 = (NCTableHeaderCell*)hcell;
				[hcell1 setAlignment:NSRightTextAlignment];
			}
		}

		{
			id hcell = [m_tablecolumn_aclcount headerCell];
			if([hcell isKindOfClass:[NCTableHeaderCell class]]) {
				NCTableHeaderCell* hcell1 = (NCTableHeaderCell*)hcell;
				[hcell1 setAlignment:NSRightTextAlignment];
			}
		}

		{
			id hcell = [m_tablecolumn_inode headerCell];
			if([hcell isKindOfClass:[NCTableHeaderCell class]]) {
				NCTableHeaderCell* hcell1 = (NCTableHeaderCell*)hcell;
				[hcell1 setAlignment:NSRightTextAlignment];
			}
		}

		{
			id hcell = [m_tablecolumn_flags headerCell];
			if([hcell isKindOfClass:[NCTableHeaderCell class]]) {
				NCTableHeaderCell* hcell1 = (NCTableHeaderCell*)hcell;
				[hcell1 setAlignment:NSRightTextAlignment];
			}
		}

		// NSRect sr = [superView frame];
		// sr.size.width = [NSScroller scrollerWidth];
		// NCListerScroller* scroller = [[NCListerScroller alloc] initWithFrame:sr];
		

        NSScrollView* scrollView = [[NSScrollView alloc] initWithFrame:svrect];

		[scrollView setHasVerticalScroller:YES];
		[scrollView setHasHorizontalScroller:YES];
		[scrollView setAutohidesScrollers:YES];
		
		[scrollView setDocumentView:tableView];
		[scrollView setFocusRingType:NSFocusRingTypeNone];
		[tableView setFocusRingType:NSFocusRingTypeNone];

/*		[[scrollView contentView] setBackgroundColor:[NSColor greenColor]];
		[[scrollView contentView] setDrawsBackground:YES];
		[scrollView setBackgroundColor:[NSColor greenColor]];
		[scrollView setDrawsBackground:YES]; */


		int mask = 
			NSViewMinXMargin | NSViewWidthSizable | NSViewMaxXMargin |
			NSViewMinYMargin | NSViewHeightSizable | NSViewMaxYMargin;
		[scrollView setAutoresizingMask:mask];

		[self setAutoresizesSubviews:YES];

		[superView addSubview:scrollView];

/*		svrect.size.height -= 1;
		[scrollView setFrame:svrect];*/

		m_lister_tableview = tableView;

		[m_lister_tableview setDelegate:self];
		[m_lister_tableview setDataSource:self];
		// [m_lister_tableview setNextResponder:self];

		[self reloadTableSetup];
	}

	// LOG_DEBUG(@"%s super", _cmd);

	[super viewDidMoveToSuperview];

	// LOG_DEBUG(@"%s leave", _cmd);
}

#pragma mark -
#pragma mark Breadcrumbs

-(NCListerBreadcrumb*)createBreadcrumb {

	NSRect rect = [[m_lister_tableview enclosingScrollView] documentVisibleRect];
	int selected_row = [m_lister_tableview selectedRow];
	NSRange range = [m_lister_tableview rowsInRect:rect];
	int number_of_rows = [m_lister_tableview numberOfRows];

	int rel_row = selected_row - range.location;
	float ofs = 0;
	if(range.length > 1) {
		ofs = (float)rel_row / (float)(range.length);
	}
	// LOG_DEBUG(@"ofs: %0.2f\ntoprow: %i", ofs, range.location);

	NSArray* items = [[NSArray alloc] initWithArray:m_items copyItems:YES]; // deep copy
	NSString* current_name = [self currentName];
	NSString* wdir = [self workingDir];
	
	NCListerBreadcrumb* crumb = [[NCListerBreadcrumb alloc] init];
	[crumb setWorkingDir:wdir];
	[crumb setSelectedRow:selected_row];
	[crumb setPositionY:ofs];
	[crumb setNumberOfRows:number_of_rows];
	[crumb setDate:[NSDate date]];
	[crumb setItems:items];                     
	[crumb setCurrentName:current_name];
	// TODO: [crumb setSortMode:sort_mode]; 
	
	// LOG_DEBUG(@"%s %@", _cmd, crumb);
	return crumb;
}

-(void)restoreFromBreadcrumb:(NCListerBreadcrumb*)crumb {
	NSParameterAssert(crumb);
	
	int number_of_rows = [crumb numberOfRows];
	int row = [crumb selectedRow];       
	float position_y = [crumb positionY];
	// LOG_DEBUG(@"%s row: %i rows: %i", _cmd, row, number_of_rows);

/*	if([m_items count] != number_of_rows) {
		LOG_DEBUG(@"%s invalid breadcrumb", _cmd);
		return NO;
	} */
	if(row > number_of_rows) {
		row = number_of_rows - 1;
	}
	
	NSString* current_name = [crumb currentName];
	int find_index = -1;
	(void)[self findItemByName:current_name index:&find_index];
	// LOG_DEBUG(@"%s name %@ found at index %i", _cmd, current_name, find_index);

	if(find_index >= 0) {
		row = find_index;
		// NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:index];
		// [m_lister_tableview selectRowIndexes:indexes byExtendingSelection:NO];
		/*
		TODO: how to scroll to the selected row, so it's vertically centered in the lister?
		*/
	}
	
	/*
	TODO: if sort mode is different then return NO.  because then our history is not useful
	*/


	NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:row];
	[m_lister_tableview selectRowIndexes:indexes byExtendingSelection:NO];

	[m_lister_tableview scrollRowToVisible:0];

	NSRect rect = [[m_lister_tableview enclosingScrollView] documentVisibleRect];
	NSRange range = [m_lister_tableview rowsInRect:rect];

	float toprow_f = row - (float)(range.length) * position_y;
	int toprow = floorf(toprow_f);
	// LOG_DEBUG(@"toprow_f: %.2f\ntoprow: %i", toprow_f, toprow);

	if(toprow < 0) toprow = 0;

	/*****************************************************************************
	Procedure for restoring the vertical scroll offset:
	
	We want to "correct" the scrolloffset, e.g when the user have scrolled using
	the mouse the top-most row becomes partially visible. We want top-most row to 
	be 100% visible, so it's perfectly aligned with the scrollview's upper edge.
	Another situation is when the user have resized the window, in this case the
	scale of things change a lot, so we want to scroll to the closest offset
	to the original offset.
	
	The simplest way to accomplish this is by:
	 1. First scrolling to the very bottom.
	 2. Then scroll so the top-most row is visible.
	 3. And finally scroll so the selected row is visible.
	*****************************************************************************/
	{
		// scroll to bottom
		[m_lister_tableview scrollRowToVisible:number_of_rows-1];
	
		// scroll up so that the toprow becomes aligned with the top-edge
		if(toprow < number_of_rows-1) {
			[m_lister_tableview scrollRowToVisible:toprow];
		}
		
		/*
		by now the row should visible, however if it isn't for some reason 
		then we scroll to ensure it's visible
		*/
		[m_lister_tableview scrollRowToVisible:row];
	}
}

-(void)resetSelectionAndCursor {
	// deselect all
	[m_selected_indexes removeAllIndexes];
	
	// set cursor to first row
	if([m_items count] >= 1) {
		NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:0];
		[m_lister_tableview selectRowIndexes:indexes byExtendingSelection:NO];
		[m_lister_tableview scrollRowToVisible:0];
	}
}

/*
you may be familiar with the design pattern "Robust Iterator", 
this method is related.

robustSetItems is a setter method that attempts to preserve the selection + cursor position.
It can preserve a selection even if the file have been renamed.
If a file was selection is no longer to be found then this file will not be selection.

TODO: how to deal with sorting? When the user has chosen to sort by a column, how do
we sort the data.. while preserving the selection?

IDEA: when a file is deleted, then we currently set the cursor to the top-most item.
We want instead the cursor to be moved to the file that was closest. How to do that?
*/
-(void)robustSetItems:(NSArray*)items {
	/*
	before overwriting the item array

	remember names and inodes for selected items so that we can
	preserve the cursor + the selected items
	*/
	NSArray* remember_selected_items = [self selectedItems];
	NCListerItem* remember_current_item = [self currentItem];
	NSUInteger other_row = [m_lister_tableview selectedRow];

	/*
	overwrite the item array
	*/
	self.items = items;
	[self rebuildIndexes];

	/* 
	after overwriting the item array

	restore selected items by name or inode
	try find the item. if that fails then go to the remembered row
	*/
	[self selectRememberedItems:remember_selected_items];
	[self setCurrentToRememberedItem:remember_current_item otherRow:other_row];
}


#pragma mark -
#pragma mark Selection

-(void)nc_selectAll {
	int n = [m_items count];
	[m_selected_indexes removeAllIndexes];
	[m_selected_indexes addIndexesInRange:NSMakeRange(1, n)];

	[m_lister_tableview reloadData];
	[self updateCounters];
}

-(void)nc_selectNone {
	[m_selected_indexes removeAllIndexes];

	[m_lister_tableview reloadData];
	[self updateCounters];
}

-(void)nc_selectAllOrNone {
	int n = [m_items count];
	NSIndexSet* iset = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, n)];
	// LOG_DEBUG(@"%s %@ %@", _cmd, iset, m_selected_indexes);
	if([iset isEqualToIndexSet:m_selected_indexes]) {
		// LOG_DEBUG(@"%s select none", _cmd);
		[self nc_selectNone];
	} else {
		// LOG_DEBUG(@"%s select all", _cmd);
		[self nc_selectAll];
	}
}


#pragma mark -
#pragma mark Navigation

-(void)navigateBackAction:(id)sender {
	[self navigateOut:NO];
}

-(void)navigateParentAction:(id)sender {
	[self navigateOut:YES];
}

-(void)navigateInOrParentAction:(id)sender {
	[self navigateInto:YES];
}

-(void)navigateInOrBackAction:(id)sender {
	[self navigateInto:NO];
}

/*
Navigate out of this dir.
If clear_history == YES then we go to the parent dir
If clear_history == NO then we go the the previos path in the history
*/
-(void)navigateOut:(BOOL)clear_history {
	NSString* current_wdir   = [self workingDir];
	NSString* current_parent = [current_wdir stringByDeletingLastPathComponent];
	NSString* current_name   = [current_wdir lastPathComponent];

	if(clear_history) {
		[m_breadcrumb_stack removeAllObjects];
	}

	NCListerBreadcrumb* crumb = [m_breadcrumb_stack popBreadcrumb];
	NSString* wdir = [crumb workingDir];
	if(!wdir) {
		wdir = current_parent;
		// LOG_DEBUG(@"%s clearing breadcrumb, because wdir is nil. breadcrumb:\n%@", _cmd, crumb);
		crumb = nil;
	}

	if([current_wdir isEqual:wdir]) {
		// in some cases you cannot navigate to parent dir, e.g. when workingdir = /
		return;
	}
	
	if(!crumb) {
		// crumb = [self createBreadcrumb];

		crumb = [[NCListerBreadcrumb alloc] init];
		[crumb setWorkingDir:wdir];
		[crumb setDate:[NSDate date]];
		[crumb setCurrentName:current_name];
	}

	{
		NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:0];
		[m_lister_tableview selectRowIndexes:indexes byExtendingSelection:NO];
	}
	// LOG_DEBUG(@"%s before set.. crumb: %@", _cmd, crumb);
	[self inner_setWorkingDir:wdir];
	[self reloadWithBreadcrumb:crumb];
}

/*
Navigate into a subdir or if cursor is on top-most row then navigate out of this dir.
*/
-(void)navigateInto:(BOOL)clear_history_in_navigate_out {
	// LOG_DEBUG(@"clear history: %i", (int)clear_history_in_navigate_out);

	int row_count = [m_items count];
	if(row_count < 1) return;

	int row = [m_lister_tableview selectedRow];
	if(row < 0) return;

	if(row == 0) {
		[self navigateOut:clear_history_in_navigate_out];
		return;
	}
	
	if(row >= row_count) {
		LOG_WARNING(@"row (%i) is out of range (%i)", row, row_count);
		return;
	}

	NSString* wdir = [self workingDir];

	id thing = [m_items objectAtIndex:row];
	if(![thing isKindOfClass:[NCListerItem class]]) return;
	NCListerItem* item = (NCListerItem*)thing;
	
	if([item countsAsFile]) {
		// if it had been a dir we could navigate into it
		// but this is a file so we cannot navigate into it.
		return;
	}


	NSString* name = [item name];
	NSString* link = [item link];
	NSString* wdir2 = [wdir stringByAppendingPathComponent:name];
	
	if(link) {
		if(![link isAbsolutePath]) {
			wdir2 = [wdir stringByAppendingPathComponent:link];
		} else {
			wdir2 = link;
		}
	}

	NCListerBreadcrumb* crumb = [self createBreadcrumb];

	{
		NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:0];
		[m_lister_tableview selectRowIndexes:indexes byExtendingSelection:NO];
		[m_lister_tableview scrollRowToVisible:0];

		[self setCurrentBreadcrumb:nil];
		[self inner_setWorkingDir:wdir2];
		[self reloadAndReset];

		/*
		we have successfully switched to another dir and thus we
		must store a breadcrumb so we can find our way back later.
		*/
		[m_breadcrumb_stack pushBreadcrumb:crumb];
	}

}

#pragma mark -
#pragma mark Focus and tab cycling

-(void)tabKeyPressed:(id)sender {
	if([self.delegate respondsToSelector:@selector(listerTabKeyPressed:)]) {
		[self.delegate listerTabKeyPressed:self];
	}
}

-(void)switchToNextTab:(id)sender {
	if([self.delegate respondsToSelector:@selector(listerSwitchToNextTab:)]) {
		[self.delegate listerSwitchToNextTab:self];
	}
}

-(void)switchToPrevTab:(id)sender {
	if([self.delegate respondsToSelector:@selector(listerSwitchToPrevTab:)]) {
		[self.delegate listerSwitchToPrevTab:self];
	}
}

-(void)closeTab:(id)sender {
	if([self.delegate respondsToSelector:@selector(listerCloseTab:)]) {
		[self.delegate listerCloseTab:self];
	}
}

-(void)activateTableView:(id)sender {
	if([self.delegate respondsToSelector:@selector(listerActivateTableView:)]) {
		[self.delegate listerActivateTableView:self];
	}
}


#pragma mark -
#pragma mark Lister callbacks

-(int)listerTableView:(NCListerTableView*)tableview formatCodeForRow:(int)row {
	return [m_selected_indexes containsIndex:row] ? 1 : 0;
}

#pragma mark -
#pragma mark Table delegate

-(void)reloadHeader {
	NSArray* columns = [m_lister_tableview tableColumns];
	NSEnumerator* enumerator = [columns objectEnumerator];
	NSTableColumn *column;
	while((column = [enumerator nextObject])) {

		BOOL is_highlighted = (m_sort_column == column);
		[[column headerCell] setHighlighted: is_highlighted];

		int v = 0;
		if(m_sort_column == column) {
			v = m_sort_reverse ? -1 : 1;
		}
		[[column headerCell] setSortIndicator:v];
	}
	
	[m_lister_tableview setNeedsDisplay:YES];
	[m_lister_tableview reloadData];
}

-(void)rebuildSortDescriptors {
	
	NSTableColumn* tc = m_sort_column;
	id identifier = [tc identifier];
	
	NSSortDescriptor* sd = nil;
	if([identifier isEqualToString:kNCListerColumnIdentifierName]) {
		sd = [[NSSortDescriptor alloc]
	        initWithKey:@"name"
	        ascending:m_sort_reverse
	        selector:@selector(localizedCaseInsensitiveCompare:)];
	} else
	if([identifier isEqualToString:kNCListerColumnIdentifierSize]) {
		sd = [[NSSortDescriptor alloc]
	        initWithKey:@"size"
	        ascending:m_sort_reverse
	        selector:@selector(compare:)];
	} else
	if([identifier isEqualToString:kNCListerColumnIdentifierRsrcSize]) {
		sd = [[NSSortDescriptor alloc]
	        initWithKey:@"resourceForkSize"
	        ascending:m_sort_reverse
	        selector:@selector(compare:)];
	} else
	if([identifier isEqualToString:kNCListerColumnIdentifierMode]) {
		sd = [[NSSortDescriptor alloc]
	        initWithKey:@"posixPermissions"
	        ascending:m_sort_reverse
	        selector:@selector(compare:)];
	} else
	if([identifier isEqualToString:kNCListerColumnIdentifierOwner]) {
		sd = [[NSSortDescriptor alloc]
	        initWithKey:@"owner"
	        ascending:m_sort_reverse
	        selector:@selector(localizedCaseInsensitiveCompare:)];
	} else
	if([identifier isEqualToString:kNCListerColumnIdentifierOwner]) {
		sd = [[NSSortDescriptor alloc]
	        initWithKey:@"group"
	        ascending:m_sort_reverse
	        selector:@selector(localizedCaseInsensitiveCompare:)];
	} else
	if([identifier isEqualToString:kNCListerColumnIdentifierAccessed]) {
		sd = [[NSSortDescriptor alloc]
	        initWithKey:@"accessDate"
	        ascending:m_sort_reverse
	        selector:@selector(compare:)];
	} else
	if([identifier isEqualToString:kNCListerColumnIdentifierDataModified]) {
		sd = [[NSSortDescriptor alloc]
	        initWithKey:@"contentModificationDate"
	        ascending:m_sort_reverse
	        selector:@selector(compare:)];
	} else
	if([identifier isEqualToString:kNCListerColumnIdentifierStatChanged]) {
		sd = [[NSSortDescriptor alloc]
	        initWithKey:@"attributeModificationDate"
	        ascending:m_sort_reverse
	        selector:@selector(compare:)];
	} else
	if([identifier isEqualToString:kNCListerColumnIdentifierCreated]) {
		sd = [[NSSortDescriptor alloc]
	        initWithKey:@"creationDate"
	        ascending:m_sort_reverse
	        selector:@selector(compare:)];
	} else
	if([identifier isEqualToString:kNCListerColumnIdentifierBackup]) {
		sd = [[NSSortDescriptor alloc]
	        initWithKey:@"backupDate"
	        ascending:m_sort_reverse
	        selector:@selector(compare:)];
	} else
	if([identifier isEqualToString:kNCListerColumnIdentifierRef]) {
		sd = [[NSSortDescriptor alloc]
	        initWithKey:@"referenceCount"
	        ascending:m_sort_reverse
	        selector:@selector(compare:)];
	} else
	if([identifier isEqualToString:kNCListerColumnIdentifierACL]) {
		sd = [[NSSortDescriptor alloc]
	        initWithKey:@"aclCount"
	        ascending:m_sort_reverse
	        selector:@selector(compare:)];
	} else
	if([identifier isEqualToString:kNCListerColumnIdentifierXAttr]) {
		sd = [[NSSortDescriptor alloc]
	        initWithKey:@"xattrCount"
	        ascending:m_sort_reverse
	        selector:@selector(compare:)];
	} else
	if([identifier isEqualToString:kNCListerColumnIdentifierInode]) {
		sd = [[NSSortDescriptor alloc]
	        initWithKey:@"inode"
	        ascending:m_sort_reverse
	        selector:@selector(compare:)];
	} else
	if([identifier isEqualToString:kNCListerColumnIdentifierFlags]) {
		sd = [[NSSortDescriptor alloc]
	        initWithKey:@"flags"
	        ascending:m_sort_reverse
	        selector:@selector(compare:)];
	} else
	if([identifier isEqualToString:kNCListerColumnIdentifierKind]) {
		sd = [[NSSortDescriptor alloc]
	        initWithKey:@"kind"
	        ascending:m_sort_reverse
	        selector:@selector(localizedCaseInsensitiveCompare:)];
	} else
	if([identifier isEqualToString:kNCListerColumnIdentifierType]) {
		sd = [[NSSortDescriptor alloc]
	        initWithKey:@"contentType"
	        ascending:m_sort_reverse
	        selector:@selector(localizedCaseInsensitiveCompare:)];
	}

	NSArray* ary = (sd != nil) ? [NSArray arrayWithObject:sd] : [NSArray array];
	[self setSortDescriptors:ary];
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
	// LOG_ERROR(@"called");
	if(tableColumn == m_sort_column) {
		if(m_sort_reverse) {
			m_sort_reverse = false;
		} else {
			m_sort_column = nil;
			m_sort_reverse = true;
		}
	} else 
	if(tableView == m_lister_tableview) {
		m_sort_column = tableColumn;
	}
	[self reloadHeader];
	[self setSortDescriptors:nil];
	[self reload];
}

- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn*)aTableColumn
    row:(NSInteger)rowIndex
{
	if(rowIndex < [m_items count]) {
		NCListerItem* item = [m_items objectAtIndex:rowIndex];
		if(aTableColumn == m_tablecolumn_name) {   
			return [item name];
		}
		if(aTableColumn == m_tablecolumn_size) {   
			int sizecolmode = [item sizeColumnMode];
			if(sizecolmode == 1) {
				return [NSString stringWithFormat:@"%i", [item itemCount]];
			}
			return NCSpacedStringForBytes([item size]);
		}
		if(aTableColumn == m_tablecolumn_resource_fork_size) {   
			return NCSpacedStringForBytes([item resourceForkSize]);
		}
		if(aTableColumn == m_tablecolumn_permissions) {   
			NSUInteger bits = [item posixPermissions];
			return [NSNumber numberWithUnsignedInteger:bits];
		}
		if(aTableColumn == m_tablecolumn_owner) {   
			return [item owner];
		}
		if(aTableColumn == m_tablecolumn_group) {   
			return [item group];
		}
		if(aTableColumn == m_tablecolumn_accessed) {   
			return [item accessDate];
		}
		if(aTableColumn == m_tablecolumn_content_modified) {   
			return [item contentModificationDate];
		}
		if(aTableColumn == m_tablecolumn_attribute_modified) {   
			return [item attributeModificationDate];
		}
		if(aTableColumn == m_tablecolumn_created) {   
			return [item creationDate];
		}
		if(aTableColumn == m_tablecolumn_backup) {   
			return [item backupDate];
		}
		if(aTableColumn == m_tablecolumn_refcount) {   
			int count = [item referenceCount];
			return [NSNumber numberWithInteger:count];
		}
		if(aTableColumn == m_tablecolumn_aclcount) {   
			int count = [item aclCount];
			return [NSNumber numberWithInteger:count];
		}
		if(aTableColumn == m_tablecolumn_xattrcount) {   
			int count = [item xattrCount];
			return [NSNumber numberWithInteger:count];
		}
		if(aTableColumn == m_tablecolumn_inode) {   
			unsigned long long inode = [item inode];
			return [NSNumber numberWithUnsignedLongLong:inode];
		}
		if(aTableColumn == m_tablecolumn_flags) {   
			unsigned long flags = [item flags];
			// return [NSNumber numberWithUnsignedLong:flags];
			return [NSString stringWithFormat:@"%lx", flags];
		}
		if(aTableColumn == m_tablecolumn_kind) {   
			return [item kind];
		}
		if(aTableColumn == m_tablecolumn_content_type) {   
			return [item contentType];
		}
/*		if(aTableColumn == m_tablecolumn_comment) {   
			return [item comment];
		}*/
	}
	
    return @"ERROR";
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [m_items count];
}

- (void)tableView:(NSTableView *)aTableView 
	willDisplayCell: (id)aCell 
	forTableColumn:(NSTableColumn *)aTableColumn 
	row: (NSInteger)rowIndex 
{
	// BOOL is_marked = NO;                        
	BOOL is_marked = [m_selected_indexes containsIndex:rowIndex];

	if(rowIndex >= [m_items count]) {
		return;
	}

	NCListerItem* item = [m_items objectAtIndex:rowIndex];

	if(aTableColumn == m_tablecolumn_name) {   
		if ([aCell isKindOfClass:[NCImageAndTextCell class]]) {
			NCImageAndTextCell* cell = (NCImageAndTextCell*)aCell;
			[cell setImage2:[self assignIconToItem:item]];
		}
	}

	if ([aCell isKindOfClass:[NCListerCell class]]) {
		[aCell setIsMarked:is_marked];
	}
	
	if ([aCell isKindOfClass:[NCListerTableTextCell class]]) {
		NCListerTableTextCell* cell = (NCListerTableTextCell*)aCell;
		
		if(aTableColumn == m_tablecolumn_size) {
			
			if([item sizeColumnMode] == 1) {
				[cell setRounded:YES];
			} else {
				[cell setRounded:NO];
			}
			
		} else {
			[cell setRounded:NO];
		}
	}
}

-(NSString*)description {
	return @"Lister";
}

#pragma mark -
#pragma mark Dump / Restore serialization

/*
-(NSData*)dump {
	NCListerState* state = [[[NCListerState alloc] init] autorelease];
	[state setWorkingDir:[self workingDir]];

    NSMutableData* data = [NSMutableData data];
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:state forKey:@"state"];
    [archiver encodeObject:[self workingDir] forKey:@"workingDir"];
    [archiver finishEncoding];

	// LOG_DEBUG(@"%s data: %@", _cmd, data);
	NSString* sdata = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
	LOG_DEBUG(@"%s %@", _cmd, sdata);
	return data;
}

-(void)restore:(NSData*)data {
	LOG_DEBUG(@"%s", _cmd);
    NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
	
	NSString* working_dir = [unarchiver decodeObjectForKey:@"workingDir"];
	
    [unarchiver finishDecoding];
	
	[self setWorkingDir:working_dir];
	[self reload];
}*/


#pragma mark -
#pragma mark Keyboard

-(void)tableView:(NCListerTableView*)tableview markRow:(int)row {
	// LOG_DEBUG(@"%s %i", _cmd, row);
	if(row <= 0) {
		// the top-most row is not selectable
	} else
	if([m_selected_indexes containsIndex:row]) {
		[m_selected_indexes removeIndex:row];
	} else {
		[m_selected_indexes addIndex:row];
	}
	[m_lister_tableview reloadData];
	
	[self updateCounters];
}

- (void)keyDown:(NSEvent *)event {
	// LOG_DEBUG(@"NCLister %s %@", _cmd, event);

	NSString* s = [event charactersIgnoringModifiers];
	unichar key = [s characterAtIndex:0];
	switch(key) {
	case 32: {
		// LOG_DEBUG(@"%s quicklook", _cmd);
#if 1
		[self showQuickLook];
#else
		LOG_DEBUG(@"%s %@", _cmd, [self currentItem]);
#endif		
		return; }
	}
	[super keyDown:event];
}

#pragma mark -
#pragma mark Quicklook


-(void)showQuickLook {
	if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible]) {
		// LOG_DEBUG(@"%s out", _cmd);
        [[QLPreviewPanel sharedPreviewPanel] orderOut:nil];
    } else {
		// LOG_DEBUG(@"%s in", _cmd);
        [[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:nil];
    }
}


-(NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel*)panel {
	return 1;
}

-(id <QLPreviewItem>)previewPanel:(QLPreviewPanel*)panel previewItemAtIndex:(NSInteger)index {
	NSString* name = [self currentName];
	NSString* wdir = [self workingDir];
	NSString* path = [wdir stringByAppendingPathComponent:name];
	
	// PROBLEM: quicklook cannot preview aliases/symlinks. 
	// SOLUTION: we resolve the path so quicklook can do it's preview stuff
	NCFileManager* ncfm = [NCFileManager shared];
	path = [ncfm resolvePath:path];
	return [[NSURL alloc] initFileURLWithPath:path];
}

-(BOOL)previewPanel:(QLPreviewPanel*)panel handleEvent:(NSEvent*)event {
	// LOG_DEBUG(@"%s %@", _cmd, event);
	NSString* s = [event charactersIgnoringModifiers];
	unichar key = [s characterAtIndex:0];

	switch(key) {
	case 32: {
		// do nothing
		// LOG_DEBUG(@"%s spacebar pressed", _cmd);
		return YES; }
	}


    if([event type] != NSKeyDown) {
        return NO;
    }

	switch(key) {
	case NSF3FunctionKey: {
		// LOG_DEBUG(@"exit quicklook", _cmd);
        [[QLPreviewPanel sharedPreviewPanel] orderOut:nil];
		return YES; }
	case NSCarriageReturnCharacter:
	case NSDeleteCharacter:
/*	case NSHomeFunctionKey:
	case NSEndFunctionKey:
	case NSPageUpFunctionKey:
	case NSPageDownFunctionKey: */
	case NSUpArrowFunctionKey:
	case NSDownArrowFunctionKey: {
		[m_lister_tableview keyDown:event];
		[[QLPreviewPanel sharedPreviewPanel] reloadData];
		return YES; }
	}

    return NO;
}

// quicklook zoom effect.. obtain the zoom start rect
- (NSRect)previewPanel:(QLPreviewPanel *)panel 
	sourceFrameOnScreenForPreviewItem:(id <QLPreviewItem>)item
{
	int row = [m_lister_tableview selectedRow];
	NSUInteger col_index = [[m_lister_tableview tableColumns] indexOfObject:m_tablecolumn_name];
	if(col_index >= [[m_lister_tableview tableColumns] count]) col_index = 0;
    NSRect r = [m_lister_tableview frameOfCellAtColumn:col_index row:row];
    NSRect vr = [m_lister_tableview visibleRect];
    if(!NSIntersectsRect(vr, r)) return NSZeroRect;
    
    // convert to screen coordinates
    r = [m_lister_tableview convertRectToBase:r];
    r.origin = [[m_lister_tableview window] convertBaseToScreen:r.origin];
    return r;
}

-(id)previewPanel:(QLPreviewPanel *)panel 
	transitionImageForPreviewItem:(id <QLPreviewItem>)item 
	contentRect:(NSRect*)contentRect {
	return [[NSWorkspace sharedWorkspace] iconForFile:[(NSURL *)item path]];
}

-(BOOL)acceptsPreviewPanelControl:(QLPreviewPanel*)panel {
	return YES;
}

-(void)beginPreviewPanelControl:(QLPreviewPanel*)panel {
	// LOG_DEBUG(@"%s", _cmd);
	[[QLPreviewPanel sharedPreviewPanel] setDataSource:self];
	[[QLPreviewPanel sharedPreviewPanel] setDelegate:self];
		// [[QLPreviewPanel sharedPreviewPanel] reloadData];/**/
}


-(void)endPreviewPanelControl:(QLPreviewPanel*)panel {
	// LOG_DEBUG(@"%s", _cmd);
}

#pragma mark -
#pragma mark Edit / Open files

/*
returns the first item and its index that matches the given name
returns nil and index -1 if there are no item with the given name
*/
-(NCListerItem*)findItemByName:(NSString*)name index:(int*)resultIindex {
	int i = 0;
	int n = [m_items count];
	for(; i < n; i++) {
		id thing = [m_items objectAtIndex:i];
		if(![thing isKindOfClass:[NCListerItem class]]) continue;
		NCListerItem* item = (NCListerItem*)thing;
		if([name isEqualToString:[item name]]) {
			if(resultIindex) *resultIindex = i;
			return item;
		}
	}
	if(resultIindex) *resultIindex = -1;
	return nil;
}

-(void)rebuildIndexes {
	NSUInteger i = 0;
	NSUInteger n = [m_items count];
    NSMutableDictionary* dict_name = [NSMutableDictionary dictionaryWithCapacity:n];
    NSMutableDictionary* dict_inode = [NSMutableDictionary dictionaryWithCapacity:n];
	for(; i < n; i++) {
		id thing = [m_items objectAtIndex:i];
		if(![thing isKindOfClass:[NCListerItem class]]) continue;
		NCListerItem* item = (NCListerItem*)thing;
    	[dict_name setObject:[NSNumber numberWithUnsignedInteger:i] 
			forKey:[item name]];
    	[dict_inode setObject:[NSNumber numberWithUnsignedInteger:i] 
			forKey:[NSNumber numberWithUnsignedLongLong:[item inode]]];
	}
	self.nameToIndex = dict_name;
	self.inodeToIndex = dict_inode;
}

-(void)selectRememberedItems:(NSArray*)remembered_items {
	if(!remembered_items) {
		LOG_WARNING(@"ERROR: expected 1 argument, but no item given");
		return;
	}
	/*
	if a file is being renamed in the Finder then the filename obviously changes,
	so we cannot reselect it if we just remember filenames.
	In order to reselect the file we must refer to its inode.
	For this reason we first try reselecting from the filename and if that doesn't
	work then we try reselect from the inode.
	*/
	// LOG_DEBUG(@"ENTER <---------------");
	[m_selected_indexes removeAllIndexes];
	for(NCListerItem* item in remembered_items) {
		NSString* name = [item name];
		NSNumber* index = [m_name_to_index objectForKey:name];
		if(!index) { 
			index = [m_inode_to_index objectForKey:[NSNumber numberWithUnsignedLongLong:[item inode]]];
		}
		if(index) {
			// LOG_DEBUG(@"found item: %@ at index: %@", name, index);
			NSUInteger row = [index unsignedIntegerValue];
			[m_selected_indexes addIndex:row];
		} else {
			// LOG_DEBUG(@"could not find item: %@", name);
		}
	}
	// LOG_DEBUG(@"LEAVE -------------->");
}

/*
PROCEDURE
 1. try find the item by its name
 2. if that fails then try find the item by its inode
 3. if that fails then go to the given row

Usually filenames stays the same between reloads, so we can just restore 
using the name. 

However... when a file has been renamed then we cannot look it up by its name,
thus we have to fallback and look it up by its inode.

And also when a file has been deleted then we can neither find it by its name nor its inode,
thus we have to fallback and use the last cursor position.

IDEA: there is too much scrolling going on, so perhaps we should not restore
in situations where the cursor is too far away from the original row.
If its outside the current visible page then I guess it would be annoying if scrolling occured.
Currently the cursor is just hidden and no scrolling occurs. However I don't like that
it's hidden and I don't like automatic scrolling.
*/
-(void)setCurrentToRememberedItem:(NCListerItem*)item otherRow:(NSUInteger)otherRow {
	NSUInteger n = [m_items count];
	if(n < 1) {
		return;
	}
	
	NSUInteger row = 0;

	if(item) {
		NSString* name = [item name];
		NSNumber* index = [m_name_to_index objectForKey:name];
		if(!index) { 
			index = [m_inode_to_index objectForKey:[NSNumber numberWithUnsignedLongLong:[item inode]]];
		}
		if(index) {
			row = [index unsignedIntegerValue];
		} else {
			row = otherRow;
		}
	}
	
	if(row >= n) {
		row = 0;
	}
	NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:row];
	[m_lister_tableview selectRowIndexes:indexes byExtendingSelection:NO];
}


-(NSArray*)selectedItems {
	NSMutableArray* item_array = [NSMutableArray arrayWithCapacity:1000];
	int i = 1;
	int n = [m_items count];
	for(; i < n; i++) {
		if(![m_selected_indexes containsIndex:i]) continue;
		
		id thing = [m_items objectAtIndex:i];
		if(![thing isKindOfClass:[NCListerItem class]]) continue;
		NCListerItem* item = (NCListerItem*)thing;
		[item_array addObject:item];
	}
	return item_array;
}

-(NCListerItem*)currentItem {
	int n = [m_items count];
	if(n < 2) return nil;

	int row = [m_lister_tableview selectedRow];
	if(row < 1) return nil;
	if(row >= n) return nil;

	id thing = [m_items objectAtIndex:row];
	if(![thing isKindOfClass:[NCListerItem class]]) return nil;
	NCListerItem* item = (NCListerItem*)thing;
	
	return item;
}

-(NSArray*)selectedItemsOrCurrentItem {
	NSArray* items = [self selectedItems];
	if([items count] >= 1) {
		return items;
	}

	NCListerItem* item = [self currentItem];
	if(item != nil) {
		return [NSArray arrayWithObject:item];
	}

	return [NSArray array];
}


-(NSArray*)selectedNames {
	NSArray* item_array = [self selectedItems];
	NSMutableArray* result = [NSMutableArray array];
	for(NCListerItem* item in item_array) {
		[result addObject:[item name]];
	}
	return result;
}

-(NSArray*)selectedNamesOrCurrentName {
	NSArray* item_array = [self selectedItemsOrCurrentItem];
	NSMutableArray* result = [NSMutableArray array];
	for(NCListerItem* item in item_array) {
		[result addObject:[item name]];
	}
	return result;
}

-(NSArray*)urlArrayWithSelectedItemsOrCurrentItem {
	NSString* working_dir = [self workingDir];
	NSArray* item_array = [self selectedItemsOrCurrentItem];
	NSMutableArray* result = [NSMutableArray array];
	for(NCListerItem* item in item_array) {
		[result addObject:[item urlInWorkingDir:working_dir]];
	}
	if([result count] == 0) {
		[result addObject:[NSURL fileURLWithPath:working_dir isDirectory:YES]];
	}
	return result;
}

-(void)openSelectedItems {
	NSArray* url_array = [self urlArrayWithSelectedItemsOrCurrentItem];
	// LOG_DEBUG(@"%s %@", _cmd, url_array);
	BOOL ok = [[NSWorkspace sharedWorkspace]
		openURLs:url_array
	    withAppBundleIdentifier:nil
		options:NSWorkspaceLaunchDefault
		additionalEventParamDescriptor:nil
		launchIdentifiers:nil
	];
	if(!ok)  {
		LOG_WARNING(@"failed opening files: %@", url_array);
	}
}

-(IBAction)openSelectedItems:(id)sender {
	[self openSelectedItems];
}	


-(void)revealSelectedItems {
	NSArray* url_array = [self urlArrayWithSelectedItemsOrCurrentItem];
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:url_array];
}

-(IBAction)revealInFinder:(id)sender {
	[self revealSelectedItems];
}

-(void)copyItemsToClipboardAbsolute:(BOOL)absolute {
	NSArray* strings = [self selectedNamesOrCurrentName];
	NSString* wdir = [self workingDir];          
	NSString* result = wdir;
	
	if([strings count] >= 1) {
		if(absolute) {
			strings = [strings prependPath:wdir];
		}
		result = [strings componentsJoinedByString:@"\n"];
	}

	NSPasteboard* pb = [NSPasteboard generalPasteboard];
	[pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	[pb setString:result forType:NSStringPboardType];        
}

-(IBAction)copyAbsolutePathsToClipboardAction:(id)sender {
	[self copyItemsToClipboardAbsolute:YES];
}

-(IBAction)copyNamesToClipboardAction:(id)sender {
	[self copyItemsToClipboardAbsolute:NO];
}

-(IBAction)ejectAction:(id)sender {
	NSString* wdir = [self workingDir];          
	NSURL* url = nil;
	NCListerItem* item = [self currentItem];
	if(item != nil) url = [item urlInWorkingDir:wdir];
	if(url == nil)  url = [NSURL fileURLWithPath:wdir isDirectory:YES];

	LOG_DEBUG(@"will unmount: %@", url);
	NSError* error = nil;
	BOOL ok = [[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtURL:url error:&error];
	if(!ok) {
		LOG_ERROR(@"ERROR: failed to unmount volume: %@\n%@", url, error);
		return;
	}
	LOG_DEBUG(@"successfully unmounted: %@", url);
}

-(void)enterRenameMode {
	// LOG_DEBUG(@"%s", _cmd);

	NSTableView* tv = m_lister_tableview;


	NSUInteger col_index = [[tv tableColumns] indexOfObject:m_tablecolumn_name];
	if(col_index == NSNotFound) {
		LOG_DEBUG(@"%s not found", _cmd);
		return;
	}


	int n = [m_items count];
	if(n < 2) {
		LOG_DEBUG(@"%s too few entries", _cmd);
		return;
	}

	int row = [tv selectedRow];
	if(row < 1) {
		LOG_DEBUG(@"%s editing row0 is not possible", _cmd);
		return;
	}
	if(row >= n) {
		LOG_DEBUG(@"%s out of bounds", _cmd);
		return;
	}
	
	NCListerItem* item = [self currentItem];
	if(!item) return;


	//Try to end any editing that is taking place in the table view
	NSWindow *w = [tv window];
	BOOL endEdit = [w makeFirstResponder:w];
	if(!endEdit) {
		LOG_DEBUG(@"%s failed to end editing", _cmd);
		return;
	}
	
	
	[m_tablecolumn_name setEditable:YES];
	[[m_tablecolumn_name dataCell] setEditable:YES];
	[[m_tablecolumn_name dataCell] setSelectable:YES];

	NSString* name = [item name];
	[self setEditName:name];
	
	NSString* filename_no_suffix = [name stringByDeletingPathExtension];
	
	[tv editColumn:col_index row:row withEvent:nil select:YES];

	NSText* txt = [tv currentEditor];
	NSAssert(txt, @"tableview must return a field editor");
	// LOG_DEBUG(@"NSText: %@", txt);
	
	[txt setRichText:NO];         
	[txt setUsesFontPanel:NO];
	[txt setImportsGraphics:NO];
	[txt setBackgroundColor:[NSColor whiteColor]];
	[txt setTextColor:[NSColor blackColor]];
	[txt setDrawsBackground:YES];

	[txt setString:name];
	[txt setSelectedRange:NSMakeRange(0, [filename_no_suffix length])]; /**/
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	// LOG_DEBUG(@"%s ", _cmd);
    // if ([aTableView isEqual:TheTableViewYouWantToChangeBehaviour])
        // [myFieldEditor setLastKnownColumn:[[aTableView tableColumns] indexOfObject:aCol] andRow:aRow];
    return YES;
}


- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
	// LOG_DEBUG(@"%s", _cmd);

	if(control == m_lister_tableview) {
		NSTableView* tv = m_lister_tableview;
		// LOG_DEBUG(@"%s same...... yes", _cmd);

		NSText* txt = [tv currentEditor];
		NSString* new_name = [txt string];

		NCListerItem* item = [self currentItem];
		if(!item) return YES;
		NSString* old_name = [item name];
		
		BOOL name_ok = [old_name isEqual:[self editName]];
		if(!name_ok) { 
			// integrity error, let's end the editing
			[self setEditName:nil];
			return YES;
		}


		// LOG_DEBUG(@"rename: %@ %@", old_name, new_name);
		BOOL ok = [self renameFrom:old_name to:new_name];

		if(ok) {
			// rename successful
			[self performSelector:@selector(reloadAction:) withObject:nil afterDelay:0];
			[self setEditName:nil];
			return YES;
		} else {
			// failed to rename
			return NO;
		}
	}

	
	return YES;
}

-(BOOL)renameFrom:(NSString*)from_name to:(NSString*)to_name {
	if([from_name isEqualToString:to_name]) {
		LOG_DEBUG(@"from_name and to_name are the same, no need to rename", _cmd);
		return YES;
	}
	

	NSError* error = nil;
	NSFileManager* fm = [NSFileManager defaultManager];
	
	NSString* wdir = [self workingDir];
	NSString* from_path = [wdir stringByAppendingPathComponent:from_name];
	NSString* to_path = [wdir stringByAppendingPathComponent:to_name];
    
	// protect against evil stuff such as slashes
	NSString* to_wdir = [to_path stringByDeletingLastPathComponent];
	if(![to_wdir isEqual:wdir]) {
		LOG_DEBUG(@"rename rejected - filename changes working directory: %@", to_name);
		return NO;
	}


	/*
	HACK: [NSFileManager moveItemAtPath] won't allow us to
	rename from "test" to "TEST". Internally moveItemAtPath
	must do a case-in-sensitive match and refuse to do the
	renaming if the strings are equal.
	
	SOLUTION: rename to a temporary name.
	*/
	NSString* s0 = [from_name lowercaseString];
	NSString* s1 = [to_name lowercaseString];
	if([s0 isEqualToString:s1]) {
		LOG_DEBUG(@"%s SAME, need temporary rename", _cmd);

		NSString* tmp_path = [to_path stringByAppendingPathExtension:@"tempname"];
		BOOL ok = [fm moveItemAtPath:from_path toPath:tmp_path error:&error];
		if(!ok) {
			LOG_DEBUG(@"ERROR: couldn't rename temporary file\n%@", error);
			return NO;
		} else {
			LOG_DEBUG(@"renamed to temporary file");
		}
		
		from_path = tmp_path;
	}
	{
		/*
		PROBLEM: rename symbolic links doesn't work.
		it seems that moveItemAtPath:toPath:error: doesn't work correct
		investigate alternatives... e.g. rename();
		*/
		BOOL ok = [fm moveItemAtPath:from_path toPath:to_path error:&error];
		if(!ok) {
			LOG_DEBUG(@"%s ERROR: couldn't rename file\n%@", _cmd, error);
			return NO;
		}
	}
	LOG_DEBUG(@"File renamed successfully\nFrom: \"%@\"\nTo: \"%@\"", from_path, to_path);
	return YES;
}

#if 0
- (void)controlTextDidEndEditing:(NSNotification *)aNotification {
	LOG_DEBUG(@"%s", _cmd);
	return;
	
	// try rename

	if([aNotification object] == m_lister_tableview) {
		NSTableView* tv = m_lister_tableview;

		NSText* txt = [tv currentEditor];
		NSString* new_name = [txt string];

		NCListerItem* item = [self currentItem];
		if(!item) return;
		NSString* old_name = [item name];


		// NSString* dst_path = [src_path stringByDeletingLastPathComponent];
		// dst_path = [dst_path stringByAppendingPathComponent:s];

		LOG_DEBUG(@"rename: %@ %@", old_name, new_name);
		
/*		SEL sel = @selector(pane:renameFromPath:toPath:);
		if([m_delegate respondsToSelector:sel]) {
			[m_delegate pane:self renameFromPath:src_path toPath:dst_path];
		} */
	}
}
#endif

/*- (void)textDidEndEditing:(NSNotification *)aNotification {
	LOG_DEBUG(@"%s", _cmd);
}*/

/*- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
	LOG_DEBUG(@"%s", _cmd);
	
	return YES;
}*/

/*-(void)tableView:(NSTableView *)view setObjectValue:(id)obj forTableColumn:(NSTableColumn *)column row:(int)rowIndex
{
	LOG_DEBUG(@"%s", _cmd);
	// 
} */

/*
traps escape key so you can cancel the operation
*/
-(BOOL)control:(NSControl *)control 
       textView:(NSTextView *)textView 
    doCommandBySelector:(SEL)command
{
	// LOG_DEBUG(@"%s selector: %@", _cmd, NSStringFromSelector(command));
	if(command == @selector(cancelOperation:) ) {
		// LOG_DEBUG(@"%s abort editing", _cmd);
		[self setEditName:nil];
		[control abortEditing];
		[[control window] makeFirstResponder:control];
		return YES;
	}
	if(command == @selector(insertTab:) ) {
		// LOG_DEBUG(@"ignore tabs");
		return YES;
	}
	return NO;
}




#pragma mark -
#pragma mark Context Menu In Table Body 

-(void)showLeftContextMenu:(id)sender {
	NSMenu* menu = nil;
	if([self.delegate respondsToSelector:@selector(listerLeftMenu:)]) {
		menu = [self.delegate listerLeftMenu:self];
	}
	[self showContextMenu:menu];
}

-(void)showRightContextMenu:(id)sender {
	NSMenu* menu = nil;
	if([self.delegate respondsToSelector:@selector(listerRightMenu:)]) {
		menu = [self.delegate listerRightMenu:self];
	}
	[self showContextMenu:menu];
}

-(void)showContextMenu:(NSMenu*)menu {
	if(!menu) {
		menu = [[NSMenu alloc] initWithTitle:@"menu"];
		[menu addItem:[[NSMenuItem alloc] initWithTitle:@"Empty" action:nil keyEquivalent:@""]];
	}
	
	float offset_x = -16;
	float offset_x_underflow = 10;
	float offset_x_overflow = 10;
	float offset_y_underflow = 10;
	float offset_y_overflow = 10;
	
	NSUInteger col_index = [[m_lister_tableview tableColumns] indexOfObject:m_tablecolumn_name];
	if(col_index == NSNotFound) {
		LOG_DEBUG(@"%s ERROR: column not found, refusing to show menu", _cmd);
		return;
	}
	
	
	NSRect crect = [m_lister_tableview frameOfCellAtColumn:col_index 
		row:[m_lister_tableview selectedRow]];
	NSPoint point = NSMakePoint(NSMinX(crect) - offset_x, NSMaxY(crect));

	// ensure we stay inside the visible rect 
	NSRect vrect = [m_lister_tableview visibleRect];
	if(NSMaxX(crect) < NSMinX(vrect)) {
		point.x = NSMinX(vrect) + offset_x_underflow;
	} else
	if(NSMinX(crect) > NSMaxX(vrect)) {
		point.x = NSMaxX(vrect) - offset_x_overflow;
	}
	if(point.y < NSMinY(vrect)) {
		point.y = NSMinY(vrect) + offset_y_underflow;
	} else
	if(point.y > NSMaxY(vrect)) {
		point.y = NSMaxY(vrect) - offset_y_overflow;
	}
	
	// LOG_DEBUG(@"A: %.2f %.2f", point.x, point.y);
	
	NSPoint location = [m_lister_tableview convertPoint:point toView:nil];
	// LOG_DEBUG(@"B: %.2f %.2f", location.x, location.y);

	NSEvent* event = [NSEvent otherEventWithType:NSApplicationDefined
		location:location 
		modifierFlags:0 
		timestamp:0
		windowNumber:[[self window] windowNumber]
		context:[[self window] graphicsContext]
		subtype:100
		data1:0
		data2:0
	];

	/*
	PROBLEM: we want the first menuitem to be highlighted
	HACK: we must simulate a key press of the arrow-down key
	*/
	{
		CGKeyCode key_code = 125;  // kVK_DownArrow = 125
		CGEventRef event1, event2;
		event1 = CGEventCreateKeyboardEvent(NULL, key_code, YES);
		event2 = CGEventCreateKeyboardEvent(NULL, key_code, NO);
		CGEventPost(kCGSessionEventTap, event1);
		CGEventPost(kCGSessionEventTap, event2);
		CFRelease(event1);
		CFRelease(event2);
	}

    [NSMenu popUpContextMenu:menu withEvent:event forView:self];
	[NSCursor setHiddenUntilMouseMoves:YES];
}


#pragma mark -
#pragma mark Context Menu In Table Header

-(NSMenu*)headerMenuForColumn:(int)column_index {
	// LOG_DEBUG(@"%s %i", _cmd, column_index);
	NSMenu* menu = [[NSMenu alloc] initWithTitle:@"Header Menu"];
	if(column_index >= 0) {
		NSString* title = @"Auto Size Column";
		NSMenuItem* mi = [menu addItemWithTitle:title action:@selector(autoSizeThisColumnMenuAction:) keyEquivalent:@""];
		[mi setTarget:self];
		[mi setTag:100];
		[mi setRepresentedObject:[NSNumber numberWithInt:column_index]];
	}
	{
		NSString* title = @"Auto Size All Columns";
		NSMenuItem* mi = [menu addItemWithTitle:title action:@selector(autoSizeAllColumnsMenuAction:) keyEquivalent:@""];
		[mi setTarget:self];
	}
	[menu addItem:[NSMenuItem separatorItem]];
	
	NSArray* columns = [m_lister_tableview tableColumns];
	NSEnumerator* enumerator = [columns objectEnumerator];
	NSTableColumn *column;
	while((column = [enumerator nextObject])) {
		NSString* title = [[column headerCell] title];
		
		NSMenuItem* item = [menu addItemWithTitle:title action:@selector(toggleColumnMenuAction:) keyEquivalent:@""];
		[item setTarget:self];
		[item setRepresentedObject:column];
		[item setState:[column isHidden] ? NSOffState : NSOnState];

		// ghost out the Name column
		if([title isEqual:@"Name"]) [item setAction:NULL]; 
	}
	
	return menu;
}

-(void)autoSizeThisColumnMenuAction:(id)sender {

	int column_index = [[sender representedObject] intValue];
	NSTableColumn* menu_column = nil;
	NSArray* cols = [m_lister_tableview tableColumns];
	if((column_index >= 0) && (column_index < [cols count])) {
		menu_column = [cols objectAtIndex:column_index];
	}
	if(!menu_column) {
		return;
	}
	/*
	The autosizing is not good, but somewhat better than nothing.
	I should query the cell for their minimum/average/max widths
	and their information priority.
	*/
	[menu_column setWidth:[menu_column minWidth]];

	NSFont* font = [[menu_column dataCell] font];
    NSMutableDictionary* attr = [[NSMutableDictionary alloc] init];
    [attr setObject:font forKey:NSFontAttributeName];

	float padding = 10;
	int n = [self numberOfRowsInTableView:m_lister_tableview];
	if(n > 0) { 

		float found_width = 0;
		int i;
		for(i = 0; i < n; i++){
			NSString* s = [self tableView:m_lister_tableview
				objectValueForTableColumn:menu_column
				row:i];
			NSSize size = [s sizeWithAttributes:attr];
			float w = size.width + padding;
			if(w > found_width){
				found_width = w;
			}
		}
		[menu_column setWidth:found_width];
    }
}

-(void)autoSizeAllColumnsMenuAction:(id)sender {
	/*
	TODO: the sizetofit effect isn't satisfying alone,
	this needs serious work.
	
	All columns are resized to the same size, up to a 
	column's maximum size. This method then invokes tile.
	*/
	[m_lister_tableview sizeToFit];
}

-(void)toggleColumnMenuAction:(id)sender {
	// LOG_DEBUG(@"%s", _cmd);
	NSTableColumn* column = [sender representedObject];
    BOOL is_onstate = NO;
    if ([sender isKindOfClass:[NSCell class]]) {
        NSCell* cell = (NSCell*)sender;
        is_onstate = ([cell state] == NSOnState);
    }
	if(is_onstate) {
		[column setHidden:YES];		
	} else {
		[column setHidden:NO];
	}
	[m_lister_tableview setNeedsDisplay:YES];
}

-(NSMenu*)menuForHeaderEvent:(NSEvent*)event {
	// LOG_DEBUG(@"%s", _cmd);
	NSPoint point = [event locationInWindow];
	// LOG_DEBUG(@"%s before: %.2f %.2f", _cmd, point.x, point.y);
	point = [self convertPoint:point fromView:nil];
	// LOG_DEBUG(@"%s after: %.2f %.2f", _cmd, point.x, point.y);
	point.y = 0;
	int column_index = [m_lister_tableview columnAtPoint:point];
	// LOG_DEBUG(@"%s %i", _cmd, column_index);
	return [self headerMenuForColumn:column_index];
}


#pragma mark -
#pragma mark Auto Save Column Layout

-(void)saveColumnLayout {
	NSArray* ary = [m_lister_tableview arrayWithColumnLayout];
	NSString* name = [self autoSaveName];
	if(!name) name = @"Noname";
	// LOG_DEBUG(@"%s %@", _cmd, name);
	[[NSUserDefaults standardUserDefaults] setObject:ary forKey:name];
}

-(void)loadColumnLayout {
	NSString* name = [self autoSaveName];
	if(!name) name = @"Noname";
	// LOG_DEBUG(@"%s %@", _cmd, name);
	NSArray* ary = [[NSUserDefaults standardUserDefaults] arrayForKey:name];
	[m_lister_tableview adjustColumnLayoutForArray:ary];
}

#pragma mark -

- (void)drawRect:(NSRect)rect{
	// [[NSColor colorWithCalibratedRed:0.597 green:0.607 blue:0.607 alpha:1.000] set];
	[[NSColor redColor] set];
	NSRectFill(rect);
}


@end
