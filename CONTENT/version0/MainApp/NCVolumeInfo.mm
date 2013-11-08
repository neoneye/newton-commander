/*********************************************************************
NCVolumeInfo.h - collect info about a mounted volume, such as
 1. volume name, e.g.  Machintosh HD
 2. harddisk capacity, e.g. 320 GB
 3. harddisk used, e.g. 42 GB

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#include "NCVolumeInfo.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/param.h>
#include <sys/mount.h>
#include <Carbon/Carbon.h>


void volumeNameForPath(const char *path, char **volname) {
	CFStringRef pathRef = CFStringCreateWithCString(
		NULL, path, CFStringGetSystemEncoding());
	CFURLRef url = CFURLCreateWithString(NULL, pathRef, NULL);
	FSRef bundleRef;
	FSCatalogInfo info;
	HFSUniStr255 volName;

	if(url) {
		if (CFURLGetFSRef(url, &bundleRef)) {
			if (FSGetCatalogInfo(&bundleRef, kFSCatInfoVolume, 
				&info, NULL, NULL, NULL) == noErr) {
				if ( FSGetVolumeInfo ( info.volume, 0, 
					NULL, kFSVolInfoNone, NULL, &volName, NULL) == noErr) {
					CFStringRef stringRef = FSCreateStringFromHFSUniStr(
						NULL, &volName);
					if (stringRef) {
						*volname = NewPtr(CFStringGetLength(stringRef)+1);
						CFStringGetCString(
							stringRef, 
							*volname, 
							CFStringGetLength(stringRef)+1, 
							kCFStringEncodingMacRoman
						);
						CFRelease(stringRef);
					}
				}
			}
		}
		CFRelease(url);
	}
}



@implementation NCVolumeInfo

- (id)init {
    self = [super init];
	if(self) {
		m_path = nil;
		m_info = nil;
		[self setPath:@"/"];
	}
    return self;
}

-(void)setPath:(NSString*)path {
	if([path isEqual:m_path]) {
		return;
	}
	
	[m_path autorelease];
	m_path = [path retain];
	
	[m_info release];
	m_info = nil;
}

-(void)reloadInfo {
	if(m_path == nil) {
		NSLog(@"%s path is nil", _cmd);
		return;
	}
	if(m_info != nil) {
		return;
	}
	// NSLog(@"%s path: %@", _cmd, m_path);
	const char* cpath = [m_path UTF8String];

	struct statfs64 st;
	int rc = statfs64(cpath, &st);
	if(rc != 0) {
		NSLog(@"%s error: statfs64 failed. %s", _cmd, strerror(errno));
		return;
	}
	// NSLog(@"%s ok", _cmd);
	
	/*
	TODO: determine media type:  FTP, DiskImage, HardDisk, etc.
	TODO: determine local/remote
	*/

    NSMutableString* s = [NSMutableString stringWithCapacity:50];

	// append volume name:  e.g.  Machintosh HD
	{
		char *volname = NULL;
		volumeNameForPath(cpath, &volname);
		[s appendFormat:@"%s", volname];
		DisposePtr(volname);
	}

	[s appendString:@" — "];

	// append type of file system
	st.f_fstypename[MFSTYPENAMELEN-1] = 0;
	[s appendFormat:@"%s", st.f_fstypename];
	
	[s appendString:@" — "];
	
	// append if we are on a readwrite or readonly file system
	if(st.f_flags & MNT_RDONLY) {
		[s appendString:@"readonly"];
	} else {
		[s appendString:@"readwrite"];
	}
	
	[s appendString:@" — "];

	st.f_mntonname[MAXPATHLEN-1] = 0;
	// [s appendFormat:@" %s", st.f_mntonname];
	
	st.f_mntfromname[MAXPATHLEN-1] = 0;
	// [s appendFormat:@" %s", st.f_mntfromname];
	
	uint64_t block_size = st.f_bsize;
	uint64_t number_of_block_total = st.f_blocks;
	uint64_t number_of_block_free = st.f_bfree;
	uint64_t fs_capacity = st.f_blocks * st.f_bsize / (1024 * 1024);
	uint64_t fs_avail = st.f_bfree * st.f_bsize / (1024 * 1024);
	
	uint64_t size_total = number_of_block_total * block_size;
	uint64_t size_avail = number_of_block_free * block_size;

	uint64_t size_total_pretty = size_total;
	const char* size_total_suffix = NULL;
	{
		uint64_t v = size_total;
		const char* s = "B";
		if(v > 1024 * 10) { v >>= 10; s = "KB"; }
		if(v > 1024 * 10) { v >>= 10; s = "MB"; }
		if(v > 1024 * 10) { v >>= 10; s = "GB"; }
		if(v > 1024 * 10) { v >>= 10; s = "TB"; }
		size_total_pretty = v;
		size_total_suffix = s;
	}

	uint64_t size_used = size_total - size_avail;

	uint64_t size_avail_pretty = size_avail;
	const char* size_avail_suffix = NULL;
	{
		uint64_t v = size_avail;
		const char* s = "B";
		size_t shift = 0;
		if(v > 1024 * 10) { v >>= 10; shift = 10; s = "KB"; }
		if(v > 1024 * 10) { v >>= 10; shift = 20; s = "MB"; }
		if(v > 1024 * 10) { v >>= 10; shift = 30; s = "GB"; }
		if(v > 1024 * 10) { v >>= 10; shift = 40; s = "TB"; }
		size_avail_pretty = v;
		size_avail_suffix = s;
		
		/*
		in order to make two numbers add up to 100 GB, 
		we must do a hack so that we ceil the size used and 
		floor the size available. This way we avoid giving a
		false impression that there is more free diskspace 
		available than what there really is.
		*/
		size_used = size_total - (v << shift);
	}

	uint64_t size_used_pretty = size_used;
	const char* size_used_suffix = NULL;
	{
		uint64_t v = size_used;
		const char* s = "B";
		if(v > 1024 * 10) { v >>= 10; s = "KB"; }
		if(v > 1024 * 10) { v >>= 10; s = "MB"; }
		if(v > 1024 * 10) { v >>= 10; s = "GB"; }
		if(v > 1024 * 10) { v >>= 10; s = "TB"; }
		size_used_pretty = v;
		size_used_suffix = s;
	}
	
	/*
	The user usually have in his head how big the disk capacity is, e.g. 100 GB.
	So showing this value will be visual noise after a few times,
	The user will inside his head subtract available from total to compute the size used.
	To make things easier we show "used" and "free"
	*/
	// [s appendFormat:@"%qi %s total", size_total_pretty, size_total_suffix];
	[s appendFormat:@"%qi %s used", size_used_pretty, size_used_suffix];
	[s appendString:@" — "];
	[s appendFormat:@"%qi %s free", size_avail_pretty, size_avail_suffix];
	
	m_info = [s copy];
}

-(NSString*)info {
	[self reloadInfo];
	return (m_info != nil) ? m_info : @"nil";
}

-(void)dealloc {
	[m_path release];
	[m_info release];
    [super dealloc];
}

@end
