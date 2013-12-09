//
//  sc_transfer.m
//  SharedCode Core+Worker
//
//  Created by Simon Strandgaard on 23/07/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "NCLog.h"
#import "sc_transfer.h"
#import "sc_traversal_objects.h"
#import "sc_tov_print.h"
#import "sc_tov_copier.h"
#import "sc_scanner.h"
#import "NCTimeProfiler.h"
#include <mach/mach_time.h>




#pragma mark -
#pragma mark TransferOperationThread Class


@interface TransferOperationThread : NSThread {
	TransferOperation* m_transfer_operation;
	NSArray* m_names;
	NSString* m_from_dir;
	NSString* m_to_dir;
	unsigned long long m_bytes_total; // filesize in bytes
	unsigned long long m_count_total; // number of items
	NSMutableArray* m_queue_pending;
	NSMutableArray* m_queue_completed;
	TOVCopier* m_copier;
	uint64_t m_start_time;
	double m_elapsed_limit_triggers_progress;

	// YES=move operation. NO=copy operation
	BOOL m_is_move;
}
@property (retain) NSArray* names;
@property (retain) NSString* fromDir;
@property (retain) NSString* toDir;
@property (assign) unsigned long long bytesTotal;
@property (assign) unsigned long long countTotal;
@property (retain) NSMutableArray* queuePending;
@property (retain) NSMutableArray* queueCompleted;
@property (retain) TOVCopier* copier;
@property BOOL isMove;

-(id)initWithTransferOperation:(TransferOperation*)transfer_operation isMove:(BOOL)is_move;

-(void)prepareForTransfer:(NSDictionary*)dict;
-(void)performScan;                    
-(void)performOperation;
-(void)abortOperation;

-(void)dump;

-(void)sendResponse:(NSDictionary*)dict forKey:(NSString*)key;

@end // class TransferOperationThread


@implementation TransferOperationThread

@synthesize names = m_names;
@synthesize fromDir = m_from_dir;
@synthesize toDir = m_to_dir;
@synthesize bytesTotal = m_bytes_total;
@synthesize countTotal = m_count_total;
@synthesize queuePending = m_queue_pending;
@synthesize queueCompleted = m_queue_completed;
@synthesize copier = m_copier;
@synthesize isMove = m_is_move;

-(id)initWithTransferOperation:(TransferOperation*)transfer_operation isMove:(BOOL)is_move {
    self = [super init];
    if(self != nil) {
		m_transfer_operation = transfer_operation;
		NSAssert(m_transfer_operation, @"must be initialized");
		
		m_is_move = is_move;

		self.queuePending   = [NSMutableArray arrayWithCapacity:1000];
		self.queueCompleted = [NSMutableArray arrayWithCapacity:1000];
    }
    return self;
}

-(void)main {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	// LOG_DEBUG(@"TransferOperationThread.main - enter");
	
	/*
	for now the TransferOperationThread is a singleton class, no simultaneous transfers. 
	The thread can't be stopped when first it's started. It could make it stoppable, 
	but it takes time and effort to code.
	
	So since we want it to be a non-stoppable thread then we 
	add a dummy input source to prevent the runloop from exiting.
	*/
	[[NSRunLoop currentRunLoop] addPort:[NSPort port] forMode:NSDefaultRunLoopMode];

	[[NSRunLoop currentRunLoop] run];

	LOG_DEBUG(@"RunLoop exited, thread is stopping");
	[pool release];
}

-(void)prepareForTransfer:(NSDictionary*)dict {
	// LOG_DEBUG(@"dict: %@", dict);
	
	self.names   = [dict objectForKey:@"names"];
	self.fromDir = [dict objectForKey:@"fromDir"];
	self.toDir   = [dict objectForKey:@"toDir"];
}

