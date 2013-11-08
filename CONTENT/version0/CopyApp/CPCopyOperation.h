/*********************************************************************
CPCopyOperation.h - lowlevel copy

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#ifndef __OPCODERS_KEYBOARDCOMMANDER_COPYAPP_COPYOPERATION_H__
#define __OPCODERS_KEYBOARDCOMMANDER_COPYAPP_COPYOPERATION_H__

@interface CPCopyOperation : NSObject {
	id m_delegate;
	
	unsigned long long m_current_bytes_to_copy;
	unsigned long long m_current_bytes_copied;
	unsigned long long m_total_bytes_to_copy;
	unsigned long long m_total_bytes_copied;
	
	NSString* m_target_dir;
	NSString* m_source_dir;
	NSArray* m_source_names;
	
	NSString* m_current_name;
	float m_current_progress;
	float m_total_progress;
	
	NSTask* m_cp_task;
}
-(void)setDelegate:(id)delegate;                    
-(id)delegate;


-(void)setTargetDir:(NSString*)v;
-(void)setSourceDir:(NSString*)v;
-(void)setSourceNames:(NSArray*)v;

-(void)execute;

-(NSString*)currentName;    
-(float)currentProgress;
-(float)totalProgress;

@end

@interface NSObject (CPCopyOperationDelegate)
-(void)willCopyFile;
-(void)updateCopyStatus;
-(void)didCopyFile;
-(void)doneCopying;
@end


#endif // __OPCODERS_KEYBOARDCOMMANDER_COPYAPP_COPYOPERATION_H__