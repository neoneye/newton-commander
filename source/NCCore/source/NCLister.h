//
//  NCLister.h
//  NCCore
//
//  Created by Simon Strandgaard on 03/02/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// Quartz framework provides the QLPreviewPanel public API
#import <Quartz/Quartz.h>



#import "NCListerDataSource.h"
#import "NCListerTableView.h"

@class NCLister;


@protocol NCListerDelegate <NSObject>
@optional
-(void)listerDidChangeWorkingDirectory:(NCLister*)aLister;
-(void)listerDidResolveWorkingDirectory:(NCLister*)aLister;

-(void)listerWillLoad:(NCLister*)aLister;
-(void)listerDidLoad:(NCLister*)aLister;

-(void)listerTabKeyPressed:(NCLister*)aLister;

-(void)listerSwitchToNextTab:(NCLister*)aLister;
-(void)listerSwitchToPrevTab:(NCLister*)aLister;

-(void)listerCloseTab:(NCLister*)aLister;

-(void)listerActivateTableView:(NCLister*)aLister;

/*
invoked whenever the number of directories/files/bytes changes and
whenever the selection is changed so that the number_of_selected_dirs/files/bytes changes.
*/
-(void)listerDidUpdateCounters:(NCLister*)aLister;

/*
invoked when the user presses the arrow_left key in order to popup the left menu
*/
-(NSMenu*)listerLeftMenu:(NCLister*)aLister;

/*
invoked when the user presses the arrow_right key in order to popup the right menu
*/
-(NSMenu*)listerRightMenu:(NCLister*)aLister;

@end


@class NCListerTableView;
@class NCListerBreadcrumb;
@class NCListerBreadcrumbStack;
@class NCListerItem;
@class NCImageCache;

typedef struct {
	int number_of_directories;
	int number_of_files;
	unsigned long long size_of_items;

	int number_of_selected_directories;
	int number_of_selected_files;
	unsigned long long size_of_selected_items;
} NCListerCountersStruct;


@interface NCLister : NSView <NSTableViewDelegate, NSTableViewDataSource, QLPreviewPanelDataSource, QLPreviewPanelDelegate, NCListerDataSourceDelegate, NCListerTableViewDelegate>
{
	NSString* m_auto_save_name;

	NCListerTableView* m_lister_tableview;
	
	id<NCListerDataSource> m_lister_data_source;

	// the columns showing data
	NSTableColumn* m_tablecolumn_name;                 // string
	NSTableColumn* m_tablecolumn_size;                 // unsigned long long (bytes or item-count)
	NSTableColumn* m_tablecolumn_resource_fork_size;   // unsigned long long (bytes)
	NSTableColumn* m_tablecolumn_permissions;
	NSTableColumn* m_tablecolumn_owner;
	NSTableColumn* m_tablecolumn_group;
	NSTableColumn* m_tablecolumn_accessed;             // date
	NSTableColumn* m_tablecolumn_content_modified;     // date
	NSTableColumn* m_tablecolumn_attribute_modified;   // date
	NSTableColumn* m_tablecolumn_created;              // date
	NSTableColumn* m_tablecolumn_backup;               // date
	NSTableColumn* m_tablecolumn_refcount;             // integer
	NSTableColumn* m_tablecolumn_aclcount;             // integer
	NSTableColumn* m_tablecolumn_xattrcount;           // integer
	NSTableColumn* m_tablecolumn_inode;                // unsigned long long
	NSTableColumn* m_tablecolumn_flags;                // unsigned long
	NSTableColumn* m_tablecolumn_kind;                 // string
	NSTableColumn* m_tablecolumn_content_type;         // string
	NSTableColumn* m_tablecolumn_comment;              // string


	// sorting
	NSTableColumn* m_sort_column;
	int m_sort_reverse;
	NSArray* m_sort_descriptors;
	
	
	// theming
	NSColor* m_highlighted_selected_text_color;
	NSColor* m_highlighted_text_color;
	NSColor* m_selected_text_color;
	NSColor* m_text_color;
	NSColor* m_selected_background_color;
	NSColor* m_grid_color;
	NCImageCache* m_image_cache;

	
	BOOL m_need_reset_when_updating_items;

	BOOL m_active;
	NSArray* m_items;
	NSMutableIndexSet* m_selected_indexes;
	NSArray* m_sorted_items;

	NSMutableDictionary* m_binding_info;
	
	NSString* m_working_dir;
	
	NCListerCountersStruct m_counters;

	NCListerBreadcrumb* m_current_breadcrumb;
	NCListerBreadcrumbStack* m_breadcrumb_stack;


	// search
	NSMutableDictionary* m_name_to_index;
	NSMutableDictionary* m_inode_to_index;
	

