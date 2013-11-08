/*********************************************************************
JFSystemCopyThread.mm - lowlevel code for copying files

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#import "JFSystemCopyThread.h"
#include <stdio.h>
#include <aio.h>



struct CopyLink {
	// input
	const char* m_arg_from_path;
	const char* m_arg_create_path;

	// internal
	char m_symlink_path[PATH_MAX];
	
	// output
	int m_error;
	int m_error_readlink;        
	int m_error_symlink;
	
	void init();
	void run();
	void inspect();
};

void CopyLink::init() {
	m_arg_from_path = NULL;
	m_arg_create_path = NULL;
	m_symlink_path[0] = 0;
	m_error = 0;
	m_error_readlink = 0;
	m_error_symlink = 0;
}

void CopyLink::run() {
	if((m_arg_from_path == NULL) || (m_arg_create_path == NULL)) {
		m_error = 1;
		return;
	}
	
	int len = readlink(m_arg_from_path, m_symlink_path, sizeof(m_symlink_path) - 1);
	if(len == -1) {
		m_symlink_path[0] = 0;
		m_error_readlink = errno;
		m_error = 2;
		return;
	}
	m_symlink_path[len] = 0;
	
	unlink(m_arg_create_path);
	
	int rc = symlink(m_symlink_path, m_arg_create_path);
	if(rc == -1) {
		m_error_symlink = errno;
		m_error = 3;
		return;
	}
	
	// we have successfully copied symlink
}

void CopyLink::inspect() {
	NSLog(@"%s %s %s %i %i %i", 
		m_arg_from_path,
		m_arg_create_path,
		m_symlink_path,
		m_error,
		m_error_readlink,
		m_error_symlink
	);
}



#if 0
struct CopyXAttr {
	// input
	int m_arg_from_filedesc;
	int m_arg_to_filedesc;

	// output
	int m_error;
	
	void init();
	void run();
};

void CopyLink::init() {
	m_error = 0;
}

void CopyXAttr::run() {
	size_t buffer_size = flistxattr(m_arg_from_filedesc, NULL, 0, XATTR_NOFOLLOW);
	if(buffer_size <= 0) {
		// no xattr's found, so there is nothing to copy
		return;
	}
	
	char* buffer = (char*)malloc(buffer_size);

	size_t bytes_read = flistxattr(m_arg_from_filedesc, buffer, buffer_size, XATTR_NOFOLLOW);
	if(bytes_read != buffer_size) {
		// NSLog(@"%s mismatch in buffer size", _cmd);
		m_error = 1;
	}
	
	free(buffer);
}
#endif





@interface JFSystemCopyThreadItem : NSObject {
	NSString* name;
	unsigned long long bytesTotal;
}
@property (copy) NSString* name;
@property (assign) unsigned long long bytesTotal;
@end

@implementation JFSystemCopyThreadItem
@synthesize name, bytesTotal;
@end








@interface JFSystemCopyThread (Private)

-(void)gatherInfoAboutFile:(NSString*)name underName:(NSString*)under_name;

-(void)gatherInfoAboutFiles;

-(void)registerTransferedBytes:(unsigned long long)bytes_read;


// notifications
-(void)willScanName:(NSString*)name;

-(void)didScanName:(NSString*)name 
              size:(unsigned long long)bytes;

-(void)didScanSummarySize:(unsigned long long)bytes 
                    count:(unsigned long long)count;

-(void)updateScanSummarySize:(unsigned long long)bytes 
                    count:(unsigned long long)count;

-(void)weAreReadyToCopy;
-(void)willCopyName:(NSString*)name;
-(void)didCopyName:(NSString*)name;
-(void)nowProcessingItem:(NSString*)item;

-(void)performanceBytesPerSecond:(double)bps;

-(void)initItemsForNames:(NSArray*)names;


-(void)updateProgess;

-(void)aioReadFrom:(int)read_fd writeTo:(int)write_fd;
-(void)normalReadFrom:(int)read_fd writeTo:(int)write_fd;
-(void)selectReadFrom:(int)read_fd writeTo:(int)write_fd;
-(void)readFrom:(int)read_fd writeTo:(int)write_fd;

-(void)copyDataFromFile:(NSString*)from_file 
	toFile:(NSString*)to_file;


-(void)cloneDirsForName:(NSString*)name;
-(void)cloneFilesForName:(NSString*)name;
	
-(void)copyFiles;
@end

@implementation JFSystemCopyThread

@synthesize delegate = m_delegate;
@synthesize sourceDir = m_source_dir;
@synthesize targetDir = m_target_dir;

-(id)init {
	self = [super init];
    if(self) {
		m_elements_created = 0;
		m_elements_total = 0;
		m_elements_under_name = 0;
		m_bytes_copied = 0;
		m_bytes_total = 0;
		m_bytes_total_under_name = 0;
		m_bytes_copied_under_name = 0;
		
		m_items = [[NSMutableArray alloc] initWithCapacity:200];
		
		m_is_running = NO;
		m_is_running_lock = [[NSLock alloc] init];
		
		m_status_lock = [[NSLock alloc] init];

		m_throughput.last_time = 0;
		m_throughput.last_bytes = 0;
		m_throughput.sample_index = 0;
		for(unsigned int i=0; i<kJFByteSampleCount; ++i) {
			m_throughput.bytes[i] = 0;
		}
    }
    return self;
}

-(void)dealloc {
	[m_items release];
    [super dealloc];
}

-(BOOL)isRunning {
	[m_is_running_lock lock];
	BOOL is_running = m_is_running;
	[m_is_running_lock unlock];
	return is_running;
}

-(void)stopRunning {
	[m_is_running_lock lock];
	BOOL was_running = m_is_running;
	m_is_running = NO;
	[m_is_running_lock unlock];
	if(was_running) {
		NSLog(@"%s aborting operation", _cmd);
	} else {
		NSLog(@"%s nothing to abort", _cmd);
	}
}

-(void)prepareCopyFrom:(NSString*)sourceDir 
                    to:(NSString*)targetDir 
                 names:(NSArray*)names
{
	[m_is_running_lock lock];
	BOOL is_already_busy = m_is_running;
	m_is_running = YES;
	[m_is_running_lock unlock];
	if(is_already_busy) {
		NSLog(@"ERROR: %s is already busy. Cannot prepare a copy operation!", _cmd);
		return;
	}

	[self setSourceDir:sourceDir];
	[self setTargetDir:targetDir];
	
	[self initItemsForNames:names];
	// NSLog(@"%s  self: %@", _cmd, self);
	
	// NSLog(@"Scanning...");
	[self gatherInfoAboutFiles];
	// NSLog(@"DONE Scanning");
	
	[self weAreReadyToCopy];

	[m_is_running_lock lock];
	m_is_running = NO;
	[m_is_running_lock unlock];
}

-(void)initItemsForNames:(NSArray*)names {
	[m_items removeAllObjects];
	id thing;
	NSEnumerator* en = [names objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[NSString class]] == NO) {
			continue;
		}
		NSString* name = (NSString*)thing;
		JFSystemCopyThreadItem* item = 
			[[[JFSystemCopyThreadItem alloc] init] autorelease];
		[item setName:name];
		[item setBytesTotal:0];
		[m_items addObject:item];
	}
}

-(void)threadMainRoutine {
	[[NSAutoreleasePool alloc] init];

	// to prevent [runlop runUntilDate] from exiting immediately
	[[NSRunLoop currentRunLoop] addPort:[NSPort port] forMode:NSDefaultRunLoopMode];

	while(1) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantFuture]];
		NSLog(@"%s exited runloop", _cmd);
	}
}

-(void)willScanName:(NSString*)name {
	if(m_delegate == nil) {
		NSLog(@"%s %@", _cmd, name);
		return;
	}
	id obj = m_delegate;
	SEL mySelector = @selector(copyThread:willScanName:);
	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:mySelector]];
	[inv setTarget:obj];
	[inv setSelector:mySelector];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	[inv setArgument:&self atIndex:2]; 
	[inv setArgument:&name atIndex:3]; 
	[inv retainArguments];
	[inv performSelectorOnMainThread:@selector(invoke) 
		withObject:nil waitUntilDone:NO];
}

-(void)nowScanningName:(NSString*)name size:(unsigned long long)bytes count:(unsigned long long)count {
	if(m_delegate == nil) {
		NSLog(@"%s %@ %llu", _cmd, name, bytes);
		return;
	}
	id obj = m_delegate;
	SEL mySelector = @selector(copyThread:nowScanningName:size:count:);
	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:mySelector]];
	[inv setTarget:obj];
	[inv setSelector:mySelector];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	[inv setArgument:&self atIndex:2]; 
	[inv setArgument:&name atIndex:3];    
	[inv setArgument:&bytes atIndex:4];                          
	[inv setArgument:&count atIndex:5]; 
	[inv retainArguments];
	[inv performSelectorOnMainThread:@selector(invoke) 
		withObject:nil waitUntilDone:NO];
}

-(void)didScanName:(NSString*)name size:(unsigned long long)bytes count:(unsigned long long)count {
	if(m_delegate == nil) {
		NSLog(@"%s %@ %llu", _cmd, name, bytes);
		return;
	}
	id obj = m_delegate;
	SEL mySelector = @selector(copyThread:didScanName:size:count:);
	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:mySelector]];
	[inv setTarget:obj];
	[inv setSelector:mySelector];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	[inv setArgument:&self atIndex:2]; 
	[inv setArgument:&name atIndex:3];    
	[inv setArgument:&bytes atIndex:4];                          
	[inv setArgument:&count atIndex:5]; 
	[inv retainArguments];
	[inv performSelectorOnMainThread:@selector(invoke) 
		withObject:nil waitUntilDone:NO];
}

-(void)updateScanSummarySize:(unsigned long long)bytes 
              count:(unsigned long long)count
{
	if(m_delegate == nil) {
		NSLog(@"%s %@ %llu %llu", _cmd, bytes, count);
		return;
	}
	id obj = m_delegate;
	SEL mySelector = @selector(copyThread:updateScanSummarySize:count:);
	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:mySelector]];
	[inv setTarget:obj];
	[inv setSelector:mySelector];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	[inv setArgument:&self atIndex:2]; 
	[inv setArgument:&bytes atIndex:3];
	[inv setArgument:&count atIndex:4]; 
	[inv retainArguments];
	[inv performSelectorOnMainThread:@selector(invoke) 
		withObject:nil waitUntilDone:NO];
}

-(void)didScanSummarySize:(unsigned long long)bytes 
              count:(unsigned long long)count
{
	if(m_delegate == nil) {
		NSLog(@"%s %@ %llu %llu", _cmd, bytes, count);
		return;
	}
	id obj = m_delegate;
	SEL mySelector = @selector(copyThread:scanSummarySize:count:);
	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:mySelector]];
	[inv setTarget:obj];
	[inv setSelector:mySelector];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	[inv setArgument:&self atIndex:2]; 
	[inv setArgument:&bytes atIndex:3];
	[inv setArgument:&count atIndex:4]; 
	[inv retainArguments];
	[inv performSelectorOnMainThread:@selector(invoke) 
		withObject:nil waitUntilDone:NO];
}

-(void)weAreReadyToCopy {
	if(m_delegate == nil) {
		NSLog(@"%s", _cmd);
		return;
	}
	id obj = m_delegate;
	SEL mySelector = @selector(copyThreadIsReadyToCopy:);
	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:mySelector]];
	[inv setTarget:obj];
	[inv setSelector:mySelector];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	[inv setArgument:&self atIndex:2]; 
	[inv retainArguments];
	[inv performSelectorOnMainThread:@selector(invoke) 
		withObject:nil waitUntilDone:NO];
}

-(void)willCopyName:(NSString*)name {
	if(m_delegate == nil) {
		NSLog(@"%s %@", _cmd, name);
		return;
	}
	id obj = m_delegate;
	SEL mySelector = @selector(copyThread:willCopyName:);
	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:mySelector]];
	[inv setTarget:obj];
	[inv setSelector:mySelector];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	[inv setArgument:&self atIndex:2]; 
	[inv setArgument:&name atIndex:3]; 
	[inv retainArguments];
	[inv performSelectorOnMainThread:@selector(invoke) 
		withObject:nil waitUntilDone:NO];
}

-(void)didCopyName:(NSString*)name {
	if(m_delegate == nil) {
		NSLog(@"%s %@", _cmd, name);
		return;
	}
	id obj = m_delegate;
	SEL mySelector = @selector(copyThread:didCopyName:);
	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:mySelector]];
	[inv setTarget:obj];
	[inv setSelector:mySelector];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	[inv setArgument:&self atIndex:2]; 
	[inv setArgument:&name atIndex:3];    
	[inv retainArguments];
	[inv performSelectorOnMainThread:@selector(invoke) 
		withObject:nil waitUntilDone:NO];
}

-(void)nowCopyingItem:(NSString*)item {
	if(m_delegate == nil) {
		NSLog(@"%s %@", _cmd, item);
		return;
	}
	id obj = m_delegate;
	SEL mySelector = @selector(copyThread:nowCopyingItem:);
	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:mySelector]];
	[inv setTarget:obj];
	[inv setSelector:mySelector];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	[inv setArgument:&self atIndex:2]; 
	[inv setArgument:&item atIndex:3];    
	[inv retainArguments];
	[inv performSelectorOnMainThread:@selector(invoke) 
		withObject:nil waitUntilDone:NO];
}

-(void)performanceBytesPerSecond:(double)bps {
	if(m_delegate == nil) {
		NSLog(@"%s %.2f", _cmd, bps);
		return;
	}
	id obj = m_delegate;
	SEL mySelector = @selector(copyThread:bytesPerSecond:);
	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:mySelector]];
	[inv setTarget:obj];
	[inv setSelector:mySelector];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	[inv setArgument:&self atIndex:2]; 
	[inv setArgument:&bps atIndex:3];
	[inv retainArguments];
	[inv performSelectorOnMainThread:@selector(invoke) 
		withObject:nil waitUntilDone:NO];
}


-(void)copyOperationCompletedBytes:(unsigned long long)actual_bytes_copied elapsed:(double)elapsed {
	if(m_delegate == nil) {
		NSLog(@"%s", _cmd);
		return;
	}
	id obj = m_delegate;
	SEL mySelector = @selector(copyThreadTransferCompleted:bytes:elapsed:);
	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:mySelector]];
	[inv setTarget:obj];
	[inv setSelector:mySelector];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	[inv setArgument:&self atIndex:2];                     
	[inv setArgument:&actual_bytes_copied atIndex:3]; 
	[inv setArgument:&elapsed atIndex:4]; 
	[inv retainArguments];
	[inv performSelectorOnMainThread:@selector(invoke) 
		withObject:nil waitUntilDone:NO];
}

-(void)registerTransferedBytes:(unsigned long long)bytes_read {
	m_bytes_copied += bytes_read;           
	m_bytes_copied_under_name += bytes_read;

	// keep track of the throughput for the last couple of seconds
	{
		double period_length = 1.0 / kJFByteSamplePerSec;
		double t = CFAbsoluteTimeGetCurrent();
		for(unsigned int retries = 0; retries < 10; ++retries) {
			if(t < (m_throughput.last_time + period_length)) break;

			m_throughput.last_time += period_length;
			long long diff = m_bytes_copied - m_throughput.last_bytes;
			m_throughput.last_bytes = m_bytes_copied;
			if(diff < 0) diff = 0;
			unsigned int sample_index = m_throughput.sample_index;
			sample_index += 1;
			sample_index %= kJFByteSampleCount;
			m_throughput.sample_index = sample_index;
			m_throughput.bytes[sample_index] = diff;
		}
	}
	
	// determine our throughput
	double result_throughput = 0;
	{
		unsigned long long b = 0;
		for(unsigned int i=0; i<kJFByteSampleCount; ++i) {
			b += m_throughput.bytes[i];
		}
		double dd = b;
		dd *= kJFByteSamplePerSec;
		dd /= kJFByteSampleCount;
		result_throughput = dd;
		// NSLog(@"%s throughput: %.2f", _cmd, dd);
		// [self performanceBytesPerSecond:dd];
	}

	double result_progress = 0;
	if(m_bytes_total_under_name > 1) {
		double a = m_bytes_copied_under_name;
		double b = m_bytes_total_under_name;
		double ab = a * 100.0 / b;
		result_progress = ab;
		// printf("%.f ", ab);
	}

	JFSystemCopyThreadStatus status;
	status.bytes_throughput = result_throughput;
	status.progress_under_name = result_progress;
	status.bytes_transfered = m_bytes_copied;
	if([m_status_lock tryLock]) {
		m_status = status;
		[m_status_lock unlock];
	} else {
		// status will be updated in a few msec anyways, 
		// so skipping a few doesn't matter
	}
}

-(BOOL)obtainStatus:(JFSystemCopyThreadStatus*)status {
	if(status == NULL) return NO;
	
	if([m_status_lock tryLock]) {
		*status = m_status;
		[m_status_lock unlock];
		return YES;
	}
	
	// status will be updated in a few msec anyways, 
	// so skipping a few doesn't matter
	return NO;
}

-(void)gatherInfoAboutFile:(NSString*)name underName:(NSString*)under_name {
	// NSLog(@"%s %@", _cmd, name);

	m_elements_total++;
	m_elements_under_name++;

	NSString* path = [m_source_dir stringByAppendingPathComponent:name];


	NSFileManager* fm = [NSFileManager defaultManager];

	NSString* filetype = nil;
	NSDictionary* attr = [fm fileAttributesAtPath:path
	 	traverseLink:NO];
	// NSLog(@"%s %@", _cmd, attr);
	{

		if(attr == nil) {
			NSLog(@"ERROR: no attributes for path: %@", path);
			return;
		}
	    if(filetype = [attr objectForKey:NSFileType]) {
			// NSLog(@"%s %@", _cmd, filetype);
	    } else {
			NSLog(@"ERROR: no filetype key for path: %@", path);
			return;
		}
	}
	
	if([filetype isEqual:NSFileTypeRegular]) {

	    NSNumber* filesize = nil;
	    if(filesize = [attr objectForKey:NSFileSize]) {
	        // NSLog(@"File size: %llu\n", [filesize unsignedLongLongValue]);
			unsigned long long bytes = [filesize unsignedLongLongValue];
			m_bytes_total += bytes;
			m_bytes_total_under_name += bytes;
	    } else {
			NSLog(@"ERROR: no filesize key for path: %@", path);
		}
	} else
	if([filetype isEqual:NSFileTypeSymbolicLink]) {
		// do nothing
	} else
	if([filetype isEqual:NSFileTypeDirectory]) {
		NSError* err = nil;
		NSArray* entries = [fm contentsOfDirectoryAtPath:path error:&err];
		// NSLog(@"%s %@", _cmd, entries);
		id thing;
		NSEnumerator* en = [entries objectEnumerator];
		while(thing = [en nextObject]) {
			if([thing isKindOfClass:[NSString class]] == NO) {
				continue;
			}
			NSString* name2 = (NSString*)thing;
			NSString* name3 = [name stringByAppendingPathComponent:name2];

			[self gatherInfoAboutFile:name3 underName:under_name];

			[self nowScanningName:under_name size:m_bytes_total_under_name count:m_elements_under_name];
			[self updateScanSummarySize:m_bytes_total
			                      count:m_elements_total];

			if([self isRunning] == NO) {
				NSLog(@"%s abort for %@", _cmd, name3);
				break;
			}
		}
	} else {
		NSLog(@"%s unknown filetype: %@   %@", _cmd, filetype, attr);
	}
}

-(void)gatherInfoAboutFiles {
	m_elements_total = 0;
	m_bytes_total = 0;
	m_elements_under_name = 0;
	m_bytes_total_under_name = 0;

	id thing;
	NSEnumerator* en = [m_items objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[JFSystemCopyThreadItem class]] == NO) {
			continue;
		}
		JFSystemCopyThreadItem* item = (JFSystemCopyThreadItem*)thing;
		NSString* name = [item name];
		
		[self willScanName:name];
		
		m_elements_under_name = 0;
		m_bytes_total_under_name = 0;
		[self gatherInfoAboutFile:name underName:name];

		[self didScanName:name size:m_bytes_total_under_name count:m_elements_under_name];
		[self updateScanSummarySize:m_bytes_total count:m_elements_total];
		
		[item setBytesTotal:m_bytes_total_under_name];

		if([self isRunning] == NO) {
			NSLog(@"%s abort scan %@", _cmd, name);
			break;
		}
		
		// NSLog(@"ENTRY  %llu  %i  %@", cii.bytes, cii.element_count, name);
	}
	// NSLog(@"TOTAL  %llu  %i", m_bytes_total, m_elements_total);
	[self didScanSummarySize:m_bytes_total count:m_elements_total];
}

-(void)updateProgess {
#if 0
	if((m_elements_created % 50) == 0) {
		printf("\n");
		
		unsigned long long a = m_bytes_copied;
		unsigned long long b = m_bytes_total;
		double fa = a;
		double fb = b;
		double progress = (fb > 1) ? (fa * 100.0 / fb) : 0;
		
		NSLog(@"STATUS %i of %i -- %llu of %llu -- %.2f", m_elements_created, m_elements_total, m_bytes_copied, m_bytes_total, progress);
	}
	printf(".");
	fflush(stdout);
#endif
}

-(void)cloneDirsForName:(NSString*)name {
	// NSLog(@"%s %@", _cmd, name);

	NSString* from_path = [m_source_dir stringByAppendingPathComponent:name];
	NSString* to_path = [m_target_dir stringByAppendingPathComponent:name];


	NSFileManager* fm = [NSFileManager defaultManager];
	{

		NSDictionary* attr = [fm fileAttributesAtPath:from_path
		 	traverseLink:NO];
		// NSLog(@"%s %@", _cmd, attr);
		if(attr == nil) {
			NSLog(@"ERROR: no attributes for path: %@", from_path);
			return;
		}
		NSString* filetype = nil;
	    if(filetype = [attr objectForKey:NSFileType]) {
			// NSLog(@"%s %@", _cmd, filetype);
	    } else {
			NSLog(@"ERROR: no filetype key for path: %@", from_path);
			return;
		}
		if([filetype isEqual:NSFileTypeDirectory] == NO) {
			// NSLog(@"%s not a dir", _cmd);
			return;
		}
	}

	BOOL is_dir = NO;
	if([fm fileExistsAtPath:to_path isDirectory:&is_dir]) {
		if(is_dir) {
			// NSLog(@"%s dir already exist", _cmd);
		} else {
			NSLog(@"%s ERROR: %@ is a file. Expected a dir", _cmd, to_path);
			// TODO: erase the file. create the dir
		}
	} else {
		NSError* err = nil;
		BOOL ok = [fm createDirectoryAtPath:to_path withIntermediateDirectories:NO attributes:nil error:&err];
		if(err != nil) {
			NSLog(@"%s couldn't create the destination dir. %@", _cmd, err);
		}
		// NSAssert(ok, @"couldn't create the destination dir for some reason");
	}
	m_elements_created++;
	[self updateProgess];

	{
		NSError* err = nil;
		NSArray* entries = [fm contentsOfDirectoryAtPath:from_path error:&err];
		// NSLog(@"%s %@", _cmd, entries);
		id thing;
		NSEnumerator* en = [entries objectEnumerator];
		while(thing = [en nextObject]) {
			if([thing isKindOfClass:[NSString class]] == NO) {
				continue;
			}
			NSString* name2 = (NSString*)thing;
			NSString* name3 = [name stringByAppendingPathComponent:name2];
			[self cloneDirsForName:name3];

			if([self isRunning] == NO) {
				NSLog(@"%s abort mkdir: %@", _cmd, name3);
				break;
			}
		}
	}
}

-(void)aioReadFrom:(int)read_fd writeTo:(int)write_fd {

	/*
	TODO: use global struct for this, since
	AIO doesn't like things on the stack!
	*/
	const unsigned int buffer_size = 4096;
	char buffer[buffer_size];

	aiocb cb;
	bzero( (char*)&cb, sizeof(aiocb) );

	cb.aio_lio_opcode = LIO_READ;
	cb.aio_fildes  = read_fd;
	cb.aio_offset  = 0;
	cb.aio_buf     = (void*)buffer;
	cb.aio_nbytes  = buffer_size;
	cb.aio_reqprio = 0;
	cb.aio_sigevent.sigev_notify = SIGEV_NONE;
	
	
	const unsigned int list_length = 1;
	aiocb* aiocb_list[list_length];
	aiocb_list[0] = &cb;
	unsigned long long offset = 0;

	int err = 0;
    
	for(;;) {

		/*
		in "sys/aio.h" I see this: 
		
		 "After a successful call to enqueue an asynchronous 
		  I/O operation, the value of the file offset for 
		  the file is unspecified."
		
		so we must always set aio_offset before calling aio_read().
		*/
		cb.aio_offset = offset;
		err = aio_read(&cb);
	
		if(err < 0) {
			if(errno == EAGAIN) {
				NSLog(@"%s aio is busy.. try again", _cmd);
				return;
			}
			if(errno == ENOSYS) {
				NSLog(@"%s aio not supported", _cmd);
				return;
			}

			perror("aio_read");
			return;
		}
		

		/*
		PROBLEM: 
		it may take long time for the buffer to be filled up.
		eg. when I connect to an FTP site in china, it takes 
		seconds between each read operation.

		Just polling with aio_error() will wait until the entire
		buffer is filled up. Calling aio_return() inside the 
		polling loop is not possible, since it must only be invoked once
		per aio_read operation.
		
		IDEA:
		we want to monitor in real time how many bytes gets
		transfered. For a really slow FTP connection.. 4096 bytes
		may take a long time, so it's difficult to see if there
		is anything going on.. or if we are just waiting.
		For this reason I want to use aio_suspend() with a timeout,
		when it times out we can take a peek at how many bytes
		has been transfered.
		PROBLEM: aio_suspend() only considers things as completed
		when the whole buffer is filled.
		PROBLEM: aio_fsync() doesn't make a difference.

		SOLUTION: none. This is UNRESOLVED!
		*/

#if 0
		struct timespec timeout;
		timeout.tv_sec = 0;
		timeout.tv_nsec = 50000000; // 50 milisec
		err = aio_suspend(aiocb_list, list_length, &timeout);
		if((err == -1) && (errno == EAGAIN)) {
			printf("TIMEOUT");
		} else
		if(err < 0) {
			perror("aio_suspend");
			return;
		}
#endif

#if 1
		// int wait_count = 0;
	    // wait until end of transaction
	    while((err = aio_error(&cb)) == EINPROGRESS) {
			// printf("_");
			usleep(50000); // 50 milisec
			// int b = aio_return(&cb);
			// printf("(%i)", b);

			// wait_count++;
/*			if(wait_count > 5) {
				aio_fsync(O_SYNC, &cb);
			}*/
		}
		if(err < 0) {
			perror("aio_error");
			return;
		}
#endif
	
		int bytes = aio_return(&cb);
		if(bytes == 0) {
			// NSLog(@"%s successfully read entire file", _cmd);
			break;
		}
		if(bytes < 0) {
			perror("aio_return");
			return;
		}
		// printf("%i", bytes);
		// NSLog(@"%s len: %i", _cmd, bytes);


		{
			int bytes_to_write = bytes;
			char* ptr = buffer;
			
			int bytes_written = 0;

			int retries = 5;
			while(bytes_to_write > 0) {
				bytes_written = write(write_fd, ptr, bytes_to_write);
				if(bytes_written < 0) break;
				if(bytes_written == 0) {
					retries -= 1;
					if(retries < 0) break;
				}

				bytes_to_write -= bytes_written;
				ptr += bytes_written;
			}
			
			if(bytes_written < 0) {
				NSLog(@"%s ERROR: write() failed", _cmd);
				break;
			}
			
			if(retries < 0) {
				NSLog(@"%s ERROR: write() has returned 0 a couple of times", _cmd);
				break;
			}
			
			m_bytes_copied += bytes;
			
		}

		offset += bytes;
	}
	// NSLog(@"%s ok", _cmd);
}


