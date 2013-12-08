//
//  WorkerChild.m
//  Kill
//
//  Created by Simon Strandgaard on 05/06/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import "WorkerChild.h"
#import "Logger.h"
#import "daemonize.h"
#import "zombie.h"
#import "exception.h"
#import "signal.h"
#include <stdlib.h>
#include <sysexits.h>


#define HANDSHAKE_TIMEOUT 5.f


float seconds_since_program_start() { 
	return ( (float)clock() / (float)CLOCKS_PER_SEC );
}



@implementation WorkerChild

@synthesize plugin = m_plugin;
@synthesize commands = m_commands;

-(id)initWithChildName:(NSString*)cname parentName:(NSString*)pname className:(NSString*)aClassName {
	self = [super init];
    if(self) {
		m_parent_name = [pname copy];
		m_child_name = [cname copy];

		m_connection = nil;
		m_parent = nil;
		m_connection_established = NO;
		
		m_ping_count = 0;
		
		Class wClass = NSClassFromString(aClassName);
		id object = [[[wClass alloc] init] autorelease];
		if(![object conformsToProtocol:@protocol(WorkerChildPlugin)]) {
			LOG_ERROR(@"class_name doesn't conform to protocol. class_name: %@", aClassName);
			exit(EXIT_FAILURE);
		}
		self.plugin = (id <WorkerChildPlugin>)object;
		
		self.commands = [NSMutableDictionary dictionaryWithCapacity:50];
    }
    return self;
}

-(void)registerCommand:(NSString*)command block:(WorkerDictionaryBlock)aBlock {
	[m_commands setObject:[WorkerCommand commandWithBlock:aBlock] forKey:command];
}

-(void)registerDefaultCommands {
	// LOG_DEBUG(@"BEFORE REGISTERING");
	
	[self registerCommand:kWorkerChildCommandStartup block:^(NSDictionary* aDictionary){
		[self runStartupCommand];
	}];

	[self registerCommand:@"ping" block:^(NSDictionary* aDictionary){
		[self runPingCommand];
	}];

	[self registerCommand:@"force_exit_failure" block:^(NSDictionary* aDictionary){
		exit(EXIT_FAILURE);
	}];

	[self registerCommand:@"force_exit_success" block:^(NSDictionary* aDictionary){
		exit(EXIT_SUCCESS);
	}];

	[self registerCommand:@"force_exception" block:^(NSDictionary* aDictionary){
		NSException *e = [NSException
	        exceptionWithName:@"Debug Forced Exception"
	        reason:@"For debugging purposes"
	        userInfo:nil];
		@throw e;
	}];

	[self registerCommand:@"force_abort" block:^(NSDictionary* aDictionary){
		abort();
	}];

	// LOG_DEBUG(@"AFTER REGISTERING");
}

-(void)didEnterRunloop {
	LOG_DEBUG(@"main.didEnterRunloop");

	[self registerDefaultCommands];
	[self.plugin prepareWorkerChild:self];

	
	// start_watchdog();
	[self initConnection];
	stop_watchdog();
	// LOG_DEBUG(@"%s STEP1 WILL SLEEP", _cmd);

	// LOG_DEBUG(@"%s STEP2 WILL CONNECT", _cmd);
	// start_watchdog();
	[self connectToParent];
	stop_watchdog();

	// LOG_DEBUG(@"%s STEP3 WILL CONTACT PARENT", _cmd);
	int pid = getpid();
	int uid = getuid();
	LOG_DEBUG(@"main.will contact parent");
	[m_parent weAreRunning:m_child_name childPID:pid childUID:uid];

	// LOG_DEBUG(@"%s STEP4 WILL VALIDATE", _cmd);
	
	[self performSelector: @selector(dieIfHandshakeFailed)
	           withObject: nil
	           afterDelay: HANDSHAKE_TIMEOUT];

	/*
	startup takes about 0.02 seconds on my macmini 1.8 GHz,
	this is when we link with the Foundation framework.
	
	if we link with the Cocoa framework, then it takes 0.07 seconds.
	*/
	{
		float seconds = seconds_since_program_start();
		LOG_DEBUG(@"main.start took %.3f seconds", seconds);
	}
}

-(void)initConnection {
	// IPC between different user accounts is not possible with mach ports, thus we use sockets
	NSSocketPort* port = [[NSSocketPort alloc] init];
	NSConnection* con = [NSConnection connectionWithReceivePort:port sendPort:nil];
	if([[NSSocketPortNameServer sharedInstance] registerPort:port name:m_child_name] == NO) {
		LOG_ERROR(@"main.registerName was unsuccessful. child_name=%@\n\nwill terminate self: %@", m_child_name, self);
		[self stop];
	}
	[con setRootObject:self];
	m_connection = [con retain]; 
}

