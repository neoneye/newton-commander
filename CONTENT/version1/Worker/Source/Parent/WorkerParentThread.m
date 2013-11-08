#import "WorkerParentThread.h"
#import "WorkerParent.h"
#import "Logger.h"
#import "WorkerParentAuthorization.h"
#include <unistd.h>
#include <sys/event.h>


#pragma mark -
#pragma mark Callback Class


@interface NSMutableArray (ShiftExtension)
// returns the first element of self and removes it
-(id)shift;
@end

@implementation NSMutableArray (ShiftExtension)
-(id)shift {
	if([self count] < 1) return nil;
	id obj = [[[self objectAtIndex:0] retain] autorelease];
	[self removeObjectAtIndex:0];
	return obj;
}
@end /* end of class NSMutableArray */



@interface WorkerParentCallback : NSObject <WorkerParentCallbackProtocol> {
	WorkerParentThread* m_worker_thread;
}

-(id)initWithWorkerThread:(WorkerParentThread*)workerThread; 

-(void)weAreRunning:(NSString*)name childPID:(int)pid childUID:(int)uid;
-(void)responseData:(NSData*)data;

@end

@implementation WorkerParentCallback

-(id)initWithWorkerThread:(WorkerParentThread*)workerThread {
    self = [super init];
    if(self != nil) {
		m_worker_thread = workerThread;
    }
    return self;
}

-(oneway void)weAreRunning:(in bycopy NSString*)name childPID:(int)pid childUID:(int)uid {
	[m_worker_thread callbackWeAreRunning:name childPID:pid childUID:uid];
}

-(oneway void)responseData:(in bycopy NSData*)data {
	[m_worker_thread callbackResponseData:data];
}

@end /* end of class WorkerParentCallback */


#pragma mark -
#pragma mark Threading Class


@interface WorkerParentThread (Private)

-(void)forwardResponse:(id)unarchivedData;
-(void)connectToChild;
-(void)childDidStop;

@end

@implementation WorkerParentThread

@synthesize connection = m_connection;
@synthesize ownerThread = m_owner_thread;
@synthesize parentProcessIdentifier = m_parent_process_identifier;

-(id)initWithWorker:(WorkerParent*)worker 
	onThread:(NSThread*)aThread
	path:(NSString*)path
	uid:(int)uid
	parentProcessIdentifier:(NSString*)pid
	childName:(NSString*)cname 
	parentName:(NSString*)pname
{
    self = [super init];
    if(self != nil) {
		m_worker = worker;
		m_path = [path copy];
		m_uid = uid;
		self.parentProcessIdentifier = pid;
		m_parent_name = [pname copy];
		m_child_name = [cname copy];
		m_callback = [[WorkerParentCallback alloc] initWithWorkerThread:self];
		m_connection = nil;
		m_distant_object = nil;
		m_connection_established = NO;
		m_request_queue = [[NSMutableArray alloc] init];
		self.ownerThread = aThread;
		m_task_running = NO;
		
		NSAssert(m_worker, @"must be initialized");
		NSAssert(m_path, @"must be initialized");
		NSAssert(m_parent_name, @"must be initialized");
		NSAssert(m_child_name, @"must be initialized"); 
		NSAssert(m_request_queue, @"must be initialized");
		NSAssert(m_callback, @"must be initialized");
		NSAssert(m_owner_thread, @"must be initialized");
    }
    return self;
}

-(void)main {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	[self performSelector:@selector(threadDidStart) withObject:nil afterDelay:0.f];

	do {

		@try {
			/*
			NSPortTimeoutException occurs when our child process dies
			in order to deal with this we wrap the runloop in a 
			try/catch block which is again wrapped in do/while block!
			*/
			[[NSRunLoop currentRunLoop] run];

		} @catch(NSException* e) {
			// TODO: notify WorkerParent that connection has timeouted
			LOG_ERROR(@"WorkerParentThread "
				"exception occured in runloop!\n"
				"name: %@\n"
				"reason: %@", 
				[e name], 
				[e reason]
			);
		}
		
	} while(1);

	LOG_DEBUG(@"NSRunLoop exited, terminating thread");
	[pool release];
}

