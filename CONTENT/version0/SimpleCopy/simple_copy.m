/*********************************************************************
simple_copy.m - AnalyzeCopy - copy files using NSFileManager
Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#include <stdio.h>
#include <Foundation/Foundation.h>
#import "sc_traversal_objects.h"
#import "sc_tov_print.h"
#import "sc_resource_fork_manager.h"
#import "sc_finder_info_manager.h"
#include <fts.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/xattr.h>
#include <sys/attr.h>
#include <sys/acl.h>


void NSPrint(NSString* str) {
     [str writeToFile:@"/dev/stdout" 
		atomically:NO 
		encoding:NSUTF8StringEncoding
		error:NULL
	 ];
}

/*
TODO: copy between filedescriptors
*/
void copy_time(const char* from_path, const char* to_path) {
	struct stat st;
	if(lstat(from_path, &st) < 0) {
		perror("stat");
		return;
	}

	struct timespec ts[2];
	ts[0] = st.st_atimespec;
	ts[1] = st.st_mtimespec;

	// convert timespec's to timeval's
	struct timeval tv[2];
	int i;
	for(i=0; i<2; ++i) {
		tv[i].tv_sec = ts[i].tv_sec;
		tv[i].tv_usec = ts[i].tv_nsec / 1000;
	}
	
	if(S_ISLNK(st.st_mode)) {
		if(lutimes(to_path, tv) < 0) {
			perror("lutimes");
		}
	} else {
		if(utimes(to_path, tv) < 0) {
			perror("utimes");
		}
	}
}
	
/*
TODO: copy between filedescriptors
*/
void copy_xattr(const char* from_path, const char* to_path) {
	ssize_t buffer_size = listxattr(from_path, NULL, 0, XATTR_NOFOLLOW);
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
	size_t n_read = listxattr(from_path, buffer, buffer_size, XATTR_NOFOLLOW);
	if(n_read != buffer_size) {
		printf("ERROR: listxattr lied to us!\n");
		free(buffer);
		return;
	}

	// build a list of name,value,name,value,name,value,...
	int index = 0;
	char* name = buffer;
	for(; name < buffer+buffer_size; name += strlen(name) + 1, index++) {
		int size = getxattr(from_path, name, 0, 0, 0, XATTR_NOFOLLOW);
		
		if(size > 0) {
			char* buf2 = (char*)malloc(size);
			int size2 = getxattr(from_path, name, buf2, size, 0, XATTR_NOFOLLOW);

			if(size != size2) {
				printf("ERROR: second size mismatch\n");
				break;
			}

			int rc = setxattr(
				to_path, 
				name, 
				buf2,
				size2,
				0,
				XATTR_NOFOLLOW
			);
			if(rc != 0)	{
				perror("setxattr");
			}

			free(buf2);
		}
		if(size == 0) {
			int rc = setxattr(
				to_path, 
				name, 
				0,
				0,
				0,
				XATTR_NOFOLLOW
			);
			if(rc != 0)	{
				perror("setxattr");
			}
		}
	}	

	free(buffer);
}


int fd_copy(int read_fd, int write_fd) {
	const unsigned int buffer_size = 4096;
	char buffer[buffer_size];

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
	}
	return 0;
}


/*
TODO: copy between filedescriptors
*/
void copy_crtime(const char* from_path, const char* to_path) {
	struct attrlist attrlist;
	struct {
		u_int32_t length;
		struct timespec ts;
	} attrbuf;
	int err;

	bzero(&attrlist, sizeof(attrlist));
	attrlist.bitmapcount = ATTR_BIT_MAP_COUNT;
	attrlist.commonattr  = ATTR_CMN_CRTIME;
    err = getattrlist(
		from_path, 
		&attrlist, 
		&attrbuf, 
		sizeof(attrbuf), 
		FSOPT_NOFOLLOW
	);
    if(err != 0) {
		perror("getattrlist");
		return;
    }
	if(attrbuf.length != sizeof(attrbuf)) {
		printf("ERROR: copy_crtime failed to get crtime\n");
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
		perror("setattrlist");
		return;
	}

	// ok, successfully copied the creation time
}


