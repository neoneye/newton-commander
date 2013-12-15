//
//  NCMoveSheet.h
//  NCCore
//
//  Created by Simon Strandgaard on 14/08/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCMoveOperationProtocol.h"


@interface NCMoveSheetItem : NSObject {
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

@interface NCMoveSheet : NSWindowController <NCMoveOperationDelegate> {
	id __unsafe_unretained m_delegate;
	NSView* __weak m_confirm_view;
	NSView* __weak m_progress_view;

	NSArray* m_names;
	NSString* m_source_dir;
	NSString* m_target_dir;

	// confirm sheet
	NSTextField* __weak m_confirm_summary;
	NSButton* __weak m_confirm_button;
	NSButton* __weak m_confirm_close_when_finished_button;
	NCPathControl* __weak m_confirm_source_path;
	NCPathControl* __weak m_confirm_target_path;

	// progress sheet
	NSTextField* __weak m_progress_summary;
	NSProgressIndicator* __weak m_progress_indicator;
	NSButton* __weak m_abort_button;
	NSButton* __weak m_progress_close_when_finished_button;
	NCPathControl* __weak m_progress_source_path;
	NCPathControl* __weak m_progress_target_path;

	NSArrayController* __weak m_progress_items;
	
	id <NCMoveOperationProtocol> m_move_operation;
}
@property (unsafe_unretained) id delegate;
@property (weak) IBOutlet NSView* confirmView;
@property (weak) IBOutlet NSView* progressView;
@property (weak) IBOutlet NSTextField* confirmSummary;
@property (weak) IBOutlet NSButton* confirmButton;
@property (weak) IBOutlet NSButton* abortButton;
@property (weak) IBOutlet NSButton* confirmCloseWhenFinishedButton;
@property (weak) IBOutlet NSButton* progressCloseWhenFinishedButton;
@property (weak) IBOutlet NSTextField* progressSummary;
@property (weak) IBOutlet NSProgressIndicator* progressIndicator;
@property (weak) IBOutlet NSArrayController* progressItems;
@property (weak) IBOutlet NCPathControl* confirmSourcePath;
@property (weak) IBOutlet NCPathControl* confirmTargetPath;
@property (weak) IBOutlet NCPathControl* progressSourcePath;
@property (weak) IBOutlet NCPathControl* progressTargetPath;
@property (copy) NSArray* names;
@property (copy) NSString* sourceDir;
@property (copy) NSString* targetDir;
@property (strong) id <NCMoveOperationProtocol> moveOperation;
+(NCMoveSheet*)shared;

-(void)beginSheetForWindow:(NSWindow*)parentWindow;

-(IBAction)cancelAction:(id)sender;
-(IBAction)submitAction:(id)sender;


@end
