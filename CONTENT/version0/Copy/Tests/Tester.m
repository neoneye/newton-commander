/*********************************************************************
Tester.m - interface for exercising the copy code

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>

TODO: how to deal with getattrlist() in unistd.h ?

timestamps
ACL's
UID/GID/permissions
resource fork

*********************************************************************/
#import "Tester.h"
#include <sys/xattr.h>
#include <sys/stat.h>
#include <sys/acl.h>
#include <CoreServices/CoreServices.h>
#include <uuid/uuid.h>

static NSString* kCopyTesterRoot   = @"/tmp/nc_copytester";
static NSString* kCopyTesterDest   = @"/tmp/nc_copytester/dest";
static NSString* kCopyTesterSource = @"/tmp/nc_copytester/src";


// returns floating point numbers between -1.0 and 1.0
float random_1d(int x) {
	int s = 71 * x; s = s * 8192 ^ s;
	return 1.0 - ((s*(s*s*15731+789221)+1376312589)&0x7fffffff)/1073741824.0;
}


@implementation Tester

@synthesize rootDir   = m_root_dir;
@synthesize sourceDir = m_source_dir;
@synthesize destDir   = m_dest_dir;

-(id)init {
	self = [super init];
    if(self) {
		[self setRootDir:kCopyTesterRoot];
		[self setSourceDir:kCopyTesterSource];
		[self setDestDir:kCopyTesterDest];
    }
    return self;
}

-(void)dealloc {

    [super dealloc];
}

+(Tester*)tester {
	Tester* t = [[[Tester alloc] init] autorelease];
	[t setup];
	return t;
}

-(BOOL)areWeUsingAppleCopy {
	return YES;
}

-(void)setup {
	NSFileManager* fm = [NSFileManager defaultManager];
	{
		BOOL isdir = NO;
		if([fm fileExistsAtPath:m_root_dir isDirectory:&isdir]) {
			NSAssert(isdir, @"a file exists where the root dir was supposed to be");
			BOOL ok = [fm removeItemAtPath:m_root_dir error:NULL];
			NSAssert(ok, @"couldn't remove destination dir for some reason");
		}
	}
	{
		BOOL ok = [fm createDirectoryAtPath:m_dest_dir
		 	withIntermediateDirectories:YES attributes:nil error:NULL];
		NSAssert(ok, @"couldn't create the dir for some reason");
	}
	{
		BOOL ok = [fm createDirectoryAtPath:m_source_dir
			withIntermediateDirectories:YES attributes:nil error:NULL];
		NSAssert(ok, @"couldn't create the dir for some reason");
	}
}

-(void)makeFile:(NSString*)name data:(NSData*)data {
	NSString* path = [m_source_dir stringByAppendingPathComponent:name];
	[data writeToFile:path atomically:YES];
}

-(void)copyFile:(NSString*)name {
	NSString* path1 = [m_source_dir stringByAppendingPathComponent:name];
	NSString* path2 = [m_dest_dir stringByAppendingPathComponent:name];
	/*
	my tests shows that NSFileManager fails to copy ACL's correct
	*/
	NSFileManager* fm = [NSFileManager defaultManager];
	BOOL ok = [fm copyItemAtPath:path1 toPath:path2 error:NULL];
	NSAssert(ok, @"should be able to copy");
}

-(void)copyFile:(NSString*)name toPath:(NSString*)absPath {
	NSString* path1 = [m_source_dir stringByAppendingPathComponent:name];
	NSFileManager* fm = [NSFileManager defaultManager];
	NSError* err = nil;
	/*
	my tests shows that NSFileManager fails to copy ACL's correct
	*/
	BOOL ok = [fm copyItemAtPath:path1 toPath:absPath error:&err];
	if(!ok) {
		NSLog(@"%s %@", _cmd, err);
	}
	NSAssert(ok, @"should be able to copy");
	
	/*
	in our copy implementation 

	we should use acl_copy_entry() or acl_dup()
	*/
}

-(BOOL)compareFile:(NSString*)name {
	if(![self compareContentFile:name]) return NO;
	if(![self compareXAttrFile:name]) return NO;
	if(![self compareFlagsFile:name]) return NO;
	if(![self compareRsrcForFile:name]) return NO;

	/*
	TODO: timestamps
	TODO: uid
	TODO: gid              
	TODO: posix permissions
	TODO: acl
	TODO: attr
	TODO: Is there something I have forgotten?
	*/
	return YES;
}