-(void)performScan {
	NSAssert(m_names, @"names must be initialized");
	NSAssert(m_from_dir, @"fromDir must be initialized");
	NSAssert(m_to_dir, @"toDir must be initialized");
	
	[m_queue_pending removeAllObjects];
	[m_queue_completed removeAllObjects];
	
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	TraversalScanner* maker = [[[TraversalScanner alloc] init] autorelease];

	NSString* name;
	NSEnumerator* en = [m_names objectEnumerator];
	while(name = [en nextObject]) { 
		
		unsigned long long bytes_total0 = [maker bytesTotal];
		unsigned long long count_total0 = [maker countTotal];
		
		{
			TOProgressBefore* obj = [[[TOProgressBefore alloc] init] autorelease];
			[obj setName:name];
			[maker addObject:obj];
		}

		[maker appendTraverseDataForPath:[m_from_dir stringByAppendingPathComponent:name]];

		{
			TOProgressAfter* obj = [[[TOProgressAfter alloc] init] autorelease];
			[obj setName:name];
			[maker addObject:obj];
		}

		unsigned long long bytes_total1 = [maker bytesTotal];
		unsigned long long count_total1 = [maker countTotal];

		unsigned long long bytes_item = bytes_total1 - bytes_total0;
		unsigned long long count_item = count_total1 - count_total0;



        /*
		TODO: update scan-progress
		TODO: poll max 10 times per second some counters protected with a mutex.. run it in a thread
		*/

		NSNumber* bytesTotal = [NSNumber numberWithUnsignedLongLong:[maker bytesTotal]];
		NSNumber* countTotal = [NSNumber numberWithUnsignedLongLong:[maker countTotal]];
		NSNumber* bytesItem = [NSNumber numberWithUnsignedLongLong:bytes_item];
		NSNumber* countItem = [NSNumber numberWithUnsignedLongLong:count_item];

		NSArray* keys = [NSArray arrayWithObjects:@"bytesTotal", @"countTotal", @"name", @"bytesItem", @"countItem", nil];
		NSArray* objects = [NSArray arrayWithObjects:bytesTotal, countTotal, name, bytesItem, countItem, nil];
		NSDictionary* dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	
		[self sendResponse:dict forKey:@"scan-progress"];
	}

	[m_queue_pending addObjectsFromArray:[maker traversalObjects]];
	m_bytes_total = [maker bytesTotal];
	m_count_total = [maker countTotal];

	{
		NSNumber* bytesTotal = [NSNumber numberWithUnsignedLongLong:[maker bytesTotal]];
		NSNumber* countTotal = [NSNumber numberWithUnsignedLongLong:[maker countTotal]];
		NSArray* keys = [NSArray arrayWithObjects:@"bytesTotal", @"countTotal", nil];
		NSArray* objects = [NSArray arrayWithObjects:bytesTotal, countTotal, nil];
		NSDictionary* dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	
		[self sendResponse:dict forKey:@"scan-complete"];
	}
	
	[pool release];
}

-(void)performOperation {
	NSAssert(m_queue_pending, @"pending queue must be initialized. PerformScan must be invoked before PerformCopy.");
	NSAssert(m_queue_completed, @"completed queue must be initialized. PerformScan must be invoked before PerformCopy.");
	NSAssert(m_names, @"names must be initialized");
	NSAssert(m_from_dir, @"fromDir must be initialized");
	NSAssert(m_to_dir, @"toDir must be initialized");
	
	m_start_time = mach_absolute_time();
	m_elapsed_limit_triggers_progress = 0;

	TOVCopier* v = [[[TOVCopier alloc] init] autorelease];
	[v setSourcePath:m_from_dir];
	[v setTargetPath:m_to_dir];
	self.copier = v;

	[self performSelector: @selector(processNext)
	           withObject: nil
	           afterDelay: 0.f];
}

