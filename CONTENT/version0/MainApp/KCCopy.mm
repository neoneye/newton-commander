/*********************************************************************
KCCopy.mm - encapsulates the background CopyApp in a thread

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#include "KCCopy.h"
#include "KCCopyThread.h"


@interface KCCopy (Private)
@end

@implementation KCCopy

-(id)initWithName:(NSString*)name path:(NSString*)path {
	self = [super init];
    if(self) {
		// NSLog(@"%@ Wrapper init: %@", name, path);
		NSAssert(name != nil, @"a name must be given");
		NSAssert(path != nil, @"a path to the Discover.app must be given");

		m_name = [name copy];
		m_path_to_child_executable = [path copy];
		m_delegate = nil;
		m_thread = nil;
		m_copy_thread = nil;

		m_source_names = nil;
		m_source_path = nil;
		m_target_path = nil;
    }
    return self;
}

-(void)setDelegate:(id)delegate { m_delegate = delegate; }
-(id)delegate { return m_delegate; }

-(void)start {
	if(m_thread != nil) {
		return;
	}
	NSAssert(m_thread == nil, @"this thread must only be started once");
	NSAssert(m_copy_thread == nil, @"wrthread is already initialized");

	// NSLog(@"%@ %s starting Wrapper", m_name, _cmd);

	KCCopyThread* wr = [[KCCopyThread alloc] initWithName:m_name path:m_path_to_child_executable];
	m_copy_thread = wr;
	
	[wr setMainThreadDelegate:self];

	NSThread* t = [[NSThread alloc] 
		initWithTarget:wr
              selector:@selector(threadMainRoutine)
                object:nil
	];
	m_thread = t;

	[t setName:m_name];
	
	[t start];
	// NSLog(@"%s did start", _cmd);
}

-(NSString*)description {
	return [NSString stringWithFormat: 
		@"KCCopy\n"
		"name: %@\n",
		m_name
	];
}

-(void)didLaunch {
	if([m_delegate respondsToSelector:@selector(processDidLaunch)]) {
		[m_delegate processDidLaunch];
	}
}

-(void)requestPath:(NSString*)path {
	// NSLog(@"KCReport %s path: %@ BEFORE", _cmd, path);
	[m_copy_thread performSelector:@selector(threadRequestPath:) 
	                   onThread:m_thread 
	                 withObject:path
	              waitUntilDone:NO
	];
	// NSLog(@"KCCopy %s AFTER", _cmd);
}

-(void)setNames:(NSArray*)v {
 	v = [v copy]; 
	[m_source_names release]; 
	m_source_names = v;
}

-(void)setSourcePath:(NSString*)v {
 	v = [v copy]; 
	[m_source_path release]; 
	m_source_path = v;
}

-(void)setTargetPath:(NSString*)v {
 	v = [v copy]; 
	[m_target_path release]; 
	m_target_path = v;
}

-(NSString*)sourcePath { return m_source_path; }
-(NSString*)targetPath { return m_target_path; }


-(void)startCopyOperation {
	NSLog(@"KCCopy %s", _cmd);
	
#if 0
	NSString* dest_path = @"/tmp/dest_dir";
	NSString* src_path = @"/tmp/src_dir";
	NSArray* src_names = [NSArray arrayWithObjects:
		@"file1", @"file2", @"file3", nil];
	NSDictionary* arguments = [NSDictionary dictionaryWithObjectsAndKeys:
        dest_path, @"DestPath",
        src_path,  @"SrcPath", 
        src_names, @"SrcNames", 
		nil
	];
#else
	NSDictionary* arguments = [NSDictionary dictionaryWithObjectsAndKeys:
        m_target_path, @"DestPath",
        m_source_path, @"SrcPath", 
        m_source_names, @"SrcNames", 
		nil
	];
#endif
	[m_copy_thread performSelector:@selector(threadRequest:) 
	                   onThread:m_thread 
	                 withObject:arguments
	              waitUntilDone:NO
	];
}

-(void)nowProcessingRequest {
	// NSLog(@"KCCopy %s BEFORE", _cmd);
	if([m_delegate respondsToSelector:@selector(reportIsNowProcessingTheRequest)]) {
		[m_delegate reportIsNowProcessingTheRequest];
	}
	// NSLog(@"KCCopy %s AFTER", _cmd);
}

-(void)hasData:(NSData*)data {
	// NSLog(@"KCCopy %s BEFORE", _cmd);
	if([m_delegate respondsToSelector:@selector(reportHasData:)]) {
		[m_delegate reportHasData:data];
	}
	// NSLog(@"KCCopy %s AFTER", _cmd);
}

-(void)response:(NSDictionary*)response {
	// NSLog(@"KCCopy %s %@", _cmd, response);
	NSString* response_type = nil;
	{
		id thing = [response objectForKey:@"ResponseType"];
		if([thing isKindOfClass:[NSString class]]) {
			response_type = (NSString*)thing;
		}
	}

	if([response_type isEqual:@"Progress"]) {
		NSString* filename = nil;
		{
			id thing = [response objectForKey:@"Name"];
			if([thing isKindOfClass:[NSString class]]) {
				filename = (NSString*)thing;
			}
		}
		float progress = -1;
		{
			id thing = [response objectForKey:@"Progress"];
			if([thing isKindOfClass:[NSNumber class]]) {
				progress = [(NSNumber*)thing floatValue];
			}
		}
		if((filename != nil) && (progress >= 0)) {
			if([m_delegate respondsToSelector:@selector(copyProgress:name:)]) {
				[m_delegate copyProgress:progress name:filename];
			}
		}
		return;
	}

	if([response_type isEqual:@"DidCopy"]) {
		NSString* filename = nil;
		{
			id thing = [response objectForKey:@"Name"];
			if([thing isKindOfClass:[NSString class]]) {
				filename = (NSString*)thing;
			}
		}
		if(filename != nil) {
			if([m_delegate respondsToSelector:@selector(didCopy:)]) {
				[m_delegate didCopy:filename];
			}
		}
		return;
	}

	if([response_type isEqual:@"WillCopy"]) {
		NSString* filename = nil;
		{
			id thing = [response objectForKey:@"Name"];
			if([thing isKindOfClass:[NSString class]]) {
				filename = (NSString*)thing;
			}
		}
		if(filename != nil) {
			if([m_delegate respondsToSelector:@selector(willCopy:)]) {
				[m_delegate willCopy:filename];
			}
		}
		return;
	}

	if([response_type isEqual:@"DoneCopying"]) {
		if([m_delegate respondsToSelector:@selector(doneCopying)]) {
			[m_delegate doneCopying];
		}
		return;
	}

	NSLog(@"KCCopy %s ERROR: unknown response type: %@\n%@", 
		_cmd, response_type, response);
}


-(void)dealloc {
	// NSLog(@"%s", _cmd);
	[m_thread release];
	
	[m_copy_thread release];
	
	[m_name release];
	[m_path_to_child_executable release];
	
	[m_source_names release];
	[m_source_path release];
	[m_target_path release];
	
    [super dealloc];
}

@end
