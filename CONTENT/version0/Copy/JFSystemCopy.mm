/*********************************************************************
JFSystemCopy.mm - threaded wrapper around the lowlevel copy code

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#import "JFSystemCopy.h"
#import "JFSystemCopyThread.h"


@interface JFSystemCopy (Private)
-(void)notifyActivity;
-(void)notifyCompletion;

-(void)startReal;
-(void)startFake;
-(void)killTimer;





-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
	willScanName:(NSString*)name;

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
  nowScanningName:(NSString*)name
             size:(unsigned long long)bytes 
			count:(unsigned long long)count;

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
      didScanName:(NSString*)name 
             size:(unsigned long long)bytes                      
			count:(unsigned long long)count;

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
      updateScanSummarySize:(unsigned long long)bytes 
	count:(unsigned long long)count;

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
      scanSummarySize:(unsigned long long)bytes 
	count:(unsigned long long)count;

-(void)copyThreadIsReadyToCopy:(JFSystemCopyThread*)sysCopyThread;

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
	willCopyName:(NSString*)name;

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
	didCopyName:(NSString*)name;

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
	nowCopyingItem:(NSString*)item;

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
	transferedBytes:(unsigned long long)bytes;

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
	bytesPerSecond:(double)bps;


@end

@implementation JFSystemCopy

@synthesize delegate = m_delegate;
@synthesize names = m_names;
@synthesize sourceDir = m_source_dir;
@synthesize targetDir = m_target_dir;

-(id)init {
	self = [super init];
    if(self) {
		m_thread = nil;
		m_system_copy_thread = nil;
		m_timer = nil;
		
		m_delegate = nil;
		
		m_debug_timer = nil;
		m_debug_timer_tick = 0;
		
		m_current_item_name = nil;
		m_current_progress = 0;
		
		m_bytes_transfered = 0;
		m_bytes_total = 0;
		m_bytes_per_second = 0;
		m_seconds_remaining = 0;

		m_name_index = 0;

		m_bytes_total = 10000;

    }
    return self;
}

-(void)dealloc {
	[m_debug_timer release]; 
	[m_timer release]; 
	[m_current_item_name release];
	[m_thread release];
	
    [super dealloc];
}

-(void)startThread {
	NSAssert(m_system_copy_thread == nil, @"must not be already initialized");
	NSAssert(m_thread == nil, @"must not be already initialized");
	
	m_system_copy_thread = [[JFSystemCopyThread alloc] init]; 
	[m_system_copy_thread setDelegate:self];
	
	NSThread* t = [[NSThread alloc] 
		initWithTarget:m_system_copy_thread
              selector:@selector(threadMainRoutine)
                object:nil
	];
	[t setName:@"SystemCopyThread"];
	[t start];
	m_thread = t;
	// NSLog(@"%s ok", _cmd);
}

-(void)prepare {
	NSAssert(m_system_copy_thread != nil, @"must be initialized");
	NSAssert(m_thread != nil, @"must be initialized");
	
	BOOL busy = [m_system_copy_thread isRunning];
	if(busy) {
		NSLog(@"%s system copy thread is busy", _cmd);
		return;
	}

	// [m_system_copy_thread prepareCopyFrom:m_source_dir to:m_target_dir names:m_names];

	id obj = m_system_copy_thread;
	SEL mySelector = @selector(prepareCopyFrom:to:names:);

	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:mySelector]];
	[inv setTarget:obj];
	[inv setSelector:mySelector];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	[inv setArgument:&m_source_dir atIndex:2]; 
	[inv setArgument:&m_target_dir atIndex:3]; 
	[inv setArgument:&m_names atIndex:4]; 
	[inv retainArguments];

	[inv performSelector:@selector(invoke) 
    	onThread:m_thread 
		withObject:nil 
		waitUntilDone:NO];

	// NSLog(@"%s ok", _cmd);
}

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
	 willScanName:(NSString*)name
{
	if([m_delegate respondsToSelector:@selector(copy:willScanName:)]) {
		[m_delegate copy:self willScanName:name];
	} else {
		NSLog(@"%s %@", _cmd, name);
	}
}

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
  nowScanningName:(NSString*)name
             size:(unsigned long long)bytes 
            count:(unsigned long long)count
{
	if([m_delegate respondsToSelector:@selector(copy:nowScanningName:size:count:)]) {
		[m_delegate copy:self nowScanningName:name size:bytes count:count];
	} else {
		NSLog(@"%s %@ %llu", _cmd, name, bytes);
	}
}

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
      didScanName:(NSString*)name 
             size:(unsigned long long)bytes                      
             count:(unsigned long long)count
{
	if([m_delegate respondsToSelector:@selector(copy:didScanName:size:count:)]) {
		[m_delegate copy:self didScanName:name size:bytes count:count];
	} else {
		NSLog(@"%s %@ %llu", _cmd, name, bytes);
	}
}

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
      updateScanSummarySize:(unsigned long long)bytes 
                count:(unsigned long long)count
{
	if([m_delegate respondsToSelector:@selector(copy:updateScanSummarySize:count:)]) {
		[m_delegate copy:self updateScanSummarySize:bytes count:count];
	} else {
		NSLog(@"%s %llu %llu", _cmd, bytes, count);
	}
}

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
      scanSummarySize:(unsigned long long)bytes 
                count:(unsigned long long)count
{
	if([m_delegate respondsToSelector:@selector(copy:scanSummarySize:count:)]) {
		[m_delegate copy:self scanSummarySize:bytes count:count];
	} else {
		NSLog(@"%s %llu %llu", _cmd, bytes, count);
	}
}

-(void)copyThreadIsReadyToCopy:(JFSystemCopyThread*)sysCopyThread {
	if([m_delegate respondsToSelector:@selector(readyToCopy:)]) {
		[m_delegate readyToCopy:self];
	} else {
		NSLog(@"%s", _cmd);
	}
}

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
	 willCopyName:(NSString*)name
{
	[self setName:name];
	if([m_delegate respondsToSelector:@selector(copy:willCopyName:)]) {
		[m_delegate copy:self willCopyName:name];
	} else {
		NSLog(@"%s %@", _cmd, name);
	}
}

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
	 didCopyName:(NSString*)name
{
	[self setName:nil];
	if([m_delegate respondsToSelector:@selector(copy:didCopyName:)]) {
		[m_delegate copy:self didCopyName:name];
	} else {
		NSLog(@"%s %@", _cmd, name);
	}
}

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
   nowCopyingItem:(NSString*)item
{
	if([m_delegate respondsToSelector:@selector(copy:nowCopyingItem:)]) {
		[m_delegate copy:self nowCopyingItem:item];
	} else {
		NSLog(@"%s %@", _cmd, item);
	}
}

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
	transferedBytes:(unsigned long long)bytes
{
	if([m_delegate respondsToSelector:@selector(copy:transferedBytes:)]) {
		[m_delegate copy:self transferedBytes:bytes];
	} else {
		NSLog(@"%s %llu", _cmd, bytes);
	}
}

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
	bytesPerSecond:(double)bps
{
	if([m_delegate respondsToSelector:@selector(copy:bytesPerSecond:)]) {
		[m_delegate copy:self bytesPerSecond:bps];
	} else {
		NSLog(@"%s %f", _cmd, bps);
	}
}

-(void)copyThreadTransferCompleted:(JFSystemCopyThread*)sysCopyThread 
	bytes:(unsigned long long)bytes
	elapsed:(double)elapsed
{
	[self killTimer];

	if([m_delegate respondsToSelector:@selector(copyCompleted:bytes:elapsed:)]) {
		[m_delegate copyCompleted:self bytes:bytes elapsed:elapsed];
	} else {
		NSLog(@"%s", _cmd);
	}
}

-(void)stop {
	[self killTimer];
	[m_system_copy_thread stopRunning];
}

-(void)start {
	[self startReal];
	// [self startFake];
}

-(void)killTimer {
	if(m_timer != nil) {
		[m_timer invalidate];
		[m_timer release];
		m_timer = nil;
	}
}

-(void)startReal {
	id obj = m_system_copy_thread;
	SEL mySelector = @selector(startCopying);

	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:mySelector]];
	[inv setTarget:obj];
	[inv setSelector:mySelector];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	// [inv setArgument:&m_names atIndex:2]; 
	[inv retainArguments];

	[inv performSelector:@selector(invoke) 
    	onThread:m_thread 
		withObject:nil 
		waitUntilDone:NO];

	if(m_timer == nil) {
		m_timer = [[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(timerAction) userInfo:nil repeats:YES] retain];
	}
}

-(void)startFake {
	if(m_debug_timer == nil) {
		m_debug_timer = [[NSTimer scheduledTimerWithTimeInterval:0.003 target:self selector:@selector(debugTimer) userInfo:nil repeats:YES] retain];
		m_debug_timer_tick = 0;
	}
	
	m_name_index = 0;
	m_bytes_transfered = 0;
	m_bytes_total = 10000;
	m_seconds_remaining = 100;
	m_current_progress = 0;
	[self setName:@"noname"];
	[self notifyActivity];
}

-(void)abort {
	[m_debug_timer invalidate];
	[m_debug_timer release];
	m_debug_timer = nil;
}

-(float)progress {
	return m_current_progress;
}

-(NSString*)currentItemName {
	return m_current_item_name;
}

-(unsigned long long)bytesTransfered {
	return m_bytes_transfered;
}

-(unsigned long long)bytesTotal {
	return m_bytes_total;
}

-(float)bytesPerSecond {
	return m_bytes_per_second;
}

-(float)secondsRemaining {
	return m_seconds_remaining;
}


-(void)timerAction {
	JFSystemCopyThreadStatus status;
	BOOL ok = [m_system_copy_thread obtainStatus:&status];
	if(!ok) return;
	
	// printf("%.f ", status.progress_under_name);
	double progress = status.progress_under_name;

	[self copyThread:m_system_copy_thread transferedBytes:status.bytes_transfered];
	[self copyThread:m_system_copy_thread bytesPerSecond:status.bytes_throughput];

	if([m_delegate respondsToSelector:@selector(copy:copyingName:progress:)]) {
		[m_delegate copy:self copyingName:m_current_item_name progress:progress];
	} else {
		NSLog(@"%s %@", _cmd, m_current_item_name);
	}

}

-(void)debugTimer {
	{
		float progress = float(m_debug_timer_tick) * 100.f / 1000.f; 
		m_current_progress = progress;
	}
	
	m_bytes_transfered++;
	m_bytes_per_second = fmodf(m_debug_timer_tick * 37.f, 31.f);
	
	m_seconds_remaining = 100 - (m_debug_timer_tick * 0.5);
	
	NSUInteger name_count = [m_names count];
	NSString* name = (m_name_index < name_count) ? [m_names objectAtIndex:m_name_index] : nil;
	
	const unsigned int name_ticks = 70;
	if((m_debug_timer_tick > m_name_index * name_ticks) && (m_debug_timer_tick < (m_name_index+1) * name_ticks)) {
		JFSystemCopyState state;
		state.bytes_copied = m_debug_timer_tick;
		[self notifyProgress:name state:state];
	}
	if(m_debug_timer_tick == m_name_index * name_ticks) {
		[self notifyWillCopy:name];
	}
	if((m_debug_timer_tick+1) >= (m_name_index+1) * name_ticks) {
		[self notifyDidCopy:name];
		m_name_index++;
	}
	
	if((m_debug_timer_tick & 7) == 0) {
		unsigned int i = (m_debug_timer_tick / 8) & 7;
		NSString* ary[8] = {
			@"the-movie.avi",
			@"Alien.mov",
			@"Superbowl-2011.mov",
			@"document.txt",
			@"README.TXT",
			@"HP LaserJet printer manual.pdf",
			@"Photoshop-CS4-crack.iso",      
			@"backup.zip",
		};
		[self setName:ary[i]];
	}
	
	[self notifyActivity];


	m_debug_timer_tick++;
	
	if(m_debug_timer_tick < 1000) {
		return;
	}

	[self notifyCompletion];

	[m_debug_timer invalidate];
	[m_debug_timer release];
	m_debug_timer = nil;
}

-(void)setName:(NSString*)name {
	[name retain];
	[m_current_item_name release];
	m_current_item_name = name;
}

-(void)notifyWillCopy:(NSString*)name {
	if([m_delegate respondsToSelector:@selector(copy:willCopy:)]) {
		[m_delegate copy:self willCopy:name];
	}
}

-(void)notifyDidCopy:(NSString*)name {
	if([m_delegate respondsToSelector:@selector(copy:didCopy:)]) {
		[m_delegate copy:self didCopy:name];
	}
}

-(void)notifyProgress:(NSString*)name state:(JFSystemCopyState)state {
	if([m_delegate respondsToSelector:@selector(copy:name:copyState:)]) {
		[m_delegate copy:self name:name copyState:state];
	}
}

-(void)notifyActivity {
	if([m_delegate respondsToSelector:@selector(copyActivity:)]) {
		[m_delegate copyActivity:self];
	}
}

-(void)notifyCompletion {
	if([m_delegate respondsToSelector:@selector(copyDidComplete:)]) {
		[m_delegate copyDidComplete:self];
	}
}


@end
