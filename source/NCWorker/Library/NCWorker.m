//
//  NCWorkerParent.m
//  NCWorker
//
//  Created by Simon Strandgaard on 08/06/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "NCLog.h"
#import "NCWorker.h"
#import "NCWorkerPrivate.h"
#import "NCWorkerProtocol.h"
#include <unistd.h>
#include <spawn.h>

//#define USE_POSIX_SPAWN

#pragma mark -
#pragma mark Callback Class


@interface NSMutableArray (ShiftExtension)
// returns the first element of self and removes it
-(id)shift;
@end

@implementation NSMutableArray (ShiftExtension)
-(id)shift {
	if([self count] < 1) return nil;
	id obj = [self objectAtIndex:0];
	[self removeObjectAtIndex:0];
	return obj;
}
@end /* end of class NSMutableArray */



@implementation NCWorkerCallback

-(id)initWithWorkerThread:(NCWorkerThread*)workerThread {
    self = [super init];
    if(self != nil) {
		m_worker_thread = workerThread;
    }
    return self;
}

-(oneway void)weAreRunning:(in bycopy NSString*)name {
	[m_worker_thread callbackWeAreRunning:name];
}

-(oneway void)responseData:(in bycopy NSData*)data {
	[m_worker_thread callbackResponseData:data];
}

@end /* end of class NCWorkerCallback */


#pragma mark -
#pragma mark Threading Class


@interface NCWorkerThread (Private)
-(void)connectToChild;

@end

@implementation NCWorkerThread

@synthesize connection = m_connection;
@synthesize task = m_task;
@synthesize uid = m_uid;

-(id)initWithWorker:(NCWorker*)worker 
	controller:(id<NCWorkerController>)controller
	path:(NSString*)path
	uid:(NSString*)uid
	label:(NSString*)label
	childName:(NSString*)cname 
	parentName:(NSString*)pname
{
    self = [super init];
    if(self != nil) {
		m_worker = worker;
		m_controller = controller;
		m_path = [path copy];
		m_cwd = [m_path stringByDeletingLastPathComponent]; 
		m_uid = [uid copy];
		m_label = [label copy];
		m_parent_name = [pname copy];
		m_child_name = [cname copy];
		m_callback = [[NCWorkerCallback alloc] initWithWorkerThread:self];
		m_connection = nil;
		m_distant_object = nil;
		m_connection_established = NO;
		m_request_queue = [[NSMutableArray alloc] init];
		m_task = nil;
		
		NSAssert(m_worker, @"must be initialized");
		NSAssert(m_controller, @"must be initialized");
		NSAssert(m_path, @"must be initialized");
		NSAssert(m_uid, @"must be initialized");
		NSAssert(m_label, @"must be initialized");
		NSAssert(m_parent_name, @"must be initialized");
		NSAssert(m_child_name, @"must be initialized"); 
		NSAssert(m_request_queue, @"must be initialized");
		NSAssert(m_callback, @"must be initialized");
    }
    return self;
}

-(void)main {
	@autoreleasepool {

		[self performSelector:@selector(threadDidStart) withObject:nil afterDelay:0.f];
		[[NSRunLoop currentRunLoop] run];

		LOG_DEBUG(@"NSRunLoop exited, terminating thread for label: %@", m_label);
	}
}

-(void)threadDidStart {
	[self createConnection];

	NSAssert((m_task == nil), @"task must not already be running");
	[self startTask];
#ifndef USE_POSIX_SPAWN
	NSAssert((m_task != nil), @"at this point the task must be running");
#endif
	// LOG_DEBUG(@"thread started");
}

