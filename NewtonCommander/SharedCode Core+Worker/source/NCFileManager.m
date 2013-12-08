//
//  NCFileManager.m
//  NCCore
//
//  Created by Simon Strandgaard on 18/05/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "NCLog.h"
#import "NCFileManager.h"
#include <sys/acl.h>
#include <sys/attr.h>
#include <sys/xattr.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <pwd.h>               
#include <grp.h>
#include <time.h>
#include <membership.h>


NSString * const NCFileSystemFileNumber             = @"FileSystemFileNumber";
NSString * const NCFileType                         = @"FileType";
NSString * const NCFileSize                         = @"FileSize";
NSString * const NCFileReferenceCount               = @"ReferenceCount";
NSString * const NCFileGroupOwnerAccountName        = @"GroupOwnerAccountName";
NSString * const NCFileOwnerAccountName             = @"OwnerAccountName";
NSString * const NCFilePosixPermissions             = @"PosixPermissions";
NSString * const NCFileFlags                        = @"Flags";
NSString * const NCFileAccessDate                   = @"AccessDate";        // stat.st_atimespec
NSString * const NCFileContentModificationDate      = @"ContentModDate";    // stat.st_mtimespec
NSString * const NCFileAttributeModificationDate    = @"AttributeModDate";  // stat.st_ctimespec
NSString * const NCFileCreationDate                 = @"CreationDate";      // stat.st_birthtimespec
NSString * const NCFileBackupDate                   = @"BackupDate";        // not found in the stat struct


NSString * const NCSpotlightKind             = @"SpotlightKind";           // corresponds to kMDItemKind
NSString * const NCSpotlightContentType      = @"SpotlightContentType";    // corresponds to kMDItemContentType
NSString * const NCSpotlightFinderComment    = @"SpotlightFinderComment";  // corresponds to kMDItemFinderComment


NSString * const NCFileTypeFIFO              = @"FIFO";
NSString * const NCFileTypeWhiteout          = @"Whiteout";
NSString * const NCFileTypeDirectory         = @"Directory";
NSString * const NCFileTypeRegular           = @"Regular";
NSString * const NCFileTypeSymbolicLink      = @"SymbolicLink";
NSString * const NCFileTypeSocket            = @"Socket";
NSString * const NCFileTypeCharacterSpecial  = @"CharacterSpecial";
NSString * const NCFileTypeBlockSpecial      = @"BlockSpecial";
NSString * const NCFileTypeUnknown           = @"Unknown";


typedef struct {
    u_int32_t length;
	off_t file_total_length;
	off_t file_total_allocsize;
	off_t file_data_length;
	off_t file_data_allocsize;
	off_t file_rsrc_length;
	off_t file_rsrc_allocsize;
} __attribute__((packed)) AttrBuffer;



// same as stat.st_mtimespec, but without the problem where dates before 1970 couldn't be seen.
// here the dates go all the way back to 1900.
// however there is another problem.. the code hangs when the path is set to "/Volumes"
NSDate* xget_contentmodtime(const char* path) {
	FSRef ref;
	Boolean is_directory;
	if(FSPathMakeRef((UInt8*)path, &ref, &is_directory) != noErr) {
		return nil;
	}

	FSCatalogInfo catinfo;
	if(FSGetCatalogInfo(&ref, (kFSCatInfoContentMod | kFSCatInfoDataSizes), &catinfo, nil, nil, nil) != noErr) {
		return nil;
	}

	CFAbsoluteTime abs_time = 0;
	UCConvertUTCDateTimeToCFAbsoluteTime( &catinfo.contentModDate, &abs_time );
	return [NSDate dateWithTimeIntervalSinceReferenceDate: abs_time];
}


