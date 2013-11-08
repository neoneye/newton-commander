/*********************************************************************
KCDiscoverThread.mm - Wrapper thread
Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>

TODO: install the KCList program into /Library/PrivilegedHelperTools

TODO: verify that the shutdown/kill procedure of the backend
really works.

IDEA: spawn a Discover process that run as the user
When necessary start the root process.

*********************************************************************/
#include "KCDiscoverThread.h"
#include "../di_protocol.h"
#include "KCDiscoverParent.h"

#include "BetterAuthorizationSampleLib.h"
#include "KCHelperCommon.h"
#include <unistd.h>


#if 1
# define USE_SOCKETPORT
# define RUN_ROOT
#endif


@interface KCDiscoverThread (Private)
-(void)initConnectionName;
-(void)startTaskRoot;
-(void)startTaskNormal;
-(void)connectToChild;
-(void)startTask;
-(void)stopTask;
-(void)verifyTwoWayConnection;
-(void)requestPath;
@end

@implementation KCDiscoverThread

-(id)initWithName:(NSString*)name path:(NSString*)path auth:(AuthorizationRef)auth {
	self = [super init];
    if(self) {
		// NSLog(@"%@ KCDiscoverThread init: %@", name, path);

		NSAssert(name != nil, @"a name must be given");
		NSAssert(path != nil, @"a path to the KCList program must be given");

		m_name = [name copy];
		m_path_to_child_executable = [path copy];
		
		m_auth = auth;

		m_mainthread_delegate = nil;

		m_pid_of_kclist_process = -1;
		m_child_name = nil;
		m_child = nil;
		m_child_distobj = nil;
		
		m_connection_name = nil;
		
		m_root_object = [[KCDiscoverParent alloc] init];
		[m_root_object setDelegate:self];
		
		m_connection = nil;
		m_task = nil;
		m_is_busy = NO;
		m_request_path = nil;
		
		m_handshake_ok = NO;
		
		m_launched = NO;
		
		m_transaction_id = -1;
    }
    return self;
}

-(void)setMainThreadDelegate:(id)delegate {
	m_mainthread_delegate = delegate;
}

-(void)initConnectionName {
	NSAssert(m_name != nil, @"m_name must be initialized");
	
	if(m_connection_name != nil) return;

	// we pick our own connection name
	NSDate* date = [NSDate date];
	NSInteger i = (NSInteger)ceil([date timeIntervalSinceReferenceDate]);
	NSString* parent_name = [NSString stringWithFormat:@"parent_%ld_%@", (long)i, m_name];
	m_connection_name = [parent_name retain];
	
	NSLog(@"%s m_connection_name = %@", _cmd, m_connection_name);
}

-(id)mainThreadDelegate {
	return m_mainthread_delegate;
}

-(void)threadMainRoutine {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	[self performSelector: @selector(threadDidStart)
	           withObject: nil
	           afterDelay: 0.f];

	[[NSRunLoop currentRunLoop] run];

	[pool release];
	NSLog(@"%s END !!!!!!!!!!!", _cmd);
}

-(void)threadDidStart {
	NSString* thread_name = [[NSThread currentThread] name];
	// NSLog(@"Thread '%@' is running", thread_name);
	
	NSAssert(m_connection == nil, @"m_connection must not be initialized");
	NSAssert(m_connection_name == nil, @"m_connection_name must not be initialized");
	NSAssert(m_task == nil, @"m_task must not be initialized");
	
	[self startTask];
}