-(void)processNext {
	NSAssert(m_copier, @"copier must be initialized. performCopy must be invoked before processNext.");
	NSAssert(m_queue_pending, @"pending queue must be initialized. performCopy must be invoked before processNext.");
	NSAssert(m_queue_completed, @"completed queue must be initialized. performCopy must be invoked before processNext.");

	unsigned int n_pending = [m_queue_pending count];
	if(n_pending == 0) {
		return;
	}
	
	
#if 1
	if(m_is_move) {
		/*
		TODO: Implement the "MOVE" operation within the TransferOperationThread class
	    I'm always too tired to code it.. but this time I think I have made all the 
		necessary preparations, so hopefully it's just to code it? (hopes for the best)
		*/
		LOG_ERROR(@"not yet implemented");

		float progress = 0.5;              
		float bytes_per_second = 0.842;
		float time_remaining = 10.3;
		unsigned long long bytes = 500;
		unsigned long long bytes_total = 1000;

		NSArray* keys = [NSArray arrayWithObjects:@"progress", @"bytes", @"bytes_total", @"bytes_per_second", @"time_remaining", nil];
		NSArray* objects = [NSArray arrayWithObjects:[NSNumber numberWithFloat:progress], [NSNumber numberWithUnsignedLongLong:bytes], [NSNumber numberWithUnsignedLongLong:bytes_total], [NSNumber numberWithDouble:bytes_per_second], [NSNumber numberWithDouble:time_remaining], nil];
		NSDictionary* dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	
		[self sendResponse:dict forKey:@"transfer-progress"];
		return;
	}
#endif

	unsigned int n_completed = [m_queue_completed count];
	unsigned int n_total = n_pending + n_completed;

	
	TOVCopier* v = m_copier;
	id thing = [m_queue_pending objectAtIndex:0];

#if 0
	if(m_is_move) {
		if([thing isKindOfClass:[TOFile class]]) {
			TOFile* tofile = (TOFile*)thing;
			NSString* path = [tofile path];
			NSString* source_path1 = path;
			NSString* target_path1 = [v convert:path];
			const char* source_path = [source_path1 fileSystemRepresentation];
			const char* target_path = [target_path1 fileSystemRepresentation];
			LOG_INFO(@"will rename: %s -> %s", source_path, target_path);
			if(rename(source_path, target_path)) {
				LOG_ERROR(@"error occurred while renaming: %@ -> %@", source_path1, target_path1);
				return;
			}
			LOG_INFO(@"rename successful");
		}
	}
#endif

	/*
	perform the copy operation of this item
	*/
#if 1
	[thing accept:v]; 
	
	NSUInteger code = [v statusCode];
	if(code != kCopierStatusOK) {
		NSString* message = [v statusMessage];
		LOG_ERROR(@"ERROR OCCURED WHILE COPYING: CODE=0x%04x. Aborting operation!\n%@", (int)code, message);

		NSArray* keys = [NSArray arrayWithObjects:@"message", @"code", nil];
		NSArray* objects = [NSArray arrayWithObjects:message, [NSNumber numberWithUnsignedInt:code], nil];
		NSDictionary* dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	
		[self sendResponse:dict forKey:@"transfer-alert"];
		return;
	}
#endif


    /*
	update progress status for tableviewitems 
	*/
	if([thing isKindOfClass:[TOProgressBefore class]]) {
		TOProgressBefore* to = (TOProgressBefore*)thing;

		NSArray* keys = [NSArray arrayWithObjects:@"name", @"message", nil];
		NSArray* objects = [NSArray arrayWithObjects:[to name], @"Copying…", nil];
		NSDictionary* dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	
		[self sendResponse:dict forKey:@"transfer-progress-item"];
	} else
	if([thing isKindOfClass:[TOProgressAfter class]]) {
		TOProgressAfter* to = (TOProgressAfter*)thing;

		NSArray* keys = [NSArray arrayWithObjects:@"name", @"message", nil];
		NSArray* objects = [NSArray arrayWithObjects:[to name], @"DONE", nil];
		NSDictionary* dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	
		[self sendResponse:dict forKey:@"transfer-progress-item"];
	}


    /*
	update progressbar approx 10 times per second, 
	so we don't waste a lot of processing power
	*/
	uint64_t t_stop = mach_absolute_time();
	double elapsed = subtract_times(t_stop, m_start_time);
	if(elapsed > m_elapsed_limit_triggers_progress) {
		m_elapsed_limit_triggers_progress = elapsed + 0.1; // 10 times per second


		unsigned long long bytes = [v bytesCopied];

		/*
		progress is computed as 80% of the amount of bytes transfered so far
		                    and 20% of the number of items transfered so far
		*/
		float progress0_f = 0;
		if(m_bytes_total >= 1) {
			progress0_f = (float)bytes / (float)m_bytes_total;
		}
		float progress1_f = 0;
		if(n_total >= 1) {
			progress1_f = (float)n_completed / (float)n_total;
		}
		float progress = progress0_f * 0.8 + progress1_f * 0.2;

		double bytes_per_second = 0;
		if(elapsed > 0.1) bytes_per_second = bytes / elapsed;
		
		double time_remaining = -1000; // negative values means that it will take forever to complete
		if(bytes >= m_bytes_total) {
			time_remaining = 0;
		} else
		if(bytes_per_second > 1) {
			time_remaining = (m_bytes_total - bytes) / bytes_per_second;
		}

		NSArray* keys = [NSArray arrayWithObjects:@"progress", @"bytes", @"bytes_total", @"bytes_per_second", @"time_remaining", nil];
		NSArray* objects = [NSArray arrayWithObjects:[NSNumber numberWithFloat:progress], [NSNumber numberWithUnsignedLongLong:bytes], [NSNumber numberWithUnsignedLongLong:m_bytes_total], [NSNumber numberWithDouble:bytes_per_second], [NSNumber numberWithDouble:time_remaining], nil];
		NSDictionary* dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	
		[self sendResponse:dict forKey:@"transfer-progress"];
	} // if


	// everything went well, move thing from pending queue to completed queue
	[m_queue_completed addObject:thing];
	[m_queue_pending removeObjectAtIndex:0];


	/*
	if we just processed the last element then
	send out a notification that copy has finished
	*/
	if([m_queue_pending count] == 0) {
		uint64_t t_stop = mach_absolute_time();
		double elapsed = subtract_times(t_stop, m_start_time);

		unsigned long long bytes = [v bytesCopied];

		double bytes_per_second = 0;
		if(elapsed > 0.1) bytes_per_second = bytes / elapsed;

		NSArray* keys = [NSArray arrayWithObjects:@"elapsed", @"bytes", @"bytes_per_second", nil];
		NSArray* objects = [NSArray arrayWithObjects:[NSNumber numberWithDouble:elapsed], [NSNumber numberWithUnsignedLongLong:bytes], [NSNumber numberWithDouble:bytes_per_second], nil];
		NSDictionary* dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	
		[self sendResponse:dict forKey:@"transfer-complete"];
	}


	// proceed with next element
	[self performSelector: @selector(processNext)
	           withObject: nil
	           afterDelay: 0.f];
}