// same as stat.st_mtimespec with the same problem that dates before 1970 cannot be seen
NSDate* get_contentmodtime(const char* path) {
	return [NSDate date];
	
	struct attrlist attrlist;
	struct {
		u_int32_t length;
		struct timespec ts;
	} attrbuf;
	int err;

	bzero(&attrlist, sizeof(attrlist));
	attrlist.bitmapcount = ATTR_BIT_MAP_COUNT;
	attrlist.commonattr  = ATTR_CMN_MODTIME;
    err = getattrlist(
		path, 
		&attrlist, 
		&attrbuf, 
		sizeof(attrbuf), 
		FSOPT_NOFOLLOW
	);
    if(err != 0) {
		perror("getattrlist");
		return nil;
    }
	if(attrbuf.length != sizeof(attrbuf)) {
		printf("ERROR: get_crtime failed to get crtime\n");
		return nil;
	}
	// printf("read: %u\n", (unsigned long)attrbuf.ts.tv_sec);

	NSTimeInterval seconds = attrbuf.ts.tv_sec;
	return [NSDate dateWithTimeIntervalSince1970:seconds];
}

// same as stat.st_birthtimespec
NSDate* get_crtime(const char* path) {
	return [NSDate date];
	
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
		path, 
		&attrlist, 
		&attrbuf, 
		sizeof(attrbuf), 
		FSOPT_NOFOLLOW
	);
    if(err != 0) {
		perror("getattrlist");
		return nil;
    }
	if(attrbuf.length != sizeof(attrbuf)) {
		printf("ERROR: get_crtime failed to get crtime\n");
		return nil;
	}
	// printf("read: %u\n", (unsigned long)attrbuf.ts.tv_sec);

	NSTimeInterval seconds = attrbuf.ts.tv_sec;
	return [NSDate dateWithTimeIntervalSince1970:seconds];
}

// has no equivalent in the stat struct
NSDate* get_backupdate(const char* path) {
	return [NSDate date];
	
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
		path, 
		&attrlist, 
		&attrbuf, 
		sizeof(attrbuf), 
		FSOPT_NOFOLLOW
	);
    if(err != 0) {
		perror("getattrlist");
		return nil;
    }
	if(attrbuf.length != sizeof(attrbuf)) {
		printf("ERROR: get_crtime failed to get crtime\n");
		return nil;
	}
	// printf("read: %u\n", (unsigned long)attrbuf.ts.tv_sec);

	NSTimeInterval seconds = attrbuf.ts.tv_sec;
	return [NSDate dateWithTimeIntervalSince1970:seconds];
}


@implementation NCFileManager

+(NCFileManager*)shared {
    static NCFileManager* shared = nil;
    if(!shared) {
        shared = [[NCFileManager allocWithZone:NULL] init];
    }
    return shared;
}

- (id)init {
	if(self = [super init]) {
	}
    return self;
}

#pragma mark -

+(NSString*)errnoString:(int)code {
	char message[1024];
	message[0] = 0;
	strerror_r(code, message, 1024);
	return [NSString stringWithFormat:@"ERRNO#%i %s", code, message];
}

#pragma mark -

