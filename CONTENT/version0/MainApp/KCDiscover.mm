/*********************************************************************
KCDiscover.mm - encapsulates the background DiscoverApp in a thread

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#include "KCDiscover.h"
#include "KCDiscoverThread.h"
#include <sched.h>

@interface KCDiscover (Private)
@end

@implementation KCDiscover

-(id)initWithName:(NSString*)name path:(NSString*)path auth:(AuthorizationRef)auth {
	self = [super init];
    if(self) {
		// NSLog(@"%@ Wrapper init: %@", name, path);
		NSAssert(name != nil, @"a name must be given");
		NSAssert(path != nil, @"a path to the KCList must be given");

		m_auth = auth;

		m_name = [name copy];
		m_path_to_child_executable = [path copy];
		m_delegate = nil;
		m_thread = nil;
		m_discover_thread = nil;
		
		for(int i=0; i<DISCOVER_NUMBER_OF_TIMESTAMPS; ++i) {
			m_timestamps[i] = 0;
		}
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
	NSAssert(m_discover_thread == nil, @"wrthread is already initialized");

	// NSLog(@"%@ %s starting Wrapper", m_name, _cmd);
	
	KCDiscoverThread* wr = [[KCDiscoverThread alloc] initWithName:m_name path:m_path_to_child_executable auth:m_auth];
	m_discover_thread = wr;
	
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
		@"KCDiscover\n"
		"name: %@\n",
		m_name
	];
}

-(void)didLaunch {
	if([m_delegate respondsToSelector:@selector(discoverDidLaunch)]) {
		[m_delegate discoverDidLaunch];
	}
}

-(void)requestPath:(NSString*)path transactionId:(int)tid {
	// NSLog(@"KCDiscover %s path: %@", _cmd, path);
	m_timestamps[DISCOVER_TIMESTAMPS_REQUEST] = CFAbsoluteTimeGetCurrent();

	id obj = m_discover_thread;
	SEL mySelector = @selector(threadRequestPath:transactionId:);


	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:mySelector]];
	[inv setTarget:obj];
	[inv setSelector:mySelector];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	[inv setArgument:&path atIndex:2]; 
	[inv setArgument:&tid atIndex:3]; 
	[inv retainArguments];

	[inv performSelector:@selector(invoke) 
    	onThread:m_thread 
		withObject:nil 
		waitUntilDone:NO];

	/*
	NOTE: we can allow the other thread to run immediately
	with sched_yield(); However it has little effect if any at all.
	*/
	// sched_yield();
}

-(void)nowProcessingRequest:(double)timestamp {
	// NSLog(@"%s called!", _cmd);
	m_timestamps[DISCOVER_TIMESTAMPS_INITIATED] = timestamp;
	if([m_delegate respondsToSelector:@selector(discoverIsNowProcessingTheRequest)]) {
		[m_delegate discoverIsNowProcessingTheRequest];
	}
}

-(void)hasName:(NSData*)data transactionId:(int)tid {
	m_timestamps[DISCOVER_TIMESTAMPS_HAS_NAME] = CFAbsoluteTimeGetCurrent();
	// NSLog(@"%s: %i", _cmd, tid);
	if([m_delegate respondsToSelector:@selector(discoverHasName:transactionId:)]) {
		[m_delegate discoverHasName:data transactionId:tid];
	}
}

-(void)hasType:(NSData*)data transactionId:(int)tid {
	m_timestamps[DISCOVER_TIMESTAMPS_HAS_TYPE] = CFAbsoluteTimeGetCurrent();
	// NSLog(@"%s: %i", _cmd, tid);
	if([m_delegate respondsToSelector:@selector(discoverHasType:transactionId:)]) {
		[m_delegate discoverHasType:data transactionId:tid];
	}
}

-(void)hasStat:(NSData*)data transactionId:(int)tid {
	m_timestamps[DISCOVER_TIMESTAMPS_HAS_STAT] = CFAbsoluteTimeGetCurrent();
	// NSLog(@"%s  tid: %i  data: %@", _cmd, tid, data);
	if([m_delegate respondsToSelector:@selector(discoverHasStat:transactionId:)]) {
		[m_delegate discoverHasStat:data transactionId:tid];
	}
}

-(void)hasAlias:(NSData*)data transactionId:(int)tid {
	m_timestamps[DISCOVER_TIMESTAMPS_HAS_ALIAS] = CFAbsoluteTimeGetCurrent();
	// NSLog(@"%s  tid: %i  data: %@", _cmd, tid, data);
	if([m_delegate respondsToSelector:@selector(discoverHasAlias:transactionId:)]) {
		[m_delegate discoverHasAlias:data transactionId:tid];
	}
}

-(void)completedTransactionId:(int)tid {
	m_timestamps[DISCOVER_TIMESTAMPS_COMPLETED] = CFAbsoluteTimeGetCurrent();
	// NSLog(@"%s: %i", _cmd, tid);
	
#if 0	
	double t0 = m_timestamps[DISCOVER_TIMESTAMPS_INITIATED];
	t0 -= m_timestamps[DISCOVER_TIMESTAMPS_REQUEST];
	double t1 = m_timestamps[DISCOVER_TIMESTAMPS_HAS_NAME];
	t1 -= m_timestamps[DISCOVER_TIMESTAMPS_INITIATED];
	double t2 = m_timestamps[DISCOVER_TIMESTAMPS_HAS_TYPE];
	t2 -= m_timestamps[DISCOVER_TIMESTAMPS_HAS_NAME];
	double t3 = m_timestamps[DISCOVER_TIMESTAMPS_HAS_STAT];
	t3 -= m_timestamps[DISCOVER_TIMESTAMPS_HAS_TYPE];
	double t4 = m_timestamps[DISCOVER_TIMESTAMPS_HAS_ALIAS];
	t4 -= m_timestamps[DISCOVER_TIMESTAMPS_HAS_STAT];
	double t5 = m_timestamps[DISCOVER_TIMESTAMPS_COMPLETED];
	t5 -= m_timestamps[DISCOVER_TIMESTAMPS_HAS_ALIAS];
	double total = m_timestamps[DISCOVER_TIMESTAMPS_COMPLETED];
	total -= m_timestamps[DISCOVER_TIMESTAMPS_REQUEST];
	NSLog(@"PROFILE: init %.3f  name %.3f  type %.3f  stat %.3f  alias %.3f  done %.3f  ---  total %.3f", 
		t0, t1, t2, t3, t4, t5, total);
#endif
}


-(void)dealloc {
	[m_thread release];
	
	[m_discover_thread release];
	
	[m_name release];
	[m_path_to_child_executable release];
    [super dealloc];
}

@end