-(void)abortOperation {
	unsigned int n_pending = [m_queue_pending count];
	unsigned int n_completed = [m_queue_completed count];

	[m_queue_pending removeAllObjects];
	[m_queue_completed removeAllObjects];
	
	LOG_DEBUG(@"operation aborted. number of pending: %i   number of completed: %i", (int)n_pending, (int)n_completed);
}

-(void)dump {
	NSArray* ary = m_queue_pending;
	NSAssert(ary, @"traversal object array must be initialized");

	TOVPrint* v = [[[TOVPrint alloc] init] autorelease];
	[v setSourcePath:m_from_dir];
	[v setTargetPath:m_to_dir];

	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) { [thing accept:v]; }
	
	LOG_DEBUG(@"result: %@", [v result]);
}

-(void)sendResponse:(NSDictionary*)dict forKey:(NSString*)key {
    dispatch_async(dispatch_get_main_queue(), ^{
		[m_transfer_operation threadResponse:dict forKey:key];
	});
}

@end // class TransferOperationThread





#pragma mark -
#pragma mark TransferOperation Class


@interface TransferOperation ()
-(void)createAndStartThread;
@end

@implementation TransferOperation

@synthesize delegate = m_delegate;
@synthesize names = m_names;
@synthesize fromDir = m_from_dir;
@synthesize toDir = m_to_dir;
@synthesize isMove = m_is_move;