-(NSDictionary*)attributesOfItemAtPath:(NSString*)path error:(NSError**)error {
	NSMutableDictionary* dict = [[[NSMutableDictionary alloc] init] autorelease];

	const char* stat_path = [path fileSystemRepresentation];
	struct stat st;

	/*
	NOTE: both stat() and lstat() can hang forever when browsing a FTP server.
	For this reason this code needs to be run as a separate process, so that
	it doesn't take down the GUI program.
	*/
	int rc = lstat(stat_path, &st);
	if(rc == -1) {
		// NSLog(@"%s ERROR: lstat() rc: %i  - trying a regular stat  - path: %@", _cmd, rc, path);
		rc = stat(stat_path, &st);
	}
	if(rc == -1) {
		if(error != NULL) {
			NSString* msg = [NCFileManager errnoString:errno];
			if(!msg) msg = @"Unable to stat file.";
	        *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno
				userInfo:[NSDictionary dictionaryWithObject:msg forKey:NSLocalizedDescriptionKey]];
		}
		return nil;
	}

	{
		int filetype = st.st_mode & S_IFMT;
		NSString* obj = NCFileTypeUnknown;
		switch(filetype) {
		case S_IFIFO:  obj = NCFileTypeFIFO; break;
	    case S_IFCHR:  obj = NCFileTypeCharacterSpecial; break;
		case S_IFDIR:  obj = NCFileTypeDirectory; break;
	    case S_IFBLK:  obj = NCFileTypeBlockSpecial; break;
	    case S_IFREG:  obj = NCFileTypeRegular; break;
	    case S_IFLNK:  obj = NCFileTypeSymbolicLink; break;
	    case S_IFSOCK: obj = NCFileTypeSocket; break;
	    case S_IFWHT:  obj = NCFileTypeWhiteout; break;
		}
		[dict setObject:obj forKey:NCFileType];
	}
	
	{
		uint64_t bytes = st.st_size;
		id obj = [NSNumber numberWithUnsignedLongLong:bytes];
		[dict setObject:obj forKey:NCFileSize];
	}

	{
		uint64_t inode = st.st_ino;  // stat.st_ino is not yet 64bit, but this may change soon
		id obj = [NSNumber numberWithUnsignedLongLong:inode];
		[dict setObject:obj forKey:NCFileSystemFileNumber];
	}

	{
		int ref_count = st.st_nlink;
		id obj = [NSNumber numberWithUnsignedLong:ref_count];
		[dict setObject:obj forKey:NCFileReferenceCount];
	}
	
	if(1) {
		//int v = st.st_uid;
		struct passwd* pw = getpwuid(st.st_uid);
		if(pw != NULL)  {
			id obj = [NSString stringWithUTF8String:pw->pw_name];
			[dict setObject:obj forKey:NCFileOwnerAccountName];
		} else {
			// IDEA: find a nice way to store the UID
			// NSLog(@"ERROR: no passwd for UID: %i", v);
		}
	}

	if(1) {
		//int v = st.st_gid;
		struct group* gr = getgrgid(st.st_gid);
		if(gr != NULL)  {
			id obj = [NSString stringWithUTF8String: gr->gr_name];
			[dict setObject:obj forKey:NCFileGroupOwnerAccountName];
		} else {
			// IDEA: find a nice way to store the GID
			// NSLog(@"ERROR: no group for GID: %i", v);
		}
	}
	
	{
		int posix_mode = st.st_mode & 07777;
		id obj = [NSNumber numberWithUnsignedLong:posix_mode];
		[dict setObject:obj forKey:NCFilePosixPermissions];
	}
	
	{
		// list of flags can be seen in /usr/include/sys/stat.h
		unsigned long flags = st.st_flags;
		id obj = [NSNumber numberWithUnsignedLong:flags];
		[dict setObject:obj forKey:NCFileFlags];
	}
	
	{
		NSTimeInterval seconds = st.st_atimespec.tv_sec;
		id obj = [NSDate dateWithTimeIntervalSince1970:seconds];
		[dict setObject:obj forKey:NCFileAccessDate];
	}

#if 1	
	{
		NSTimeInterval seconds = st.st_mtimespec.tv_sec;
		id obj = [NSDate dateWithTimeIntervalSince1970:seconds];
		[dict setObject:obj forKey:NCFileContentModificationDate];
	}
#else
	{
		NSDate* obj = get_contentmodtime(stat_path);
		[dict setObject:obj forKey:NCFileContentModificationDate];
	}
#endif

	{
		NSTimeInterval seconds = st.st_ctimespec.tv_sec;
		id obj = [NSDate dateWithTimeIntervalSince1970:seconds];
		[dict setObject:obj forKey:NCFileAttributeModificationDate];
	}

	{
		/*
		paradox: to use stat64 one must use the define: _DARWIN_FEATURE_64_BIT_INODE
		however our lister code uses getdirentries that uses the define: _DARWIN_NO_64_BIT_INODE
		DAMN IT! In the past I could BOTH use stat64 and getdirentries, however with these
		64bit defines, one of them must go :-(

		TODO: solve st.st_birthtimespec.tv_sec vs. getdirentries  64bit problem
		*/
/*		NSTimeInterval seconds = st.st_birthtimespec.tv_sec;
		id obj = [NSDate dateWithTimeIntervalSince1970:seconds];
		[dict setObject:obj forKey:NCFileCreationDate];*/
		
		// this will work until I eventually find a solution
		NSDate* obj = get_crtime(stat_path);
		[dict setObject:obj forKey:NCFileCreationDate];
	}
	
	{
		NSDate* obj = get_backupdate(stat_path);
		[dict setObject:obj forKey:NCFileBackupDate];
	}
	
	// NSLog(@"dict: %@", dict);
	
	return [dict copy];
}