/*
TODO: copy between filedescriptors
*/
void copy_bkuptime(const char* from_path, const char* to_path) {
	struct attrlist attrlist;
	struct {
		u_int32_t length;
		struct timespec ts;
	} attrbuf;
	int err;

	bzero(&attrlist, sizeof(attrlist));
	attrlist.bitmapcount = ATTR_BIT_MAP_COUNT;
	attrlist.commonattr  = ATTR_CMN_BKUPTIME;
    err = getattrlist(
		from_path, 
		&attrlist, 
		&attrbuf, 
		sizeof(attrbuf), 
		FSOPT_NOFOLLOW
	);
    if(err != 0) {
		perror("getattrlist");
		return;
    }
	if(attrbuf.length != sizeof(attrbuf)) {
		printf("ERROR: copy_bkuptime failed to get bkuptime\n");
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
		perror("setattrlist");
		return;
	}

	// ok, successfully copied the backup time
}


/*
TODO: copy between filedescriptors
*/
void copy_permissions(const char* from_path, const char* to_path) {
	struct stat st;
	if(lstat(from_path, &st) < 0) {
		perror("lstat");
		return;
	}
	if(lchmod(to_path, st.st_mode) < 0) {
		perror("lchmod");
		return;
	}
	// ok, successfully copied the permissions
}

/*
TODO: copy between filedescriptors
*/
void copy_owner(const char* from_path, const char* to_path) {
	struct stat st;
	if(lstat(from_path, &st) < 0) {
		perror("lstat");
		return;
	}
	if(lchown(to_path, st.st_uid, st.st_gid) < 0) {
		perror("lchown");
		return;
	}
	// ok, successfully copied the ownership info
}

/*
TODO: copy between filedescriptors
*/
void copy_flags(const char* from_path, const char* to_path) {
	struct stat st;
	if(lstat(from_path, &st) < 0) {
		perror("lstat");
		return;
	}
	if(lchflags(to_path, st.st_flags) < 0) {
		perror("lchflags");
		return;
	}
	// ok, successfully copied the flags
}

/*
TODO: copy between filedescriptors
*/
void copy_acl(const char* from_path, const char* to_path) {
	acl_t acl = acl_get_link_np(from_path, ACL_TYPE_EXTENDED);
	if((acl_t)NULL == acl) {
		if(errno == ENOENT) {
			return; // file has no ACL that we can copy
		}
		perror("acl_get_link_np");
		return;
	}
	
	if(acl_set_file(to_path, ACL_TYPE_EXTENDED, acl) < 0) {
		perror("acl_set_file");
		acl_free(acl);
		return;
	}
	
	acl_free(acl);
	// ok, successfully copied the acl
}



@interface TOVCopier : NSObject <TraversalObjectVisitor> {
	NSMutableString* m_result;
	NSString* m_source_path;
	NSString* m_target_path;
}
@property (retain) NSString* sourcePath;
@property (retain) NSString* targetPath;

-(NSString*)result;

-(NSString*)convert:(NSString*)path;
@end

@implementation TOVCopier

@synthesize sourcePath = m_source_path;
@synthesize targetPath = m_target_path;

-(id)init {
	self = [super init];
    if(self) {
		m_result = [[NSMutableString alloc] initWithCapacity:100000];
    }
    return self;
}

-(void)dealloc {
	[m_result release];
    [super dealloc];
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
	const char* target_path = [[self convert:[obj path]] fileSystemRepresentation];
	const char* source_path = [[obj path] fileSystemRepresentation];

	// TODO: take mode_t from source_path
	
	if(mkdir(target_path, 0777) < 0) {
		perror("mkdir");
	}
	
	// copy finder info
	[[FinderInfoManager shared] 
		copyFrom:[obj path] 
		      to:[self convert:[obj path]]
	];

	copy_xattr(source_path, target_path);
	copy_acl(source_path, target_path);
	copy_permissions(source_path, target_path);
	copy_owner(source_path, target_path);
	copy_flags(source_path, target_path);
	copy_crtime(source_path, target_path);
	copy_bkuptime(source_path, target_path);
	copy_time(source_path, target_path);
}

-(void)visitDirPost:(TODirPost*)obj {
	// do nothing
}

