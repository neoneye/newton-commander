/*********************************************************************
cp_main.mm - CopyApp's main loop

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#include "../cp_protocol.h"
#include "CPCopyOperation.h"
#include <unistd.h>
#include <ctime>


float seconds_since_program_start() { 
	return ( (float)clock() / (float)CLOCKS_PER_SEC );
}



@interface Main : NSObject <CopyChildProtocol> {
	NSConnection* m_connection;
	NSString* m_name;
	NSString* m_parent_name;
	NSString* m_child_name;
	id <CopyParentProtocol> m_parent;
	BOOL m_handshake_ok;
	
	NSArray* m_filenames;
	NSString* m_path;
	
	int m_ppid;
	
	CPCopyOperation* m_copy_operation;
}
-(id)initWithParentId:(int)ppid 
                 name:(NSString*)name 
           parentName:(NSString*)pname;
@end


@interface Main (Private)
-(void)initConnection;
-(void)connectToParent;
-(void)selfTerminate;
@end

@implementation Main

-(id)initWithParentId:(int)ppid name:(NSString*)name parentName:(NSString*)pname {
	self = [super init];
    if(self) {
		/*
		init is called after 0.06 seconds on my macmini 1.8 GHz
		*/
		// float seconds = seconds_since_program_start();
		// NSLog(@"Copy.app - init invoked after %.3f seconds", seconds);

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
		m_path = nil;
		
		m_copy_operation = nil;
    }
    return self;
}

-(void)applicationDidFinishLaunching:(NSNotification*)notification {
	// NSLog(@"DI %s", _cmd);
	// NSLog(@"%@", self);

	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self 
		selector:@selector(appTerminated:) 
		name:NSWorkspaceDidTerminateApplicationNotification 
		object:nil
	];
	
	[self initConnection];
	[self connectToParent];
	[m_parent parentWeAreRunning:m_child_name];
	
	[self performSelector: @selector(validateHandshake)
	           withObject: nil
	           afterDelay: 1.f];

	/*
	startup takes about 0.07 seconds on my macmini 1.8 GHz.
	*/
	// float seconds = seconds_since_program_start();
	// NSLog(@"Copy.app - start took %.3f seconds", seconds);
}

- (void)appTerminated:(NSNotification *)note {
    // NSLog(@"terminated %@\n", [note userInfo]);
	id thing = [[note userInfo] objectForKey:@"NSApplicationProcessIdentifier"];
	if([thing isKindOfClass:[NSNumber class]]) {
		NSNumber* number = (NSNumber*)thing;
		int pid = [number intValue];
		// NSLog(@"%s the pid is %@", _cmd, number);
		
		if(pid == m_ppid) {
			// NSLog(@"%s our parent has died. We must die too!", _cmd);
			exit(0);
		} else {
			// NSLog(@"%s not our parent: %i != %i", _cmd, pid, m_ppid);
		}
	}
}

-(void)validateHandshake {
	if(m_handshake_ok) {
		// NSLog(@"%s %@ OK", _cmd, m_name);
	} else {
		NSLog(@"%s %@ ERROR: handshake never took place", _cmd, m_name);
		NSLog(@"TERMINATE: %s\n%@", _cmd, self);
		[self selfTerminate];
	}
}

-(void)initConnection {
	NSConnection* con = [NSConnection defaultConnection];
	[con setRootObject:self];
	if([con registerName:m_child_name] == NO) {
		NSLog(@"ERROR: registerName was unsuccessful. child_name=%@", m_child_name);
		NSLog(@"TERMINATE: %s\n%@", _cmd, self);
		[NSApp terminate:self];
	}
	[con addRequestMode:NSEventTrackingRunLoopMode];
	[con addRequestMode:NSConnectionReplyMode];
	[con addRequestMode:NSModalPanelRunLoopMode];
	m_connection = [con retain];
}
	   