+(TransferOperation*)copyOperation {
	TransferOperation* opera = [[[TransferOperation alloc] init] autorelease];
	[opera setIsMove:NO];
	[opera createAndStartThread];
	return opera;
}

+(TransferOperation*)moveOperation {
	TransferOperation* opera = [[[TransferOperation alloc] init] autorelease];
	[opera setIsMove:YES];
	[opera createAndStartThread];
	return opera;
}

-(void)createAndStartThread {
	NSAssert(m_thread == nil, @"at this point m_thread must not always be initialized");
	
	BOOL is_move = m_is_move;
	
	m_thread = [[TransferOperationThread alloc] initWithTransferOperation:self isMove:is_move];
	
	[m_thread start]; // IDEA: it's ugly to start a thread in the ctor, better to move this to performScan.. 
}

-(void)performScan {
	NSAssert(m_thread, @"thread must be initialized");
	NSAssert(m_names, @"names must be initialized");
	NSAssert(m_from_dir, @"fromDir must be initialized");
	NSAssert(m_to_dir, @"toDir must be initialized");

	// transfer all the information to the thread
	{
		NSArray* keys = [NSArray arrayWithObjects:@"names", @"fromDir", @"toDir", nil];
		NSArray* objects = [NSArray arrayWithObjects:m_names, m_from_dir, m_to_dir, nil];
		NSDictionary* dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	

		NSThread* thread = m_thread;
		id obj = m_thread;
		SEL sel = @selector(prepareForTransfer:);

		NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:sel]];
		[inv setTarget:obj];
		[inv setSelector:sel];
		// arguments starts at 2, since 0 is the target and 1 is the selector
		[inv setArgument:&dict atIndex:2]; 
		[inv retainArguments];

		[inv performSelector:@selector(invoke) 
	    	onThread:thread 
			withObject:nil 
			waitUntilDone:NO];
	}

	// carry out the operation
	{
		NSThread* thread = m_thread;
		id obj = m_thread;
		SEL sel = @selector(performScan);

		NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:sel]];
		[inv setTarget:obj];
		[inv setSelector:sel];
		[inv retainArguments];

		[inv performSelector:@selector(invoke) 
	    	onThread:thread 
			withObject:nil 
			waitUntilDone:NO];
	}
}

-(void)performOperation {
	NSThread* thread = m_thread;
	id obj = m_thread;
	SEL sel = @selector(performOperation);

	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:sel]];
	[inv setTarget:obj];
	[inv setSelector:sel];
	[inv retainArguments];

	[inv performSelector:@selector(invoke) 
    	onThread:thread 
		withObject:nil 
		waitUntilDone:NO];
}

-(void)abortOperation {
	NSThread* thread = m_thread;
	id obj = m_thread;
	SEL sel = @selector(abortOperation);

	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:sel]];
	[inv setTarget:obj];
	[inv setSelector:sel];
	[inv retainArguments];

	[inv performSelector:@selector(invoke) 
    	onThread:thread 
		withObject:nil 
		waitUntilDone:NO];
}


-(void)threadResponse:(NSDictionary*)dict forKey:(NSString*)key {
	// LOG_DEBUG(@"scan: %@", dict);
	if([m_delegate respondsToSelector:@selector(transferOperation:response:forKey:)]) {
		[m_delegate transferOperation:self response:dict forKey:key];
	}
}

-(void)dump {
	NSThread* thread = m_thread;
	id obj = m_thread;
	SEL sel = @selector(dump);

	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:sel]];
	[inv setTarget:obj];
	[inv setSelector:sel];
	[inv retainArguments];

	[inv performSelector:@selector(invoke) 
    	onThread:thread 
		withObject:nil 
		waitUntilDone:NO];
}

@end // class TransferOperation
