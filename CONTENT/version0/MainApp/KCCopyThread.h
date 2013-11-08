/*********************************************************************
KCCopyThread.h - Wrapper thread

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#ifndef __OPCODERS_KEYBOARDCOMMANDER_COPY_THREAD_H__
#define __OPCODERS_KEYBOARDCOMMANDER_COPY_THREAD_H__

@protocol CopyChildProtocol;
@class KCCopyParent;

@interface KCCopyThread : NSObject {
	/*
	all messages to the mainthread_delegate must be	made with
	performSelectorOnMainThread:withObject:waitUntilDone:
	*/
	id m_mainthread_delegate;

	NSString* m_name;
	NSString* m_path_to_child_executable;
	NSString* m_connection_name;
	NSTask* m_task;
	KCCopyParent* m_root_object;
	NSConnection* m_connection;

	NSString* m_child_name;
	id <CopyChildProtocol> m_child;
	NSDistantObject* m_child_distobj;
	
	/*
	when ever we launch a report operation we
	set this busy flag, so that we can determine
	whether the background task has completed or not.
	*/
	BOOL m_is_busy;
	
	NSString* m_request_path;
	NSDictionary* m_request_arguments;
	
	/*
	when starting a new task, we want to know if it
	starts up within a fair amount of time.
	If it doesn't start up for some reason, then we
	want debug info.
	*/
	BOOL m_handshake_ok;
	
	/*
	when everything is up running and the child process is ready
	to be put to work.
	*/
	BOOL m_launched;
}

-(id)initWithName:(NSString*)name path:(NSString*)path;

/*
all messages to the mainthread_delegate must be made with
performSelectorOnMainThread:withObject:waitUntilDone:
*/
-(void)setMainThreadDelegate:(id)delegate;
-(id)mainThreadDelegate;

-(void)threadMainRoutine;

-(void)threadRequest:(NSDictionary*)arguments;

// -(void)threadRequestPath:(NSString*)path;

@end

@interface NSObject (KCCopyThreadDelegate)
-(void)response:(NSDictionary*)response;
-(void)nowProcessingRequest;
// -(void)hasData:(NSData*)data;
@end


#endif // __OPCODERS_KEYBOARDCOMMANDER_COPY_THREAD_H__