-(void)normalReadFrom:(int)read_fd writeTo:(int)write_fd {
	const unsigned int buffer_size = 4096;
	char buffer[buffer_size];

	for(;;) {
		if([self isRunning] == NO) {
			NSLog(@"%s abort for %i -> %i", _cmd, read_fd, write_fd);
			break;
		}
		
		int bytes_read = read(read_fd, buffer, buffer_size);
		// printf(">");

		if(bytes_read > 0) {
			int bytes_to_write = bytes_read;
			char* ptr = buffer;
			
			int bytes_written = 0;

			int retries = 5;
			while(bytes_to_write > 0) {
				bytes_written = write(write_fd, ptr, bytes_to_write);
				if(bytes_written < 0) break;
				if(bytes_written == 0) {
					retries -= 1;
					if(retries < 0) break;
				}

				bytes_to_write -= bytes_written;
				ptr += bytes_written;
			}
			
			if(bytes_written < 0) {
				NSLog(@"%s ERROR: write() failed", _cmd);
				break;
			}
			
			if(retries < 0) {
				NSLog(@"%s ERROR: write() has returned 0 a couple of times", _cmd);
				break;
			}
			
			[self registerTransferedBytes:bytes_read];

			// printf("+");
			// we are still reading data
			continue;
		}
		
		if(bytes_read == 0) {
			// upon reading end-of-file, zero is returned
			// printf("r");
			break;
		}
		
		if(errno != EAGAIN) {
			// something is wrong
			NSLog(@"%s ERROR occured while reading", _cmd);
			break;
		}
		
		// NSLog(@"%s nonblock", _cmd);

		// non-blocking I/O, and no data were ready to be read
		// go to sleep for 1 second
		
	}
}


