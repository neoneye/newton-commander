/*********************************************************************
OFMPane.h - controller for the left/right work areas in the UI

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#ifndef __OPCODERS_ORTHODOXFILEMANAGER_PANE_H__
#define __OPCODERS_ORTHODOXFILEMANAGER_PANE_H__



@class OPPartialSearch;
@class KCDiscover;
@class JFSizeInfoCell;
@class JFDateInfoCell;
@class JFPermissionInfoCell;


struct BreadcrumItem {
	int m_selected_row;
	
	int m_number_of_rows;

	/*
	PROBLEM: if we store the visible rect, then we can restore the pixel position 
	assuming the window is NOT resized. However our window IS resizable, so we 
	will have to solve it in another way.
	SOLUTION: store a percentage for the y position.
	  0% = top of scrollview
	 50% = middle of scrollview
	100% = bottom of scrollview
	*/
	float m_position_y;
};

enum {
	CHANGE_DIR_FOLLOW_LINK = 0,
	CHANGE_DIR_GOTO_PARENT = 1,
};

enum {
	ATTRIBUTES_ERROR = 0,
	ATTRIBUTES_PARENTDIR,
	ATTRIBUTES_FILENAME,
	ATTRIBUTES_FILENAME_SELECTED,
	ATTRIBUTES_FILENAME_HIGHLIGHTED,
	ATTRIBUTES_EXTENSION,
	ATTRIBUTES_EXTENSION_SELECTED,
	ATTRIBUTES_LETTER_MATCHED,
	ATTRIBUTES_LETTER_UNMATCHED,
	ATTRIBUTES_LAST,
};

enum {
	IMAGES_DIR = 0,
	IMAGES_DIR_LINK,
	IMAGES_FILE,   
	IMAGES_FILE_LINK,   
	IMAGES_OTHER,
	IMAGES_OTHER_LINK,
	IMAGES_LOADING,
	IMAGES_PERM000,
	IMAGES_PERM001,
	IMAGES_PERM010,
	IMAGES_PERM011,
	IMAGES_PERM100,
	IMAGES_PERM101,
	IMAGES_PERM110,
	IMAGES_PERM111,
	IMAGES_LAST,
};

@class KCDiscoverStatItem;
@class PanelTable;
@class NCVolumeInfo;

@interface OFMPane : NSObject {
	NSString* m_name;
	id m_delegate;
	NSTableView* m_tableview;      
	NSTextView* m_textview;
	NSComboBox* m_path_combobox;
	NSButton* m_quicklook_button;
	NSTabView* m_tabview;
	NSSearchField* m_searchfield;

	PanelTable* m_panel_table;

	
	NSArrayController* m_discover_stat_items;
	
	NSString* m_path;
	
	NSFont* m_font_tableview;
	NSFont* m_font_textview;
	
	int m_row;
	NSAttributedString* m_info;
	
	NSDictionary* m_table_attributes[ATTRIBUTES_LAST];

	NSDictionary* m_info_attr1;
	NSDictionary* m_info_attr2;
	
	int m_active_infotab;
	
	NSTask* m_task;
	NSMutableString* m_task_output;

	NSImage* m_images[IMAGES_LAST];
	
	NSMutableArray* m_breadcrum_stack;

	OPPartialSearch* m_partial_search;
	
	JFSizeInfoCell* m_size_info_cell;
	JFDateInfoCell* m_date_info_cell;
	JFPermissionInfoCell* m_permission_info_cell;
	
	NSTimeInterval m_cache_item_timestamp;

	KCDiscover* m_wrapper;
	
	
	BOOL m_show_hidden_files;
	

	// statistics for how the KCList process is doing
	KCDiscoverStatItem* m_discover_stat_item;
	
	double m_time_change_path;
	double m_time_process_begin;
	double m_time_has_names;
	double m_time_has_dirinfo;
	double m_time_has_sizes;
	
	
	// transaction handling
	int m_transaction_id;
	
	BOOL m_request_is_pending;
	
	NCVolumeInfo* m_volume_info;
}
-(id)initWithName:(NSString*)name;
-(void)setDelegate:(id)delegate;
-(void)installCustomCells;
-(void)setWrapper:(KCDiscover*)w;
-(void)setTableView:(NSTableView*)tv;
-(void)setTextView:(NSTextView*)tv;
-(void)setPathComboBox:(NSComboBox*)pc;
-(void)setTabView:(NSTabView*)tv;
-(void)setQuickLookButton:(NSButton*)b;
-(void)setSearchField:(NSSearchField*)sf;
-(void)setDiscoverStatItems:(NSArrayController*)ac;

-(void)setTextViewFont:(NSFont*)font;
-(void)setTableViewFont:(NSFont*)font;


-(void)reloadTableAttributes;

-(void)refreshUI;
-(void)refreshPathControl;
-(void)reloadTableData;

-(void)activate; 


-(void)update;
-(void)reloadSizes;

-(id)tableNameForRow:(int)row;
-(id)tableIconForRow:(int)row;
-(void)changePath:(NSString*)path;
-(NSString*)path;
-(NSAttributedString*)info;
-(void)rebuildInfo;
-(void)setRow:(int)row;
-(int)row;
-(BOOL)gotoParentDir;
-(void)changeDir:(int)action;
-(BOOL)isSelectedRow:(int)row;
-(void)toggleSelectForRow:(int)row;
-(void)setAttributes:(NSDictionary*)attr forIndex:(int)index;


/*
return codes:
 NO = path unchanged
YES = enter subdir 
*/
-(BOOL)followLink;

-(void)setActiveInfoPanel:(int)index;
-(int)activeInfoPanel;
-(void)cycleActiveInfoPanel;

-(NSString*)pathForRow:(int)row;
-(NSString*)pathForCurrentRow;
-(NSString*)nameForCurrentRow;
-(NSString*)pathInFinder;
-(NSString*)pathForReport;
-(NSString*)windowTitle;

-(void)pushBreadcrum:(BreadcrumItem)item;
-(void)popBreadcrum;
-(BreadcrumItem)breadcrum;
-(void)eraseBreadcrums;
-(void)swapBreadcrums:(OFMPane*)other;
-(void)takeBreadcrumsFrom:(OFMPane*)other;
-(void)showMenu;
-(void)revealInFinder;
-(void)openFile;
-(void)selectCenterRow;
-(void)editFilename;

// read (again) the file-list from disk
-(void)reloadPath;

-(void)markCacheItems;

-(void)selectAll;
-(void)selectNone;
-(void)selectAllOrNone;
-(void)invertSelection;


-(void)registerForDraggedTypes;

-(void)appToOpenPath:(NSString*)path;

-(NSArray*)selectedNames;

@end


@interface NSObject (OFMPaneDelegate)

// create a unique transaction id
-(int)mkTransactionId;

-(void)tabAwayFromPane:(OFMPane*)pane;           
-(void)selectionDidChange:(OFMPane*)pane;
-(void)cleanupCache;
-(void)pane:(OFMPane*)pane renameFromPath:(NSString*)fromPath toPath:(NSString*)toPath;
@end


#endif // __OPCODERS_ORTHODOXFILEMANAGER_PANE_H__