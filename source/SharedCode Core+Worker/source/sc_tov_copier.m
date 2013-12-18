//
// sc_tov_copier.m
// Newton Commander
//

/*

getattrlist       stat              PBGetCatInfo FSGetCatalogInfo
-----------       ----              ------------ ----------------
ATTR_CMN_CRTIME   st_birthtimespec  ioFlCrDat    createDate
ATTR_CMN_MODTIME  st_mtimespec      ioFlMdDat    contentModDate
ATTR_CMN_CHGTIME  st_ctimespec                   attributeModDate
ATTR_CMN_ACCTIME  st_atimespec                   accessDate
ATTR_CMN_BKUPTIME                   ioFlBkDat    backupDate


*/

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "NCLog.h"
#import "NCFileManager.h"
#import "sc_tov_copier.h"
#import "sc_resource_fork_manager.h"
#import "sc_finder_info_manager.h"
#include <stdio.h>
#include <fts.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/xattr.h>
#include <sys/attr.h>
#include <sys/acl.h>



#if 0
/*
EXPERIMENT: HFS has high precision timestamps. posix doesn't have. So we should use
the HFS code if we want to copy with full precision.

kFSCatInfoSettableInfo
*/
void copy_time2(const char* from_path, const char* to_path) {
	FSRef from_ref;
	Boolean from_is_directory;
	if(FSPathMakeRef(from_path, &from_ref, &from_is_directory) != noErr) {
		return;
	}

	FSRef to_ref;
	Boolean to_is_directory;
	if(FSPathMakeRef(to_path, &to_ref, &to_is_directory) != noErr) {
		return;
	}
	
	FSCatalogInfo catinfo;
	if(FSGetCatalogInfo(&from_ref, (kFSCatInfoContentMod | kFSCatInfoDataSizes), &catinfo, nil, nil, nil) != noErr) {
		return;
	}
	 
	if(FSSetCatalogInfo(&to_ref, (kFSCatInfoContentMod | kFSCatInfoDataSizes), &catinfo) != noErr) {
		return;
	}
}
#endif
	

/*
copy xattr between filedescriptors
*/
void copy_xattr_fd(int from_fd, int to_fd) {
	int options = XATTR_SHOWCOMPRESSION;
	ssize_t buffer_size = flistxattr(from_fd, NULL, 0, options);
	if(buffer_size < 0) {
		// something went wrong
		printf("ERROR: something went wrong with listxattr\n");
		return;
	}
	if(buffer_size == 0) {
		// no xattr data
		return;
	}
	
	char* buffer = (char*)malloc(buffer_size);
	size_t n_read = flistxattr(from_fd, buffer, buffer_size, options);
	if(n_read != buffer_size) {
		printf("ERROR: listxattr lied to us!\n");
		free(buffer);
		return;
	}

	// build a list of name,value,name,value,name,value,...
	int index = 0;
	char* name = buffer;
	for(; name < buffer+buffer_size; name += strlen(name) + 1, index++) {
		int size = fgetxattr(from_fd, name, 0, 0, 0, options);
		
		if(size > 0) {
			char* buf2 = (char*)malloc(size);
			int size2 = fgetxattr(from_fd, name, buf2, size, 0, options);

			if(size != size2) {
				printf("ERROR: second size mismatch\n");
				break;
			}

			int rc = fsetxattr(
				to_fd, 
				name, 
				buf2,
				size2,
				0,
				options
			);
			if(rc != 0)	{
				perror("setxattr");
			}

			free(buf2);
		}
		if(size == 0) {
			int rc = fsetxattr(
				to_fd, 
				name, 
				0,
				0,
				0,
				options
			);
			if(rc != 0)	{
				perror("setxattr");
			}
		}
	}	

	free(buffer);
}