-(void)threadDidStart {
	[self createConnection];
	
	NSAssert(!m_task_running, @"task must not already be running");

	int our_uid = getuid();
	BOOL need_privileges = (our_uid != m_uid);
	if(need_privileges) {
		[self startTaskWithPrivileges];
	} else {
		[self startTask];
	}
	// LOG_DEBUG(@"thread started");

	NSAssert(m_task_running, @"at this point the task must be running");
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
	
	[con setRequestTimeout:1.0];  // TODO: is this a too short timeout?
	[con setReplyTimeout:1.0];    // TODO: is this a too short timeout?
	
	self.connection = con;
}

-(void)startTask {
	LOG_DEBUG(@"start task without special privileges");
	NSAssert(!m_task_running, @"task must not already be running");
	
	NSString* path = m_path;                   
	NSString* uid_str = [NSString stringWithFormat:@"%i", m_uid];
	NSString* pid = m_parent_process_identifier;
	NSString* parent_name = m_parent_name;
	NSString* child_name = m_child_name;

	NSAssert(path, @"path must be initialized");
	NSAssert(pid, @"pid must be initialized");
	NSAssert(parent_name, @"parent_name must be initialized");
	NSAssert(child_name, @"child_name must be initialized");
	
	NSArray* args = [NSArray arrayWithObjects: 
		uid_str,
		pid,
		parent_name,
		child_name,
		nil
	];
	LOG_DEBUG(@"arguments for worker: %@", args);
	
	NSTask* task = [[[NSTask alloc] init] autorelease];
	[task setEnvironment:[NSDictionary dictionary]];
	[task setCurrentDirectoryPath:[path stringByDeletingLastPathComponent]];
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
		LOG_ERROR(@"WorkerParentThread "
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

	m_task_running = YES;
}

-(void)startTaskWithPrivileges {
	LOG_DEBUG(@"start task with administrator privileges");
	NSAssert(!m_task_running, @"task must not already be running");

	NSString* path = m_path;                   
	NSString* uid_str = [NSString stringWithFormat:@"%i", m_uid];
	NSString* pid = m_parent_process_identifier;
	NSString* parent_name = m_parent_name;
	NSString* child_name = m_child_name;

	NSAssert(path, @"path must be initialized");
	NSAssert(pid, @"pid must be initialized");
	NSAssert(parent_name, @"parent_name must be initialized");
	NSAssert(child_name, @"child_name must be initialized");
	
	NSArray* args = [NSArray arrayWithObjects:
		uid_str,
		pid,
		parent_name,
		child_name,
		nil
	];
	[[WorkerParentAuthorization shared] execute:path arguments:args];

	m_task_running = YES;
}

#if 0
-(void)startTask3 {
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
	
    AuthorizationRef auth;

    OSStatus rc = AuthorizationCreate(NULL, NULL, kAuthorizationFlagDefaults, &auth);
	if(rc != noErr) {
		LOG_ERROR(@"failed to create authorization");
		return;
	}

	FILE* fd = NULL; // file descriptor

	char* args[] = {
		(char*)[uid UTF8String],
		(char*)[parent_name UTF8String],
		(char*)[child_name UTF8String],
		(char*)[label UTF8String],
		NULL
	};

	
	LOG_DEBUG(@"AuthorizationExecuteWithPrivileges before");
	{
#if 1
		// char *command = "/usr/bin/sudo -n -u #510 \"$HELP\"";
		// const char *command = "sudo -u #512 whoami";
		const char *command = "/usr/bin/su johndoe -c /usr/bin/whoami";
		setenv("HELP", [path fileSystemRepresentation], 1);
		char *arguments[] = {
			(char*)"-c", 
			(char*)command, 
			NULL
		};
		rc = AuthorizationExecuteWithPrivileges(auth, "/bin/sh", kAuthorizationFlagDefaults, arguments, NULL);
		unsetenv("HELP");
#endif		
#if 0
		// char *command = "/usr/bin/sudo -u #510 \"$HELP\"";
		const char *command = "sudo -u #512 whoami";
		setenv("HELP", [path fileSystemRepresentation], 1);
		char *arguments[] = {
			(char*)"-c", 
			(char*)command, 
			NULL
		};
		rc = AuthorizationExecuteWithPrivileges(auth, "/bin/sh", kAuthorizationFlagDefaults, arguments, NULL);
		unsetenv("HELP");
#endif		
#if 0
		// char *command = "/usr/bin/sudo -u #510 \"$HELP\"";
		const char *command = "whoami";
		setenv("HELP", [path fileSystemRepresentation], 1);
		char *arguments[] = {
			(char*)"-n", 
			(char*)"-u", 
			(char*)"#510", 
			(char*)command, 
			NULL
		};
		rc = AuthorizationExecuteWithPrivileges(auth, "/usr/bin/sudo", kAuthorizationFlagDefaults, arguments, NULL);
		unsetenv("HELP");
#endif		
	}
	LOG_DEBUG(@"AuthorizationExecuteWithPrivileges after");
	
	/*
	does this block the main-thread until the child worker task has started?
	the child worker will close stdin/stdout/stderr, which I guess is what
	causes the while loop to be ended
	*/
	// IDEA: maybe remove the while loop entirely
	if(rc == noErr) {
		char buffer[1024];
		while(1) {
			if(!fd) {
				break;
			}
	        if(fgets(buffer, sizeof(buffer)-1, fd) == NULL) {
				break;
			}
			buffer[sizeof(buffer)-1] = 0;
			LOG_DEBUG(@"read: %s", buffer);
		}

		if(fd != NULL) {
			fclose(fd);
		}
	} else {
		LOG_ERROR(@"aborted authorized exe: %i", (int)rc);
	}

	AuthorizationFree(auth, kAuthorizationFlagDestroyRights);
	m_aewp_task_running = YES;
}
#endif

#if 0
- (BRLayerController *)myApplianceController
{
	NSString *path = [[NSBundle bundleForClass:[SLoadAppliance class]] pathForResource:@"InstallHelper" ofType:@""];
	NSDictionary *attrs = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES];
	if(![[attrs objectForKey:NSFileOwnerAccountName] isEqualToString:@"root"] || !([[attrs objectForKey:NSFilePosixPermissions] intValue] | S_ISUID))
	{
		/* Permissions are incorrect */
		AuthorizationItem authItems[2] = {
			{kAuthorizationEnvironmentUsername, strlen("frontrow"), "frontrow", 0},
			{kAuthorizationEnvironmentPassword, strlen("frontrow"), "frontrow", 0},
		};
		AuthorizationEnvironment environ = {2, authItems};
		AuthorizationItem rightSet[] = {{kAuthorizationRightExecute, 0, NULL, 0}};
		AuthorizationRights rights = {1, rightSet};
		AuthorizationRef auth;
		OSStatus result = AuthorizationCreate(&rights, &environ, kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights, &auth);
		if(result == errAuthorizationSuccess)
		{
			char *command = "chown root:admin \"$HELP\" && chmod 4755 \"$HELP\"";
			setenv("HELP", [path fileSystemRepresentation], 1);
			char *arguments[] = {"-c", command, NULL};
			result = AuthorizationExecuteWithPrivileges(auth, "/bin/sh", kAuthorizationFlagDefaults, arguments, NULL);
			unsetenv("HELP");
		}
		if(result != errAuthorizationSuccess)
		{
			/*Need to present the error dialog here telling the user to fix the permissions*/
			return nil;
		}
	}
    return [[[SLoadApplianceController alloc] initWithScene: nil] autorelease];
}
#endif