-(void)selectReadFrom:(int)read_fd writeTo:(int)write_fd {
	const unsigned int buffer_size = 4096;
	char buffer[buffer_size];

	fd_set f;
	FD_ZERO(&f);
	FD_SET(read_fd, &f);
	for(;;) {
		struct timeval timeout;
		timeout.tv_sec = 1;
		timeout.tv_usec = 0;
	
		// printf("<");
		int rc = select(FD_SETSIZE, &f, NULL, NULL, &timeout);
		if(rc == 0) {
			NSLog(@"%s timeout. 1 sec without activity.", _cmd);
			continue;
		}
		// printf("-");
		
		if(rc < 0) {
			NSLog(@"%s ERROR occured", _cmd);
			break;
		}
		
		if(!FD_ISSET(read_fd, &f)) {
			NSLog(@"%s not our descriptor", _cmd);
			continue;
		}
		

		int bytes_read = read(read_fd, buffer, buffer_size);
		// printf(">");

		if(bytes_read > 0) {
			int bytes_to_write = bytes_read;
			char* ptr = buffer;
			
			int bytes_written = 0;

			int retries = 5;
			while(bytes_to_write > 0) {
				bytes_written = write(write_fd, ptr, bytes_to_write);
				if(bytes_written < 0) break;
				if(bytes_written == 0) {
					retries -= 1;
					if(retries < 0) break;
				}

				bytes_to_write -= bytes_written;
				ptr += bytes_written;
			}
			
			if(bytes_written < 0) {
				NSLog(@"%s ERROR: write() failed", _cmd);
				break;
			}
			
			if(retries < 0) {
				NSLog(@"%s ERROR: write() has returned 0 a couple of times", _cmd);
				break;
			}
			
			[self registerTransferedBytes:bytes_read];

			// printf("+");
			// we are still reading data
			continue;
		}
		
		if(bytes_read == 0) {
			// upon reading end-of-file, zero is returned
			// printf("r");
			break;
		}
		
		if(errno != EAGAIN) {
			// something is wrong
			NSLog(@"%s ERROR occured while reading", _cmd);
			break;
		}
		
		// NSLog(@"%s nonblock", _cmd);

		// non-blocking I/O, and no data were ready to be read
		// go to sleep for 1 second
		
	}
}