/*
IDEA: use FSIterateForks() to make sure that we copy all the forks.
This code only copies the data fork.
err = FSReadFork( srcRefNum, fsAtMark + noCacheMask, 0, bytesToReadThisTime, params->copyBuffer, NULL );
if( err == noErr )
	err = FSWriteFork( destRefNum, fsAtMark + noCacheMask, 0, bytesToWriteThisTime, params->copyBuffer, NULL );
if( err == noErr )
	bytesRemaining -= bytesToReadThisTime;

*/
int copy_data_fd(int read_fd, int write_fd, unsigned long long* result_bytes_copied) {
	const unsigned int buffer_size = 4096;
	char buffer[buffer_size];

	if(result_bytes_copied) {
		*result_bytes_copied = 0;
	}
	
	unsigned long long bytes_copied = 0;

	for(;;) {
		int bytes_read = read(read_fd, buffer, buffer_size);

		if(bytes_read < 0) {
			return -1; // read failed
		}
		if(bytes_read == 0) {
			// upon reading end-of-file, zero is returned
			// printf("r");
			break;
		}

		int bytes_to_write = bytes_read;
		char* ptr = buffer;
		
		int bytes_written = 0;

		int retries = 5;
		while(bytes_to_write > 0) {
			bytes_written = write(write_fd, ptr, bytes_to_write);
			if(bytes_written < 0) {
				return -1; // write failed
			}
			if(bytes_written == 0) {
				retries -= 1;
				if(retries < 0) break;
			}

			bytes_to_write -= bytes_written;
			ptr += bytes_written;
		}
		
		if(retries < 0) {
			errno = EIO; // write() has returned 0 a too many times
			return -1;
		}
		
		bytes_copied += bytes_read;
	}
	
	if(result_bytes_copied) {
		*result_bytes_copied = bytes_copied;
	}
	return 0;
}


void copy_crtime_fd(int from_fd, int to_fd) {
	
	struct attrlist attrlist;
	struct {
		u_int32_t length;
		struct timespec ts;
	} attrbuf;
	int err;

	bzero(&attrlist, sizeof(attrlist));
	attrlist.bitmapcount = ATTR_BIT_MAP_COUNT;
	attrlist.commonattr  = ATTR_CMN_CRTIME;
    err = fgetattrlist(
		from_fd, 
		&attrlist, 
		&attrbuf, 
		sizeof(attrbuf), 
		FSOPT_NOFOLLOW
	);
    if(err != 0) {
		perror("fgetattrlist");
		return;
    }
	if(attrbuf.length != sizeof(attrbuf)) {
		printf("ERROR: copy_crtime_fd failed to get crtime\n");
		return;
	}
	// printf("read: %u\n", (unsigned long)attrbuf.ts.tv_sec);

    err = fsetattrlist(
		to_fd, 
		&attrlist, 
		&attrbuf.ts, 
		sizeof(attrbuf.ts), 
		FSOPT_NOFOLLOW
	);
	if(err != 0) {
		perror("fsetattrlist");
		return;
	}

	// ok, successfully copied the creation time
}

#if 0
void copy_crtime_fd2(int from_fd, const char* to_path) {
	if(!to_path) {
		LOG_ERROR(@"to_path is null");
		return;
	}
	
	struct attrlist attrlist;
	struct {
		u_int32_t length;
		struct timespec ts;
	} attrbuf;
	int err;

	bzero(&attrlist, sizeof(attrlist));
	attrlist.bitmapcount = ATTR_BIT_MAP_COUNT;
	attrlist.commonattr  = ATTR_CMN_CRTIME;
    err = fgetattrlist(
		from_fd, 
		&attrlist, 
		&attrbuf, 
		sizeof(attrbuf), 
		FSOPT_NOFOLLOW
	);
    if(err != 0) {
		perror("fgetattrlist");
		return;
    }
	if(attrbuf.length != sizeof(attrbuf)) {
		printf("ERROR: copy_crtime_fd failed to get crtime\n");
		return;
	}
	// printf("read: %u\n", (unsigned long)attrbuf.ts.tv_sec);

    err = setattrlist(
		to_path, 
		&attrlist, 
		&attrbuf.ts, 
		sizeof(attrbuf.ts), 
		FSOPT_NOFOLLOW
	);
	if(err != 0) {
		perror("fsetattrlist");
		return;
	}

	// ok, successfully copied the creation time
}
#endif