-(void)initConnection {	
	NSAssert(m_connection_name != nil, @"m_connection_name must be initialized");

	if(m_connection != nil) {
		NSLog(@"%s - connection is already initialized", _cmd);
		return;
	}
	
#ifdef USE_SOCKETPORT

	// create a connection
	NSSocketPort* port = [[NSSocketPort alloc] init];
	NSConnection* con = [NSConnection connectionWithReceivePort:port sendPort:nil];
	if([[NSSocketPortNameServer sharedInstance] registerPort:port name:m_connection_name] == NO) {
		NSLog(@"ERROR: In parent.. registerName was unsuccessful. connection_name=%@", m_connection_name);
		NSLog(@"TERMINATE: %s\n%@", _cmd, self);
		[NSApp terminate:self];
	}
	[con setRootObject:m_root_object];

#else
	
	// create a connection
	NSConnection* con = [NSConnection defaultConnection];
	[con setRootObject:m_root_object];
	if([con registerName:m_connection_name] == NO) {
		NSLog(@"ERROR: In parent.. registerName was unsuccessful. connection_name=%@", m_connection_name);
		NSLog(@"TERMINATE: %s\n%@", _cmd, self);
		[NSApp terminate:self];
	}

#endif
	[con addRequestMode:NSEventTrackingRunLoopMode];
	[con addRequestMode:NSConnectionReplyMode];
	[con addRequestMode:NSModalPanelRunLoopMode];
	
	[con setRequestTimeout:1.f];
	[con setReplyTimeout:1.f];
	
	m_connection = [con retain];
	NSLog(@"KCDiscoverThread %s - connection is up: %@", _cmd, m_connection_name);
}

-(void)startTaskRoot {
	if(m_task != nil) {
		NSLog(@"%s - task is already running", _cmd);
		return;
	}
	
	NSString* path_to_discover_app = m_path_to_child_executable;


    OSStatus        err;
    BASFailCode     failCode;
    NSString *      bundleID;
    NSDictionary *  request;
    CFDictionaryRef response;

    response = NULL;

    // Create our request.  Note that NSDictionary is toll-free bridged to CFDictionary, so 
    // we can use an NSDictionary as our request.

	if(path_to_discover_app == nil) {
		NSLog(@"%s ERROR: path is not initialized", _cmd);
		return;
	}


	int pid_int = static_cast<int>(getpid());
	NSNumber* our_pid = [NSNumber numberWithInt:pid_int];
	NSLog(@"%s our pid is: %@", _cmd, our_pid);

    request = [NSDictionary dictionaryWithObjectsAndKeys:
		@kKCHelperStartListCommand, @kBASCommandKey, 
#if 1
		/*
		TODO: install the KCList program into /Library/PrivilegedHelperTools
		otherwise we allow users to run arbitrary code as root
		we can't risk that
		*/
		path_to_discover_app, @kKCHelperPathToListProgram,
#endif
		m_connection_name, @kKCHelperFrontendConnectionName,
		our_pid, @kKCHelperFrontendProcessId,
		m_name, @kKCHelperAssignNameToListProcess,
		nil
	];
    assert(request != NULL);

    bundleID = [[NSBundle mainBundle] bundleIdentifier];
    assert(bundleID != NULL);

    // Execute it.

	err = BASExecuteRequestInHelperTool(
        m_auth, 
        kKCHelperCommandSet, 
        (CFStringRef) bundleID, 
        (CFDictionaryRef) request, 
        &response
    );

    // If it failed, try to recover.

    if ( (err != noErr) && (err != userCanceledErr) ) {
        int alertResult;

        failCode = BASDiagnoseFailure(m_auth, (CFStringRef) bundleID);

        // At this point we tell the user that something has gone wrong and that we need 
        // to authorize in order to fix it.  Ideally we'd use failCode to describe the type of 
        // error to the user.

        alertResult = NSRunAlertPanel(@"Needs Install", @"BAS needs to install", @"Install", @"Cancel", NULL);

        if ( alertResult == NSAlertDefaultReturn ) {
            // Try to fix things.

            err = BASFixFailure(m_auth, (CFStringRef) bundleID, CFSTR("InstallKCHelper"), CFSTR("KCHelper"), failCode);

            // If the fix went OK, retry the request.

            if (err == noErr) {
                err = BASExecuteRequestInHelperTool(
                    m_auth, 
                    kKCHelperCommandSet, 
                    (CFStringRef) bundleID, 
                    (CFDictionaryRef) request, 
                    &response
                );
            }
        } else {
            err = userCanceledErr;
        }
    }

    // If all of the above went OK, it means that the IPC to the helper tool worked.  We 
    // now have to check the response dictionary to see if the command's execution within 
    // the helper tool was successful.

    if (err == noErr) {
        err = BASGetErrorFromResponse(response);
    }

    // Log our results.

    if (err == noErr) {
		NSLog(@"%s OK", _cmd);
    } else {
		NSLog(@"%s Failed with error %ld.", _cmd, (long) err);
    }

    if (response != NULL) {
        CFRelease(response);
    }

	m_task = [@"placeholder" retain];
	NSLog(@"%s task started ok", _cmd);
}