-(void)readFrom:(int)read_fd writeTo:(int)write_fd {
	[self normalReadFrom:read_fd writeTo:write_fd];
	// [self selectReadFrom:read_fd writeTo:write_fd];
	// [self aioReadFrom:read_fd writeTo:write_fd];
}

-(void)copyDataFromFile:(NSString*)from_file toFile:(NSString*)to_file {
	const char* from_path = [from_file UTF8String];
	const char* to_path = [to_file UTF8String];
	if((from_path == NULL) || (to_path == NULL)) {
		NSLog(@"%s ERROR: from or to path is NULL", _cmd);
		return;
	}
	
	int from_fd = -1;
	int to_fd = -1;
	do {
		// printf("[");
		from_fd = open(from_path, O_RDONLY | O_NONBLOCK, 0);
		// from_fd = open(from_path, O_RDONLY, 0);
		if(from_fd == -1) {
			NSLog(@"%s failed to open source file: %@", _cmd, from_path);
			break;
		}
		// printf("O");
		
/*		if(fcntl(from_fd, F_SETFL, O_NONBLOCK) == -1) {
			NSLog(@"%s failed to enable async for file: %@", _cmd, from_path);
			break;
		}/**/
		
		to_fd = open(to_path, O_CREAT | O_WRONLY, 0755);
		if(to_fd == -1) {
			NSLog(@"%s failed to open dest file: %@", _cmd, to_path);
			break;
		}
		
		[self readFrom:from_fd writeTo:to_fd];
		
	} while(0);
	
	if(from_fd >= 0) {
		close(from_fd);
		// printf("]");
	}
	if(to_fd >= 0) {
		close(to_fd);
	}
}