#pragma mark -


-(NSString*)resolveAlias:(NSString*)path_alias mode:(int*)alias_type {
	// TODO: resolveAlias needs NSError handling
	FSRef ref;
	OSStatus error = 0;

	error = FSPathMakeRef((const UInt8 *)[path_alias fileSystemRepresentation], &ref, NULL);	
	if(error) {
		// NSLog(@"%s ERROR making FSRef", _cmd);
		return nil;
	}


	Boolean is_alias;
	Boolean is_folder;

	error = FSResolveAliasFileWithMountFlags(&ref, false, &is_folder, &is_alias, kResolveAliasFileNoUI);
	if(error != noErr) {
		// NSLog(@"%s ERROR occured calling FSResolveAliasFileWithMountFlags", _cmd);
		return nil;
	}
	if(!is_alias) {
		// this is not an alias file, so we don't output anything
		return nil;
	}

	NSURL* target_url = [(NSURL *)CFURLCreateFromFSRef(NULL, &ref) autorelease];
	if(target_url == nil) {
		// NSLog(@"%s ERROR occurred creating NSURL from FSRef", _cmd);
		return nil;
	}

	NSString* target_path = [target_url path];
	if(target_path == nil) {
		// NSLog(@"%s ERROR occurred creating NSString from NSURL", _cmd);
		return nil;
	}
	
	if(alias_type) {
		*alias_type = (is_folder ? 1 : 0);
	}

	return target_path;
}

-(NSString*)resolvePath:(NSString*)the_path {
	// TODO: resolvePath needs NSError handling
	NSFileManager* fm = [NSFileManager defaultManager];

	NSString* path = @"";
	NSMutableArray* components = [[the_path pathComponents] mutableCopy];
	
	NSMutableSet* set = [NSMutableSet setWithCapacity:10];

	struct stat st;
	
	int iteration_count = 0;
	while([components count] >= 1) {

		/*
		reject symlink loops or alias loops
		*/
		iteration_count++;
		if(iteration_count > 4000) {
			NSLog(@"ERROR: something is wrong.. we are in a loop: %@", fm);
			return nil;
		}
		
		NSString* name = [components objectAtIndex:0];
		[[name retain] autorelease];
		[components removeObjectAtIndex:0];
		
		// removing extraneous path components
		if([name isEqual:@"."]) {
			continue;
		}
		if([name isEqual:@".."]) {
			path = [path stringByDeletingLastPathComponent];
			continue;
		}

		NSString* old_path = path;
		path = [path stringByAppendingPathComponent:name];
		int rc = lstat([fm fileSystemRepresentationWithPath:path], &st);
		if(rc == -1) {
			// NSLog(@"cannot lstat file: %@", path);
			return nil;
		}

		if(S_ISDIR(st.st_mode)) {
			continue;
		}
		
		if(S_ISLNK(st.st_mode)) {
			NSString* target = [fm destinationOfSymbolicLinkAtPath:path error:NULL];
			if(!target) {
				// NSLog(@"symlink didn't return a string: '%@'", path);
				return nil;
			}

			NSString* new_path = target;
			if(![target isAbsolutePath]) {
				new_path = [old_path stringByAppendingPathComponent:target];
			}
			
			if([set containsObject:path]) {
				// NSLog(@"loop detected with symlink: '%@'", path);
				return nil;
			}
			[set addObject:path];

			NSArray* ary = [new_path pathComponents];
			[components replaceObjectsInRange:NSMakeRange(0,0) withObjectsFromArray:ary];
			path = @"";
			continue;
		}

		if(S_ISREG(st.st_mode)) {
			// this is a file, so we determine if it's an alias file
			// NSString* target = [path nc_stringByResolvingAliasMode:NULL];
			NSString* target = [self resolveAlias:path mode:NULL];
			if(!target) {
				// NSLog(@"alias didn't return a string: '%@'", path);
				continue;
			}

			NSString* new_path = target;
			if(![target isAbsolutePath]) {
				// can aliases be relative ?
				new_path = [old_path stringByAppendingPathComponent:target];
			}

			if([set containsObject:path]) {
				// NSLog(@"loop detected with alias: '%@'", path);
				return nil;
			}
			[set addObject:path];

			NSArray* ary = [new_path pathComponents];
			[components replaceObjectsInRange:NSMakeRange(0,0) withObjectsFromArray:ary];
			path = @"";
			continue;
		}
		
	}
	
	return path;
}