-(void)connectToParent {

	NSString* name = m_parent_name;

	// IPC between different user accounts is not possible with mach ports, thus we use sockets
	NSPort* port = [[NSSocketPortNameServer sharedInstance] portForName:name host:@"*"];
	NSConnection* connection = [NSConnection connectionWithReceivePort:nil sendPort:port];
	
	NSDistantObject* obj = [[connection rootProxy] retain]; 
	if(obj == nil) {
		LOG_ERROR(@"main.could not connect to parent: %@\n\nwill terminate self: %@", name, self);
		[self stop];
		return;
	}
	[obj setProtocolForProxy:@protocol(WorkerParentCallbackProtocol)];
	id <WorkerParentCallbackProtocol> proxy = (id <WorkerParentCallbackProtocol>)obj;
	m_parent = proxy;
}

-(void)dieIfHandshakeFailed {
	if(m_connection_established) {
		LOG_DEBUG(@"connection has been established");
	} else {
		LOG_ERROR(@"main.handshake never took place\nwill terminate self: %@", self);
		[self stop];
	}
}

-(int)handshakeAcknowledge:(int)value {
	LOG_DEBUG(@"main.handshakeAcknowledge %i", value);
	m_connection_established = YES;
	return value + 1;
}

-(void)runPingCommand {
	m_ping_count++;
	
	NSArray* keys = [NSArray arrayWithObjects:@"command", @"count", nil];
	NSArray* objects = [NSArray arrayWithObjects:@"ping", [NSNumber numberWithInteger:m_ping_count], nil];
	NSDictionary* dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	

	[self deliverResponse:dict];
}

-(void)runStartupCommand {
	int child_pid = getpid();
	int child_uid = getuid();

	LOG_DEBUG(@"pid: %i  uid: %i", child_pid, child_uid);

	NSArray* keys = [NSArray arrayWithObjects:
		@"command", 
		@"child_process_identifier", 
		@"child_user_identifier", 
		nil
	];
	NSArray* objects = [NSArray arrayWithObjects:
		kWorkerParentCommandChildDidStart, 
		[NSNumber numberWithInteger:child_pid], 
		[NSNumber numberWithInteger:child_uid], 
		nil
	];
	NSDictionary* dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	

	LOG_DEBUG(@"dict: %@", dict);
	[self deliverResponse:dict];
}

-(oneway void)requestData:(in bycopy NSData*)data {
	// log_error_objc(@"main.requestData before");
	// start_watchdog();

	id obj = [NSUnarchiver unarchiveObjectWithData:data];
	// ensure that it's a dictionary
	if(![obj isKindOfClass:[NSDictionary class]]) {
		LOG_ERROR(@"ERROR: expected a dictionary, but got %@. Ignoring this request!", NSStringFromClass([obj class]));
		return;
	}
	NSDictionary* dict = (NSDictionary*)obj;
	LOG_DEBUG(@"main.requestData: %@", dict);
	
	id value_command = [dict objectForKey:@"command"];
	if(![value_command isKindOfClass:[NSString class]]) {
		LOG_ERROR(@"ERROR: expected a string, but got %@. Ignoring this request!", NSStringFromClass([value_command class]));
		return;
	}
	NSString* command_name = (NSString*)value_command;
	
	
	id thing = [m_commands objectForKey:command_name];
	// LOG_DEBUG(@"thing: %@", thing);
	if([thing isKindOfClass:[WorkerCommand class]]) {
		// LOG_DEBUG(@"yes its the right kind");
		WorkerCommand* command = (WorkerCommand*)thing;
		LOG_DEBUG(@"before run: %@", command_name);
		[command run:dict];
		LOG_DEBUG(@"after run: %@", command_name);
		return;
	}

	{
		LOG_ERROR(@"unknown command: %@", command_name);
		NSString* message = [NSString stringWithFormat:@"unknown command %@", command_name];

		NSArray* keys = [NSArray arrayWithObjects:@"command", @"error", nil];
		NSArray* objects = [NSArray arrayWithObjects:@"no_such_command_in_child", message, nil];
		NSDictionary* rdict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	

		[self deliverResponse:rdict];
		return;
	}

	// stop_watchdog();
}

