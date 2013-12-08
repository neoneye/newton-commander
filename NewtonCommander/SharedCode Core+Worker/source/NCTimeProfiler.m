//
//  NCTimeProfiler.m
//  NCCore
//
//  Created by Simon Strandgaard on 14/07/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

/*
I asked on IRC and Mike Ash replied.
Q: should I use CFAbsoluteTimeGetCurrent() or mach_absolute_time()
A: the latter.

So I'm using mach_absolute_time() from now on.
*/

#import "NCTimeProfiler.h"
#import "FPOCsvWriter.h"
#include <mach/mach_time.h>

/*
Raw mach_absolute_times going in, difference in seconds out
http://www.macresearch.org/tutorial_performance_and_time

NOTE: somewhat evil since it relies on static vars.
*/
double subtract_times(uint64_t endTime, uint64_t startTime) {
    uint64_t difference = endTime - startTime;
    static double conversion = -1.0;
    
    if(conversion < 0.0) {
        mach_timebase_info_data_t info;
        kern_return_t err = mach_timebase_info( &info );
        
		//Convert the timebase into seconds
        if(err == KERN_SUCCESS)
			conversion = 1e-9 * (double)info.numer / (double)info.denom;
    }
    
    return conversion * (double)difference;
}


@interface NCTimeProfilerShared (Private)
-(void)createLog;
@end

@implementation NCTimeProfilerShared

@synthesize handle = m_handle;
@synthesize writer = m_writer;

- (id)init {
    if(self = [super init]) {
		self.handle = [NSFileHandle fileHandleWithStandardOutput];
	}
	return self;
}

/*+(NCTimeProfilerShared*)shared {
    static NCTimeProfilerShared* shared = nil;
    if(!shared) {
        shared = [[NCTimeProfilerShared allocWithZone:NULL] init];
		[shared createLog];
    }
    return shared;
} */

-(void)createLog {
	NSString* path = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/NewtonCommander"];

	NSString* filename = [[NSDate date] descriptionWithCalendarFormat:@"profile_%Y_%m_%d_%H_%M_%S.csv" timeZone:nil locale:nil];
	NSString* logfile = [path stringByAppendingPathComponent:filename];

	NSFileManager* fm = [NSFileManager defaultManager];
	{
		BOOL isdir = NO;
		BOOL exists = [fm fileExistsAtPath:path isDirectory:&isdir];
		if((exists==YES) && (isdir==NO)) {
			[NSException raise:@"Cannot access log file" format:@"Failed to create %@ dir, because there is a file with the same name.", path];
			return;
		}
		if(!exists) {
			BOOL ok = [fm
				createDirectoryAtPath:path 
				withIntermediateDirectories:NO 
				attributes:nil 
				error:NULL];
			NSAssert(ok, @"failed to create dir");
		}
	}

	{
		BOOL isdir = NO;
		BOOL exists = [fm fileExistsAtPath:logfile isDirectory:&isdir];
		NSAssert(!exists, @"there is already a logfile with the exact same name");
	}
	{
		BOOL ok = [fm createFileAtPath:logfile contents:[NSData data] attributes:nil];
		NSAssert(ok, @"couldn't create logfile");
	}

	NSFileHandle* fh = [NSFileHandle fileHandleForWritingAtPath:logfile];
	NSAssert(fh, @"couldn't init filehandle");
	
	self.handle = fh;

    FPOCsvWriter* writer = [[FPOCsvWriter alloc] initWithFileHandle:m_handle];
	self.writer = writer;

/*    [writer writeRow:[NSArray arrayWithObjects:@"Hello \n World", @"Hey", @"\"Good morning\", she said", nil]];
    [writer writeRow:[NSArray arrayWithObjects:@"I can haz üñîçø∂é", @"...", @"New\nline", nil]];
	[m_handle synchronizeFile]; */
}

-(void)writeRow:(NSArray *)row {
	[m_writer writeRow:row];
	[m_handle synchronizeFile];
}

@end


@implementation NCTimeProfiler