#if 0
/*
nope.. impossible. ctime cannot be set. It's not at settable attribute.
I keep forgetting this.. and the next month I again believe that it's
possible. But it is NOT possible.
http://lists.apple.com/archives/carbon-dev/2007/Aug/msg00338.html
*/
void copy_chgtime_fd2(int from_fd, const char* to_path) {
	if(!to_path) {
		LOG_ERROR(@"to_path is null");
		return;
	}
	
	struct attrlist attrlist;
	struct {
		u_int32_t length;
		struct timespec ts;
	} attrbuf;
	int err;

	bzero(&attrlist, sizeof(attrlist));
	attrlist.bitmapcount = ATTR_BIT_MAP_COUNT;
	attrlist.commonattr  = ATTR_CMN_CHGTIME;  // <------- also know as st_ctimespec
    err = fgetattrlist(
		from_fd, 
		&attrlist, 
		&attrbuf, 
		sizeof(attrbuf), 
		FSOPT_NOFOLLOW
	);
    if(err != 0) {
		perror("fgetattrlist");
		return;
    }
	if(attrbuf.length != sizeof(attrbuf)) {
		printf("ERROR: copy_chgtime_fd failed to get chgtime\n");
		return;
	}
	// printf("read: %u\n", (unsigned long)attrbuf.ts.tv_sec);

    err = setattrlist(
		to_path, 
		&attrlist, 
		&attrbuf.ts, 
		sizeof(attrbuf.ts), 
		FSOPT_NOFOLLOW
	);
	if(err != 0) {
		perror("fsetattrlist");
		return;
	}

	// ok, successfully copied the creation time
}

void set_attrmodtime(const char* path) {
	FSRef ref;
	Boolean is_directory;
	if(FSPathMakeRef(path, &ref, &is_directory) != noErr) {
		LOG_ERROR(@"can't make ref");
		return;
	}
	
	FSCatalogInfo theInfo;
	if(FSGetCatalogInfo(&ref, kFSCatInfoNodeFlags, &theInfo, NULL, NULL, NULL) != noErr) {
		LOG_ERROR(@"can't get catalog info");
		return;
	}
	
	
	FSCatalogInfoBitmap whichInfo = kFSCatInfoAttrMod;   // <------- also know as st_ctimespec
	// theInfo.attributeModDate = processData->currTime;

	// CFAbsoluteTime	 absoluteTimeNow = CFAbsoluteTimeGetCurrent ();
	// UCConvertCFAbsoluteTimeToUTCDateTime(absoluteTimeNow,&theInfo.attributeModDate);

	theInfo.attributeModDate.highSeconds        = 0;
    theInfo.attributeModDate.lowSeconds         = 0xf0000000;
    theInfo.attributeModDate.fraction           = 0;
	
	if(FSSetCatalogInfo(&ref, whichInfo, &theInfo) != noErr) {
		LOG_ERROR(@"can't set catalog info");
		return;
	}

	LOG_INFO(@"set catalog info successful");
	

/*	FSCatalogInfo catinfo;
	if(FSGetCatalogInfo(&ref, (kFSCatInfoContentMod | kFSCatInfoDataSizes), &catinfo, nil, nil, nil) != noErr) {
		return;
	}

	CFAbsoluteTime abs_time = 0;
	UCConvertUTCDateTimeToCFAbsoluteTime( &catinfo.contentModDate, &abs_time );
	return [NSDate dateWithTimeIntervalSinceReferenceDate: abs_time]; */
}
#endif


void copy_bkuptime_fd(int from_fd, int to_fd) {
	struct attrlist attrlist;
	struct {
		u_int32_t length;
		struct timespec ts;
	} attrbuf;
	int err;

	bzero(&attrlist, sizeof(attrlist));
	attrlist.bitmapcount = ATTR_BIT_MAP_COUNT;
	attrlist.commonattr  = ATTR_CMN_BKUPTIME;
    err = fgetattrlist(
		from_fd, 
		&attrlist, 
		&attrbuf, 
		sizeof(attrbuf), 
		FSOPT_NOFOLLOW
	);
    if(err != 0) {
		perror("fgetattrlist");
		return;
    }
	if(attrbuf.length != sizeof(attrbuf)) {
		printf("ERROR: copy_bkuptime_fd failed to get bkuptime\n");
		return;
	}
	// printf("read: %u\n", (unsigned long)attrbuf.ts.tv_sec);

    err = fsetattrlist(
		to_fd, 
		&attrlist, 
		&attrbuf.ts, 
		sizeof(attrbuf.ts), 
		FSOPT_NOFOLLOW
	);
	if(err != 0) {
		perror("fsetattrlist");
		return;
	}

	// ok, successfully copied the backup time
}


/*
copy permissions between filedescriptors
*/
void copy_permissions_fd(const struct stat *from_st, int to_fd) {
	if(!from_st) {
		LOG_ERROR(@"stat is null");
		return;
	}

	if(fchmod(to_fd, from_st->st_mode) < 0) {
		perror("fchmod");
		return;
	}
	// ok, successfully copied the permissions
}