-(void)cloneFilesForName:(NSString*)name {
	// NSLog(@"%s %@", _cmd, name);
	NSString* from_path = [m_source_dir stringByAppendingPathComponent:name];
	NSString* to_path = [m_target_dir stringByAppendingPathComponent:name];


	NSFileManager* fm = [NSFileManager defaultManager];

	NSString* filetype = nil;
	NSDictionary* from_attr = [fm fileAttributesAtPath:from_path
	 	traverseLink:NO];
	// NSLog(@"%s %@", _cmd, from_attr);
	{

		if(from_attr == nil) {
			NSLog(@"ERROR: no attributes for path: %@", from_path);
			return;
		}
	    if(filetype = [from_attr objectForKey:NSFileType]) {
			// NSLog(@"%s %@", _cmd, filetype);
	    } else {
			NSLog(@"ERROR: no filetype key for path: %@", from_path);
			return;
		}
	}
	// NSLog(@"%s xx", _cmd);
	
	if([filetype isEqual:NSFileTypeRegular]) {
		NSError* err = nil;
		// BOOL ok = [fm copyItemAtPath:from_path toPath:to_path error:&err];
		// NSAssert(ok, @"couldn't copy the file for some reason");

		[self nowCopyingItem:name];
		
		// NSLog(@"%s before", _cmd);
		[self copyDataFromFile:from_path toFile:to_path];
		// NSLog(@"%s after", _cmd);
		

		m_elements_created++;
		[self updateProgess];
	} else
	if([filetype isEqual:NSFileTypeSymbolicLink]) {

		CopyLink v;
		v.init();
		v.m_arg_from_path = [from_path UTF8String];
		v.m_arg_create_path = [to_path UTF8String];
		v.run();
		if(v.m_error) {
			v.inspect();
		}

		m_elements_created++;
		[self updateProgess];
	} else
	if([filetype isEqual:NSFileTypeDirectory]) {
		NSError* err = nil;
		NSArray* entries = [fm contentsOfDirectoryAtPath:from_path error:&err];
		// NSLog(@"%s %@", _cmd, entries);
		id thing;
		NSEnumerator* en = [entries objectEnumerator];
		while(thing = [en nextObject]) {
			if([thing isKindOfClass:[NSString class]] == NO) {
				continue;
			}
			NSString* name2 = (NSString*)thing;
			NSString* name3 = [name stringByAppendingPathComponent:name2];

			[self cloneFilesForName:name3];

			if([self isRunning] == NO) {
				NSLog(@"%s abort for %@", _cmd, name3);
				break;
			}
		}
	} else {
		NSLog(@"%s unknown filetype: %@   %@", _cmd, filetype, from_attr);
	}
}