-(BOOL)compareContentFile:(NSString*)name {
	NSString* path1 = [m_source_dir stringByAppendingPathComponent:name];
	NSString* path2 = [m_dest_dir stringByAppendingPathComponent:name];
	NSFileManager* fm = [NSFileManager defaultManager];
	return [fm contentsEqualAtPath:path1 andPath:path2];
}

-(void)setXattr:(NSString*)xattrname 
          value:(NSData*)xattrvalue 
           file:(NSString*)name 
{
	NSString* path = [m_source_dir stringByAppendingPathComponent:name];
	const char* filename = [path UTF8String];
	const char* xattrname2 = [xattrname UTF8String];
	int rc = setxattr(
		filename, 
		xattrname2, 
		[xattrvalue bytes],
		[xattrvalue length],
		0,
		XATTR_NOFOLLOW
	);
	if(rc != 0)	{
		perror("setxattr failed");
		NSAssert(0, @"setxattr failed");
	}
	// NSLog(@"%s ok: %@ %@ %@", _cmd, xattrname, xattrvalue, path);
}

-(BOOL)compareXAttrFile:(NSString*)name {
	NSString* path1 = [m_source_dir stringByAppendingPathComponent:name];
	NSString* path2 = [m_dest_dir stringByAppendingPathComponent:name];
	NSArray* xattr1 = [self xattrForFile:path1];
	NSArray* xattr2 = [self xattrForFile:path2];
	// NSLog(@"%s xattr1: %@", _cmd, xattr1);
	// NSLog(@"%s xattr2: %@", _cmd, xattr2);
	return [xattr1 isEqualTo:xattr2];
}

-(NSArray*)xattrForFile:(NSString*)abs_path {
	const char* filename = [abs_path UTF8String];

	ssize_t buffer_size = listxattr(filename, NULL, 0, XATTR_NOFOLLOW);
	if(buffer_size < 0) {
		// something went wrong
		return nil;
	}
	if(buffer_size == 0) {
		// no xattr data
		return [NSArray array];
	}
	
	char* buffer = (char*)malloc(buffer_size);
	size_t n_read = listxattr(filename, buffer, buffer_size, XATTR_NOFOLLOW);
	NSAssert((n_read == buffer_size), @"listxattr lied to us");

	// build a list of name,value,name,value,name,value,...
	NSMutableArray* ary = [NSMutableArray arrayWithCapacity:30];
	int index = 0;
	char* name = buffer;
	for(; name < buffer+buffer_size; name += strlen(name) + 1, index++) {
		int size = getxattr(filename, name, 0, 0, 0, XATTR_NOFOLLOW);
		
		// append the name
		[ary addObject:[NSString stringWithUTF8String:name]];
		
		// append the value
		if(size > 0) {
			char* buf2 = (char*)malloc(size);
			int size2 = getxattr(filename, name, buf2, size, 0, XATTR_NOFOLLOW);
			NSAssert((size == size2), @"second size mismatch");
			[ary addObject:[NSData dataWithBytes:buf2 length:size2]];
			free(buf2);
		} else {
			[ary addObject:[NSNull null]];
		}
	}	

	free(buffer);
	return ary;
}

-(BOOL)compareFlagsFile:(NSString*)name {
	NSString* path1 = [m_source_dir stringByAppendingPathComponent:name];
	NSString* path2 = [m_dest_dir stringByAppendingPathComponent:name];
	NSString* flags1 = [self flagsForFile:path1];
	NSString* flags2 = [self flagsForFile:path2];
	// NSLog(@"%s flags1: %@", _cmd, flags1);
	// NSLog(@"%s flags2: %@", _cmd, flags2);
	return [flags1 isEqualTo:flags2];
}

-(NSString*)flagsForFile:(NSString*)abs_path {
	const char* filename = [abs_path UTF8String];
	struct stat64 st;
	int rc = stat64(filename, &st);
	if(rc == -1) {
		perror("stat64");
		return nil;
	}
	char* s = fflagstostr(st.st_flags);
	if(!s) s = "NULL";
	return [NSString stringWithFormat:@"%s (%08x)", s, st.st_flags];
}

-(void)setFlags:(NSUInteger)flags file:(NSString*)name {
	NSString* path = [m_source_dir stringByAppendingPathComponent:name];
	const char* filename = [path UTF8String];
	int rc = chflags(filename, flags);
	if(rc == -1) {
		perror("chflags");
		NSAssert(0, @"chflags failed");
	}
}

-(void)setRsrcData:(NSData*)data file:(NSString*)name {
	NSString* path = [m_source_dir stringByAppendingPathComponent:name];

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
	NSAssert((oserr == noErr), @"failed to write to resourcefork");
	NSAssert((n_write == [data length]), @"failed to write all the data");
	
	oserr = FSCloseFork(ref_num);
	NSAssert((oserr == noErr), @"failed to close resourcefork");
}
	