-(void)visitFile:(TOFile*)obj {
	const char* target_path = [[self convert:[obj path]] fileSystemRepresentation];
	const char* source_path = [[obj path] fileSystemRepresentation];

	// copy the data fork
	int fd0 = -1;
	int fd1 = -1;
	do {
		fd0 = open(source_path, O_RDONLY, 0);
		if(fd0 == -1) {
			NSLog(@"%s failed to open source file: %s", _cmd, source_path);
			break;
		}

		fd1 = open(target_path, O_CREAT | O_WRONLY, 0755);
		if(fd1 == -1) {
			NSLog(@"%s failed to open target file: %s", _cmd, target_path);
			break;
		}
	
		fd_copy(fd0, fd1);
	} while(0);
	if(fd0 >= 0) { close(fd0); }
	if(fd1 >= 0) { close(fd1); }


	// copy the resource fork
	[[ResourceForkManager shared] 
		copyFrom:[obj path] 
		      to:[self convert:[obj path]]
	];
	
	// copy finder info
	[[FinderInfoManager shared] 
		copyFrom:[obj path] 
		      to:[self convert:[obj path]]
	];

	copy_xattr(source_path, target_path);
	copy_acl(source_path, target_path);
	copy_permissions(source_path, target_path);
	copy_owner(source_path, target_path);
	copy_flags(source_path, target_path);
	copy_crtime(source_path, target_path);
	copy_bkuptime(source_path, target_path);
	copy_time(source_path, target_path);
}

-(void)visitHardlink:(TOHardlink*)obj {
	const char* link_path = [[self convert:[obj linkPath]] fileSystemRepresentation];
	const char* target_path = [[self convert:[obj path]] fileSystemRepresentation];
	if(link(link_path, target_path) < 0) {
		perror("link");
	}
}

-(void)visitSymlink:(TOSymlink*)obj {
	const char* link_path = [[self convert:[obj linkPath]] fileSystemRepresentation];
	const char* target_path = [[self convert:[obj path]] fileSystemRepresentation];
	const char* source_path = [[obj path] fileSystemRepresentation];
	if(symlink(link_path, target_path) < 0) {
		perror("symlink");
	}

	copy_xattr(source_path, target_path);
	copy_acl(source_path, target_path);
	copy_permissions(source_path, target_path);
	copy_owner(source_path, target_path);
	copy_flags(source_path, target_path);
	copy_crtime(source_path, target_path);
	copy_bkuptime(source_path, target_path);
	copy_time(source_path, target_path);
}

-(void)visitFifo:(TOFifo*)obj {
	const char* target_path = [[self convert:[obj path]] fileSystemRepresentation];
	const char* source_path = [[obj path] fileSystemRepresentation];
	// TODO: obtain mode_t from source_path
	if(mkfifo(target_path, 0777) < 0) {
		perror("mkfifo");
	}

	copy_crtime(source_path, target_path);
	copy_acl(source_path, target_path);
	copy_permissions(source_path, target_path);
	copy_owner(source_path, target_path);
	copy_flags(source_path, target_path);
	copy_bkuptime(source_path, target_path);
	copy_time(source_path, target_path);
}

-(void)visitChar:(TOChar*)obj {
	const char* target_path = [[self convert:[obj path]] fileSystemRepresentation];
	const char* source_path = [[obj path] fileSystemRepresentation];
	struct stat st;
	if(stat(source_path, &st) < 0) {
		perror("stat");
		return;
	}
	if(mknod(target_path, st.st_mode, st.st_rdev) < 0) {
		perror("mknod");
		return;
	}

	copy_acl(source_path, target_path);
	copy_permissions(source_path, target_path);
	copy_owner(source_path, target_path);
	copy_flags(source_path, target_path);
	copy_crtime(source_path, target_path);
	copy_bkuptime(source_path, target_path);
	copy_time(source_path, target_path);
}

-(void)visitBlock:(TOBlock*)obj {
	const char* target_path = [[self convert:[obj path]] fileSystemRepresentation];
	const char* source_path = [[obj path] fileSystemRepresentation];
	struct stat st;
	if(stat(source_path, &st) < 0) {
		perror("stat");
		return;
	}
	if(mknod(target_path, st.st_mode, st.st_rdev) < 0) {
		perror("mknod");
		return;
	}

	copy_acl(source_path, target_path);
	copy_permissions(source_path, target_path);
	copy_owner(source_path, target_path);
	copy_flags(source_path, target_path);
	copy_crtime(source_path, target_path);
	copy_bkuptime(source_path, target_path);
	copy_time(source_path, target_path);
}