- (id)init {
    if(self = [super init]) {
		m_start_time = [[NSMutableDictionary alloc] init];
		m_stop_time = [[NSMutableDictionary alloc] init];
		m_elapsed_time = [[NSMutableDictionary alloc] init];
		m_info = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc {
	[m_start_time release];
	m_start_time = nil;
	
	[m_stop_time release];
	m_stop_time = nil;
	
	[m_elapsed_time release];
	m_elapsed_time = nil;
	
	[m_info release];
	m_info = nil;
	
	[super dealloc];
}

-(void)setObject:(id)obj forKey:(NSString*)key {
	[m_info setObject:obj forKey:key];
}

-(void)startCounter:(NSString*)counterName {
	uint64_t t = mach_absolute_time();
	id obj = [NSNumber numberWithUnsignedLongLong:t];
	[m_start_time setObject:obj forKey:counterName];
}

-(double)stopCounter:(NSString*)counterName {
	uint64_t t_stop = mach_absolute_time();
	{
		id obj = [NSNumber numberWithUnsignedLongLong:t_stop];
		[m_stop_time setObject:obj forKey:counterName];
	}
	
	id obj2 = [m_start_time objectForKey:counterName];
	if(!obj2) {
		return -1;
	}
	if(![obj2 isKindOfClass:[NSNumber class]]) {
		return -1;
	}
	NSNumber* num = (NSNumber*)obj2;
	uint64_t t_start = [num unsignedLongLongValue];
	
	double elapsed = subtract_times(t_stop, t_start);
	// LOG_DEBUG(@"%s time: %lf  counter: %@", _cmd, elapsed, counterName);
	
	{
		id obj = [NSNumber numberWithDouble:elapsed];
		[m_elapsed_time setObject:obj forKey:counterName];
	}
	return elapsed;
}

-(void)start { 
	[self startCounter:@"default"]; 
	[self setObject:[NSDate date] forKey:@"starttime"];
}

-(double)stop { 
	return [self stopCounter:@"default"]; 
}

-(NSString*)description {
	return [NSString stringWithFormat:@"%@ %@", m_info, m_elapsed_time];
}

@end



@interface NSDictionary (NCTimeProfiler)
-(double)microSecondsForKey:(NSString*)key;
-(NSString*)stringForKey:(NSString*)key;
-(int)intForKey:(NSString*)key;
-(NSString*)dateStringForKey:(NSString*)key;
@end

@implementation NSDictionary (NCTimeProfiler)

-(double)microSecondsForKey:(NSString*)key {
	id obj = [self objectForKey:key];
	if([obj isKindOfClass:[NSNumber class]]) {
		double v = [(NSNumber*)obj doubleValue];
		return v * 1e+6; // convert a second to 10^6 microseconds 
	}
	return 0;
}

-(NSString*)stringForKey:(NSString*)key {
	id obj = [self objectForKey:key];
	if([obj isKindOfClass:[NSString class]]) {
		return (NSString*)obj;
	}
	return nil;
}

-(int)intForKey:(NSString*)key {
	id obj = [self objectForKey:key];
	if([obj isKindOfClass:[NSNumber class]]) {
		return [(NSNumber*)obj intValue];
	}
	return 0;
}

-(NSString*)dateStringForKey:(NSString*)key {
	id obj = [self objectForKey:key];
	if([obj isKindOfClass:[NSDate class]]) {
		return [(NSDate*)obj descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S" timeZone:nil locale:nil];
	}
	return @"YYYY-MM-DD hh:mm:ss";
}

@end

@implementation NCTimeProfilerSetWorkingDir

-(NSArray*)columns {
	return [NSArray arrayWithObjects:
		[m_info dateStringForKey:@"starttime"],
		[NSString stringWithFormat:@"%i", [m_info intForKey:@"numberofitems"]],
		[NSString stringWithFormat:@"%.0lf", [m_elapsed_time microSecondsForKey:@"default"]],
		[NSString stringWithFormat:@"%.0lf", [m_elapsed_time microSecondsForKey:@"resolvepath"]],
		[NSString stringWithFormat:@"%.0lf", [m_elapsed_time microSecondsForKey:@"obtainnames"]],
		[NSString stringWithFormat:@"%.0lf", [m_elapsed_time microSecondsForKey:@"obtaintypes"]],
		[NSString stringWithFormat:@"%.0lf", [m_elapsed_time microSecondsForKey:@"analyzelinks"]],
		[NSString stringWithFormat:@"%.0lf", [m_elapsed_time microSecondsForKey:@"detectaliases"]],
		[NSString stringWithFormat:@"%.0lf", [m_elapsed_time microSecondsForKey:@"statremaining"]],
		[m_info stringForKey:@"workingdir"],
		[m_info stringForKey:@"resolvedpath"],
		nil];
}

-(NSArray*)headers {
	return [NSArray arrayWithObjects:
		@"START TIME",
		@"NUMBER OF ITEMS",
		@"TIME TOTAL",
		@"TIME RESOLVING PATH",
		@"TIME OBTAINING NAMES",
		@"TIME OBTAINING TYPES",
		@"TIME ANALYZING LINKS",
		@"TIME DETECTING ALIASES",
		@"TIME STATING THE REMAINING",
		@"WORKING DIR",
		@"RESOLVED PATH",
		nil];
}

-(void)write {
    static NCTimeProfilerShared* shared = nil;
    if(!shared) {
        shared = [[NCTimeProfilerShared allocWithZone:NULL] init];
		[shared createLog];
		[shared writeRow:[self headers]];
    }
	[shared writeRow:[self columns]];
}

-(NSString*)description {
	double t_total = [m_elapsed_time microSecondsForKey:@"default"];
	double t_resolvepath = [m_elapsed_time microSecondsForKey:@"resolvepath"];
	double t_obtainnames = [m_elapsed_time microSecondsForKey:@"obtainnames"];
	double t_obtaintypes = [m_elapsed_time microSecondsForKey:@"obtaintypes"];
	double t_analyzelinks = [m_elapsed_time microSecondsForKey:@"analyzelinks"];
	double t_detectaliases = [m_elapsed_time microSecondsForKey:@"detectaliases"];
	double t_statremaining = [m_elapsed_time microSecondsForKey:@"statremaining"];
	NSString* wdir = [m_info stringForKey:@"workingdir"];
	NSString* rpath = [m_info stringForKey:@"resolvedpath"];
	NSString* date = [m_info dateStringForKey:@"starttime"];
	int numberofitems = [m_info intForKey:@"numberofitems"];
	return [NSString stringWithFormat:@"%@ %.0lf [%.0lf %.0lf %.0lf %.0lf %.0lf %.0lf] %i %@ -> %@", 
		date, t_total, t_resolvepath, t_obtainnames, t_obtaintypes, t_analyzelinks, 
		t_detectaliases, t_statremaining, numberofitems, wdir, rpath];
}

@end
