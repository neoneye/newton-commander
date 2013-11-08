/*********************************************************************
kclist_main.mm - daemon for listing files in an asynchronous fashion
Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>

*********************************************************************

IDEA: rename this program to JuxtaFile_List.
total commander uses the word "lister", so we should do that too.
thus maybe rename to "JF_lister".

TODO: for each alias.. actively obtain the full path that they point at,
so that we can follow the alias without waiting for the filesystem.
Alternatively lazily obtain the info at the point where the user 
follows the link. This info can be stored in a dictionary, since
I have yet to see a huge dir containing just aliases.

IDEA: GetDirectoryEntries updates accesstime, which doesn't allow
us to browse stealth. It's uncomfortable that we change things when
we browe as root. We want no leave no evidence.

IDEA: start a 30 second watchdog for every runloop operation, just to 
be sure that we don't get stuck in some hang/crash/infinite loop.

IDEA: in every phase, we need a check to see if the request has been
aborted... most likely because the user wants to do a new request.
So in every phase we need to detect if it's transaction has been aborted
and start working on the new request.

IDEA: is it possible to give a rough estimate of how many elements
that are in the dir. The inode count is only available on some filesystems.
Are there a better way? By sending this to the frontend ASAP, the UI can
be updated, so the rows is marked with ??? until the filenames arrive.
This would tell the user that the system is busy obtaining filenames.

IDEA: run all lowlevel calls to the filesystem in a separate thread,
so that we can do synchronous calls with the frontend process, without
blocking the process of obtaining data (it must be fast!).
*********************************************************************

The set of goals for KCList is:

1. Responsive
   - no spinning beachballs in the UI
   - resistent against the many timeouts in Apple's filesystem code
   - provide data as fast as possible
2. Sudo
   - must be able to browse dirs as Admin
3. Show as much data as possible
   - apparently Apple is hiding some dirs (rixstep's getdirentries hack)
4. Be nice
   - don't let an attacker take over the privileged KCList program
   - don't let any zombie processes run wild

The filesystem on Mac OS X sometimes can time out for over 10 seconds, 
it's necessary to kill these jobs that are hanging.
Because of this KCList runs as a separate process. When it times out
we kill and restart the process.

As the only user of my computer I expect to be able to browse
the entire filesystem. In a terminal you can type "sudo ls /somedir"
and see what it contains, but in a GUI program its necessary
to separate out privileged code into a separate process (KCList).

The dir /usr/share/man/man3 takes nearly 2 seconds to query on my
macmini. It has 6255 filenames in it.
Speed depending on the kind of info you try to obtain from the
filesystem. It can take a long time to obtain filenames, filesizes and
filetypes. A faster response can be made by splitting up the
requests into just a request for just filenames, followed by another
request for filesizes, followed by a request for filetypes. 
This gives the best responsiveness in the UI. 
By splitting up the big request for /usr/share/man/man3 into smaller
ones.. the first response can be made after 100 msec, the following
two request takes 1 sec each. 100 msec is a great improvement in
responsiveness over having to wait 2 seconds!

I just tried the ACP by rixstep.. there is a tool in it named GDE
Browsing to the root folder, reveals some dirs that I can't see
with KeyboardCommander. I really wonder WTF is going on.
How can GDE do it.. when I can't?!? see
file:///Applications/ACP/ACP.framework/Versions/2.0/Resources/GDE.html
Apple's sample code FSMegaInfo can do it
prompt> ./FSMegaInfo getdirentries -r /
OK. Now I have adapted the apple code, and we can now show these 
kind of files/dirs as well.


*********************************************************************


PROBLEM:
Try run this command "ls -la /net" in Terminal.app and see that it takes 10 seconds.

The "/net" directory times out when iterating it. It does so in most of the other filemanagers I have tried out too. Most of the file system traversal functions seems to be syncronous.

API#1 - CoreServices async
I found this, that may indicate that CoreServices has some async support???
http://developer.apple.com/documentation/Carbon/Reference/File_Manager/Reference/reference.html#//apple_ref/c/func/PBOpenIteratorAsync

void PBOpenIteratorAsync (
   FSCatalogBulkParam *paramBlock
);

Will have to try it out.


API#2 - BSD fts
http://www.manpagez.com/man/3/fts/

OMG. fts_read() is so damn fast. Still has 10 second timeout problem,
that I don't know how to deal with.
fts_read() only takes 0.1 second to process 4000 files.
where the cocoa code would take 1.2 seconds for 4000 files.


API#3 - Cocoa contentsOfDirectoryAtPath
http://developer.apple.com/documentation/Cocoa/Reference/Foundation/Classes/nsfilemanager_Class/Reference/Reference.html#//apple_ref/occ/instm/NSFileManager/contentsOfDirectoryAtPath:error:
Mostly fast. Except when it times out, then it takes 10 seconds!
try visit the "/net" dir. No way to abort.
You only get filenames back. No info about if its dirs nor filesizes.
In Inspector it seems like these functions are being called internally:
 1. PBOpenIteratorSync
 2. PathGetObjectInfo
 3. ResolveSyntheticAliasFileByPath
 4. PBCloseIteratorSync


API#4 - Cocoa enumeratorAtPath
http://developer.apple.com/documentation/Cocoa/Reference/Foundation/Classes/nsfilemanager_Class/Reference/Reference.html#//apple_ref/occ/instm/NSFileManager/enumeratorAtPath:

Slower than API#3, and no way to abort.



*********************************************************************

PROBLEM: ensure that our process dies when the frontend process dies.
At first I used NSWorkspaceDidTerminateApplicationNotification
but that requires the Cocoa framework, which is not appropriate
for tools that runs as root.

SOLUTION: kqueue
This seems to be the most reliable solution. Requires no polling.

see 
http://developer.apple.com/technotes/tn/tn2050.html

see
http://developer.apple.com/documentation/CoreFoundation/Reference/CFFileDescriptorRef/Reference/reference.html



*********************************************************************/
#include <Foundation/Foundation.h>
#include <sys/event.h>
#include "../di_protocol.h"
#include <unistd.h>
#include <ctime>
#include <signal.h>
#include <string.h>
#include <mach/mach.h>
#include <asl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "system_GDE.h"