-(void)visitOther:(TOOther*)obj {
	// socket and whiteout is not something that we can copy
	NSString* s = [self convert:[obj path]];
	[m_result appendFormat:@"touch '%@'\n", s];
}

@end // @implementation TOVCopier





NSNumber* number_with_inode(ino_t inode) {
	return [NSNumber numberWithUnsignedLongLong:
		(unsigned long long)inode];
}



@interface SimpleCopy : NSObject {
	NSString* m_from_path;
	NSString* m_to_path;
	BOOL m_error;
}
@property (retain) NSString* fromPath;
@property (retain) NSString* toPath;

-(NSArray*)scanHierarchy:(char* const*)argv;
@end

@implementation SimpleCopy

@synthesize fromPath = m_from_path;
@synthesize toPath = m_to_path;

-(id)init {
	self = [super init];
    if(self) {
		m_error = NO;
    }
    return self;
}

-(BOOL)copyFromPath:(NSString*)src toPath:(NSString*)dest {
	[self setFromPath:src];
	[self setToPath:dest];

	NSArray* traversal_object_array = nil;
	{
		const char* path = [m_from_path UTF8String];
		char* ptr = strdup(path);
		char* const paths[] = {
			ptr,
			NULL
		};
		traversal_object_array = [self scanHierarchy:paths];
		free(ptr);
	}

	if(0) {
		TOVPrint* v = [[[TOVPrint alloc] init] autorelease];
		[v setSourcePath:m_from_path];
		[v setTargetPath:m_to_path];

		id thing;
		NSEnumerator* en = [traversal_object_array objectEnumerator];
		while(thing = [en nextObject]) {
			[thing accept:v];
		}
		
		// NSLog(@"%s %@", _cmd, [v result]);
		NSPrint([v result]);
	}

	if(1) {
		TOVCopier* v = [[[TOVCopier alloc] init] autorelease];
		[v setSourcePath:m_from_path];
		[v setTargetPath:m_to_path];

		id thing;
		NSEnumerator* en = [traversal_object_array objectEnumerator];
		while(thing = [en nextObject]) {
			[thing accept:v];
		}
		
		// NSLog(@"%s %@", _cmd, [v result]);
		// NSPrint([v result]);
	}

	
	return YES;
}