-(BOOL)compareRsrcForFile:(NSString*)name {
	NSString* path1 = [m_source_dir stringByAppendingPathComponent:name];
	NSString* path2 = [m_dest_dir stringByAppendingPathComponent:name];
	NSData* data1 = [self rsrcDataFromFile:path1];
	NSData* data2 = [self rsrcDataFromFile:path2];
	// NSLog(@"%s data1: %@", _cmd, data1);
	// NSLog(@"%s data2: %@", _cmd, data2);
	return [data1 isEqualTo:data2];
}

-(NSData*)rsrcDataFromFile:(NSString*)abs_path {
	FSRef ref;
	OSStatus osstatus = 0;

	osstatus = FSPathMakeRef((const UInt8 *)[abs_path fileSystemRepresentation], &ref, NULL);	
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
	
	return [data copy];
}
	
#if 0	
-(void)appendRsrcData:(NSData*)data file:(NSString*)name {
	NSString* path = [m_source_dir stringByAppendingPathComponent:name];

	FSRef ref;
	OSStatus error = 0;

	error = FSPathMakeRef((const UInt8 *)[path fileSystemRepresentation], &ref, NULL);	
	NSAssert((error == 0), @"failed to make FSRef");
	

	HFSUniStr255 fork_name;
	FSGetResourceForkName(&fork_name);

	error = FSCreateResourceFork(
		&ref,
		fork_name.length, 
		fork_name.unicode,
		0
	);
	NSAssert((error == noErr), @"failed to create resourcefork");

	ResFileRefNum ref_num;

	error = FSOpenResourceFile(
		&ref, 
		fork_name.length, 
		fork_name.unicode,
		fsRdWrPerm, 
		&ref_num
	);
	NSAssert((error == noErr), @"failed to open resourcefork");
	
	UseResFile(ref_num);
	error = ResError();
	NSAssert((error == noErr), @"failed to use resfile");


/*
	ResType res_type = 'STR';
	short res_id = 128;
	char* res_data = "Testing Data";
	
	Byte c = 0;
	AddResource(res_data, res_type, res_id, &c);
	err = ResError();	 
/**/
	
	CloseResFile(ref_num);
}
#endif

-(NSString*)sourcePathForFile:(NSString*)name {
	return [m_source_dir stringByAppendingPathComponent:name];
}

-(void)setACL:(NSString*)acl_text path:(NSString*)path {
	NSTask* task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/chmod"];
    NSArray* arguments = [NSArray arrayWithObjects: @"+a", acl_text, path, nil];
    [task setArguments: arguments];
	[task launch];
	[task waitUntilExit];
}

-(void)assignGarbageACLToFile:(NSString*)name {
	NSString* path = [m_source_dir stringByAppendingPathComponent:name];
	const char* path1 = [path UTF8String];
	
	int count = 1;
	acl_t acl;
	acl_entry_t entry;
	
	acl = acl_init(count);
	acl_create_entry(&acl, &entry);
	acl_set_tag_type(entry, ACL_EXTENDED_ALLOW);

#if 1
	acl_permset_t pset;
	acl_get_permset(entry, &pset);
    acl_clear_perms(pset);
	acl_add_perm(pset, ACL_READ_DATA);
	int i;
	for(i=0; i<32; ++i) {
		acl_add_perm(pset, (1<<i));
	}
#endif
	
#if 1
	/*
	only flags that seems to have effect is
		ACL_ENTRY_LIMIT_INHERIT
		NONE
	no other flags seems to make a difference
	*/
	acl_flagset_t flags;
	acl_get_flagset_np(entry, &flags);
	acl_clear_flags_np(flags);
	acl_add_flag_np(flags, ACL_ENTRY_LIMIT_INHERIT);
	// acl_add_flag_np(flags, ACL_ENTRY_ONLY_INHERIT);
	// acl_add_flag_np(flags, ACL_ENTRY_DIRECTORY_INHERIT);
	// acl_add_flag_np(flags, ACL_ENTRY_FILE_INHERIT);
	// acl_add_flag_np(flags, ACL_ENTRY_INHERITED);
	// acl_add_flag_np(flags, ACL_FLAG_DEFER_INHERIT);
#endif
	

#if 0
	// acl_to_text() always returns "!#acl 1".. totally useless :-(
	char* s;
	s = acl_to_text(acl, NULL);
	NSLog(@"%s THE ACL IS: %s", _cmd, s);
	acl_free((void*)s); // surprisingly.. the acl_to_text man page says acl_free must be used. One would have expected "free()" to be used.
#endif
	
	acl_set_file(path1, ACL_TYPE_ACCESS, acl);
	// int fd = open(path1, O_RDWR);
	// acl_set_fd_np(fd, acl, ACL_TYPE_EXTENDED);
	// acl_set_fd_np(fd, acl, ACL_TYPE_DEFAULT);
	// acl_set_fd_np(fd, acl, ACL_TYPE_CODA);
	// acl_set_fd_np(fd, acl, ACL_TYPE_NWFS);
	// close(fd);
	
	// for symlinks there are acl_set_link_np()
	
	
	acl_free(acl);
}