#if 1
# define USE_SOCKETPORT
#endif


#define kWatchdogTimeoutInSeconds 1


float seconds_since_program_start() { 
	return ( (float)clock() / (float)CLOCKS_PER_SEC );
}


BOOL is_process_running(int pid) {
	// NOTE that kill() is not used for killing,
	// but for determining if the pid is valid.
	return (kill(pid, 0) == 0);
}



/*
Start the watchdog timer.  If you don't call DisableWatchdog before the 
timer expires, the process will die with a SIGALRM.
*/
void enable_watchdog() {
	alarm(kWatchdogTimeoutInSeconds);
}

void disable_watchdog() {
	alarm(0);
}


/*
apple sys log
*/
aslclient global_aslclient = NULL;
aslmsg	  global_aslmsg = NULL;



// log_debug_objc(@"content of dictionary: %@", dict);
#define log_debug_objc(format, ...) \
	asl_log(global_aslclient, global_aslmsg, ASL_LEVEL_DEBUG, \
	"DEBUG %s", [[NSString stringWithFormat:format, ##__VA_ARGS__] UTF8String])

// log_debug("the code is %i", 42);
#define log_debug(format, ...) \
	asl_log(global_aslclient, global_aslmsg, ASL_LEVEL_DEBUG, \
	"DEBUG " format, ##__VA_ARGS__)

// log_info_objc(@"content of dictionary: %@", dict);
#define log_info_objc(format, ...) \
	asl_log(global_aslclient, global_aslmsg, ASL_LEVEL_INFO, \
	"INFO  %s", [[NSString stringWithFormat:format, ##__VA_ARGS__] UTF8String])

// log_info("the code is %i", 42);
#define log_info(format, ...) \
	asl_log(global_aslclient, global_aslmsg, ASL_LEVEL_INFO, \
	"INFO  " format, ##__VA_ARGS__)

// log_error_objc(@"something bad happened %@", obj);
#define log_error_objc(format, ...) \
	asl_log(global_aslclient, global_aslmsg, ASL_LEVEL_ERR, \
	"ERROR %s", [[NSString stringWithFormat:format, ##__VA_ARGS__] UTF8String])

// log_error("something bad happened %i", 42);
#define log_error(format, ...) \
	asl_log(global_aslclient, global_aslmsg, ASL_LEVEL_ERR, \
	"ERROR " format, ##__VA_ARGS__)








class MyGetDirEntries : public SystemGetDirEntries {
private:
	NSMutableArray* m_names;
	NSMutableData* m_types;

public:
	MyGetDirEntries() : m_names(nil), m_types(nil) {
		m_names = [NSMutableArray arrayWithCapacity:10000];
		m_types = [NSMutableData dataWithCapacity:10000 * sizeof(unsigned int)];
	}
	
	NSArray* get_names() {
		return [[m_names copy] autorelease];
	}
	
	NSData* get_types() {
		return [[m_types copy] autorelease];
	}
	
	void process_error() {
		// nothing
	}

	void process_dirent(
		unsigned long long d_inode,
		u_int16_t d_reclen,
		u_int8_t d_type,
		u_int8_t d_namlen,
		const char* d_name,
		const char* pretty_d_type)
	{
		NSString* name = [NSString stringWithUTF8String:d_name];
		[m_names addObject:name];
		
		unsigned int t = d_type;
		[m_types appendBytes:&t length:sizeof(unsigned int)];
	}
};








@interface Main : NSObject <DiscoverChildProtocol> {
	NSConnection* m_connection;
	NSString* m_name;
	NSString* m_parent_name;
	NSString* m_child_name;
	id <DiscoverParentProtocol> m_parent;
	BOOL m_handshake_ok;
	
	NSArray* m_filenames;
	NSData* m_filetypes;
	NSData* m_filestat64;
	
	NSString* m_path;
	int m_transaction_id;
	
	int m_ppid;
}
-(id)initWithParentId:(int)ppid 
                 name:(NSString*)name 
           parentName:(NSString*)pname;

-(void)terminateIfNoPing;

-(void)willEnterRunloop;
-(void)didEnterRunloop;

@end


@interface Main (Private)
-(void)testNoteExit:(id)sender;
-(void)initConnection;
-(void)connectToParent;
-(void)selfTerminate;
-(BOOL)canPingFrontend;
-(void)obtainType;
-(void)obtainStat;
-(void)obtainAlias;
@end

@implementation Main

-(id)initWithParentId:(int)ppid name:(NSString*)name parentName:(NSString*)pname {
	self = [super init];
    if(self) {
		// NSLog(@"DI init: name=%@ parent=%@ ppid=%i", name, pname, ppid);
		m_name = [name copy];
		m_parent_name = [pname copy];
		m_ppid = ppid;

		int pid = [[NSProcessInfo processInfo] processIdentifier];
		NSString* child_name = [NSString stringWithFormat:@"child_%@_%i", m_name, pid];
		m_child_name = [child_name retain];
		// NSLog(@"%s %@", _cmd, m_child_name);

		m_connection = nil;
		m_parent = nil;
		m_handshake_ok = NO;
		
		m_filenames = nil;
		m_filetypes = nil;
		m_filestat64 = nil;
		
		m_path = nil;
		m_transaction_id = -1;
    }
    return self;
}

-(void)willEnterRunloop {
	log_debug("willEnterRunloop");                  
	[self performSelector: @selector(didEnterRunloop)
	           withObject: nil
	           afterDelay: 0];
}

-(void)didEnterRunloop {
	log_debug("didEnterRunloop");

	[self initConnection];
	// NSLog(@"%s STEP1 WILL SLEEP", _cmd);
	// sleep(1);

	// NSLog(@"%s STEP2 WILL CONNECT", _cmd);
	[self connectToParent];
	// sleep(1);

	// NSLog(@"%s STEP3 WILL CONTACT PARENT", _cmd);
	int pid = getpid();
	NSNumber* our_pid = [NSNumber numberWithInt:pid];
	[m_parent parentWeAreRunning:m_child_name processId:our_pid];
	// sleep(1);

	// NSLog(@"%s STEP4 WILL VALIDATE", _cmd);
	
	[self performSelector: @selector(validateHandshake)
	           withObject: nil
	           afterDelay: 1.f];

	/*
	startup takes about 0.02 seconds on my macmini 1.8 GHz,
	this is when we link with the Foundation framework.
	
	if we link with the Cocoa framework, then it takes 0.07 seconds.
	*/
	{
		float seconds = seconds_since_program_start();
		log_debug("start took %.3f seconds", seconds);
	}
}


-(void)validateHandshake {
	if(m_handshake_ok) {
		// NSLog(@"%s %@ OK", _cmd, m_name);
	} else {
		log_error("handshake never took place");
		log_info_objc(@"will terminate self: %@", self);
		[self selfTerminate];
	}
}

-(void)initConnection {
	NSConnection* con = [NSConnection defaultConnection];
	[con setRootObject:self];
	if([con registerName:m_child_name] == NO) {
		log_error_objc(@"registerName was unsuccessful. child_name=%@", m_child_name);
		log_info_objc(@"will terminate self: %@", self);
		[self selfTerminate];
	}
	m_connection = [con retain];
}
	   
-(void)connectToParent {

#ifdef USE_SOCKETPORT

	NSString* name = m_parent_name;

	NSSocketPort* port = [[NSSocketPortNameServer sharedInstance] portForName:name host:@"*"];
	NSConnection* connection = [NSConnection connectionWithReceivePort:nil sendPort:port];
	
	NSDistantObject* obj = [connection rootProxy]; 
	if(obj == nil) {
		log_error_objc(@"could not connect to parent: %@", name);
		log_info_objc(@"will terminate self: %@", self);
		[self selfTerminate];
		return;
	}
	[obj retain];
	[obj setProtocolForProxy:@protocol(DiscoverParentProtocol)];
	id <DiscoverParentProtocol> proxy = (id <DiscoverParentProtocol>)obj;
	m_parent = proxy;

#else

	NSString* name = m_parent_name;
	NSDistantObject* obj = [NSConnection 
		rootProxyForConnectionWithRegisteredName:name
		host:nil
	];
	if(obj == nil) {
		log_error_objc(@"could not connect to parent: %@", name);
		log_info_objc(@"will terminate self: %@", self);
		[self selfTerminate];
		return;
	}
	[obj retain];
	[obj setProtocolForProxy:@protocol(DiscoverParentProtocol)];
	id <DiscoverParentProtocol> proxy = (id <DiscoverParentProtocol>)obj;
	m_parent = proxy;

#endif
}

-(int)childPingSync:(int)value {
	// NSLog(@"%s, %i", _cmd, value);
	m_handshake_ok = YES;
	return value + 1;
}

-(oneway void)childRequestPath:(in bycopy NSString*)path transactionId:(int)tid {
	// NSLog(@"%s %@", _cmd, path);

#if 0
	NSFileManager* fm = [NSFileManager defaultManager];
	
	NSError* error = nil;

	double time0 = CFAbsoluteTimeGetCurrent();
	NSArray* filenames = [fm contentsOfDirectoryAtPath:path error:&error];
	NSData* filetypes = nil;
	double time1 = CFAbsoluteTimeGetCurrent();
	
	if(error) {
		NSLog(@"ERROR: %@", error);
		return;
	}
#else
	MyGetDirEntries gde;
	double time0 = CFAbsoluteTimeGetCurrent();
	gde.run([path UTF8String]);
	double time1 = CFAbsoluteTimeGetCurrent();

	if(gde.run_error) {
		log_error("gde.run_error: %i", gde.run_error);
		return;
	}


	NSArray* filenames = gde.get_names();
	NSData*  filetypes = gde.get_types();
#endif
	
	// NSLog(@"%s %@", _cmd, filenames);
	log_debug("obtain-filenames-operation took %.3f seconds", float(time1 - time0));
	
	[m_filenames autorelease];
	m_filenames = [filenames retain];
	
	[m_filetypes autorelease];
	m_filetypes = [filetypes retain];

	[m_filestat64 autorelease];
	m_filestat64 = nil;
	
	[m_path autorelease];
	m_path = [path retain];
	
	m_transaction_id = tid;

	NSString* error = nil;
	NSData* data = [NSPropertyListSerialization 
		dataFromPropertyList:m_filenames
		format:NSPropertyListXMLFormat_v1_0
	    errorDescription:&error
	];

	if(error != nil) {
	    log_error_objc(@"failed to make xml %@", error);
	    [error release];
		return;
	}

	double time2 = CFAbsoluteTimeGetCurrent();
	log_debug("obtain-filenames-operation-with-xml took %.3f seconds", float(time2 - time0));

	
	[m_parent parentWeHaveName:data transactionId:tid];

	[self performSelector: @selector(obtainType)
	           withObject: nil
	           afterDelay: 0.f];
}

-(void)obtainType {
	[m_parent parentWeHaveType:m_filetypes transactionId:m_transaction_id];

	[self performSelector: @selector(obtainStat)
	           withObject: nil
	           afterDelay: 0.f];
}

-(void)obtainStat {
	double time0 = CFAbsoluteTimeGetCurrent();

	NSString* path = m_path;

	NSUInteger datasize = [m_filenames count] * sizeof(struct stat64);
	NSMutableData* data = [NSMutableData dataWithCapacity:datasize]; 

	struct stat64 stnull;
	bzero(&stnull, sizeof(struct stat64));


	id thing;
	NSEnumerator* en = [m_filenames objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[NSString class]] == NO) {
			log_debug("%s ERROR: filename is not a string", _cmd);
			[data appendBytes:&stnull length:sizeof(struct stat64)];
			continue;
		}

		NSString* name = (NSString*)thing;
		NSString* file_path = [path stringByAppendingPathComponent:name];
			
		const char* stat_path = [file_path UTF8String];
		struct stat64 st;
		int rc = stat64(stat_path, &st);
		if(rc == -1) {
			log_debug("%s ERROR: stat() rc: %i", _cmd, rc);
			[data appendBytes:&stnull length:sizeof(struct stat64)];
			continue;
		}
		
		[data appendBytes:&st length:sizeof(struct stat64)];
	}
	
	// NSLog(@"%s stat: %@", _cmd, ary);
	NSData* result = [[data copy] autorelease];

	double time1 = CFAbsoluteTimeGetCurrent();
	log_debug("obtain-stat64-operation took %.3f seconds", float(time1 - time0));

	[m_filestat64 autorelease];
	m_filestat64 = [result retain];

	[m_parent parentWeHaveStat:result transactionId:m_transaction_id];
	
	[self performSelector: @selector(obtainAlias)
	           withObject: nil
	           afterDelay: 0.f];
}

-(void)obtainAlias {
	double time0 = CFAbsoluteTimeGetCurrent();

	NSUInteger number_of_filenames = [m_filenames count];
	NSString* path = m_path;

	NSUInteger datasize = number_of_filenames * sizeof(unsigned int);
	NSMutableData* data = [NSMutableData dataWithCapacity:datasize];

	NSMutableDictionary* alias_dict = [NSMutableDictionary dictionaryWithCapacity:200];


	/*
	for this code to work some preconditions must be meet.
	stat64 structs must have been gathered.
	GetDirectoryEntries must have been gathered.
	*/
	BOOL ok_stat64 = YES;
	if(m_filestat64 == nil) {
		ok_stat64 = NO;
	} else {
		NSUInteger number_of_stat64 = [m_filestat64 length] / sizeof(struct stat64);
		if(number_of_stat64 != number_of_filenames) {
			ok_stat64 = NO;
		}
	}
	BOOL ok_types = YES;
	if(m_filetypes == nil) {
		ok_types = NO;
	} else {
		NSUInteger number_of_types = [m_filetypes length] / sizeof(unsigned int);
		if(number_of_types != number_of_filenames) {
			ok_types = NO;
		}
	}

	unsigned int value_not_an_alias_stat64   = kListToolIsAliasNoDeterminedByStat64;
	unsigned int value_not_an_alias_gde      = kListToolIsAliasNoDeterminedByGDE;
	unsigned int value_error_bad_filename    = kListToolIsAliasErrorBadFilename;
	unsigned int value_error_making_fsref    = kListToolIsAliasErrorBadFSRef;
	unsigned int value_error_resolving_alias = kListToolIsAliasErrorResolvingAlias;
	unsigned int value_error_filenotfound    = kListToolIsAliasErrorFileNotFound;
	unsigned int value_not_an_alias          = kListToolIsAliasNo;
	unsigned int value_is_alias_for_file     = kListToolIsAliasYesFile;
	unsigned int value_is_alias_for_folder   = kListToolIsAliasYesFolder;

	NSUInteger error_count_filename = 0;
	NSUInteger error_count_fsref = 0;
	NSUInteger error_count_resolve = 0;
	
	for(NSUInteger index=0; index<number_of_filenames; ++index) {
		if(ok_stat64) {
			struct stat64 st;
			NSRange range = NSMakeRange(
				index * sizeof(struct stat64), 
				sizeof(struct stat64)
			);
			[m_filestat64 getBytes:&st range:range];
			
			if((st.st_mode & S_IFMT) != S_IFREG) {
				[data appendBytes:&value_not_an_alias_stat64 length:sizeof(unsigned int)];
				// NSLog(@"%s it's not a file.. thus we are sure it's not an alias file", _cmd);
				continue;
			}
		}
		if(ok_types) {
			unsigned int result_type = 0;
			NSRange range = NSMakeRange(
				index * sizeof(unsigned int), 
				sizeof(unsigned int)
			);
			[m_filetypes getBytes:&result_type range:range];
			
			if(result_type != SystemGetDirEntriesTypeFile) {
				[data appendBytes:&value_not_an_alias_gde length:sizeof(unsigned int)];
				// NSLog(@"%s it's not a file.. thus we are sure it's not an alias file", _cmd);
				continue;
			}
		}


		id thing = [m_filenames objectAtIndex:index];
		if([thing isKindOfClass:[NSString class]] == NO) {
			error_count_filename++;
			[data appendBytes:&value_error_bad_filename length:sizeof(unsigned int)];
			continue;
		}

		NSString* name = (NSString*)thing;
		NSString* file_path = [path stringByAppendingPathComponent:name];

		FSRef ref;
		OSStatus error = 0;

		error = FSPathMakeRef((const UInt8 *)[file_path fileSystemRepresentation], &ref, NULL);	
		if(error) {
			error_count_fsref++;
			[data appendBytes:&value_error_making_fsref length:sizeof(unsigned int)];
			continue;
		}

		Boolean isAlias;
		Boolean isFolder;

		error = FSResolveAliasFileWithMountFlags(&ref, false, &isFolder, &isAlias, kResolveAliasFileNoUI);
		if(error == fnfErr) {
			/*
			FSResolveAliasFileWithMountFlags doesn't like browsing
			the hidden /.HFS folders, so it yields lots of 
			file not found errors.
			*/
			[data appendBytes:&value_error_filenotfound length:sizeof(unsigned int)];
			continue;
		} else
		if(error != noErr) {
			if(error_count_resolve == 0) {
				log_debug("%s FSResolveAliasFileWithMountFlags returned: %i", _cmd, (int)error);
			}
			error_count_resolve++;
			[data appendBytes:&value_error_resolving_alias length:sizeof(unsigned int)];
			continue;
		}

		unsigned int value = value_not_an_alias;
		if(isAlias) {
			if(isFolder) {
				value = value_is_alias_for_folder;
			} else {
				value = value_is_alias_for_file;
			}

			// keep track of target-path for every alias
			NSURL* target_url = [(NSURL *)CFURLCreateFromFSRef(NULL, &ref) autorelease];
			if(target_url == nil) {
				// log_debug_objc(@"%s error making url", _cmd);
				[alias_dict setObject:[NSNull null] forKey:name];
			} else {
				NSString* target_path = [target_url path];
				[alias_dict setObject:target_path forKey:name];
				// log_debug_objc(@"alias path: %@", target_path);
			}
			
		}
		[data appendBytes:&value length:sizeof(unsigned int)];
	}

	if(error_count_filename > 0) {
		log_debug("%s filename is not a string.. occured %i times", _cmd, (int)error_count_filename);
	}
	if(error_count_fsref > 0) {
		log_debug("%s could not make FSRef.. occured %i times", _cmd, (int)error_count_fsref);
	}
	if(error_count_resolve > 0) {
		log_debug("%s occured calling FSResolveAliasFileWithMountFlags.. occured %i times", _cmd, (int)error_count_resolve);
	}

	if([alias_dict count] > 0) {
		log_debug_objc(@"alias_dict: %@", alias_dict);
		// TODO: transfer this data to the UI process
	}
	
	// NSLog(@"%s stat: %@", _cmd, ary);
	NSData* result = [[data copy] autorelease];

	double time1 = CFAbsoluteTimeGetCurrent();
	log_debug("obtain-alias-operation took %.3f seconds", float(time1 - time0));

	[m_parent parentWeHaveAlias:result transactionId:m_transaction_id];
	
	[m_parent parentCompletedTransactionId:m_transaction_id];
}

-(BOOL)canPingFrontend {
	log_debug("will ping frontend");
	int value = [m_parent parentPingSync:42];
	log_debug("did ping frontend: %i", value);
	return (value == 43);
}

-(oneway void)childForceCrash {
	log_error("exit! child force crash");
	exit(-1);
}

-(void)selfTerminate {
	log_error("exit! self terminate");
	exit(-1);
}

-(NSString*)description {
	return [NSString stringWithFormat: 
		@"DISCOVER_CHILD\n"
		"name: %@\n"
		"parent_name: %@\n"
		"child_name: %@\n"
		"handshake: %i", 
		m_name,
		m_parent_name,
		m_child_name,
		(int)m_handshake_ok
	];
}

-(void)terminateIfNoPing {
	log_debug("terminateIfNoPing");

	if([self canPingFrontend]) {
		// everything is good. 
		// we can safe disable the watchdog now.
		disable_watchdog();
		log_info("we have connection. no need to die");
		return;
	}
	
	/*
	the frontend doesn't respond to our ping,
	we are no longer connected and not useful
	so we must kill ourselves. Otherwise we will 
	stick around like zombies.
	*/
	log_info("exit! not connected with frontend. will terminate.");
	exit(EXIT_SUCCESS);
}

@end




static mach_port_t exit_m_port = MACH_PORT_NULL;

void ExitCallback(CFMachPortRef port, void *msg, CFIndex size, void *info) {
	log_debug("SIGUSR1 processing");

	if(info == NULL) {
		log_error("exit! signal_callback expected info, got NULL");
		exit(EXIT_FAILURE);
	}
	Main* m = reinterpret_cast<Main*>(info);
	[m terminateIfNoPing];
}

void handle_sigalrm(int signo) {
	log_debug("SIGALRM caught");
	
	log_info("exit! watchdog timed out");
	exit(EXIT_SUCCESS);
}

void handle_sigusr1(int signo) {
	log_debug("SIGUSR1 caught");

	enable_watchdog();

	/*
	mach_msg is the only signal safe way we can wake up the runloop
	and check for connectivity with the frontend.
	If there are no connection we clean up and quit.
	If the runloop is hanging the SIGALRM will ensure that we quit.
	*/
	mach_msg_header_t header;
	header.msgh_bits = MACH_MSGH_BITS(MACH_MSG_TYPE_MAKE_SEND, 0);
	header.msgh_remote_port = exit_m_port;
	header.msgh_local_port = MACH_PORT_NULL;
	header.msgh_size = sizeof(header);
	header.msgh_id = 0;
	mach_msg_send(&header);
	
	log_debug("will wake up runloop");
}

void handle_objc_exception(NSException* exception) {
	log_error_objc(@"exit! uncaught exception %@", exception);
    // NSLog(@"%@", [exception reason]);
    // NSLog(@"%@", [exception userInfo]);
	exit(-1);
}

static void noteProcDeath(
	CFFileDescriptorRef fdref, 
	CFOptionFlags callBackTypes, 
	void* info) 
{
    struct kevent kev;
    int fd = CFFileDescriptorGetNativeDescriptor(fdref);
    kevent(fd, NULL, 0, &kev, 1, NULL);
    // take action on death of process here
	unsigned int dead_pid = (unsigned int)kev.ident;

    CFFileDescriptorInvalidate(fdref);
    CFRelease(fdref); // the CFFileDescriptorRef is no longer of any use in this example

	int our_pid = getpid();
	/*
	when the frontend dies we die as well.. 
	this is actually the way KCList is intended to die.
	*/
	log_info("exit! frontend process (pid %u) died. no need for us (pid %i) to stick around", dead_pid, our_pid);
	exit(EXIT_SUCCESS);
}


void init_logging() {
	global_aslclient = asl_open(NULL, NULL, 0U);
	asl_set_filter(global_aslclient, ASL_FILTER_MASK_UPTO(ASL_LEVEL_DEBUG));

	global_aslmsg = asl_new(ASL_TYPE_MSG);
    assert(global_aslmsg != NULL);

    asl_set(global_aslmsg, ASL_KEY_SENDER, "KCList Boot");
    
	if(0) {
		log_debug("this is debug");
		log_info("this is info");
		log_error("this is error");
	}
}

void close_stdout_stderr_stdin() {
/*	fprintf(stderr, "now you see me\n");
	fflush(stderr);*/

	int i;
	
	// close all open descriptors.
	for(i=getdtablesize(); i>=0; --i)
	  close(i);

	// reopen STDIN, STDOUT, STDERR to /dev/null.
	i=open("/dev/null", O_RDWR); // STDIN
	dup(i); // STDOUT
	dup(i); // STDERR

/*	fprintf(stderr, "now you dont\n");
	fflush(stderr);*/
}

int main(int argc, char** argv) {

	/*
	argv[0] = programname
	argv[1] = our assigned name
	argv[2] = connection name to get in touch with the frontend process
	argv[3] = PID of the frontend process
	*/
	if(argc < 4) {
		printf("ERROR: must be give 3 arguments: assigned_name connection_name frontend_pid\n");
		fflush(stdout);
		return EXIT_FAILURE;
	}

	
	/*
	daemonize
	*/
	
	init_logging();
	close_stdout_stderr_stdin();
	

	
	int err;
    
	log_debug("up running");

	
	/*
	to kill our daemon one can send this process a SIGUSR1 signal.
	it will then check for connectivity with the frontend process,
	if the connection is broken then we terminate.
	if the connection isn't broken then it may be an attempt at
	hijacking our signal and we refuse to die.
	*/
	struct sigaction act;
	act.sa_handler = handle_sigusr1;
	sigemptyset(&act.sa_mask);
	act.sa_flags = 0;
	if(sigaction(SIGUSR1, &act, NULL) == -1) {
		log_error("exit! can't install SIGUSR1 handler");
		exit(EXIT_FAILURE);
	}

	// we use it as our watchdog 
	act.sa_handler = handle_sigalrm;
	if(sigaction(SIGALRM, &act, NULL) == -1) {
		log_error("exit! can't install SIGALRM handler");
		exit(EXIT_FAILURE);
	}

	
	if(1) {
		for(int i=0; i<4; ++i) {
			log_debug("argv[%i] = %s\n", i, argv[i]);
		}
	}
	


	/*
	PROBLEM: when our program is started as root via launchd,
	then we will be killed if we don't change process group.
	
	SOLUTION: detach our process if we are root
	*/
	if(getuid() == 0) {
		log_debug("we run as root");

		err = setsid(); // obtain a new process group
		if(err < 0) {
			log_error("exit! setsid failed %i %i %s\n", err, (int)errno, strerror(errno));
			return EXIT_FAILURE;
		}
	} else {
		log_debug("we run as a regular user");
	}

	// atoi conversion
	int frontend_pid = strtol(argv[3], NULL, 10);
	if((frontend_pid == 0) && (errno == EINVAL)) {
		log_error("exit! frontend_pid is malformed");
		return EXIT_FAILURE;
	}

	// refuse to start if theres no process that 
	// corresponds to the specified frontend_pid
	if(is_process_running(frontend_pid) == NO) {
		log_error("exit! the frontend process (pid: %i) is not running\n", frontend_pid);
		return EXIT_FAILURE;
	}

	// setup autorelease pool
	[[NSAutoreleasePool alloc] init];

	
	/* 
	we don't want to generate a crashreport whenever our daemon 
	raises an exception related to distributed-objects, such
	as NSPortTimeoutException.
	instead we just want to die.
	*/
	NSSetUncaughtExceptionHandler(&handle_objc_exception);


	// init our Main class
	NSString* name1 = [NSString stringWithUTF8String:argv[1]];
	NSString* name2 = [NSString stringWithUTF8String:argv[2]];
	Main* main = [[Main alloc] initWithParentId:frontend_pid name:name1 parentName:name2];


	/*
	monitor the pid of the frontend
	if it dies then we commit suicide, because we are no longer needed.
	*/
	{
	    int fd = kqueue();
	    struct kevent kev;
	    EV_SET(&kev, frontend_pid, EVFILT_PROC, EV_ADD|EV_ENABLE, NOTE_EXIT, 0, NULL);
	    kevent(fd, &kev, 1, NULL, 0, NULL);
	    CFFileDescriptorRef fdref = CFFileDescriptorCreate(kCFAllocatorDefault, fd, true, noteProcDeath, NULL);
	    CFFileDescriptorEnableCallBacks(fdref, kCFFileDescriptorReadCallBack);
	    CFRunLoopSourceRef source = CFFileDescriptorCreateRunLoopSource(kCFAllocatorDefault, fdref, 0);
	    CFRunLoopAddSource(CFRunLoopGetMain(), source, kCFRunLoopDefaultMode);
	    CFRelease(source);
	}


	/*
	if we get a signal we want to wake up the runloop
	and try ping the frontend process.
	if that fails we commit suicide.
	*/
	{
		CFMachPortContext  ctx;
		ctx.version = 0;
		ctx.info = static_cast<void*>(main);
		ctx.retain = NULL;
		ctx.release = NULL;
		ctx.copyDescription = NULL;
		
		CFMachPortRef      e_port = CFMachPortCreate(NULL, ExitCallback, &ctx, NULL);
		CFRunLoopSourceRef e_rls  = CFMachPortCreateRunLoopSource(NULL, e_port, 0);		
		
		exit_m_port = CFMachPortGetPort(e_port);
		CFRunLoopAddSource(CFRunLoopGetCurrent(), e_rls, kCFRunLoopDefaultMode);
		
		CFRelease(e_rls);
	}


	/*
	update the ASL Sender name, so that we can see
	more clearly which process we are dealing with.
	If it's the process for the Left pane.. then its named "KCList left".
	And for the right pane its named "KCList right".
	*/
	{
		char buffer[20];
		snprintf(buffer, 20, "KCList %s", argv[1]);
		asl_set(global_aslmsg, ASL_KEY_SENDER, buffer);
	}


	// enter the main event loop
	[main willEnterRunloop];
	CFRunLoopRun();

	return EXIT_SUCCESS;
}
