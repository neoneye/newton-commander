#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "sc_tov_print.h"

@implementation TOVPrint

@synthesize sourcePath = m_source_path;
@synthesize targetPath = m_target_path;

-(id)init {
	self = [super init];
    if(self) {
		m_result = [[NSMutableString alloc] initWithCapacity:100000];
    }
    return self;
}


-(NSString*)result {
	return [m_result copy];
}

-(NSString*)convert:(NSString*)path {
	if([path hasPrefix:m_source_path]) {
		NSString* s = [path substringFromIndex:[m_source_path length]];
		return [m_target_path stringByAppendingString:s];
	}
	return path;
}

-(void)visitDirPre:(TODirPre*)obj {
	NSString* s = [self convert:[obj path]];
	[m_result appendFormat:@"mkdir '%@'\n", s];
}

-(void)visitDirPost:(TODirPost*)obj {
	// do nothing
}

-(void)visitFile:(TOFile*)obj {
	NSString* s = [self convert:[obj path]];
	[m_result appendFormat:@"touch '%@'\n", s];
}

-(void)visitHardlink:(TOHardlink*)obj {
	NSString* s0 = [self convert:[obj linkPath]];
	NSString* s1 = [self convert:[obj path]];
	[m_result appendFormat:@"bb_hardlink '%@' '%@'\n", s0, s1];
}

-(void)visitSymlink:(TOSymlink*)obj {
	if([obj linkPath] == nil) {
		NSString* s = [self convert:[obj path]];
		[m_result appendFormat:@"touch '%@'\n", s];
	} else {
		NSString* s0 = [self convert:[obj linkPath]];
		NSString* s1 = [self convert:[obj path]];
		[m_result appendFormat:@"ln -s '%@' '%@'\n", s0, s1];
	}
}

-(void)visitFifo:(TOFifo*)obj {
	NSString* s = [self convert:[obj path]];
	[m_result appendFormat:@"mkfifo '%@'\n", s];
}

-(void)visitChar:(TOChar*)obj {
	NSString* s = [self convert:[obj path]];
	NSUInteger major = [obj major];
	NSUInteger minor = [obj minor];
	[m_result appendFormat:@"sudo mknod '%@' c %lu %lu\n", 
		s, (unsigned long)major, (unsigned long)minor];
}

-(void)visitBlock:(TOBlock*)obj {
	NSString* s = [self convert:[obj path]];
	NSUInteger major = [obj major];
	NSUInteger minor = [obj minor];
	[m_result appendFormat:@"sudo mknod '%@' b %lu %lu\n", 
		s, (unsigned long)major, (unsigned long)minor];
}

-(void)visitOther:(TOOther*)obj {
	// socket and whiteout is not something that we can copy
	NSString* s = [self convert:[obj path]];
	[m_result appendFormat:@"touch '%@'\n", s];
}

-(void)visitProgressBefore:(TOProgressBefore*)obj {
	[m_result appendFormat:@"progress_before '%@'\n", [obj name]];
}

-(void)visitProgressAfter:(TOProgressAfter*)obj {
	[m_result appendFormat:@"progress_after '%@'\n", [obj name]];
}

@end