/*
copy owner between filedescriptors
*/
void copy_owner_fd(const struct stat *from_st, int to_fd) {
	if(!from_st) {
		LOG_ERROR(@"stat is null");
		return;
	}

	if(fchown(to_fd, from_st->st_uid, from_st->st_gid) < 0) {
		perror("fchown");
		return;
	}
	// ok, successfully copied the ownership info
}

/*
copy flags between filedescriptors
*/
void copy_flags_fd(const struct stat *from_st, int to_fd) {
	if(!from_st) {
		LOG_ERROR(@"stat is null");
		return;
	}

	if(fchflags(to_fd, from_st->st_flags) < 0) {
		perror("fchflags");
		return;
	}
	// ok, successfully copied the flags
}

/*
copy ACL between filedescriptors
*/
void copy_acl_fd(int from_fd, int to_fd) {
	acl_t acl = acl_get_fd_np(from_fd, ACL_TYPE_EXTENDED);
	if((acl_t)NULL == acl) {
		if(errno == ENOENT) {
			return; // file has no ACL that we can copy
		}
		perror("acl_get_fd_np");
		return;
	}

	if(acl_set_fd_np(to_fd, acl, ACL_TYPE_EXTENDED) < 0) {
		perror("acl_set_fd_np");
		acl_free(acl);
		return;
	}
	
	acl_free(acl);
	// ok, successfully copied the acl
}

void copy_time_fd(const struct stat *from_st, int to_fd) {
	if(!from_st) {
		LOG_ERROR(@"stat is null");
		return;
	}

	struct timespec ts[2];
	ts[0] = from_st->st_atimespec;
	ts[1] = from_st->st_mtimespec;

	// convert timespec's to timeval's
	struct timeval tv[2];
	int i;
	for(i=0; i<2; ++i) {
		tv[i].tv_sec = ts[i].tv_sec;
		tv[i].tv_usec = ts[i].tv_nsec / 1000;
	}
	
	/*
	TODO: wrong to use futimes(). This doesn't work on symlinks!!
	*/
	if(futimes(to_fd, tv) < 0) {
		perror("futimes");
	}
}


enum {
	NC_COPYFILE_ACL         = 0x0001,
	NC_COPYFILE_XATTR       = 0x0002,
	NC_COPYFILE_PERMISSIONS = 0x0004,
	NC_COPYFILE_OWNER       = 0x0008,
	NC_COPYFILE_FLAGS       = 0x0010,
	NC_COPYFILE_CRTIME      = 0x0020,
	NC_COPYFILE_BKUPTIME    = 0x0040,
	NC_COPYFILE_TIME        = 0x0080,
	NC_COPYFILE_ALL         = 0xffff,
};

void nc_copyfile_fd(const struct stat *from_st, int from_fd, int to_fd, int flags) {
	if(flags & NC_COPYFILE_XATTR) {
		copy_xattr_fd(from_fd, to_fd);
	}
	if(flags & NC_COPYFILE_ACL) {
		copy_acl_fd(from_fd, to_fd);
	}
	if(flags & NC_COPYFILE_PERMISSIONS) {
		copy_permissions_fd(from_st, to_fd);
	}
	if(flags & NC_COPYFILE_OWNER) {
		copy_owner_fd(from_st, to_fd);
	}
	if(flags & NC_COPYFILE_FLAGS) {
		copy_flags_fd(from_st, to_fd);
	}
	if(flags & NC_COPYFILE_CRTIME) {
		copy_crtime_fd(from_fd, to_fd);
	}
	if(flags & NC_COPYFILE_BKUPTIME) {
		copy_bkuptime_fd(from_fd, to_fd);
	}
	if(flags & NC_COPYFILE_TIME) {
		copy_time_fd(from_st, to_fd);
	}

	/*
	IDEA: st_atimespec is settable, but I have not made any attempts at copying it. I could try
	
	NOTE: st_ctimespec is not settable, so we make no attempt at copying this value
	
	NOTE: inode is not settable, so we make no attempt at copying this value
	*/
}



@implementation TOVCopier

@synthesize sourcePath = m_source_path;
@synthesize targetPath = m_target_path;
@synthesize bytesCopied = m_bytes_copied;
@synthesize statusCode = m_status_code;
@synthesize statusMessage = m_status_message;

-(id)init {
	self = [super init];
    if(self) {
		m_status_code = kCopierStatusOK;
    }
    return self;
}