#pragma mark -

-(NSDictionary*)aclForItemAtPath:(NSString*)path error:(NSError**)error {
	// TODO: aclForItemAtPath needs NSError handling
	NSMutableDictionary* dict = [[[NSMutableDictionary alloc] init] autorelease];

	const char* fs_path = [path fileSystemRepresentation];

	acl_t acl = acl_get_link_np(fs_path, ACL_TYPE_EXTENDED);

	acl_entry_t dummy;
	if (acl && acl_get_entry(acl, ACL_FIRST_ENTRY, &dummy) == -1) {
		acl_free(acl);
		acl = NULL;

		return nil; // no ACL
	}

	if(acl == NULL) {
		return nil; // no ACL
	}

	acl_free(acl);
	
	/*
	for now we can only return wether a file has ACL or not
	*/
	
	return [dict copy]; // file has ACL records
}

#pragma mark -

-(NSDictionary*)extendedAttributesOfItemAtPath:(NSString*)path error:(NSError**)error {

	const char* fs_path = [path fileSystemRepresentation];
                                                                                            
	int options = XATTR_NOFOLLOW | XATTR_SHOWCOMPRESSION;
	ssize_t buffer_size = listxattr(fs_path, NULL, 0, options);
	if(buffer_size <= 0) {
		return nil;
	}


	NSMutableDictionary* dict = [[[NSMutableDictionary alloc] init] autorelease];
	NSMutableArray* ary = [[[NSMutableArray alloc] init] autorelease];

	char* buffer = (char*)malloc(buffer_size);

	size_t bytes_read = listxattr(fs_path, buffer, buffer_size, options);
	if(bytes_read != buffer_size) {
		LOG_ERROR(@"mismatch in buffer size for file: %@", path);
		return nil;
	}

	// if(m_debug) NSLog(@"%s bytes_read: %i", _cmd, (int)bytes_read);

	int index = 0;
	char* name = buffer;
	for(; name < buffer+buffer_size; name += strlen(name) + 1, index++) {
		/*int size =*/ getxattr(fs_path, name, 0, 0, 0, options);
		
		// if(m_debug) NSLog(@"row: %i  size: %i  name: %s", index, (int)size, name);

		// NSString* s1 = [NSString stringWithFormat:@"xattr[%i]  bytes: ", index];
		// NSString* s2 = [NSString stringWithFormat:@"%i", (int)size];
		NSString* s3 = [NSString stringWithFormat:@"%s", name];
		[ary addObject:s3];

#if 0		
		if(size > 0) {
			char* buf2 = (char*)malloc(size+1);
			int size2 = getxattr(fs_path, name, buf2, size, 0, options);
			if(size != size2) {
				NSLog(@"%s second size mismatch", _cmd);
			}
			
			buf2[size] = 0;
			
			/*
			TODO: how to show xattr in the report, without
			making the report LONG! ?
			*/
			
			if(m_debug) NSLog(@"value: %s", buf2);
			free(buf2);
		}
#endif
	}
	
	free(buffer);


	[dict setObject:ary forKey:@"Keys"];
	[dict setObject:[NSNumber numberWithUnsignedInteger:[ary count]] forKey:@"Count"];
	
	return [dict copy]; // file has xattr records
}

