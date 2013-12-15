//
//  NCCopySheet.h
//  NCCore
//
//  Created by Simon Strandgaard on 25/04/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCCopyOperationProtocol.h"


#ifndef __has_attribute
#define __has_attribute(x) 0  // Compatibility with non-clang compilers
#endif

#if __has_attribute(objc_method_family)
#define BV_OBJC_METHOD_FAMILY_NONE __attribute__((objc_method_family(none)))
#else
#define BV_OBJC_METHOD_FAMILY_NONE
#endif


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
	
	id <NCCopyOperationProtocol> m_copy_operation;
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

// --- PROBLEM BEGIN
// According to Apples: Transitioning to ARC Release Notes
// You cannot give a property a name that begins with new or copy.
// TODO: remove the copy prefix, so that we comply with the ARC guidelines
@property (strong) id <NCCopyOperationProtocol> copyOperation;
-(id <NCCopyOperationProtocol>)copyOperation BV_OBJC_METHOD_FAMILY_NONE;
// --- PROBLEM END

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