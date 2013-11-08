/*********************************************************************
JFCopy.h - UI for copying files

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/

@interface JFCopyItem : NSObject {
	// filename
	NSString* name;
	
	// textual description of current progress of copying
	NSString* status;

	// textual description of current progress obtaining size in bytes and item count
	NSString* scanStatus;
	
	// filesize in bytes
	unsigned long long size;
	
	// number of items
	unsigned long long count;
}
@property (copy) NSString* name;
@property (copy) NSString* status;
@property (copy) NSString* scanStatus;
@property (assign) unsigned long long size;
@property (assign) unsigned long long count;
@end


@class JFSystemCopy;

@interface JFCopy : NSObject {
	IBOutlet NSWindow* m_window;

	IBOutlet NSArrayController* m_copy_items;

	// confirm sheet
	IBOutlet NSView* m_confirm_sheet;
	IBOutlet NSButton* m_confirm_sheet_button;
	IBOutlet NSTextField* m_confirm_source_path;
	IBOutlet NSTextField* m_confirm_target_path;
	IBOutlet NSTextField* m_confirm_summary;
	
	// progress sheet
	IBOutlet NSView* m_progress_sheet;
	IBOutlet NSProgressIndicator* m_progress_indicator;
	IBOutlet NSButton* m_progress_sheet_button;
	IBOutlet NSTextField* m_progress_name_of_current_item;
	IBOutlet NSTextField* m_progress_summary;
	IBOutlet NSTextField* m_progress_source_path;
	IBOutlet NSTextField* m_progress_target_path;

	// no longer needed
	IBOutlet NSView* m_completed_sheet;



	id m_delegate;
	
	NSArray* m_source_names;
	NSString* m_source_path;
	NSString* m_target_path;
	
	JFSystemCopy* m_system_copy;
	
	unsigned long long m_bytes_total;
	unsigned long long m_bytes_copied;
	double m_bytes_per_second;
}

-(void)load;

-(void)beginSheetForWindow:(NSWindow*)parent_window;
-(IBAction)cancelAction:(id)sender;

-(IBAction)startCopyingAction:(id)sender;


-(void)setDelegate:(id)delegate;                    
-(id)delegate;

-(void)setSourcePath:(NSString*)v;
-(void)setTargetPath:(NSString*)v;
-(void)setNames:(NSArray*)v;

-(IBAction)fillWithDummyData:(id)sender;

@end