-(NSString*)result {
	if(m_status_code != kCopierStatusOK) {
		return [NSString stringWithFormat:@"ERROR:%i", (int)m_status_code];
	}
	return @"OK";
}

-(NSString*)convert:(NSString*)path {
	if([path hasPrefix:m_source_path]) {
		NSString* s = [path substringFromIndex:[m_source_path length]];
		return [m_target_path stringByAppendingString:s];
	}
	return path;
}

-(void)setStatus:(NSUInteger)status posixError:(int)error_code message:(NSString*)message, ... {
	va_list ap;
	va_start(ap,message);
	NSString* message2 = [[NSString alloc] initWithFormat:message arguments:ap];
	va_end(ap);

	NSString* error_text = [NCFileManager errnoString:error_code];
	NSString* status_message = [NSString stringWithFormat:@"ERROR status: %i\nposix-code: %@\nmessage: %@", (int)status, error_text, message2];
	LOG_ERROR(@"%@", status_message);

	m_status_code = status;
	self.statusMessage = status_message;
}

-(void)visitDirPre:(TODirPre*)obj {
	const char* target_path = [[self convert:[obj path]] fileSystemRepresentation];
	if(mkdir(target_path, 0700) < 0) {
		if(errno == EEXIST) {
			[self setStatus:kCopierStatusExist posixError:errno 
				message:@"mkdir %s", target_path];
			return;
		}
		[self setStatus:kCopierStatusUnknownDir posixError:errno 
			message:@"mkdir %s", target_path];
	}
}

-(void)visitDirPost:(TODirPost*)obj {
	const char* target_path = [[self convert:[obj path]] fileSystemRepresentation];
	const char* source_path = [[obj path] fileSystemRepresentation];

	// copy finder info
	[[FinderInfoManager shared] 
		copyFrom:[obj path] 
		      to:[self convert:[obj path]]
	];

	int from_fd = open(source_path, O_DIRECTORY);
	if(from_fd < 0) {
		[self setStatus:kCopierStatusUnknownDir posixError:errno 
			message:@"open source dir %s", source_path];
		return;
	}
	struct stat from_st;
	if(fstat(from_fd, &from_st) < 0) {
		[self setStatus:kCopierStatusUnknownDir posixError:errno 
			message:@"stat source dir %s", source_path];
		// TODO: close file descriptors
		return;
	}
	int to_fd = open(target_path, O_DIRECTORY);
	if(to_fd < 0) {
		[self setStatus:kCopierStatusUnknownDir posixError:errno 
			message:@"open target dir %s", target_path];
		// TODO: close file descriptors
		return;
	}
	int flags = NC_COPYFILE_ALL;
	nc_copyfile_fd(&from_st, from_fd, to_fd, flags);
	
	close(to_fd);
	close(from_fd);
}