-(void)callbackWeAreRunning:(NSString*)name childPID:(int)pid childUID:(int)uid {
	// LOG_DEBUG(@"pid: %i  uid: %i", pid, uid);
	// TODO: maybe save pid as an ivar
	// TODO: maybe save uid as an ivar
	
	[self monitorChildProcess:pid];
	
/*	if(uid != m_uid) {
		// failed to start child with the desired UID
	}*/
	
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
	
	NSDistantObject* obj = [[connection rootProxy] retain];
	if(obj == nil) {
		LOG_ERROR(@"ERROR: could not connect to child: %@\nTERMINATE: %@", name, self);
		exit(-1);
		return;
	}
	[obj setProtocolForProxy:@protocol(WorkerChildCallbackProtocol)];
	id <WorkerChildCallbackProtocol> proxy = (id <WorkerChildCallbackProtocol>)obj;
	if([proxy handshakeAcknowledge:42] != 43) {
		LOG_ERROR(@"ERROR: failed creating two-way connection. child: %@", name);
		return;
	}

	m_connection_established = YES;
	m_distant_object = obj;
}

-(void)dispatchQueue {
	// LOG_DEBUG(@"dispatchQueue... ENTER");
	if(!m_connection_established) return;
	if(!m_distant_object) return;
	
	// IDEA: autoreleasepool... is this really needed here?

	id <WorkerChildCallbackProtocol> proxy = (id <WorkerChildCallbackProtocol>)m_distant_object;
	
	NSData* data;
	while(data = [m_request_queue shift]) {
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
	/*
	It takes precious time to unarchive, thus we do it here in this thread.
	The less we can bother the main thread the better.
	*/
	id unarchived_data = [NSUnarchiver unarchiveObjectWithData:data];
	[self forwardResponse:unarchived_data];
}

-(void)forwardResponse:(id)unarchivedData {
	/*
	NOTE: unarchivedData is always a NSDictionary
	I have set the type to "id" to post-pose typechecking until the WorkerParent thread,
	in order to minimize the amount of error handling taking place in threads,
	better to do error-handling in the main-thread.
	*/
	SEL sel = @selector(forwardResponse:);
	id obj = m_worker;
	id arg2 = unarchivedData;

	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:sel]];
	[inv setTarget:obj];
	[inv setSelector:sel];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	[inv setArgument:&arg2 atIndex:2]; 
	[inv retainArguments];
	// NOTE: WorkerParent can run in any thread (not just restricted to main thread)
	[inv performSelector:@selector(invoke) onThread:self.ownerThread withObject:nil waitUntilDone:NO];
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

	[m_distant_object release];
	m_distant_object = nil;
}