-(void)copyFiles {
	m_elements_created = 0;
	m_bytes_copied = 0;

	JFSystemCopyThreadStatus status;
	status.bytes_throughput = 0;
	status.progress_under_name = 0;
	status.bytes_transfered = 0;
	if([m_status_lock tryLock]) {
		m_status = status;
		[m_status_lock unlock];
	}

	[self updateProgess];

	// mkdirs
	{
		id thing;
		NSEnumerator* en = [m_items objectEnumerator];
		while(thing = [en nextObject]) {
			if([thing isKindOfClass:[JFSystemCopyThreadItem class]] == NO) {
				continue;
			}
			JFSystemCopyThreadItem* item = (JFSystemCopyThreadItem*)thing;
			NSString* name = [item name];

			// NSLog(@"cloning dirs... %@", name);
			[self cloneDirsForName:name];
			// NSLog(@"successfully cloned dirs.  %@", name);

			if([self isRunning] == NO) {
				NSLog(@"%s abort for mkdir: %@", _cmd, name);
				return;
			}
		}
	}
	
	// copy data
	{
		id thing;
		NSEnumerator* en = [m_items objectEnumerator];
		while(thing = [en nextObject]) {
			if([thing isKindOfClass:[JFSystemCopyThreadItem class]] == NO) {
				continue;
			}
			JFSystemCopyThreadItem* item = (JFSystemCopyThreadItem*)thing;
			NSString* name = [item name];
	 		m_bytes_total_under_name = [item bytesTotal];
			m_bytes_copied_under_name = 0;

			// reset progress
			if([m_status_lock tryLock]) {
				m_status.progress_under_name = 0;
				[m_status_lock unlock];
			}

			// NSLog(@"cloning files... %@", name);
			[self willCopyName:name];
			[self cloneFilesForName:name];
			[self didCopyName:name];
			// NSLog(@"successfully cloned files.  %@", name);

			if([self isRunning] == NO) {
				NSLog(@"%s abort for %@", _cmd, name);
				return;
			}
		}
	}
}

