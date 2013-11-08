/*
 *  CMFunctions.c
 *  worker
 *
 *  Created by Simon Strandgaard on 29/05/11.
 *  Copyright 2011 opcoders.com. All rights reserved.
 *
 */


/*

getattrlist       stat              PBGetCatInfo FSGetCatalogInfo
-----------       ----              ------------ ----------------
ATTR_CMN_CRTIME   st_birthtimespec  ioFlCrDat    createDate
ATTR_CMN_MODTIME  st_mtimespec      ioFlMdDat    contentModDate
ATTR_CMN_CHGTIME  st_ctimespec                   attributeModDate
ATTR_CMN_ACCTIME  st_atimespec                   accessDate
ATTR_CMN_BKUPTIME                   ioFlBkDat    backupDate


*/


#include "CMFunctions.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <fts.h>
#include <unistd.h>
#include <errno.h>
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
		perror("stat is null");
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
		perror("stat is null");
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
		perror("stat is null");
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
		perror("stat is null");
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
	Is it possible to copy FinderInfo via file descriptors?
	Currently I'm using FSGetCatalogInfo + FSSetCatalogInfo, but it sux because it uses FSRef
	TODO: There is a ATTR_CMN_FNDRINFO, so I guess it is possible
	
	Is it possible to copy the resourcefork via file descriptors?
	Currently I'm using FSReadFork + FSWriteFork, but it sux because it uses FSRef
	
	
	IDEA: st_atimespec is settable, but I have not made any attempts at copying it. I could try
	
	NOTE: st_ctimespec is not settable, so we make no attempt at copying this value
	
	NOTE: inode is not settable, so we make no attempt at copying this value
	*/
}