-(NSString*)aclDataFromFile:(NSString*)path {
	const char* path1 = [path UTF8String];
	
	NSMutableString* result = [NSMutableString stringWithCapacity:10000];

	// is there an acl
	acl_t acl = acl_get_link_np(path1, ACL_TYPE_EXTENDED);
	if(acl == (acl_t)NULL) {
		[result appendString:@"acl_get -> NULL"];
		return result;
	}
	
	// does the acl have any entries at all
	{
		acl_entry_t dummy;
		if(acl_get_entry(acl, ACL_FIRST_ENTRY, &dummy) == -1) {
			[result appendString:@"acl_get_entry first -> no entries"];
			acl_free(acl);
			return result;
		}
	}

	// dump all entries
	{
		acl_entry_t entry;
		unsigned int index;
		
		for (index = 0;
		     acl_get_entry(acl, index == 0 ? ACL_FIRST_ENTRY : ACL_NEXT_ENTRY, &entry) == 0;
		     index++) 
		{
			if(index > 0) [result appendString:@"\n"];
			[result appendFormat:@"index#%i, ", index];
            
			// dump qualifier name (apple's kind of user id + group id)
			uuid_t* uu = (uuid_t*)acl_get_qualifier(entry);
			if(uu == NULL) {
				[result appendString:@"no qualifier, "];
			} else {
				char tmp[37]; // uuid's are 36 bytes long
				bzero(tmp, 37);
				uuid_unparse(*uu, tmp);
				tmp[36] = 0;
				[result appendFormat:@"%s, ", tmp];
			}

			// dump the tag_type number
			acl_tag_t tag;
			if(acl_get_tag_type(entry, &tag) != 0) {
				[result appendString:@"no tag, "];
			} else {
				unsigned int tmp = (unsigned int)tag;
				[result appendFormat:@"tag#%u, ", tmp];
			}

			// dump the flags
			acl_flagset_t flags;
			if(acl_get_flagset_np(entry, &flags) != 0) {
				[result appendString:@"no flags, "];
			} else {
				unsigned int bits = 0;                             
				unsigned int i;
				for(i=0; i<32; ++i) {
					unsigned int bit = 1 << i;
					if(acl_get_flag_np(flags, bit)) {
						bits |= bit;
					};
				}
				[result appendFormat:@"flags#%08x, ", bits];
			}

            // dump the permissions
			acl_permset_t perms;
			if(acl_get_permset(entry, &perms) != 0) {
				[result appendString:@"no perms, "];
			} else {
				unsigned int bits = 0;                             
				unsigned int i;
				for(i=0; i<32; ++i) {
					unsigned int bit = 1 << i;
					if(acl_get_perm_np(perms, bit)) {
						bits |= bit;
					};
				}
				[result appendFormat:@"perms#%08x, ", bits];
			}

			// entry has been processed
		}
	}

	[result appendString:@"\nACL HAS BEEN FULLY READ"];
	return result;
}

-(BOOL)compareACLFile:(NSString*)name {
	NSString* path1 = [m_source_dir stringByAppendingPathComponent:name];
	NSString* path2 = [m_dest_dir stringByAppendingPathComponent:name];
	NSString* data1 = [self aclDataFromFile:path1];
	NSString* data2 = [self aclDataFromFile:path2];
	NSLog(@"%s data1: %@", _cmd, data1);
	NSLog(@"%s data2: %@", _cmd, data2);
	return [data1 isEqualTo:data2];
}

-(NSData*)randomDataOfSize:(NSUInteger)bytes {
	NSUInteger i;
	unsigned char* ary = (unsigned char*)malloc(bytes);
	for(i=0; i<bytes; i++) {
		ary[i] = (int)(random_1d(i) * 1000.f) & 255;
	}
	NSData* data = [NSData dataWithBytes:ary length:bytes];
	free(ary);
	return data;
}

@end