-(void)start {
/*	NSLog(@"%s started", _cmd);
	NSLog(@"%s source: %@", _cmd, m_source_dir);
	NSLog(@"%s target: %@", _cmd, m_target_dir);
	NSLog(@"%s items: %@", _cmd, m_items); */
	
	[self gatherInfoAboutFiles];
	[self copyFiles];
}

-(void)startCopying {
	// NSLog(@"%s", _cmd);
	double t0 = CFAbsoluteTimeGetCurrent();

	[m_is_running_lock lock];
	BOOL is_already_busy = m_is_running;
	m_is_running = YES;
	[m_is_running_lock unlock];
	if(is_already_busy) {
		NSLog(@"ERROR: %s is already busy. Cannot start copying!", _cmd);
		return;
	}

	m_throughput.last_time = t0;
	m_throughput.last_bytes = 0;
	m_throughput.sample_index = 0;
	for(unsigned int i=0; i<kJFByteSampleCount; ++i) {
		m_throughput.bytes[i] = 0;
	}
	[self copyFiles];


	[m_is_running_lock lock];
	m_is_running = NO;
	[m_is_running_lock unlock];
	
	double t1 = CFAbsoluteTimeGetCurrent();
	
	double elapsed_time = t1 - t0;

	// NSLog(@"%s %llu of %llu. %.3f", _cmd, m_bytes_copied, m_bytes_total, elapsed_time);

	[self copyOperationCompletedBytes:m_bytes_copied elapsed:elapsed_time];
}

-(NSString*)description {
	NSString* thread_name = [[NSThread currentThread] name];
	return [NSString stringWithFormat: 
		@"JFSystemCopyThread\n"
		"thread_name: %@\n"
		"m_source_dir: %@\n"
		"m_target_dir: %@\n"
		"m_items: %@",
		thread_name,
		m_source_dir,
		m_target_dir,
		m_items
	];
}


@end