-(void)visitFile:(TOFile*)obj {
	const char* target_path = [[self convert:[obj path]] fileSystemRepresentation];
	const char* source_path = [[obj path] fileSystemRepresentation];

	{
		/*
		ensure that no file already exists
		this prevent us from overwriting a file if it already exists,
		since open() with O_CREAT doesn't complain if a file already exist
		*/
		struct stat to_st;
		if(lstat(target_path, &to_st) == 0) {
			[self setStatus:kCopierStatusExist posixError:EEXIST 
				message:@"stat target file %s", target_path];
			return;
		}
	}

	unsigned long long bytes_copied = 0;

	{
		// copy the data fork
		int fd0 = -1;
		int fd1 = -1;
		do {
			fd0 = open(source_path, O_RDONLY, 0);
			if(fd0 == -1) {
				[self setStatus:kCopierStatusUnknownFile posixError:errno 
					message:@"open source file %s", source_path];
				break;
			}

			fd1 = open(target_path, O_CREAT | O_WRONLY, 0700);
			if(fd1 == -1) {
				[self setStatus:kCopierStatusUnknownFile posixError:errno 
					message:@"open target file %s", target_path];
				break;
			}
	
			copy_data_fd(fd0, fd1, &bytes_copied);
		} while(0);
		if(fd0 >= 0) { close(fd0); }
		if(fd1 >= 0) { close(fd1); }
		
		if(m_status_code != kCopierStatusOK) {
			return;
		}
	}
	
	/*
	NOTE: This is not optimal. We open the files, transfer data, close the files.
	Then we copy resourcefork and finderinfo using the filenames.
	And finally we open the files, transfer metadata, close the files.
	
	IDEA: I suspect this hurts performance. Could be fun to run some tests.
	*/

	/*
	copy the resource fork
	only FILES have a resource fork. 
	DIRS/Symlinks/FIFOs/Char/Block doesn't have resource fork.
	*/
	[[ResourceForkManager shared] 
		copyFrom:[obj path] 
		      to:[self convert:[obj path]]
	];
	
	// copy finder info
	[[FinderInfoManager shared] 
		copyFrom:[obj path] 
		      to:[self convert:[obj path]]
	];

	{
		int from_fd = open(source_path, O_RDONLY);
		if(from_fd < 0) {
			[self setStatus:kCopierStatusUnknownFile posixError:errno 
				message:@"open source file %s", source_path];
			return;
		}
		struct stat from_st;
		if(fstat(from_fd, &from_st) < 0) {
			[self setStatus:kCopierStatusUnknownFile posixError:errno 
				message:@"stat source file %s", source_path];
			// TODO: close file descriptors
			return;
		}
		int to_fd = open(target_path, O_WRONLY);
		if(to_fd < 0) {
			[self setStatus:kCopierStatusUnknownFile posixError:errno 
				message:@"stat target file %s", target_path];
			// TODO: close file descriptors
			return;
		}
		int flags = NC_COPYFILE_ALL;
		nc_copyfile_fd(&from_st, from_fd, to_fd, flags);

		close(to_fd);
		close(from_fd);
	}

	// keep track of how many bytes we have copied so far, 
	// so we can update progressbars accordingly
	m_bytes_copied += bytes_copied;
}

-(void)visitHardlink:(TOHardlink*)obj {
	const char* link_path = [[self convert:[obj linkPath]] fileSystemRepresentation];
	const char* target_path = [[self convert:[obj path]] fileSystemRepresentation];
	if(link(link_path, target_path) < 0) {
		[self setStatus:kCopierStatusUnknownHardlink posixError:errno 
			message:@"hardlink %s %s", link_path, target_path];
	}
}

-(void)visitSymlink:(TOSymlink*)obj {
	const char* link_path = [[self convert:[obj linkPath]] fileSystemRepresentation];
	const char* target_path = [[self convert:[obj path]] fileSystemRepresentation];
	const char* source_path = [[obj path] fileSystemRepresentation];
	if(symlink(link_path, target_path) < 0) {
		[self setStatus:kCopierStatusUnknownSymlink posixError:errno 
			message:@"symlink %s %s", link_path, target_path];
		return;
	}

	int from_fd = open(source_path, O_SYMLINK);
	if(from_fd < 0) {
		[self setStatus:kCopierStatusUnknownSymlink posixError:errno 
			message:@"open source symlink %s", source_path];
		return;
	}
	struct stat from_st;
	if(fstat(from_fd, &from_st) < 0) {
		[self setStatus:kCopierStatusUnknownSymlink posixError:errno 
			message:@"stat source symlink %s", source_path];
		// TODO: close file descriptors
		return;
	}
	int to_fd = open(target_path, O_SYMLINK);
	if(to_fd < 0) {
		[self setStatus:kCopierStatusUnknownSymlink posixError:errno 
			message:@"open target symlink %s", target_path];
		// TODO: close file descriptors
		return;
	}
	int flags = NC_COPYFILE_ALL;
	nc_copyfile_fd(&from_st, from_fd, to_fd, flags);
	
	close(to_fd);
	close(from_fd);
}

-(void)visitFifo:(TOFifo*)obj {
	const char* target_path = [[self convert:[obj path]] fileSystemRepresentation];
	const char* source_path = [[obj path] fileSystemRepresentation];
	if(mkfifo(target_path, 0700) < 0) {
		[self setStatus:kCopierStatusUnknownFifo posixError:errno 
			message:@"mkfifo %s", target_path];
		return;
	}

	int from_fd = open(source_path, O_RDONLY | O_NONBLOCK);
	if(from_fd < 0) {
		[self setStatus:kCopierStatusUnknownFifo posixError:errno 
			message:@"open source fifo %s", source_path];
		return;
	}
	struct stat from_st;
	if(fstat(from_fd, &from_st) < 0) {
		[self setStatus:kCopierStatusUnknownFifo posixError:errno 
			message:@"stat source fifo %s", source_path];
		// TODO: close file descriptors
		return;
	}
	int to_fd = open(target_path, O_WRONLY | O_NONBLOCK);
	if(to_fd < 0) {
		[self setStatus:kCopierStatusUnknownFifo posixError:errno 
			message:@"open target fifo %s", target_path];
		// TODO: close file descriptors
		return;
	}

	int flags = NC_COPYFILE_ALL;
	flags &= ~NC_COPYFILE_XATTR;
	nc_copyfile_fd(&from_st, from_fd, to_fd, flags);
	
	close(to_fd);
	close(from_fd);
}

