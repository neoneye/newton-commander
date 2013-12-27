//
// main.m
// Newton Commander
//

/*

IDEA: use a watchdog to protect against hangups.. maybe a 1 minute alarm is good
This watchdog could be specified via the commandline, e.g:  NewtonCommanderHelper --watchdog=60
*/
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <Foundation/Foundation.h>
#import "NCLog.h"
#import "daemonize.h"
#import "zombie.h"
#import "exception.h"
#import "signal.h"
#import "NCWorkerProtocol.h"
#import "NCWorkerPlugin.h"
#import "NCWorkerPluginAdvanced.h"

#define INCLUDE_DEBUG_CODE


@interface Main : NSObject {
}

-(void)didEnterRunloop;

-(void)stop;

#ifdef INCLUDE_DEBUG_CODE
-(void)debug;
#endif

@end

@implementation Main

#ifdef INCLUDE_DEBUG_CODE
-(void)debug {
	// LOG_DEBUG(@"debug");
	// [self debugWatchdogHandler];
	[self debugWhoami];
}

-(void)debugWhoami {
	system("/usr/bin/whoami > /tmp/result_whoami.txt");
	system("/bin/ls /Volumes/mydoom > /tmp/result_ls");
}

-(void)debugWatchdogHandler {
	start_watchdog();
	sleep(10);
}
#endif

-(void)didEnterRunloop {
	// LOG_DEBUG(@"didEnterRunloop");                  

#ifdef INCLUDE_DEBUG_CODE
	[self debug];
#endif

	LOG_DEBUG(@"will sleep now");
	[self performSelector: @selector(stop)
	           withObject: nil
	           afterDelay: 10.f];
}

-(void)stop {
	CFRunLoopStop(CFRunLoopGetMain());
}
@end



float seconds_since_program_start() { 
	return ( (float)clock() / (float)CLOCKS_PER_SEC );
}


@interface Main2 : Main <NCWorkerChildCallbackProtocol, NCWorkerPluginDelegate> {
	NSConnection* m_connection;
	NSString* m_label;
	NSString* m_child_name;
	NSString* m_parent_name;
	id <NCWorkerParentCallbackProtocol> m_parent;
	BOOL m_connection_established;
	
	id <NCWorkerPlugin> m_plugin;
}

-(id)initWithLabel:(NSString*)label childName:(NSString*)cname parentName:(NSString*)pname;
-(void)initConnection;
-(void)connectToParent;

@end

@implementation Main2
-(id)initWithLabel:(NSString*)label childName:(NSString*)cname parentName:(NSString*)pname {
	self = [super init];
    if(self) {
		m_label = [label copy];
		m_parent_name = [pname copy];
		m_child_name = [cname copy];

		m_connection = nil;
		m_parent = nil;
		m_connection_established = NO;
		
		m_plugin = [[NCWorkerPluginAdvanced alloc] init];
		[m_plugin setDelegate:self];
    }
    return self;
}

-(void)didEnterRunloop {
	LOG_DEBUG(@"main.didEnterRunloop");

	// start_watchdog();
	[self initConnection];
	stop_watchdog();
	// NSLog(@"%s STEP1 WILL SLEEP", _cmd);

	// NSLog(@"%s STEP2 WILL CONNECT", _cmd);
	// start_watchdog();
	[self connectToParent];
	stop_watchdog();

	// NSLog(@"%s STEP3 WILL CONTACT PARENT", _cmd);
	LOG_DEBUG(@"main.will contact parent");
	[m_parent weAreRunning:m_child_name];

	// NSLog(@"%s STEP4 WILL VALIDATE", _cmd);
	
	[self performSelector: @selector(dieIfHandshakeFailed)
	           withObject: nil
	           afterDelay: 23.f];

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
	[con setRootObject:self]; // IDEA: use another seperate class as root object
	m_connection = con; 
}

-(void)connectToParent {

	NSString* name = m_parent_name;

	// IPC between different user accounts is not possible with mach ports, thus we use sockets
	NSPort* port = [[NSSocketPortNameServer sharedInstance] portForName:name host:@"*"];
	NSConnection* connection = [NSConnection connectionWithReceivePort:nil sendPort:port];
	
	NSDistantObject* obj = [connection rootProxy]; 
	if(obj == nil) {
		LOG_ERROR(@"main.could not connect to parent: %@\n\nwill terminate self: %@", name, self);
		[self stop];
		return;
	}
	[obj setProtocolForProxy:@protocol(NCWorkerParentCallbackProtocol)];
	id <NCWorkerParentCallbackProtocol> proxy = (id <NCWorkerParentCallbackProtocol>)obj;
	m_parent = proxy;
}