-(void)startTaskNormal {
	if(m_task != nil) {
		NSLog(@"%s - task is already running", _cmd);
		return;
	}
	
	NSString* path = m_path_to_child_executable;

	int pid_int = static_cast<int>(getpid());
	NSString* pid = [NSString stringWithFormat:@"%i", pid_int];

	
	NSArray* args = [NSArray arrayWithObjects:
		m_name, 
		m_connection_name, 
		pid,
		nil
	];
	NSTask* task = [[[NSTask alloc] init] autorelease];
	[task setLaunchPath:path];
	[task setArguments:args];

	@try {
		/*
		"launch" throws an exception if the path is invalid
		*/
		[task launch];

	} @catch(NSException* e) {
		NSLog(@"KCDiscoverThread "
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
	m_task = [task retain];
	// NSLog(@"%s task started ok", _cmd);
}

-(void)startTask {
	if(m_task != nil) {
		NSLog(@"%s - task is already running", _cmd);
		return;
	}

	NSLog(@"BEFORE STARTTASK");

	[self initConnectionName];
	[self initConnection];

	m_is_busy = NO;
	m_handshake_ok = NO;

#ifdef RUN_ROOT
	[self startTaskRoot];
#else
	[self startTaskNormal];
#endif

	[self verifyTwoWayConnection];

	NSLog(@"AFTER STARTTASK");
}

-(void)stopTask {
	if(m_task == nil) {
		NSLog(@"%s - no task is running", _cmd);
		return;
	}

	// drop resources used for the connection
	// to ensure that we don't use them next time we start a task
	NSLog(@"%s will drop all resources", _cmd);

#ifdef USE_SOCKETPORT
	if([[NSSocketPortNameServer sharedInstance] removePortForName:m_connection_name] == NO) {
		NSLog(@"%s failed to remove port: %@", _cmd, m_connection_name);
	}
#endif

	[[m_connection receivePort] invalidate];
	[[m_connection sendPort] invalidate];
	[m_connection invalidate];

	NSConnection* con = [m_child_distobj connectionForProxy];
	[[con receivePort] invalidate];
	[[con sendPort] invalidate];
	[con invalidate];

	[m_connection release];
	m_connection = nil;

	[m_child release];
	m_child = nil;

	[m_child_distobj release];
	m_child_distobj = nil;

	[m_connection_name release];
	m_connection_name = nil;

	NSLog(@"%s did drop all resources", _cmd);


#ifdef RUN_ROOT

	
	/*
	TODO: ensure that we don't respond to any ping from that process
	otherwise it wont kill itself.
	*/
	


	/*
	call KCHelper with a StopList command and a m_pid_of_kclist_process
	*/
    OSStatus        err;
    BASFailCode     failCode;
    NSString *      bundleID;
    NSDictionary *  request;
    CFDictionaryRef response;

    response = NULL;

    // Create our request.  Note that NSDictionary is toll-free bridged to CFDictionary, so 
    // we can use an NSDictionary as our request.


	NSNumber* its_pid = [NSNumber numberWithInt:m_pid_of_kclist_process];
	NSLog(@"%s lets try stop the backend with pid: %@", _cmd, its_pid);

    request = [NSDictionary dictionaryWithObjectsAndKeys:
		@kKCHelperStopListCommand, @kBASCommandKey, 
		its_pid, @kKCHelperListProcessId,
		nil
	];
    assert(request != NULL);

    bundleID = [[NSBundle mainBundle] bundleIdentifier];
    assert(bundleID != NULL);

    // Execute it.

	err = BASExecuteRequestInHelperTool(
        m_auth, 
        kKCHelperCommandSet, 
        (CFStringRef) bundleID, 
        (CFDictionaryRef) request, 
        &response
    );

    // If all of the above went OK, it means that the IPC to the helper tool worked.  We 
    // now have to check the response dictionary to see if the command's execution within 
    // the helper tool was successful.

    if (err == noErr) {
        err = BASGetErrorFromResponse(response);
    }

    // Log our results.

    if (err == noErr) {
		NSLog(@"%s OK", _cmd);
    } else {
		NSLog(@"%s Failed with error %ld.", _cmd, (long) err);
    }

    if (response != NULL) {
        CFRelease(response);
    }


	/*
	TODO: kill it
	
	
	TODO: we must change connection_name, shutdown the connection,
	so that the backend can't ping us.. and thus die.
	
	PROBLEM: we can't allow people to kill tasks via KCHelper.
	Giving them the ability to pass in a PID is somewhat unsafe,
	a hijacker can abuse this to kill an arbitrary process.
	
	fe = frontend process
	be = backend process

	PROCEDURE#1
	FE sends terminate-task via DO to the BE.
	BE terminates.
	
	if PROCEDURE#1 doesn't work.. because DO is busy
	then we move on to PROCEDURE#2

    PROCEDURE#2	
	FE contacts KCHelper with PID for BE.
	KCHelper sends SIGUSR1 to the BE.
	BE wakes up
	BE starts watchdog
	BE terminates if runloop is inaccessible for a long period
	BE tries to ping FE
	BE terminates if FE doesn't respond.
	BE stops watchdog
	
	

	pass the authentication to KCHelper and let it
	contact the process. If the process has same authentication
	then kill it.
	
	frontend sends a signal to the backend process.
	backend process checks who signaled it,
	if it was the frontend's PID.. then it commits suicide.
	Is it possible to determine who signalled it? seems not
	
	establish a pipe between the frontend process and
	the backend process. When we want the backend to die
	we simply close the pipe.. and it gets signalled
	and dies! no. SIGPIPE seems only to be for writes
	that can't succed :-(
	
	sigalarm. After a while without any activity.. 
	say 1 minute.. commit suicide. 
	
	BAS execute("kill process with pid")
	security problem

	NSDistributedNotificationCenter 
	 killModule:@"left" 
	 forFrontendWithProcessId:pid
	However it's no guarantee that it dies.
	
	let KCList run multithreaded so it's already
	ready to listen. Then have a killAction.
	However it's no guarantee that it dies.
	*/

#else
	NSLog(@"BEFORE STOPTASK", _cmd);
	[m_task terminate];
	NSLog(@"AFTER STOPTASK", _cmd);
	[m_task release];
#endif
	
	m_task = nil;
	// NSLog(@"%s task stopped ok", _cmd);
}

-(void)verifyTwoWayConnection {
	[self performSelector: @selector(didHandshakeTakePlace)
	           withObject: nil
	           afterDelay: 5.f];
}

-(void)didHandshakeTakePlace {
	if(m_handshake_ok) {
		NSLog(@"handshake took place, everything is good");
		// NSLog(@"%s %@ OK", _cmd, m_name);
	} else {
		NSLog(@"%s %@ ERROR: handshake never took place", _cmd, m_name);
		NSLog(@"TERMINATE: %s\n%@", _cmd, self);
		exit(-1);
	}
}


-(void)parentWeAreRunning:(NSString*)name processId:(NSNumber*)pid {
	NSString* thread_name = [[NSThread currentThread] name];
	NSLog(@"%s - Thread '%@' - %@ - %@", _cmd, thread_name, name, pid);
	
	m_pid_of_kclist_process = [pid intValue];
	

	[m_child_name release];
	m_child_name = [name copy];

	[self connectToChild];

	if([m_child childPingSync:42] != 43) {
		NSLog(@"ERROR: failed creating two-way connection. thread: %@  child: %@", thread_name, name);
		return;
	}
	// NSLog(@"two-way connection established successfully. thread: %@  child: %@", thread_name, name);
	m_handshake_ok = YES;

	// if this is the very first time, then notify our parent that we launched
	if(m_launched == NO) {
		m_launched = YES;
		[m_mainthread_delegate performSelectorOnMainThread:@selector(didLaunch) 
			withObject:nil waitUntilDone:NO];
	}
	
	// request path after handshake
	if(m_request_path != nil) {
		[self performSelector: @selector(requestPath)
		           withObject: nil
		           afterDelay: 0.f];
	}
}

-(void)connectToChild {
	if(m_child_distobj != nil) {
		NSLog(@"%s m_child_distobj must not be initialized", _cmd);
		return;
	}
	if(m_child != nil) {
		NSLog(@"%s m_child must not be initialized", _cmd);
		return;
	}
	
	NSLog(@"%s will connect to %@", _cmd, m_name);
	NSString* name = m_child_name;
	NSDistantObject* obj = [NSConnection 
		rootProxyForConnectionWithRegisteredName:name
		host:nil
	];
	if(obj == nil) {
		NSLog(@"ERROR: could not connect to child: %@", name);
		NSLog(@"TERMINATE: %s\n%@", _cmd, self);
		exit(-1);
		return;
	}
	[obj retain];
	[obj setProtocolForProxy:@protocol(DiscoverChildProtocol)];
	id <DiscoverChildProtocol> proxy = (id <DiscoverChildProtocol>)obj;
	m_child = proxy;
	
	NSLog(@"%s did connect to %@", _cmd, m_name);
	
	m_child_distobj = [obj retain];
}

-(void)threadRequestPath:(NSString*)path transactionId:(int)tid {
	NSString* thread_name = [[NSThread currentThread] name];
	// NSLog(@"KCDiscoverThread %s %@ %@", _cmd, thread_name, path);
	
	m_transaction_id = tid;
	
	[m_request_path autorelease];
	m_request_path = [path retain];

	if(m_is_busy) {
		NSLog(@"%s we are busy. will restart KCList daemon", _cmd);

		[self stopTask];
		
		m_is_busy = NO;
		m_handshake_ok = NO;
		
		[self startTask];
		return;
	}

	[self requestPath];
}

-(void)requestPath {
	NSString* path = m_request_path;
	if(m_is_busy) {
		NSLog(@"%s is busy, ignore. %@", _cmd, path);
		return;
	}


	m_is_busy = YES;

	int tid = m_transaction_id;
	// NSLog(@"%s begin transaction: %i", _cmd, m_transaction_id);

	// double t0 = CFAbsoluteTimeGetCurrent();
	@try {

		[m_child childRequestPath:path transactionId:tid];

	} @catch(NSException* e) {
		printf("%s: %s\n", [[e name] cString], [[e reason] cString] );
		fflush(stdout);
	}
	double t1 = CFAbsoluteTimeGetCurrent();


	// deliver the timestamp to our delegate for profiling purposes
	id obj = m_mainthread_delegate;
	SEL mySelector = @selector(nowProcessingRequest:);
	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:mySelector]];
	[inv setTarget:obj];
	[inv setSelector:mySelector];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	[inv setArgument:&t1 atIndex:2]; 
	[inv retainArguments];
	[inv performSelectorOnMainThread:@selector(invoke) 
		withObject:nil waitUntilDone:NO];

	// double diff = t1 - t0;
	// NSLog(@"%s calling child takes: %.3f", _cmd, (float)diff);
}

