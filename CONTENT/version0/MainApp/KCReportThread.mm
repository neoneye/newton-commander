/*********************************************************************
KCReportThread.mm - Wrapper thread

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#include "KCReportThread.h"
#include "../re_protocol.h"
#include "KCReportParent.h"


@interface KCReportThread (Private)
-(void)connectToChild;
-(void)startTask;
-(void)stopTask;
-(void)verifyTwoWayConnection;
-(void)requestPath;
@end

@implementation KCReportThread

-(id)initWithName:(NSString*)name path:(NSString*)path {
	self = [super init];
    if(self) {
		// NSLog(@"%@ KCReportThread init: %@", name, path);

		NSAssert(name != nil, @"a name must be given");
		NSAssert(path != nil, @"a path to the Report.app must be given");

		m_name = [name copy];
		m_path_to_child_executable = [path copy];

		m_mainthread_delegate = nil;

		m_child_name = nil;
		m_child = nil;
		m_child_distobj = nil;
		
		// we pick our connection name
		NSDate* date = [NSDate date];
		NSInteger i = (NSInteger)ceil([date timeIntervalSinceReferenceDate]);
		NSString* parent_name = [NSString stringWithFormat:@"parent_%ld_%@", (long)i, name];
		m_connection_name = [parent_name retain];
		
		m_root_object = [[KCReportParent alloc] init];
		[m_root_object setDelegate:self];
		
		m_connection = nil;
		m_task = nil;
		m_is_busy = NO;
		m_request_path = nil;
		
		m_handshake_ok = NO;
		
		m_launched = NO;
    }
    return self;
}

-(void)setMainThreadDelegate:(id)delegate {
	m_mainthread_delegate = delegate;
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
	NSAssert(m_task == nil, @"m_task must not be initialized");
	
	
	
	// create a connection
	NSConnection* con = [NSConnection defaultConnection];
	[con setRootObject:m_root_object];
	if([con registerName:m_connection_name] == NO) {
		NSLog(@"ERROR: In parent.. registerName was unsuccessful. connection_name=%@", m_connection_name);
		NSLog(@"TERMINATE: %s\n%@", _cmd, self);
		[NSApp terminate:self];
	}
	[con addRequestMode:NSEventTrackingRunLoopMode];
	[con addRequestMode:NSConnectionReplyMode];
	[con addRequestMode:NSModalPanelRunLoopMode];
	
	[con setRequestTimeout:1.0];
	[con setReplyTimeout:1.0];
	
	m_connection = [con retain];
	// NSLog(@"%s connection ok", _cmd);
	
	
	m_handshake_ok = NO;
	[self startTask];
	[self verifyTwoWayConnection];
}

-(void)startTask {
	if(m_task != nil) {
		NSLog(@"%s - task is already running", _cmd);
		return;
	}
	
	NSString* path = m_path_to_child_executable;
	NSArray* args = [NSArray arrayWithObjects:
		m_name, m_connection_name, nil
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
		NSLog(@"KCReportThread "
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

-(void)stopTask {
	if(m_task == nil) {
		NSLog(@"%s - no task is running", _cmd);
		return;
	}

	[m_task terminate];
	[m_task release];
	
	m_task = nil;
	// NSLog(@"%s task stopped ok", _cmd);
}

-(void)verifyTwoWayConnection {
#if 0
	[self performSelector: @selector(didHandshakeTakePlace)
	           withObject: nil
	           afterDelay: 0.5f];
#endif
}

-(void)didHandshakeTakePlace {
	if(m_handshake_ok) {
		NSLog(@"handshake took place, everything is good");
		// NSLog(@"%s %@ OK", _cmd, m_name);
	} else {
		NSLog(@"%s %@ ERROR: handshake never took place", _cmd, m_name);
		NSLog(@"TERMINATE: %s\n%@", _cmd, self);
		// TODO: kill child and handle this problem gracefully
		exit(-1);
	}
}


-(void)parentWeAreRunning:(NSString*)name {
	// NSLog(@"KCReportThread %s BEFORE - childname=%@", _cmd, name);
	NSString* thread_name = [[NSThread currentThread] name];
	// NSLog(@"%s - Thread '%@' - %@", _cmd, thread_name, name);

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
	// NSLog(@"KCReportThread %s AFTER", _cmd);
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
	
	// NSLog(@"%@ %s", m_name, _cmd);
	NSString* name = m_child_name;
	NSDistantObject* obj = [NSConnection 
		rootProxyForConnectionWithRegisteredName:name
		host:nil
	];
	if(obj == nil) {
		NSLog(@"ERROR: could not connect to child: %@", name);
		NSLog(@"TERMINATE: %s\n%@", _cmd, self);
		// TODO: kill child and handle this problem gracefully
		exit(-1);
		return;
	}
	[obj retain];
	[obj setProtocolForProxy:@protocol(ReportChildProtocol)];
	id <ReportChildProtocol> proxy = (id <ReportChildProtocol>)obj;
	m_child = proxy;
	
	m_child_distobj = [obj retain];
}

-(void)threadRequestPath:(NSString*)path {
	// NSLog(@"KCReportThread %s BEFORE", _cmd);
	NSString* thread_name = [[NSThread currentThread] name];
	// NSLog(@"KCReportThread %s %@ %@", _cmd, thread_name, path);
	
	[m_request_path autorelease];
	m_request_path = [path retain];

	if(m_is_busy) {
		// NSLog(@"%s we are busy", _cmd);

		[self stopTask];
		
		m_is_busy = NO;
		
		// drop the connection
		[m_child release];
		m_child = nil;
		[m_child_distobj release];
		m_child_distobj = nil;

		m_handshake_ok = NO;
		
		[self startTask];
		[self verifyTwoWayConnection];

		// NSLog(@"KCReportThread %s AFTER (1)", _cmd);
		return;
	}
	

	[self requestPath];

	// NSLog(@"KCReportThread %s AFTER (2)", _cmd);
}

-(void)requestPath {
	// NSLog(@"KCReportThread %s BEFORE", _cmd);

	NSString* path = m_request_path;
	if(m_is_busy) {
		NSLog(@"KCReportThread %s is busy, ignore. %@", _cmd, path);
		return;
	}

	m_is_busy = YES;

	// NSLog(@"KCReportThread %s will call childRequestPath", _cmd);
	@try {

		[m_child childRequestPath:path];

	} @catch(NSException* e) {
		printf("%s: %s\n", [[e name] cString], [[e reason] cString] );
		fflush(stdout);
	}
	// NSLog(@"KCReportThread %s did call childRequestPath", _cmd);

/*	if([m_request_path isEqual:@"/.fseventsd"]) {
		NSLog(@"KCReportThread %s this is fseventsd (aka. nemisis)", _cmd);
		NSLog(@"KCReportThread %s will now sleep(100)", _cmd);
		sleep(100);
		NSLog(@"KCReportThread %s done sleeping", _cmd);
	}*/
	

	[m_mainthread_delegate performSelectorOnMainThread:@selector(nowProcessingRequest) 
		withObject:nil waitUntilDone:NO];

	// NSLog(@"KCReportThread %s AFTER", _cmd);
}

-(void)parentWeHaveData:(NSData*)data forPath:(NSString*)path {
	// NSLog(@"KCReportThread %s BEFORE", _cmd);
	data = [[data copy] autorelease];
	[m_mainthread_delegate performSelectorOnMainThread:@selector(hasData:) 
		withObject:data waitUntilDone:NO];

	/*
	the entire report operation has been completed
	and the background process is now ready for more jobs.
	*/
	m_is_busy = NO;
	// NSLog(@"KCReportThread %s AFTER", _cmd);
}

-(NSString*)description {
	NSString* thread_name = [[NSThread currentThread] name];
	return [NSString stringWithFormat: 
		@"KCReportThread\n"
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
