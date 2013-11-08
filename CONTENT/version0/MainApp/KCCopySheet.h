/*********************************************************************
KCCopySheet.h - controls the modal dialog for "copying"

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#ifndef __OPCODERS_KEYBOARDCOMMANDER_COPY_SHEET_H__
#define __OPCODERS_KEYBOARDCOMMANDER_COPY_SHEET_H__


/*
display the filenames that we are going to copy
and status for our copy operation.
*/
@interface KCCopySheetItem : NSObject {
	NSString* name;
	NSString* status;
	unsigned long long size;
	float progress;
	int state;
}
-(void)setName:(NSString*)v;
-(NSString*)name;
-(void)setSize:(unsigned long long)v;
-(unsigned long long)size;
-(void)setProgress:(float)v;
-(float)progress;
-(void)setState:(int)v;
-(int)state;
-(void)setStatus:(NSString*)v;
-(NSString*)status;
@end


/*
controls the sheets
*/
@class KCCopy;
@interface KCCopySheet : NSObject {
	NSWindow* m_parent_window;
	
	IBOutlet NSView* m_ask_view;
	IBOutlet NSView* m_perform_view;
	IBOutlet NSWindow* m_window;
	
	IBOutlet NSArrayController* m_copy_items;
	IBOutlet NSTextField* m_ask_for_target_path;
	
	NSString* m_source_path;
	NSString* m_target_path;
	
	KCCopy* m_copy;
	NSString* m_exec_path;
}
+(KCCopySheet*)shared;

-(void)setParentWindow:(NSWindow*)window;
-(void)setExecPath:(NSString*)path;

-(void)loadBundle;

-(void)showAskSheet;
-(void)showPerformSheet;
	
-(IBAction)askCancelAction:(id)sender;     
-(IBAction)askSubmitAction:(id)sender;

-(IBAction)performAbortAction:(id)sender;

-(void)setNames:(NSArray*)ary;
-(void)setSourcePath:(NSString*)v;
-(void)setTargetPath:(NSString*)v;

-(NSString*)sourcePath;
-(NSString*)targetPath;

@end

#endif // __OPCODERS_KEYBOARDCOMMANDER_COPY_SHEET_H__