-(void)createConnection {
	NSAssert(m_connection == nil, @"m_connection must not already be initialized");

	id root_object = m_callback;
	NSString* parent_name = m_parent_name;

	// IPC between different user accounts is not possible with mach ports, thus we use sockets
	NSSocketPort* port = [[NSSocketPort alloc] init];
	NSConnection* con = [NSConnection connectionWithReceivePort:port sendPort:nil];
	if([[NSSocketPortNameServer sharedInstance] registerPort:port name:parent_name] == NO) {
		LOG_ERROR(@"ERROR: In parent.. registerName was unsuccessful. connection_name=%@\nTERMINATE: %@", parent_name, self);
		[NSApp terminate:self];
	}
	[con setRootObject:root_object];

	[con addRequestMode:NSEventTrackingRunLoopMode];
	[con addRequestMode:NSConnectionReplyMode];
	[con addRequestMode:NSModalPanelRunLoopMode];
	
	[con setRequestTimeout:1.0];
	[con setReplyTimeout:1.0];
	
	self.connection = con;
}

-(void)startTask {
#ifdef USE_POSIX_SPAWN
	[self startTaskWithSpawn];
#else
	[self startTaskWithNSTask];
#endif
}

-(void)startTaskWithSpawn {
	NSAssert(m_task == nil, @"task must not already be running");
	
	NSString* path = m_path;
	NSString* uid = m_uid;
	NSString* label = m_label;
	NSString* parent_name = m_parent_name;
	NSString* child_name = m_child_name;
	NSString* cwd = m_cwd;
	
	NSAssert(path, @"path must be initialized");
	NSAssert(uid, @"uid must be initialized");
	NSAssert(label, @"label must be initialized");
	NSAssert(parent_name, @"parent_name must be initialized");
	NSAssert(child_name, @"child_name must be initialized");
	NSAssert(cwd, @"cwd must be initialized");
	
	NSArray* args = [NSArray arrayWithObjects:
					 label,
					 parent_name,
					 child_name,
					 uid,
					 nil
					 ];
	LOG_DEBUG(@"arguments for worker: %@", args);
	
	
	// path to the executable file of the child process
	const char *spawnPath = [path UTF8String];

	// commandline arguments for the child process
	char *spawnArgs[10];
	for (int i=0; i<10; i++) {
		spawnArgs[i] = NULL;
	}
	NSString *programName = [path lastPathComponent];
	NSArray *allArgs = [[NSArray arrayWithObject:programName] arrayByAddingObjectsFromArray:args];
	for (int i=0; i<allArgs.count; i++) {
		NSString *s = [allArgs objectAtIndex:i];
		const char *ptr = [s UTF8String];
		spawnArgs[i] = strdup(ptr);
	}
	
	
#define NC_PIPE_READ 0
#define NC_PIPE_WRITE 1
	
	int p_stdin[2];
	int p_stdout[2];
	int p_stderr[2];
	int p_stdin2[2];
	int p_stdout2[2];
	
	// create pipes
	pipe(p_stdin);
	pipe(p_stdout);
	pipe(p_stderr);
	pipe(p_stdin2);
	pipe(p_stdout2);
	
	posix_spawn_file_actions_t actions;
	posix_spawn_file_actions_init(&actions);
	
	// prepare the child process to connect with our pipes
	posix_spawn_file_actions_adddup2(&actions, p_stdin[NC_PIPE_READ], 0);
	posix_spawn_file_actions_adddup2(&actions, p_stdout[NC_PIPE_WRITE], 1);
	posix_spawn_file_actions_adddup2(&actions, p_stderr[NC_PIPE_WRITE], 2);
	posix_spawn_file_actions_adddup2(&actions, p_stdin2[NC_PIPE_READ], 3);
	posix_spawn_file_actions_adddup2(&actions, p_stdout2[NC_PIPE_WRITE], 4);
	
	// start the child process
	int pid;
	posix_spawnp(&pid, spawnPath, &actions, NULL, spawnArgs, NULL);
	
	posix_spawn_file_actions_destroy(&actions);
	
	// close the child process' end of the pipes
	close(p_stdin[NC_PIPE_READ]);
	close(p_stdout[NC_PIPE_WRITE]);
	close(p_stderr[NC_PIPE_WRITE]);
	close(p_stdin2[NC_PIPE_READ]);
	close(p_stdout2[NC_PIPE_WRITE]);
	

#if 0
	int handle_xxx = p_stdout2[NC_PIPE_READ];
	
	struct timeval tv;
	fd_set readfds;
	tv.tv_sec = 3;
	tv.tv_usec = 0;
	FD_ZERO(&readfds);
	FD_SET(handle_xxx, &readfds);
	
	LOG_DEBUG(@"waiting for activity");
	select(handle_xxx + 1, &readfds, NULL, NULL, &tv);
	
	if(FD_ISSET(handle_xxx, &readfds)) {
		LOG_DEBUG(@"we got activity");
		char buff[5] = "";
		read(handle_xxx, buff, 4);
		buff[4] = '\0';
		LOG_DEBUG(@"message: %s", buff);
	} else {
		LOG_DEBUG(@"no activity");
	}
#endif
}