-(NSArray*)scanHierarchy:(char* const*)argv {
	FTS *ftsp;
	FTSENT *p, *chp;
	int fts_options = FTS_COMFOLLOW | FTS_PHYSICAL | FTS_NOCHDIR;
	int rval = 0;

	if((ftsp = fts_open(argv, fts_options, NULL)) == NULL) {
		warn("fts_open");
		m_error = YES;
		return;
	}
	/* Initialize ftsp with as many argv[] parts as possible. */
	chp = fts_children(ftsp, 0);
	if(chp == NULL) {
        /* no files to traverse */
    	return;
	}

	NSMutableArray* traversal_object_array = [NSMutableArray arrayWithCapacity:10000];
	NSMutableDictionary* inode_dict = [NSMutableDictionary
	 	dictionaryWithCapacity:10000];

	char symlink_path[PATH_MAX+1];


	while((p = fts_read(ftsp)) != NULL) {
		ino_t inode = p->fts_statp->st_ino;
		NSNumber* inode_number = number_with_inode(inode);

		NSString* path_str = nil;
		if(p->fts_path != NULL) { 
			path_str = [NSString stringWithUTF8String:p->fts_path];
		}


		switch(p->fts_info) {
		case FTS_D: {
			// Directory, pre-order traversal
			id found_obj = [inode_dict objectForKey:inode_number];
			if(found_obj != nil) {
				TOHardlink* obj = [[[TOHardlink alloc] init] autorelease];
				[obj setPath:path_str];
				[obj setLink:found_obj];
				[traversal_object_array addObject:obj];
				
				fts_set(ftsp, p, FTS_SKIP);
				
			} else {
				TODirPre* obj = [[[TODirPre alloc] init] autorelease];
				[obj setPath:path_str];
				[traversal_object_array addObject:obj];
				[inode_dict setObject:obj forKey:inode_number];
			}
			break; }
		case FTS_DP: {
			// Directory, post-order traversal
			TODirPost* obj = [[[TODirPost alloc] init] autorelease];
			[obj setPath:path_str];
			[traversal_object_array addObject:obj];
			break; }
			
		case FTS_F: {
			// File
			id found_obj = [inode_dict objectForKey:inode_number];
			if(found_obj != nil) {
				TOHardlink* obj = [[[TOHardlink alloc] init] autorelease];
				[obj setPath:path_str];
				[obj setLink:found_obj];
				[traversal_object_array addObject:obj];
			} else {
				TOFile* obj = [[[TOFile alloc] init] autorelease];
				[obj setPath:path_str];
				[traversal_object_array addObject:obj];
				[inode_dict setObject:obj forKey:inode_number];
			}
			break; }
			
		case FTS_SL: {
			// Symlink
			// it is NOT possible to create a hardlink to a symlink. 
			// So no need to deal check for hardlinks

			NSString* sl_path = nil;
			int len = readlink(p->fts_path, symlink_path, sizeof(symlink_path) - 1);
			if(len >= 0) {
				symlink_path[len] = '\0';
				sl_path = [NSString stringWithUTF8String:symlink_path];
			}
			TOSymlink* obj = [[[TOSymlink alloc] init] autorelease];
			[obj setPath:path_str];
			[obj setLinkPath:sl_path];
			[traversal_object_array addObject:obj];
			break; }
			
		case FTS_DEFAULT: {
			// Special types
			if(S_ISFIFO(p->fts_statp->st_mode)) {
				// FIFO
				id found_obj = [inode_dict objectForKey:inode_number];
				if(found_obj != nil) {
					// it IS possible to create a hardlink to a fifo.
					TOHardlink* obj = [[[TOHardlink alloc] init] autorelease];
					[obj setPath:path_str];
					[obj setLink:found_obj];
					[traversal_object_array addObject:obj];
				} else {
					TOFifo* obj = [[[TOFifo alloc] init] autorelease];
					[obj setPath:path_str];
					[traversal_object_array addObject:obj];
					[inode_dict setObject:obj forKey:inode_number];
				}
			} else
			if(S_ISCHR(p->fts_statp->st_mode)) {
				// CHAR DEVICE
				TOChar* obj = [[[TOChar alloc] init] autorelease];
				[obj setMajor:major(p->fts_statp->st_rdev)];
				[obj setMinor:minor(p->fts_statp->st_rdev)];
				[obj setPath:path_str];
				[traversal_object_array addObject:obj];
			} else
			if(S_ISBLK(p->fts_statp->st_mode)) {
				// BLOCK DEVICE
				TOBlock* obj = [[[TOBlock alloc] init] autorelease];
				[obj setMajor:major(p->fts_statp->st_rdev)];
				[obj setMinor:minor(p->fts_statp->st_rdev)];
				[obj setPath:path_str];
				[traversal_object_array addObject:obj];
			} else
			{
				// Sockets, Whiteout, are there any others?
				TOOther* obj = [[[TOOther alloc] init] autorelease];
				[obj setPath:path_str];
				[traversal_object_array addObject:obj];
			}
			break; }
		default: {
			printf("XXXXXXXXXXXX %s\n", p->fts_path);
			break; }
		}
	}
	fts_close(ftsp);
	
	return traversal_object_array;
}

-(void)dealloc {
    [super dealloc];
}

@end



int main(int argc, char** argv) {
	if(argc < 3) {
		printf("simple_copy 0.0\n");
		printf("by Simon Strandgaard <simon@opcoders.com>\n\n");
		printf("  usage:\n  simple_copy <srcdir> <destdir>\n\n\n");
		fflush(stdout);
		return -1;
	}
	
	[[NSAutoreleasePool alloc] init];

	// obtain absolute paths
	NSString* src = nil;
	NSString* dest = nil;
	{
		char absolute_path[PATH_MAX + 1];
		realpath(argv[1], absolute_path);
		src = [NSString stringWithUTF8String:absolute_path];
	}
	{
		char absolute_path[PATH_MAX + 1];
		realpath(argv[2], absolute_path);
		dest = [NSString stringWithUTF8String:absolute_path];
	}

	// copy
	SimpleCopy* sc = [[SimpleCopy alloc] init];
	BOOL ok = [sc copyFromPath:src toPath:dest];
	if(!ok) {
		NSLog(@"ERROR");
		return 1;
	}
	return 0;
}
