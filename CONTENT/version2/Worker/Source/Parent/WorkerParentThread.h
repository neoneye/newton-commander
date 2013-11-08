//
//  NCWorkerPrivate.h
//  WorkerParent
//
//  Created by Simon Strandgaard on 11/06/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "WorkerParent.h"
#import "WorkerShared.h"

@class WorkerParentCallback;

/*
WorkerParentThread is an internal class only supposed to be used by WorkerParent.
It runs in a separate thread and all communication between it and WorkerParent
happens using NSInvocation so that it's thread-safe without any mutexes at all.

This class communicates with the child process using Distributed Objects.
*/
@interface WorkerParentThread : NSThread {
	WorkerParent* m_worker;
	WorkerParentCallback* m_callback;
	NSConnection* m_connection;
	NSDistantObject* m_distant_object;
	NSString* m_path;
	int m_uid;       
	NSString* m_parent_process_identifier;
	NSString* m_child_name;
	NSString* m_parent_name;
	BOOL m_connection_established;
	NSMutableArray* m_request_queue;
	BOOL m_task_running;
	NSThread* m_owner_thread;
}
@property(nonatomic, retain) NSConnection* connection;
@property(nonatomic, retain) NSString* parentProcessIdentifier;
@property(nonatomic, retain) NSThread* ownerThread;

/*
worker:      the class that owns us
path:        path to the executable that this thread should run as sub-task
childName:   machine unique connection name for the child process
parentName:  machine unique connection name for the parent process
uid:         the user-id that the task should run as (switch user ala sudo)
*/
-(id)initWithWorker:(WorkerParent*)worker 
	onThread:(NSThread*)aThread
	path:(NSString*)path
	uid:(int)uid
	parentProcessIdentifier:(NSString*)pid
	childName:(NSString*)cname 
	parentName:(NSString*)pname;

-(void)callbackWeAreRunning:(NSString*)name childPID:(int)pid childUID:(int)uid;
-(void)callbackResponseData:(NSData*)data;

-(void)addRequestToQueue:(NSData*)data;

-(void)startTask;
-(void)startTaskWithPrivileges;

-(void)createConnection;

-(void)shutdownConnection;
-(void)stopTask;

-(void)monitorChildProcess:(int)process_identifier;

@end