-(void)dieIfHandshakeFailed {
	if(m_connection_established) {
		LOG_DEBUG(@"connection has been established %@ OK", m_label);
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
	// LOG_DEBUG(@"main.requestData: %@", dict);

	[m_plugin request:dict];
	// log_error_objc(@"main.requestData after");

	// stop_watchdog();
}

-(void)plugin:(id<NCWorkerPlugin>)plugin response:(NSDictionary*)dict {
	// log_error_objc(@"main.plugin_response before");
	NSData* data = [NSArchiver archivedDataWithRootObject:dict];

	// IDEA: maybe use NSInvocation, so it doesn't happen in the same NSRunloop cycle. Not sure if it matters
	[m_parent responseData:data];
	// log_error_objc(@"main.plugin_response after");
}

@end


int main (int argc, const char * argv[]) {
	if(argc <= 1) {
		printf("usage: NCWorker uid label parent child\n");
		return EXIT_FAILURE;
	}

    @autoreleasepool {
        @autoreleasepool {

		[NCLog setupWorker];
		// LOG_ERROR(@"test error <---------------");
		// LOG_WARNING(@"test warning <---------------");
		// LOG_DEBUG(@"test debug <---------------");

		/*
		argv[0] = programname
		argv[1] = label, description of our purpose (string)
		argv[2] = parent-name, connection name to get in touch with the frontend process (string)
		argv[3] = child-name, our connection name, so parent can get in touch with us (string)
		argv[4] (optional) = try run as uid (integer)
		*/
		if((argc < 4) || (argc > 5)) {
			LOG_ERROR(@"ERROR: wrong number of arguments. There must be given 3 arguments and a 4th optional argument: label parent_name child_name (uid)");
			return EXIT_FAILURE;
		}

		// parse integer if an UID is provided
		int run_as_uid = 0;
		BOOL should_switch_user = NO;
		if(argc == 5) {
			run_as_uid = strtol(argv[4], NULL, 10);
			if((run_as_uid == 0) && (errno == EINVAL)) {
				LOG_ERROR(@"ERROR: interpreting argument[4]. The value must be a signed integer.");
				return EXIT_FAILURE;
			}
			should_switch_user = YES;
		}
		
		const char* label = argv[1];
		const char* parent_name = argv[2];
		const char* child_name = argv[3];

		{
			char buffer[500];
			snprintf(
				buffer, 
				500, 
				"arg[1]     run_as_uid: %i\n"
				"arg[2]          label: \"%-20s\"\n"
				"arg[3]    parent name: \"%-20s\"\n"
				"arg[4]     child name: \"%-20s\"\n"
				"           parent pid: %i\n"
				"                  pid: %i\n"
				" real / effective uid: %i / %i\n"
				" real / effective gid: %i / %i\n",
				run_as_uid, 
				label,     
				parent_name,
				child_name,
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
		if(should_switch_user) {
			if(setreuid(run_as_uid, run_as_uid)) {
				if(errno == EPERM) {
					/*
					TODO: somehow notify our parent process, letting it know that we failed to switch user.
					*/
					LOG_ERROR(@"main() - ERROR: we don't have permission to change user! maybe setuid wasn't set?");
					return EXIT_FAILURE;
				}
				/*
				TODO: somehow notify our parent process, letting it know that we failed to switch user.
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
		suicide_if_we_become_a_zombie();
		setup_signals();
		install_exception_handler();

		// raise_test_exception();

		NSString* s0 = [NSString stringWithUTF8String:label];
		NSString* s1 = [NSString stringWithUTF8String:child_name];
		NSString* s2 = [NSString stringWithUTF8String:parent_name];
		Main* main = [[Main2 alloc] initWithLabel:s0 childName:s1 parentName:s2];
		[main performSelector: @selector(didEnterRunloop)
		           withObject: nil
		           afterDelay: 0];

        }
	LOG_DEBUG(@"main() - runloop");
	CFRunLoopRun();

	LOG_DEBUG(@"main() - cleanup");
    }

	LOG_DEBUG(@"main() - leave");
    return EXIT_SUCCESS;
}
