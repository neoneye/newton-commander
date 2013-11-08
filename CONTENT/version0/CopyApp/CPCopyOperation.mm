/*********************************************************************
CPCopyOperation.mm - lowlevel copy

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#include "CPCopyOperation.h"


@interface CPCopyOperation (Private)
-(void)setCurrentName:(NSString*)v;
@end

@implementation CPCopyOperation

-(id)init {
	self = [super init];
    if(self) {
		m_delegate = nil;
		
		m_current_bytes_to_copy = 0;
		m_current_bytes_copied = 0;
		m_total_bytes_to_copy = 0;
		m_total_bytes_copied = 0;

		m_target_dir = nil;
		m_source_dir = nil;
		m_source_names = nil;
		
		m_current_name = nil;
		m_current_progress = 0;       
		m_total_progress = 0;
		
		m_cp_task = nil;
    }
    return self;
}

-(void)setDelegate:(id)delegate { m_delegate = delegate; }
-(id)delegate { return m_delegate; }

-(void)setTargetDir:(NSString*)v { [v copy]; [m_target_dir release]; m_target_dir = v; }

-(void)setSourceDir:(NSString*)v { [v copy]; [m_source_dir release]; m_source_dir = v; }

-(void)setSourceNames:(NSArray*)v { [v copy]; [m_source_names release]; m_source_names =
v; }

-(void)setCurrentName:(NSString*)v { [v copy]; [m_current_name release]; m_current_name
= v; }
-(NSString*)currentName { return m_current_name; }


-(float)currentProgress { return m_current_progress; }
-(float)totalProgress { return m_total_progress; }

-(void)execute {
	NSAssert(m_source_names != nil, @"source_names must be provided");
	NSAssert(m_source_dir != nil, @"source_dir must be provided");
	NSAssert(m_target_dir != nil, @"target_dir must be provided");
	
	// NSLog(@"CPCopyOperation %s", _cmd);

	m_total_progress = 0;
	m_current_progress = 0;

	id thing;
	NSEnumerator* en = [m_source_names objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[NSString class]] == NO) {
			continue;
		}
		NSString* name = (NSString*)thing;
		[self setCurrentName:name];
		
		[m_delegate willCopyFile];
		
		for(int i=0; i<100; ++i) {
			usleep(10000);
			float p = (float)i / 100.f;
			m_current_progress = p;
			m_total_progress += 0.01f;
			
			[m_delegate updateCopyStatus];
		}

		[m_delegate didCopyFile];
	}

	[m_delegate doneCopying];
}

#if 0
-(void)launchCp {
	if(m_task != nil) {
		NSLog(@"CPCopyOperation %s ERROR: m_task already started", _cmd);
		return;
	}
	
	NSString* path = @"/bin/cp";
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
		NSLog(@"CPCopyOperation "
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
}
#endif

-(void)dealloc {
	[m_cp_task release];
	[m_target_dir release];
	[m_source_dir release];
	[m_source_names release];
	[m_current_name release];
    [super dealloc];
}

@end