-(void)deliverResponse:(NSDictionary*)dict {
	// log_error_objc(@"main.plugin_response before");
	LOG_DEBUG(@"main.plugin_response: %@", dict);
	NSData* data = [NSArchiver archivedDataWithRootObject:dict];

	// IDEA: maybe use NSInvocation, so it doesn't happen in the same NSRunloop cycle. Not sure if it matters
	[m_parent responseData:data];
	// log_error_objc(@"main.plugin_response after");
}

-(void)stop {
	CFRunLoopStop(CFRunLoopGetMain());
}

@end


int worker_child_main(int argc, const char * argv[], const char* logger_name, const char* class_name) {
    NSAutoreleasePool* pool_outer = [[NSAutoreleasePool alloc] init];
    NSAutoreleasePool* pool_inner = [[NSAutoreleasePool alloc] init];

	[Logger setupWorkerApp:[NSString stringWithUTF8String:logger_name]];

	if(argc < 5) {
		LOG_ERROR(@"ERROR: too few arguments (%i). There must be given at least 4 arguments: uid parent_pid parent_name child_name", argc);
		return EXIT_FAILURE;
	}
	//const char* executable_path = argv[0];  // program name
	const char* uid_str           = argv[1];  // user-identifier (integer) that we should run under
	const char* parent_pid_str    = argv[2];  // parent process identifier (integer) that we monitor and commit suicide when it dies
	const char* parent_name       = argv[3];  // parent-name (string), connection name to get in touch with the parent process
	const char* child_name        = argv[4];  // child-name (string), our connection name, so parent can get in touch with us

	// parse integer if an UID is provided
	BOOL has_uid = YES;
	int run_as_uid = strtol(uid_str, NULL, 10);
	if((errno == EINVAL) || (errno == ERANGE)) {
		// has_uid = NO;
	}

	// parse integer if a ParentProcessIdentifier is provided
	int parent_pid = strtol(parent_pid_str, NULL, 10);
	if((errno == EINVAL) || (errno == ERANGE)) {
		parent_pid = getppid();
	}
	

	{
		char buffer[500];
		snprintf(
			buffer, 
			500, 
			"arg[1]     run_as_uid: %i\n"
			"           parent pid: %i\n"
			"                  pid: %i\n"
			" real / effective uid: %i / %i\n"
			" real / effective gid: %i / %i\n",
			run_as_uid, 
			getppid(),
			getpid(),
	        getuid(),
	        geteuid(),
	        getgid(),
	        getegid()
		);
		LOG_DEBUG(@"Newton Commander Worker Process\n%s", buffer);
	}


	/*
	switch to a different user
	NOTE: uid's can be negative, e.g nobody has uid=-2
	*/
	if(has_uid) {
		if(setreuid(run_as_uid, run_as_uid)) {
			if(errno == EPERM) {
				/*
				TODO: somehow notify our parent process, letting it know that we failed to switch user.
				alternatively continue running and let the parent process decide wether to stop the child or not
				*/
				LOG_ERROR(@"main() - ERROR: we don't have permission to change user! maybe setuid wasn't set?");
				return EXIT_FAILURE;
			}
			/*
			TODO: somehow notify our parent process, letting it know that we failed to switch user.
			alternatively continue running and let the parent process decide wether to stop the child or not
			*/
			LOG_ERROR(@"main() - ERROR: change user failed!!! maybe setuid wasn't set?");
			return EXIT_FAILURE;
		}

		char buffer[200];
		snprintf(
			buffer, 
			200, 
			" real / effective uid: %i / %i\n"
			" real / effective gid: %i / %i\n",
	        getuid (),
	        geteuid(),
	        getgid (),
	        getegid()
		);
		LOG_DEBUG(@"main() - successfully changed user\n%s", buffer);
	} else {
		LOG_DEBUG(@"main() - not changing user");
	}


	close_stdout_stderr_stdin();
	suicide_if_we_become_a_zombie(parent_pid);
	setup_signals();
	install_exception_handler();

	NSString* s0 = [NSString stringWithUTF8String:child_name];
	NSString* s1 = [NSString stringWithUTF8String:parent_name];
	NSString* s2 = [NSString stringWithUTF8String:class_name];
	WorkerChild* main = [[WorkerChild alloc] initWithChildName:s0 parentName:s1 className:s2];
	[main performSelector: @selector(didEnterRunloop)
	           withObject: nil
	           afterDelay: 0];

    [pool_inner drain];
	LOG_DEBUG(@"main() - runloop");
	CFRunLoopRun();

	LOG_DEBUG(@"main() - cleanup");
    [pool_outer drain];

	LOG_DEBUG(@"main() - leave");
    return EXIT_SUCCESS;
}
