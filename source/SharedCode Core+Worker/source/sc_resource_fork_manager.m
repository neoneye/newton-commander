//
// sc_resource_fork_manager.m
// Newton Commander
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "sc_resource_fork_manager.h"
#import <CoreServices/CoreServices.h>

@implementation ResourceForkManager

+(ResourceForkManager*)shared {
    static ResourceForkManager* shared = nil;
    if(!shared) {
        shared = [[ResourceForkManager alloc] init];
    }
    return shared;
}

-(NSData*)getResourceForkFromFile:(NSString*)path {
	FSRef ref;
	OSStatus osstatus = 0;

	osstatus = FSPathMakeRef((const UInt8 *)[path fileSystemRepresentation], &ref, NULL);	
	NSAssert((osstatus == 0), @"failed to make FSRef");

	OSErr oserr;

	HFSUniStr255 fork_name;
	oserr = FSGetResourceForkName(&fork_name);
	if(oserr != noErr) {
		NSLog(@"failed to get name of resourcefork");
		return nil;
	}
	

	FSIORefNum ref_num;
	oserr = FSOpenFork(
		&ref,
		fork_name.length, 
		fork_name.unicode,
		fsRdWrPerm,
		&ref_num
	);
	if(oserr != noErr) {
		// NSLog(@"failed to open resourcefork");
		return nil;
	}

	NSUInteger start_capacity = 1000;
	NSUInteger grow_capacity = 1000;
	
	NSMutableData* data = [NSMutableData dataWithCapacity:start_capacity];
	
	NSUInteger len = 0;
	for(;;) {
		ByteCount n_read = 0;
		oserr = FSReadFork(
			ref_num,
			fsAtMark,
			0, // ignored because we use fsAtMark
			[data length] - len,
			((char*)[data mutableBytes]) + len,
			&n_read
		);
		len += n_read;
		
		if(oserr == eofErr) {
			break;
		}
		NSAssert((oserr == noErr), @"failed to read from resourcefork");
		
		[data increaseLengthBy:grow_capacity];
	} 
	[data setLength:len];
	
	oserr = FSCloseFork(ref_num);
	NSAssert((oserr == noErr), @"failed to close resourcefork");
	
	if(len == 0) {
		// no data in resource fork
		return nil;
	}
	
	return [data copy];
}

-(void)setResourceFork:(NSData*)data onFile:(NSString*)path {
	FSRef ref;
	OSStatus osstatus = 0;

	osstatus = FSPathMakeRef((const UInt8 *)[path fileSystemRepresentation], &ref, NULL);	
	NSAssert((osstatus == 0), @"failed to make FSRef");

	HFSUniStr255 fork_name;
	FSGetResourceForkName(&fork_name);
	
	OSErr oserr;

	FSIORefNum ref_num;
	oserr = FSOpenFork(
		&ref,
		fork_name.length, 
		fork_name.unicode,
		fsRdWrPerm,
		&ref_num
	);
	NSAssert((oserr == noErr), @"failed to open resourcefork");
	
	ByteCount n_write = 0;
	oserr = FSWriteFork(
		ref_num,
		fsFromStart,
		0,
		[data length],
		[data bytes],
		&n_write
	);
	if(oserr != noErr) {
		NSLog(@"failed to write to resourcefork, code: %i", (int)oserr);
	} else {
		NSAssert((n_write == [data length]), @"failed to write all the data");
	}
	
	oserr = FSCloseFork(ref_num);
	if(oserr != noErr) {
		NSLog(@"failed to close resourcefork for writing");
	}
}

-(void)copyFrom:(NSString*)fromPath to:(NSString*)toPath {
	NSData* data = [self getResourceForkFromFile:fromPath];
	if(data != nil) {
		[self setResourceFork:data onFile:toPath];
	}
}

@end // @implementation ResourceForkManager