-(void)parentWeHaveName:(NSData*)data transactionId:(int)tid {
	// NSLog(@"%s %@", _cmd, data);

	data = [[data copy] autorelease];
	id obj = m_mainthread_delegate;
	SEL mySelector = @selector(hasName:transactionId:);


	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:mySelector]];
	[inv setTarget:obj];
	[inv setSelector:mySelector];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	[inv setArgument:&data atIndex:2]; 
	[inv setArgument:&tid atIndex:3]; 
	[inv retainArguments];
	[inv performSelectorOnMainThread:@selector(invoke) 
		withObject:nil waitUntilDone:NO];
}

-(void)parentWeHaveType:(NSData*)data transactionId:(int)tid {
	// NSLog(@"%s %@", _cmd, path);

	data = [[data copy] autorelease];
	id obj = m_mainthread_delegate;
	SEL mySelector = @selector(hasType:transactionId:);


	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:mySelector]];
	[inv setTarget:obj];
	[inv setSelector:mySelector];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	[inv setArgument:&data atIndex:2]; 
	[inv setArgument:&tid atIndex:3]; 
	[inv retainArguments];
	[inv performSelectorOnMainThread:@selector(invoke) 
		withObject:nil waitUntilDone:NO];
}

-(void)parentWeHaveStat:(NSData*)data transactionId:(int)tid {
	// NSLog(@"%s %@", _cmd, path);

	data = [[data copy] autorelease];
	id obj = m_mainthread_delegate;
	SEL mySelector = @selector(hasStat:transactionId:);


	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:mySelector]];
	[inv setTarget:obj];
	[inv setSelector:mySelector];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	[inv setArgument:&data atIndex:2]; 
	[inv setArgument:&tid atIndex:3]; 
	[inv retainArguments];
	[inv performSelectorOnMainThread:@selector(invoke) 
		withObject:nil waitUntilDone:NO];
}

