/*********************************************************************
KCDiscoverThread.h - Wrapper thread

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#ifndef __OPCODERS_KEYBOARDCOMMANDER_DISCOVER_THREAD_H__
#define __OPCODERS_KEYBOARDCOMMANDER_DISCOVER_THREAD_H__

@protocol DiscoverChildProtocol;
@class KCDiscoverParent;

@interface KCDiscoverThread : NSObject {
	/*
	all messages to the mainthread_delegate must be	made with
	performSelectorOnMainThread:withObject:waitUntilDone:
	*/
	id m_mainthread_delegate;

	AuthorizationRef m_auth;

	NSString* m_name;
	NSString* m_path_to_child_executable;
	NSString* m_connection_name;
	NSTask* m_task;
	KCDiscoverParent* m_root_object;
	NSConnection* m_connection;

	int m_pid_of_kclist_process;
	NSString* m_child_name;
	id <DiscoverChildProtocol> m_child;
	NSDistantObject* m_child_distobj;
	
	/*
	when ever we launch a discover operation we
	set this busy flag, so that we can determine
	whether the background task has completed or not.
	*/
	BOOL m_is_busy;
	
	NSString* m_request_path;
	
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
	
	/*
	Apparently Apple's distributed objects (DO) cannot hang up 
	a connection to another process. In order to rule out bogus
	data, it's necessary with a transaction id.
	*/
	int m_transaction_id;
}

-(id)initWithName:(NSString*)name path:(NSString*)path auth:(AuthorizationRef)auth;

/*
all messages to the mainthread_delegate must be made with
performSelectorOnMainThread:withObject:waitUntilDone:
*/
-(void)setMainThreadDelegate:(id)delegate;
-(id)mainThreadDelegate;

-(void)threadMainRoutine;

-(void)threadRequestPath:(NSString*)path transactionId:(int)tid;

@end

@interface NSObject (KCDiscoverThreadDelegate)
-(void)nowProcessingRequest:(double)timestamp;
// -(void)nowProcessingRequest;

// a NSData object containing a string-array
-(void)hasName:(NSData*)data transactionId:(int)tid;

// a byte sequence of unsigned int's
-(void)hasType:(NSData*)data transactionId:(int)tid;

// a byte sequence with lots of "struct stat64"
-(void)hasStat:(NSData*)data transactionId:(int)tid;

// a byte sequence of unsigned int's
-(void)hasAlias:(NSData*)data transactionId:(int)tid;

-(void)completedTransactionId:(int)tid;
-(void)didLaunch;
@end


#endif // __OPCODERS_KEYBOARDCOMMANDER_DISCOVER_THREAD_H__