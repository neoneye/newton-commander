/*********************************************************************
KCReport.mm - encapsulates the background ReportApp in a thread

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#include "KCReport.h"
#include "KCReportThread.h"


@interface KCReport (Private)
@end

@implementation KCReport

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
		m_report_thread = nil;
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
	NSAssert(m_report_thread == nil, @"wrthread is already initialized");

	// NSLog(@"%@ %s starting Wrapper", m_name, _cmd);

	KCReportThread* wr = [[KCReportThread alloc] initWithName:m_name path:m_path_to_child_executable];
	m_report_thread = wr;
	
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
		@"KCReport\n"
		"name: %@\n",
		m_name
	];
}

-(void)didLaunch {
	if([m_delegate respondsToSelector:@selector(reportDidLaunch)]) {
		[m_delegate reportDidLaunch];
	}
}

-(void)requestPath:(NSString*)path {
	// NSLog(@"KCReport %s path: %@ BEFORE", _cmd, path);
	[m_report_thread performSelector:@selector(threadRequestPath:) 
	                   onThread:m_thread 
	                 withObject:path
	              waitUntilDone:NO
	];
	// NSLog(@"KCReport %s AFTER", _cmd);
}

-(void)nowProcessingRequest {
	// NSLog(@"KCReport %s BEFORE", _cmd);
	if([m_delegate respondsToSelector:@selector(reportIsNowProcessingTheRequest)]) {
		[m_delegate reportIsNowProcessingTheRequest];
	}
	// NSLog(@"KCReport %s AFTER", _cmd);
}

-(void)hasData:(NSData*)data {
	// NSLog(@"KCReport %s BEFORE", _cmd);
	if([m_delegate respondsToSelector:@selector(reportHasData:)]) {
		[m_delegate reportHasData:data];
	}
	// NSLog(@"KCReport %s AFTER", _cmd);
}

-(void)dealloc {
	// NSLog(@"%s", _cmd);
	[m_thread release];
	
	[m_report_thread release];
	
	[m_name release];
	[m_path_to_child_executable release];
    [super dealloc];
}

@end