-(void)stopTask {
	// TODO: how to stop it?
/*    [[NSNotificationCenter defaultCenter] 
        removeObserver:self 
        name:NSTaskDidTerminateNotification 
        object:self.task
    ];

	[self.task terminate];
	self.task = nil;*/
}

- (void)taskExited:(NSNotification*)aNotification {
	// TODO: how to get notification that the child has died?
/*    // You've been notified!
	LOG_DEBUG(@"task exited");
	
	int status = [self.task terminationStatus];

	[self stopTask];

	NSArray* keys = [NSArray arrayWithObjects:@"command", @"termination_status", nil];
	NSArray* objects = [NSArray arrayWithObjects:kWorkerParentCommandChildDidStop, [NSNumber numberWithInteger:status], nil];
	NSDictionary* dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	
	[self forwardResponse:dict];*/
}

-(void)childDidStop {
	LOG_INFO(@"child did stop!");
	NSArray* keys = [NSArray arrayWithObjects:@"command", nil];
	NSArray* objects = [NSArray arrayWithObjects:kWorkerParentCommandChildDidStop, nil];
	NSDictionary* dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	
	[self forwardResponse:dict];
}

void monitorChildProcessCallback(
	CFFileDescriptorRef fdref, 
	CFOptionFlags callBackTypes, 
	void* info) 
{
	// LOG_DEBUG(@"noteProcDeath... ");

    struct kevent kev;
    int fd = CFFileDescriptorGetNativeDescriptor(fdref);
    kevent(fd, NULL, 0, &kev, 1, NULL);
    // take action on death of process here
	unsigned int dead_pid = (unsigned int)kev.ident;

    CFFileDescriptorInvalidate(fdref);
    CFRelease(fdref); // the CFFileDescriptorRef is no longer of any use in this example


	// int our_pid = getpid();
	/*
	when our parent dies we die as well.. 
	this is actually the way our worker process is supposed to die.
	*/
	LOG_INFO(@"exit! child process (pid %u) died", dead_pid);

	if(info != NULL) {
		id thing = (id)info;
		if([thing isKindOfClass:[WorkerParentThread class]]) {
			WorkerParentThread* wpt = (WorkerParentThread*)thing;
			[wpt childDidStop];
		}
	}

}

-(void)monitorChildProcess:(int)process_identifier {
	/*
	maybe use waitpid()
	pid = waitpid(-pid, &status, 0)
	this would provide me with the exit-status code for the dead process.
	a piece of information that I cannot obtain with kqueue
	waitpid would have to run in a separate thread though and would not be "stoppable",
	so I guess it's a bad idea to use it.
	*/
	
	CFFileDescriptorContext context = { 0, self, NULL, NULL, NULL };
    int fd = kqueue();
    struct kevent kev;
    EV_SET(&kev, process_identifier, EVFILT_PROC, EV_ADD|EV_ENABLE, NOTE_EXIT, 0, NULL);
    kevent(fd, &kev, 1, NULL, 0, NULL);
    CFFileDescriptorRef fdref = CFFileDescriptorCreate(kCFAllocatorDefault, fd, true, monitorChildProcessCallback, &context);
    CFFileDescriptorEnableCallBacks(fdref, kCFFileDescriptorReadCallBack);
    CFRunLoopSourceRef source = CFFileDescriptorCreateRunLoopSource(kCFAllocatorDefault, fdref, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
    CFRelease(source);
}

@end