-(void)startTaskWithNSTask {
	NSAssert(m_task == nil, @"task must not already be running");
	
	NSString* path = m_path;                   
	NSString* uid = m_uid;
	NSString* label = m_label;
	NSString* parent_name = m_parent_name;
	NSString* child_name = m_child_name;
	NSString* cwd = m_cwd;

	NSAssert(path, @"path must be initialized");
	NSAssert(uid, @"uid must be initialized");
	NSAssert(label, @"label must be initialized");
	NSAssert(parent_name, @"parent_name must be initialized");
	NSAssert(child_name, @"child_name must be initialized");
	NSAssert(cwd, @"cwd must be initialized");
	
	NSArray* args = [NSArray arrayWithObjects: 
		label,
		parent_name,
		child_name,
		uid,
		nil
	];
	LOG_DEBUG(@"arguments for worker: %@", args);

	NSTask* task = [[NSTask alloc] init];
	[task setEnvironment:[NSDictionary dictionary]];
	[task setCurrentDirectoryPath:cwd];
	[task setLaunchPath:path];
	[task setArguments:args];
	[task setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
	[task setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
	[task setStandardError:[NSFileHandle fileHandleWithNullDevice]];

	@try {
		/*
		"launch" throws an exception if the path is invalid
		*/
		[task launch];

	} @catch(NSException* e) {
		LOG_ERROR(@"NCWorkerThread "
			"failed to launch task!\n"
			"name: %@\n"
			"reason: %@\n" 
			"launch_path: %@\n" 
			"arguments: %@", 
			[e name], 
			[e reason],
			path,
			args
		);
		exit(-1);
		return;
	}

	self.task = task;
}

-(void)callbackWeAreRunning:(NSString*)name {
	// LOG_DEBUG(@"will connect to child %@", name);
	/*
	we are halfway through the handshake procedure:
	connection from child to parent is now up running.
	connection from parent to child is not yet established.
	*/

	[self connectToChild];

    /*
	at this point we now have a estabilished a two-way connection using sockets
	*/
	// LOG_DEBUG(@"bidirectional connection OK");

	[self performSelector: @selector(dispatchQueue)
	           withObject: nil
	           afterDelay: 0.f];
}

-(void)connectToChild {
	NSString* name = m_child_name;

	// IPC between different user accounts is not possible with mach ports, thus we use sockets
	NSPort* port = [[NSSocketPortNameServer sharedInstance] portForName:name host:@"*"];
	NSConnection* connection = [NSConnection connectionWithReceivePort:nil sendPort:port];
	
	NSDistantObject* obj = [connection rootProxy];
	if(obj == nil) {
		LOG_ERROR(@"ERROR: could not connect to child: %@\nTERMINATE: %@", name, self);
		exit(-1);
		return;
	}
	[obj setProtocolForProxy:@protocol(NCWorkerChildCallbackProtocol)];
	id <NCWorkerChildCallbackProtocol> proxy = (id <NCWorkerChildCallbackProtocol>)obj;
	LOG_INFO(@"Will handshake with child");
	double t0 = CFAbsoluteTimeGetCurrent();
	int rc = [proxy handshakeAcknowledge:42];
	double t1 = CFAbsoluteTimeGetCurrent();
	double elapsed = t1 - t0;
	if(rc != 43) {
		LOG_ERROR(@"ERROR: failed creating two-way connection. child: %@  elapsed: %.6f", name, elapsed);
		return;
	}
	LOG_INFO(@"Did handshake with child. elapsed: %.6f", elapsed);

	m_connection_established = YES;
	m_distant_object = obj;
}

-(void)dispatchQueue {
	// LOG_DEBUG(@"dispatchQueue... ENTER");
	if(!m_connection_established) return;
	if(!m_distant_object) return;
	
	// IDEA: autoreleasepool

	id <NCWorkerChildCallbackProtocol> proxy = (id <NCWorkerChildCallbackProtocol>)m_distant_object;
	
    for(;;) {
        NSData* data = [m_request_queue shift];
        if (!data) {
            break;
        }
		// LOG_DEBUG(@"dispatch");
		[proxy requestData:data];
	}
	
	// LOG_DEBUG(@"dispatchQueue... DONE");
}

-(void)addRequestToQueue:(NSData*)data {
	[m_request_queue addObject:data];
	[self dispatchQueue];
}

-(void)callbackResponseData:(NSData*)data {
	// TODO: type check that it's a dictionary
	// TODO: discard pending invokations in lister mode
	NSDictionary* dict = (NSDictionary*)[NSUnarchiver unarchiveObjectWithData:data];

	SEL sel = @selector(worker:response:);
	id obj = m_controller;
	id arg2 = m_worker;
	id arg3 = dict;


	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:sel]];
	[inv setTarget:obj];
	[inv setSelector:sel];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	[inv setArgument:&arg2 atIndex:2]; 
	[inv setArgument:&arg3 atIndex:3]; 
	[inv retainArguments];
	[inv performSelectorOnMainThread:@selector(invoke) 
		withObject:nil waitUntilDone:NO];
}