	// renaming
	NSString* m_edit_name;
}
@property (strong) NSString* autoSaveName;
@property (unsafe_unretained) IBOutlet id<NCListerDelegate> delegate;
@property (strong) id<NCListerDataSource> listerDataSource;
@property (readonly) BOOL active;
@property (strong) NSTableColumn* tableColumnName;
@property (strong) NSTableColumn* tableColumnSize;
@property (strong) NSTableColumn* tableColumnResourceForkSize;
@property (strong) NSTableColumn* tableColumnPermissions;
@property (strong) NSTableColumn* tableColumnOwner;
@property (strong) NSTableColumn* tableColumnGroup;
@property (strong) NSTableColumn* tableColumnAccessed;
@property (strong) NSTableColumn* tableColumnContentModified;
@property (strong) NSTableColumn* tableColumnAttributeModified;
@property (strong) NSTableColumn* tableColumnCreated; 
@property (strong) NSTableColumn* tableColumnBackup; 
@property (strong) NSTableColumn* tableColumnRefCount;
@property (strong) NSTableColumn* tableColumnAclCount;
@property (strong) NSTableColumn* tableColumnXattrCount;
@property (strong) NSTableColumn* tableColumnInode; 
@property (strong) NSTableColumn* tableColumnFlags;
@property (strong) NSTableColumn* tableColumnKind;
@property (strong) NSTableColumn* tableColumnContentType;
@property (strong) NSTableColumn* tableColumnComment;
@property (strong) NSArray* items;             
@property (strong) NSArray* sortedItems;             
@property (strong) NSMutableIndexSet* selectedIndexes;             
@property (strong) NCListerBreadcrumb* currentBreadcrumb;
@property (strong) NCListerBreadcrumbStack* breadcrumbStack;
@property (strong) NSColor* highlightedSelectedTextColor;
@property (strong) NSColor* highlightedTextColor;
@property (strong) NSColor* selectedTextColor;
@property (strong) NSColor* textColor;
@property (strong) NSColor* selectedBackgroundColor;
@property (strong) NSColor* gridColor;
@property (strong) NCImageCache* imageCache;
@property (copy) NSString* editName;
@property (strong) NSMutableDictionary* nameToIndex;
@property (strong) NSMutableDictionary* inodeToIndex;
@property (strong) NSArray* sortDescriptors;
@property (readonly) NCListerCountersStruct counters;


-(void)setDataSource:(id<NCListerDataSource>)dataSource;
-(id<NCListerDataSource>)dataSource;


-(NCListerBreadcrumb*)currentBreadcrumb;
-(void)setCurrentBreadcrumb:(NCListerBreadcrumb*)crumb;


-(IBAction)reloadAction:(id)sender;

-(void)activate;
-(void)deactivate;

-(void)navigateBackAction:(id)sender;
-(void)navigateParentAction:(id)sender;
-(void)navigateInOrBackAction:(id)sender;
-(void)navigateInOrParentAction:(id)sender;

-(void)nc_selectAll;
-(void)nc_selectNone;
-(void)nc_selectAllOrNone;

-(void)revealSelectedItems;
-(IBAction)revealInFinder:(id)sender;

-(void)openSelectedItems;
-(IBAction)openSelectedItems:(id)sender;

-(void)copyItemsToClipboardAbsolute:(BOOL)absolute;
-(IBAction)copyAbsolutePathsToClipboardAction:(id)sender;
-(IBAction)copyNamesToClipboardAction:(id)sender;

-(IBAction)ejectAction:(id)sender;

-(void)enterRenameMode;

-(NSString*)currentName;
-(void)setCurrentName:(NSString*)name;

-(NSArray*)selectedNames;
-(NSArray*)selectedNamesOrCurrentName;

-(NSArray*)urlArrayWithSelectedItemsOrCurrentItem;


-(BOOL)renameFrom:(NSString*)from_name to:(NSString*)to_name;


-(int)listerTableView:(NCListerTableView*)tableview formatCodeForRow:(int)row;

-(void)saveColumnLayout;
-(void)loadColumnLayout;

-(void)adjustThemeForDictionary:(NSDictionary*)dict;
+(NSDictionary*)whiteTheme;
+(NSDictionary*)blackTheme;


// NCListerTableView actions
-(void)tabKeyPressed:(id)sender;
-(void)switchToNextTab:(id)sender;
-(void)switchToPrevTab:(id)sender;
-(void)closeTab:(id)sender;
-(void)activateTableView:(id)sender;




/************************************
	working dir
************************************/
- (NSString*)workingDir;
- (void)setWorkingDir:(NSString*)s;
-(void)navigateToDir:(NSString*)path;


@end