-(void)parentWeHaveAlias:(NSData*)data transactionId:(int)tid {
	// NSLog(@"%s %@", _cmd, path);

	data = [[data copy] autorelease];
	id obj = m_mainthread_delegate;
	SEL mySelector = @selector(hasAlias:transactionId:);


	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:mySelector]];
	[inv setTarget:obj];
	[inv setSelector:mySelector];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	[inv setArgument:&data atIndex:2]; 
	[inv setArgument:&tid atIndex:3]; 
	[inv retainArguments];
	[inv performSelectorOnMainThread:@selector(invoke) 
		withObject:nil waitUntilDone:NO];
}

-(void)parentCompletedTransactionId:(int)tid {
	id obj = m_mainthread_delegate;
	SEL mySelector = @selector(completedTransactionId:);


	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:mySelector]];
	[inv setTarget:obj];
	[inv setSelector:mySelector];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	[inv setArgument:&tid atIndex:2]; 
	[inv retainArguments];
	[inv performSelectorOnMainThread:@selector(invoke) 
		withObject:nil waitUntilDone:NO];


	/*
	the entire discover operation has been completed
	and the background process is now ready for more jobs.
	*/
	m_is_busy = NO;
}

-(NSString*)description {
	NSString* thread_name = [[NSThread currentThread] name];
	return [NSString stringWithFormat: 
		@"KCDiscoverThread\n"
		"m_name: %@\n"
		"thread_name: %@\n"
		"path_to_child_executable: %@\n"
		"m_connection_name: %@\n"
		"m_child_name: %@\n"
		"m_request_path: %@\n"
		"m_handshake_ok: %i\n"
		"m_is_busy: %i", 
		m_name,
		thread_name,
		m_path_to_child_executable,
		m_connection_name,
		m_child_name,
		m_request_path,
		(int)m_handshake_ok,
		(int)m_is_busy
	];
}

-(void)dealloc {
	// NSLog(@"%s", _cmd);
	[m_path_to_child_executable release];
	[m_name release];
	[m_root_object release];
	[m_connection release];
	[m_connection_name release];
	[m_child_name release];
	[m_child release];
    [super dealloc];
}

@end