-(void)visitChar:(TOChar*)obj {
	const char* target_path = [[self convert:[obj path]] fileSystemRepresentation];
	const char* source_path = [[obj path] fileSystemRepresentation];
	struct stat st;
	if(stat(source_path, &st) < 0) {
		[self setStatus:kCopierStatusUnknownChar posixError:errno 
			message:@"stat source char %s", source_path];
		return;
	}
	if(mknod(target_path, st.st_mode, st.st_rdev) < 0) {
		[self setStatus:kCopierStatusUnknownChar posixError:errno 
			message:@"mknod char %s", target_path];
		return;
	}

	int from_fd = open(source_path, O_RDONLY);
	if(from_fd < 0) {
		[self setStatus:kCopierStatusUnknownChar posixError:errno 
			message:@"open source char %s", source_path];
		return;
	}
	struct stat from_st;
	if(fstat(from_fd, &from_st) < 0) {
		[self setStatus:kCopierStatusUnknownChar posixError:errno 
			message:@"stat source char %s", source_path];
		// TODO: close file descriptors
		return;
	}
	int to_fd = open(target_path, O_WRONLY);
	if(to_fd < 0) {
		[self setStatus:kCopierStatusUnknownChar posixError:errno 
			message:@"open target char %s", target_path];
		// TODO: close file descriptors
		return;
	}
	int flags = NC_COPYFILE_ALL;
	flags &= ~NC_COPYFILE_XATTR;
	nc_copyfile_fd(&from_st, from_fd, to_fd, flags);
	
	close(to_fd);
	close(from_fd);
}

-(void)visitBlock:(TOBlock*)obj {
	const char* target_path = [[self convert:[obj path]] fileSystemRepresentation];
	const char* source_path = [[obj path] fileSystemRepresentation];
	struct stat st;
	if(stat(source_path, &st) < 0) {
		[self setStatus:kCopierStatusUnknownBlock posixError:errno 
			message:@"stat source block %s", source_path];
		return;
	}
	if(mknod(target_path, st.st_mode, st.st_rdev) < 0) {
		[self setStatus:kCopierStatusUnknownBlock posixError:errno 
			message:@"mknod block %s", target_path];
		return;
	}

	int from_fd = open(source_path, O_RDONLY);
	if(from_fd < 0) {
		[self setStatus:kCopierStatusUnknownBlock posixError:errno 
			message:@"open source block %s", source_path];
		return;
	}
	struct stat from_st;
	if(fstat(from_fd, &from_st) < 0) {
		[self setStatus:kCopierStatusUnknownBlock posixError:errno 
			message:@"stat source block %s", source_path];
		// TODO: close file descriptors
		return;
	}
	int to_fd = open(target_path, O_WRONLY);
	if(to_fd < 0) {
		[self setStatus:kCopierStatusUnknownBlock posixError:errno 
			message:@"open target block %s", target_path];
		// TODO: close file descriptors
		return;
	}
	int flags = NC_COPYFILE_ALL;
	flags &= ~NC_COPYFILE_XATTR;
	nc_copyfile_fd(&from_st, from_fd, to_fd, flags);
	
	close(to_fd);
	close(from_fd);
}

-(void)visitOther:(TOOther*)obj {
	// socket and whiteout is not something that we can copy
	/*
	IDEA: create a file with the target_name.. where the content is: 
	Newton Commander - Error - Socket or Other filetype encountered.
	*/
	NSString* s = [self convert:[obj path]];
	[self setStatus:kCopierStatusUnknownOther posixError:0 
		message:@"Unknown file-type at path %@", s];
}

-(void)visitProgressBefore:(TOProgressBefore*)obj {
	// do nothing
}

-(void)visitProgressAfter:(TOProgressAfter*)obj {
	// do nothing
}

@end // @implementation TOVCopier