/*-(void)changeUid:(NSString*)uid {
	
} */

-(void)restartTask {
	// m_uid = @"0";
	
	LOG_DEBUG(@"thread.%s will shutdown connection to worker", _cmd);
	[self shutdownConnection];    

	LOG_DEBUG(@"thread.%s will stop current task", _cmd);
	[self stopTask];

	LOG_DEBUG(@"thread.%s will create a new connection", _cmd);
	[self createConnection];
	
	LOG_DEBUG(@"thread.%s will start new task", _cmd);
	[self startTask];

	LOG_DEBUG(@"thread.%s restart completed", _cmd);
}

-(void)shutdownConnection {

	if([[NSSocketPortNameServer sharedInstance] removePortForName:m_parent_name] == NO) {
		LOG_ERROR(@"%s failed to remove port: %@", _cmd, m_parent_name);
	}

	/*
	TODO: figure out what objects to invalidate
	*/
	[[m_connection receivePort] invalidate];
	[[m_connection sendPort] invalidate];
	[m_connection invalidate];

	NSConnection* con = [m_distant_object connectionForProxy];
	[[con receivePort] invalidate];
	[[con sendPort] invalidate];
	[con invalidate];

	self.connection = nil;

	m_distant_object = nil;
}

-(void)stopTask {
	[m_task terminate];
	self.task = nil;
}

@end /* end of class NCWorkerThread */


#pragma mark -
#pragma mark Worker Class

@interface NCWorker (Private)
+(NSString*)createIdentifier;
-(NSString*)taskPath;
-(void)restartTask;
@end

@implementation NCWorker

-(id)initWithController:(id<NCWorkerController>)controller label:(NSString*)label {
    self = [super init];
    if(self != nil) {
		m_controller = controller;
		m_label = [label copy];
		m_thread = nil;
		m_identifier = [NCWorker createIdentifier];
		[self resetUid];
		
		NSAssert(m_controller, @"must be initialized");
		NSAssert(m_label, @"must be initialized");
		NSAssert(m_identifier, @"must be initialized");
    }
    return self;
}

