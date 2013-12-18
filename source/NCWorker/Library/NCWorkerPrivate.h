//
// NCWorkerPrivate.m
// Newton Commander
//
#import "NCWorker.h"
#import "NCWorkerProtocol.h"

@class NCWorkerThread;


@interface NCWorkerCallback : NSObject <NCWorkerParentCallbackProtocol> {
	NCWorkerThread* m_worker_thread;
}

-(id)initWithWorkerThread:(NCWorkerThread*)workerThread; 

-(void)weAreRunning:(NSString*)name;
-(void)responseData:(NSData*)data;

@end


@interface NCWorkerThread : NSThread {
	NCWorker* m_worker;
	id<NCWorkerController> m_controller;
	NCWorkerCallback* m_callback;
	NSConnection* m_connection;
	NSDistantObject* m_distant_object;
	NSString* m_path;
	NSString* m_uid;
	NSString* m_label;
	NSString* m_child_name;
	NSString* m_parent_name;
	NSString* m_cwd;
	BOOL m_connection_established;
	NSMutableArray* m_request_queue;
	NSTask* m_task;
}
@property(nonatomic, strong) NSConnection* connection;
@property(nonatomic, strong) NSTask* task;
@property(nonatomic, strong) NSString* uid;

/*
worker:      the class that owns us
path:        path to the executable that this thread should run as sub-task
label:       purpose of this worker
childName:   machine unique connection name for the child process
parentName:  machine unique connection name for the parent process
uid:         the user-id that the task should run as (switch user ala sudo)
*/
-(id)initWithWorker:(NCWorker*)worker 
	controller:(id<NCWorkerController>)controller
	path:(NSString*)path
	uid:(NSString*)uid
	label:(NSString*)label
	childName:(NSString*)cname 
	parentName:(NSString*)pname;

-(void)callbackWeAreRunning:(NSString*)name;
-(void)callbackResponseData:(NSData*)data;

-(void)addRequestToQueue:(NSData*)data;

-(void)restartTask;
-(void)startTask;

-(void)createConnection;

-(void)shutdownConnection;
-(void)stopTask;

@end
