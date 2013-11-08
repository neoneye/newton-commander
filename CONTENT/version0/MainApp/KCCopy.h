/*********************************************************************
KCCopy.h - encapsulates the background CopyApp in a thread

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#ifndef __OPCODERS_KEYBOARDCOMMANDER_COPYAPP_WRAPPER_H__
#define __OPCODERS_KEYBOARDCOMMANDER_COPYAPP_WRAPPER_H__

@class KCCopyThread;

@interface KCCopy : NSObject {
	NSString* m_name;
	NSString* m_path_to_child_executable;
	id m_delegate;
	
	NSThread* m_thread;
	
	/*
	all method calls for m_copy_thread must be made with
	performSelector:onThread:withObject:waitUntilDone:modes:
	*/
	KCCopyThread* m_copy_thread;
	
	NSArray* m_source_names;
	NSString* m_source_path;
	NSString* m_target_path;
}
-(id)initWithName:(NSString*)name path:(NSString*)path;

-(void)setDelegate:(id)delegate;                    
-(id)delegate;

-(void)start;

-(void)requestPath:(NSString*)path;

-(void)startCopyOperation;

-(void)setSourcePath:(NSString*)v;
-(void)setTargetPath:(NSString*)v;
-(void)setNames:(NSArray*)v;

@end

@interface NSObject (KCCopyDelegate)
-(void)processDidLaunch;
-(void)copyProgress:(float)progress name:(NSString*)name;
-(void)didCopy:(NSString*)name;
-(void)willCopy:(NSString*)name;
-(void)doneCopying;



-(void)reportIsNowProcessingTheRequest;
-(void)reportHasData:(NSData*)data;
@end


#endif // __OPCODERS_KEYBOARDCOMMANDER_COPYAPP_WRAPPER_H__