-(void)connectToParent {
	NSString* name = m_parent_name;
	NSDistantObject* obj = [NSConnection 
		rootProxyForConnectionWithRegisteredName:name
		host:nil
	];
	if(obj == nil) {
		NSLog(@"ERROR: could not connect to parent: %@", name);
		NSLog(@"TERMINATE: %s\n%@", _cmd, self);
		[self selfTerminate];
		return;
	}
	[obj retain];
	[obj setProtocolForProxy:@protocol(CopyParentProtocol)];
	id <CopyParentProtocol> proxy = (id <CopyParentProtocol>)obj;
	m_parent = proxy;
}

-(int)childPingSync:(int)value {
	// NSLog(@"%s, %i", _cmd, value);
	m_handshake_ok = YES;
	return value + 1;
}

-(oneway void)childRequest:(in bycopy NSDictionary*)arguments {
	NSLog(@"cp_main: %s      %@", _cmd, arguments);
	
	NSArray* src_names = nil;
	{
		id thing = [arguments objectForKey:@"SrcNames"];
		if([thing isKindOfClass:[NSArray class]]) {
			src_names = (NSArray*)thing;
		}
	}
	NSString* src_path = nil;
	{
		id thing = [arguments objectForKey:@"SrcPath"];
		if([thing isKindOfClass:[NSString class]]) {
			src_path = (NSString*)thing;
		}
	}
	NSString* dest_path = nil;
	{
		id thing = [arguments objectForKey:@"DestPath"];
		if([thing isKindOfClass:[NSString class]]) {
			dest_path = (NSString*)thing;
		}
	}
	
	if(src_names == nil) {
		[m_parent parentError:nil];
		return;
	}
	if(src_path == nil) {
		[m_parent parentError:nil];
		return;
	}
	if(dest_path == nil) {
		[m_parent parentError:nil];
		return;
	}
	

	{
		[m_copy_operation release];
		m_copy_operation = [[CPCopyOperation alloc] init];
		[m_copy_operation setDelegate:self];
		[m_copy_operation setTargetDir:dest_path];
		[m_copy_operation setSourceDir:src_path];
		[m_copy_operation setSourceNames:src_names];
		
		[m_copy_operation execute];
	}

}

-(void)willCopyFile {
	NSDictionary* d = [NSDictionary dictionaryWithObjectsAndKeys:
        @"WillCopy", @"ResponseType",
        [m_copy_operation currentName], @"Name", 
		nil
	];
	[self fireResponse:d];
}

-(void)updateCopyStatus {
	NSDictionary* d = [NSDictionary dictionaryWithObjectsAndKeys:
	    @"Progress", @"ResponseType",
	    [m_copy_operation currentName], @"Name", 
	    [NSNumber numberWithFloat:[m_copy_operation currentProgress]], @"Progress", 
	    [NSNumber numberWithFloat:[m_copy_operation totalProgress]], @"Progress2", 
		nil
	];
	[self fireResponse:d];
}

-(void)didCopyFile {
	NSDictionary* d = [NSDictionary dictionaryWithObjectsAndKeys:
        @"DidCopy", @"ResponseType",
        [m_copy_operation currentName], @"Name", 
		nil
	];
	[self fireResponse:d];
}

-(void)doneCopying {
	NSDictionary* d = [NSDictionary dictionaryWithObjectsAndKeys:
        @"DoneCopying", @"ResponseType",
		nil
	];
	[self fireResponse:d];

	[m_copy_operation release];
	m_copy_operation = nil;
}


-(void)fireResponse:(NSDictionary*)response {
	// NSLog(@"BEFORE %s %@", _cmd, response);
	[m_parent parentResponse:response];
	// NSLog(@"AFTER %s %@", _cmd, response);
}

-(oneway void)childRequestPath:(in bycopy NSString*)path {
	// NSLog(@"%s %@", _cmd, path);

	NSFileManager* fm = [NSFileManager defaultManager];
	
	NSError* error = nil;

	double time0 = CFAbsoluteTimeGetCurrent();
	NSArray* filenames = [fm contentsOfDirectoryAtPath:path error:&error];
	double time1 = CFAbsoluteTimeGetCurrent();
	
	if(error) {
		NSLog(@"ERROR: %@", error);
		return;
	}
	
	// NSLog(@"%s %@", _cmd, filenames);
	// NSLog(@"operation took %.3f seconds", float(time1 - time0));
	
	[m_filenames autorelease];
	m_filenames = [filenames retain];
	[m_path autorelease];
	m_path = [path retain];

	[m_parent parentWeHaveFilenames:filenames forPath:path];


	[self performSelector: @selector(obtainDirInfo)
	           withObject: nil
	           afterDelay: 0.f];
}

