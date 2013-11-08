/*********************************************************************
AppDelegate.h - the control center for the entire program

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#ifndef __OPCODERS_ORTHODOXFILEMANAGER_APPDELEGATE_H__
#define __OPCODERS_ORTHODOXFILEMANAGER_APPDELEGATE_H__


@class OFMPane;
@class KCDiscover;
@class KCReport; 
@class KCDiscoverStatItem;
@class JFCopy;

@interface AppDelegate : NSObject {
	IBOutlet NSWindow* m_window;

	IBOutlet NSButton* m_left_quicklook_button;
	IBOutlet NSButton* m_right_quicklook_button;

	IBOutlet NSTabView* m_left_tabview;
	IBOutlet NSTabView* m_right_tabview;
	
	IBOutlet NSTextView* m_left_textview;
	IBOutlet NSTextView* m_right_textview;
	
	IBOutlet NSTableView* m_left_tableview;
	IBOutlet NSTableView* m_right_tableview;
	
	IBOutlet NSTextView* m_left_report_textview;
	IBOutlet NSTextView* m_right_report_textview;
	
	IBOutlet NSView* m_move_alert_accessory;
	IBOutlet NSTextField* m_move_alert_textfield;
	NSString* m_move_src_location;

	IBOutlet NSView* m_copy_alert_accessory;
	IBOutlet NSTextField* m_copy_alert_textfield;
	NSString* m_copy_src_location;

	IBOutlet NSView* m_mkdir_alert_accessory;
	IBOutlet NSTextField* m_mkdir_alert_textfield;
	NSString* m_mkdir_location;

	IBOutlet NSView* m_mkfile_alert_accessory;
	IBOutlet NSTextField* m_mkfile_alert_textfield;
	NSString* m_mkfile_location;

	NSString* m_delete_path;
	
	IBOutlet NSPopUpButton* m_toolbar_popupbutton;

	IBOutlet NSComboBox* m_left_path_combobox;
	IBOutlet NSComboBox* m_right_path_combobox;

	IBOutlet NSArrayController* m_discover_stat_items;
	IBOutlet NSWindow* m_discover_stat_window;

	IBOutlet NSArrayController* m_report_stat_items;
	IBOutlet NSWindow* m_report_stat_window;

	IBOutlet NSWindow* m_about_window;
	IBOutlet NSTextField* m_about_name_textfield;
	IBOutlet NSTextField* m_about_version_textfield;
	IBOutlet NSTextField* m_about_copyright_textfield;
	IBOutlet NSTextField* m_about_shortversion_textfield;

	OFMPane* m_left_pane;
	OFMPane* m_right_pane;
	
	NSAlert* m_alert;
	
	float m_table_font_size;
	
	KCDiscover* m_left_discover;
	KCDiscover* m_right_discover;
	
	KCReport* m_report;
	
	NSString* m_path_to_discover_app_executable;
	NSString* m_path_to_report_app_executable;
	NSString* m_path_to_copy_app_executable;
	
	JFCopy* m_copy;


	IBOutlet NSSearchField* m_left_toolbar_searchfield;
	IBOutlet NSSearchField* m_right_toolbar_searchfield;
	
	
	NSToolbarItem* m_toolbar_item1;
	NSToolbarItem* m_toolbar_item7;


	// statistics for how the Report.app process is doing
	KCDiscoverStatItem* m_report_stat_item;
	double m_time_report_begin;
	double m_time_report_processing;
	
	int m_transaction_id_seed;
}

-(void)start;

-(void)setBookmarkMenu:(NSMenu*)menu;

-(IBAction)reloadTab:(id)sender;
-(IBAction)swapTabs:(id)sender;
-(IBAction)mirrorTabs:(id)sender;
-(IBAction)cycleInfoPanes:(id)sender;
-(IBAction)revealInFinder:(id)sender;
-(IBAction)revealInfoInFinder:(id)sender;
-(IBAction)selectCenterRow:(id)sender;
-(IBAction)renameAction:(id)sender;
-(IBAction)mkdirAction:(id)sender;
-(IBAction)mkfileAction:(id)sender;
-(IBAction)deleteAction:(id)sender;
-(IBAction)moveAction:(id)sender;
-(IBAction)newCopyAction:(id)sender;
-(IBAction)copyAction:(id)sender;
-(IBAction)helpAction:(id)sender;
-(IBAction)viewAction:(id)sender;
-(IBAction)editAction:(id)sender;
-(IBAction)changeFontSizeAction:(id)sender;
-(IBAction)restartDiscoverTaskAction:(id)sender;
-(IBAction)forceCrashDiscoverTaskAction:(id)sender;     
-(IBAction)hideShowDiscoverStatWindowAction:(id)sender;
-(IBAction)hideShowReportStatWindowAction:(id)sender;
-(IBAction)debugInspectCacheAction:(id)sender;          
-(IBAction)debugSeparatorAction:(id)sender;             
-(IBAction)debugAction:(id)sender;             
-(IBAction)selectAllAction:(id)sender;
-(IBAction)selectNoneAction:(id)sender;
-(IBAction)selectAllOrNoneAction:(id)sender;
-(IBAction)invertSelectionAction:(id)sender;
-(IBAction)copyCurrentPathStringToClipboardAction:(id)sender;
-(IBAction)openDiffToolAction:(id)sender;
-(IBAction)openCurrentPathInTerminalAction:(id)sender;  
-(IBAction)showReportAction:(id)sender;

-(IBAction)installCommandlineToolAction:(id)sender;

-(IBAction)installKCHelperAction:(id)sender;
-(IBAction)launchDiscoverAction:(id)sender;

-(IBAction)showPreferencesPanel:(id)sender;
-(IBAction)showBookmarkPreferencesPanel:(id)sender;

-(IBAction)showAboutPanel:(id)sender;

// go to the paypal homepage
-(IBAction)donateMoneyAction:(id)sender;

// go to the opcoders homepage
-(IBAction)visitWebsiteAction:(id)sender;

@end

#endif // __OPCODERS_ORTHODOXFILEMANAGER_APPDELEGATE_H__