#pragma mark -

-(NSDictionary*)spotlightAttributesOfItemAtPath:(NSString*)path error:(NSError**)error {
	// TODO: spotlightAttributesOfItemAtPath needs NSError handling
	/*
	TODO: make sure things gets released correct in this function
	
	http://developer.apple.com/MacOsX/spotlight.html
	
	prompt> mdls TODO.txt
	...
	huge list of attributes
	...
	prompt>
	
	
	http://developer.apple.com/documentation/Carbon/Reference/MetadataAttributesRef/Reference/CommonAttrs.html#//apple_ref/doc/uid/TP40001694
	*/

#if 1
	if(!path) {
		LOG_DEBUG(@"path is nil");
		return nil;
	}

	NSMutableDictionary* dict = [[[NSMutableDictionary alloc] init] autorelease];

	FSRef ref;
	OSStatus err = FSPathMakeRef((const UInt8 *)[path fileSystemRepresentation], &ref, NULL);
	if(err != noErr) {
		LOG_DEBUG(@"could not make fsref for path: %@", path);
		return nil;
	}
	


	NSString *kind = nil;
	/*NSURL* url = */ [NSURL fileURLWithPath:[path stringByExpandingTildeInPath]];
	LSCopyKindStringForRef(&ref, (CFStringRef*)&kind);
	if(kind) {
		[dict setObject:kind forKey:NCSpotlightKind];
		[kind autorelease];
	}


 	CFTypeRef theUTI = NULL;
    err = LSCopyItemAttribute(&ref, kLSRolesAll, kLSItemContentType, &theUTI);
    [(id)theUTI autorelease];

    // we get this for e.g. doi or unrecognized schemes; let FVPreviewer handle those
    if (err == fnfErr) {
        return nil;
	}
	
	[dict setObject:(NSString*)theUTI forKey:NCSpotlightContentType];

#endif
#if 0
	
	if(!path) {
		LOG_DEBUG(@"path is nil");
		return nil;
	}

	CFStringRef path2 = (CFStringRef)path;
	// CFStringRef path2 = CFSTR("/Volumes/Data/movies1/aliens.avi");       
	// CFStringRef path2 = CFSTR("/Users/neoneye/Desktop/footer.box1");
	// CFStringRef path2 = CFSTR("/Applications/Chess.app");
	// CFStringRef path2 = CFSTR("/Applications/Chess.app/Contents/Info.plist");
	
	MDItemRef item = MDItemCreate(kCFAllocatorDefault, (CFStringRef)path2);
	// MDItemRef item = MDItemCreate(NULL, (CFStringRef)path);
	// MDItemRef item = MDItemCreate(CFGetAllocator((CFStringRef)path), (CFStringRef)path);
	if(!item) {
		LOG_DEBUG(@"MDItemCreate returned NULL for path: %@", path);
		return nil;
	}
	

	CFStringRef comment = MDItemCopyAttribute( item, kMDItemFinderComment );
	if(comment) {
		LOG_DEBUG(@"file: %@  comment: %@", path, (NSString*)comment);
		[dict setObject:(NSString*)comment forKey:NCSpotlightFinderComment];
		CFRelease( comment );
	} else {
		LOG_DEBUG(@"file: %@  has no kMDItemFinderComment attribute", path);
	}
	CFRelease( item );

#endif
#if 0
	
	if(!path) {
		LOG_DEBUG(@"path is nil");
		return nil;
	}

	CFStringRef path2 = (CFStringRef)path;
	// CFStringRef path2 = CFSTR("/Volumes/Data/movies1/aliens.avi");       
	// CFStringRef path2 = CFSTR("/Users/neoneye/Desktop/footer.box1");
	// CFStringRef path2 = CFSTR("/Applications/Chess.app");
	// CFStringRef path2 = CFSTR("/Applications/Chess.app/Contents/Info.plist");
	
	MDItemRef item = MDItemCreate(kCFAllocatorDefault, (CFStringRef)path2);
	// MDItemRef item = MDItemCreate(NULL, (CFStringRef)path);
	// MDItemRef item = MDItemCreate(CFGetAllocator((CFStringRef)path), (CFStringRef)path);
	if(!item) {
		LOG_DEBUG(@"MDItemCreate returned NULL for path: %@", path);
		return nil;
	}
	

	NSMutableDictionary* dict = [[[NSMutableDictionary alloc] init] autorelease];
	CFStringRef kind = MDItemCopyAttribute( item, kMDItemKind );
	if(kind) {
		LOG_DEBUG(@"file: %@  kind: %@", path, (NSString*)kind);
		[dict setObject:(NSString*)kind forKey:NCSpotlightKind];
		CFRelease( kind );                            
	} else {
		LOG_DEBUG(@"file: %@  has no kMDItemKind attribute", path);
	}
	CFRelease( item );


	// NSDictionary *metadataDictionary = (NSDictionary*)MDItemCopyAttributes (fileMetadata,
   	// 		(CFArrayRef)[NSArray arrayWithObjects:(id)kMDItemPixelHeight,(id)kMDItemPixelWidth,nil]);
	
#endif
	
#if 0	

	if(!path) {
		LOG_DEBUG(@"path is nil");
		return nil;
	}

	MDItemRef item = MDItemCreate(kCFAllocatorDefault, (CFStringRef)path);
	if(!item) {
		LOG_DEBUG(@"MDItemCreate returned NULL for path: %@", path);
		return nil;
	}

	CFArrayRef attributeNames = MDItemCopyAttributeNames(item);
	NSArray* array = (NSArray*)attributeNames;
	NSEnumerator *e = [array objectEnumerator];
    id arrayObject;
    
	NSMutableDictionary* dict = [[[NSMutableDictionary alloc] init] autorelease];
    CFTypeRef ref;
    
    while ((arrayObject = [e nextObject])) {
        ref = MDItemCopyAttribute(item, (CFStringRef)[arrayObject description]);
    
        //cast to get an NSObject for convenience
        NSObject* tempObject = (NSObject*)ref;
        
		id thing1 = [arrayObject description];
		id thing2 = [tempObject description];
		if(thing1 == nil) thing1 = @"nil";
		if(thing2 == nil) thing2 = @"nil";
		
		NSString* key = nil;      
		
		if([thing1 isEqual:kMDItemKind]) {
			key = NCSpotlightKind;
		} else
		if([thing1 isEqual:kMDItemContentType]) {
			key = NCSpotlightContentType;
		} else
		if([thing1 isEqual:kMDItemFinderComment]) {
			key = NCSpotlightFinderComment;
		}

		if(key) {
			[dict setObject:thing2 forKey:key];
		}
    }

	CFRelease( item );

#endif

	return [dict copy]; // file has spotlight info
}

-(unsigned long long)sizeOfResourceFork:(NSString*)path {
	const char* path1 = [path fileSystemRepresentation];

	struct attrlist al;
	bzero(&al, sizeof(struct attrlist));
	al.bitmapcount = ATTR_BIT_MAP_COUNT;
	al.fileattr = 
		ATTR_FILE_TOTALSIZE |
		ATTR_FILE_ALLOCSIZE |
		ATTR_FILE_DATALENGTH | 
		ATTR_FILE_DATAALLOCSIZE |
		ATTR_FILE_RSRCLENGTH |
		ATTR_FILE_RSRCALLOCSIZE;

	AttrBuffer buf;
	int err = getattrlist(path1, &al, &buf, sizeof(AttrBuffer), FSOPT_NOFOLLOW);
	if(err) {
		return 0;
	}


	unsigned long long value = buf.file_rsrc_length;
	return value;
}

@end