-(void)obtainDirInfo {
	double time0 = CFAbsoluteTimeGetCurrent();
	NSFileManager* fm = [NSFileManager defaultManager];
	
	NSString* path = m_path;


	NSMutableArray* ary = [NSMutableArray arrayWithCapacity:[m_filenames count]]; 

    NSNumber* number_no = [NSNumber numberWithBool:NO];
    NSNumber* number_yes = [NSNumber numberWithBool:YES];

	id thing;
	NSEnumerator* en = [m_filenames objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[NSString class]]) {
			NSString* name = (NSString*)thing;
			NSString* file_path = [path stringByAppendingPathComponent:name];

			BOOL isdir = NO;
			BOOL ok = [fm fileExistsAtPath:file_path isDirectory:&isdir];
			[ary addObject:(ok && isdir) ? number_yes : number_no];
		}
	}
	
	// NSLog(@"%s dirs: %@", _cmd, ary);
	NSArray* result = [[ary copy] autorelease];

	double time1 = CFAbsoluteTimeGetCurrent();
	// NSLog(@"operation took %.3f seconds", float(time1 - time0));

	
	[m_parent parentWeHaveDirInfo:result forPath:path];

	[self performSelector: @selector(obtainSizes)
	           withObject: nil
	           afterDelay: 0.f];
}

-(void)obtainSizes {
	double time0 = CFAbsoluteTimeGetCurrent();
	NSFileManager* fm = [NSFileManager defaultManager];
	
	NSString* path = m_path;


	NSMutableArray* ary = [NSMutableArray arrayWithCapacity:[m_filenames count]]; 

    NSNumber* filesize_zero = [NSNumber numberWithUnsignedLongLong:0];

	id thing;
	NSEnumerator* en = [m_filenames objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[NSString class]]) {
			NSString* name = (NSString*)thing;
			NSString* file_path = [path stringByAppendingPathComponent:name];

			NSDictionary* attr = [fm fileAttributesAtPath:file_path
			 	traverseLink:YES];		

		    NSNumber* filesize = filesize_zero;
			if(attr != nil) {
			    if(filesize = [attr objectForKey:NSFileSize]) {
			        // NSLog(@"File size: %qi\n", [filesize unsignedLongLongValue]);
			    } else {
					NSLog(@"ERROR: no filesize key for path: %@", file_path);
				}
			}
			[ary addObject:filesize];
		}
	}
	
	// NSLog(@"%s sizes: %@", _cmd, ary);
	NSArray* result = [[ary copy] autorelease];

	double time1 = CFAbsoluteTimeGetCurrent();
	// NSLog(@"operation took %.3f seconds", float(time1 - time0));
	
	[m_parent parentWeHaveSizes:result forPath:path];
	
	[m_parent parentWeAreDone];
}

-(oneway void)childForceCrash {
	NSLog(@"DI %s", _cmd);
	exit(-1);
}

-(void)selfTerminate {
	NSLog(@"DI %s", _cmd);
	[NSApp terminate:self];
}

-(NSString*)description {
	return [NSString stringWithFormat: 
		@"Copy_CHILD\n"
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

@end


int main(int argc, char** argv) {
	/*
	argv[0] = programname
	argv[1] = module name
	argv[2] = unique connection name to get in touch with the parent process
	*/
	if(argc < 3) {
		printf("ERROR: must be give two arguments: name parentname\n");
		fflush(stdout);
		return -1;
	}

	int ppid = (int)getppid();
	
	[[NSAutoreleasePool alloc] init];
	[NSApplication sharedApplication];
	NSString* name1 = [NSString stringWithUTF8String:argv[1]];
	NSString* name2 = [NSString stringWithUTF8String:argv[2]];
	Main* main = [[Main alloc] initWithParentId:ppid name:name1 parentName:name2];
	[NSApp setDelegate:main];
	[[NSApplication sharedApplication] run];
	return 0;
}