-(NSString*)taskPath {
	NSFileManager* fm = [NSFileManager defaultManager];
	NSBundle* bundle = [NSBundle mainBundle];
	NSAssert(bundle, @"cannot find our bundle");
	NSString* path = [bundle pathForAuxiliaryExecutable:@"NewtonCommanderHelper"];
	if([fm fileExistsAtPath:path] == NO) {
		NSRunAlertPanel(
			@"NCWorker is missing, cannot run program",
			@"Is supposed to be in the MacOS folder.",
			nil, nil, nil
		);
		[NSApp terminate:self];
	}
	return path;
}

+(NSString*)createIdentifier {
	static NSUInteger tag_counter = 0;                          
	NSUInteger pid = getpid();
	NSUInteger tag = tag_counter++; // autoincrement it
	return [NSString stringWithFormat:@"%lu_%lu", 
		(unsigned long)pid, (unsigned long)tag]; 
}

-(void)setUid:(int)uid {
	m_uid = uid;
}

-(void)resetUid {
	m_uid = getuid();
}

-(void)start {
	if(m_thread) return;
	
	NSString* uid_str = [NSString stringWithFormat:@"%i", m_uid];
	// uid_str = @"501"; // user: neoneye
	// uid_str = @"503"; // user: johndoe
	// uid_str = @"-2";  // user: nobody
	// uid_str = @"0";   // user: root
	// uid_str = @"";    // ignore user

	NSString* path = [self taskPath];
	// TODO: use worker label in cname and pname's to distinguish between workers
	NSString* cname = [NSString stringWithFormat:@"child_%@", m_identifier];
	NSString* pname = [NSString stringWithFormat:@"parent_%@", m_identifier];

	
	m_thread = [[NCWorkerThread alloc] 
		initWithWorker:self 
		controller:m_controller
		path:path
		uid:uid_str
		label:m_label
		childName:cname
		parentName:pname
	];
	[m_thread setName:@"WorkerThread"];
	[m_thread start];
}

-(void)restart {
	LOG_DEBUG(@"ncworker.%s", _cmd);

	NCWorkerThread* t = m_thread; 
	if(!t) {
		[self start];
		t = m_thread;
		NSAssert(t, @"start is always supposed to initialize m_thread");
	}
	
	NSString* uid_str = [NSString stringWithFormat:@"%i", m_uid];
	
	NSThread* thread = t;
	id obj = t;
	SEL sel = @selector(setUid:);

	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:sel]];
	[inv setTarget:obj];
	[inv setSelector:sel];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	[inv setArgument:&uid_str atIndex:2]; 
	[inv retainArguments];

	[inv performSelector:@selector(invoke) 
    	onThread:thread 
		withObject:nil 
		waitUntilDone:NO];

	
	[self restartTask];
}

-(void)restartTask {
	NCWorkerThread* t = m_thread; 
	if(!t) return;
	NSAssert(t, @"start is always supposed to initialize m_thread");
	
	//NSThread* thread = t;
	id obj = t;
	SEL sel = @selector(restartTask);

	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:sel]];
	[inv setTarget:obj];
	[inv setSelector:sel];
	[inv performSelector:@selector(invoke) 
    	onThread:m_thread 
		withObject:nil 
		waitUntilDone:NO];
}

-(void)request:(NSDictionary*)dict {
	
	// start thread if not already started
	NCWorkerThread* t = m_thread; 
	if(!t) {
		[self start];
		t = m_thread;
		NSAssert(t, @"start is always supposed to initialize m_thread");
	}
	
	NSData* data = [NSArchiver archivedDataWithRootObject:dict];
	
	
	NSThread* thread = t;
	id obj = t;
	SEL sel = @selector(addRequestToQueue:);

	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:sel]];
	[inv setTarget:obj];
	[inv setSelector:sel];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	[inv setArgument:&data atIndex:2]; 
	[inv retainArguments];

	[inv performSelector:@selector(invoke) 
    	onThread:thread 
		withObject:nil 
		waitUntilDone:NO];
}

@end /* end of class NCWorker */
