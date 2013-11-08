//
//  NCCopySheet.h
//  NCCore
//
//  Created by Simon Strandgaard on 25/04/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCCopyOperationProtocol.h"


@interface NCCopySheetItem : NSObject {
	NSString* name;
	NSString* message;
	unsigned long long bytes; // filesize in bytes
	unsigned long long count; // number of items
}
@property (copy) NSString* name;
@property (copy) NSString* message;
@property (assign) unsigned long long bytes;
@property (assign) unsigned long long count;

+(NSArray*)itemsFromNames:(NSArray*)ary;
@end

@class NCPathControl;

@interface NCCopySheet : NSWindowController <NCCopyOperationDelegate> {
	id m_delegate;
	NSView* m_confirm_view;
	NSView* m_progress_view;

	NSArray* m_names;
	NSString* m_source_dir;
	NSString* m_target_dir;

	// confirm sheet
	NSTextField* m_confirm_summary;
	NSButton* m_confirm_button;
	NSButton* m_confirm_close_when_finished_button;
	NCPathControl* m_confirm_source_path;
	NCPathControl* m_confirm_target_path;

	// progress sheet
	NSTextField* m_progress_summary;
	NSProgressIndicator* m_progress_indicator;
	NSButton* m_abort_button;
	NSButton* m_progress_close_when_finished_button;
	NCPathControl* m_progress_source_path;
	NCPathControl* m_progress_target_path;

	NSArrayController* m_progress_items;
	
	id <NCCopyOperationProtocol> m_copy_operation;
}
@property (assign) id delegate;
@property (assign) IBOutlet NSView* confirmView;
@property (assign) IBOutlet NSView* progressView;
@property (assign) IBOutlet NSTextField* confirmSummary;
@property (assign) IBOutlet NSButton* confirmButton;
@property (assign) IBOutlet NSButton* abortButton;
@property (assign) IBOutlet NSButton* confirmCloseWhenFinishedButton;
@property (assign) IBOutlet NSButton* progressCloseWhenFinishedButton;
@property (assign) IBOutlet NSTextField* progressSummary;
@property (assign) IBOutlet NSProgressIndicator* progressIndicator;
@property (assign) IBOutlet NSArrayController* progressItems;
@property (assign) IBOutlet NCPathControl* confirmSourcePath;
@property (assign) IBOutlet NCPathControl* confirmTargetPath;
@property (assign) IBOutlet NCPathControl* progressSourcePath;
@property (assign) IBOutlet NCPathControl* progressTargetPath;
@property (copy) NSArray* names;
@property (copy) NSString* sourceDir;
@property (copy) NSString* targetDir;
@property (retain) id <NCCopyOperationProtocol> copyOperation;
+(NCCopySheet*)shared;

-(void)beginSheetForWindow:(NSWindow*)parentWindow;
-(IBAction)cancelAction:(id)sender;
-(IBAction)submitAction:(id)sender;

-(IBAction)closeWindowWhenFinishedAction:(id)sender;

@end

@interface NSObject (NCCopySheetDelegate)
-(void)copySheetDidClose:(NCCopySheet*)sheet;
-(void)copySheetDidFinish:(NCCopySheet*)sheet;
@end