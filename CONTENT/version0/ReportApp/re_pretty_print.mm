/*********************************************************************
re_pretty_print.mm - obtain detailed info about a file/dir/...

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>

TODO: fails doing stat64 with broken symlinks

TODO: don't include Carbon. Use CoreFoundation instead.

TODO: Rixstep's ACP Catinfo tool can show a lot of fields that 
doesn't show up in this report. How can I obtain the same info?
HFSPlusCatalogFile has these fields.. HFS timestamps epoch is 1904
fields not present in stat64: backupDate, textEncoding, ...
http://developer.apple.com/technotes/tn/tn1150.html#CatalogFile

TODO: Amit Sing's hfsdebug tool also shows lots of info.
that I have no clue how to obtain.

TODO: obtain more info using getattrlist()

*********************************************************************/
#include "re_pretty_print.h"

#include <sys/acl.h>
#include <sys/attr.h>
#include <sys/xattr.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <pwd.h>               
#include <grp.h>
#include <time.h>
#include <membership.h>
#include <Carbon/Carbon.h>


/*
get attributes
*/
struct AttrBuffer {
    u_int32_t length;
	off_t file_total_length;
	off_t file_total_allocsize;
	off_t file_data_length;
	off_t file_data_allocsize;
	off_t file_rsrc_length;
	off_t file_rsrc_allocsize;
} __attribute__((packed));


/*
this one must be defined in membershipPriv.h, that I don't have access to.
So 400 bytes is just a guess
*/
#define MAXLOGNAME 400


/*
 * print access control list
 */
static struct {
	acl_perm_t	perm;
	char		*name;
	int		flags;
#define ACL_PERM_DIR	(1<<0)
#define ACL_PERM_FILE	(1<<1)
} acl_perms[] = {
	{ACL_READ_DATA,		"read",		ACL_PERM_FILE},
	{ACL_LIST_DIRECTORY,	"list",		ACL_PERM_DIR},
	{ACL_WRITE_DATA,	"write",	ACL_PERM_FILE},
	{ACL_ADD_FILE,		"add_file",	ACL_PERM_DIR},
	{ACL_EXECUTE,		"execute",	ACL_PERM_FILE},
	{ACL_SEARCH,		"search",	ACL_PERM_DIR},
	{ACL_DELETE,		"delete",	ACL_PERM_FILE | ACL_PERM_DIR},
	{ACL_APPEND_DATA,	"append",	ACL_PERM_FILE},
	{ACL_ADD_SUBDIRECTORY,	"add_subdirectory", ACL_PERM_DIR},
	{ACL_DELETE_CHILD,	"delete_child",	ACL_PERM_DIR},
	{ACL_READ_ATTRIBUTES,	"readattr",	ACL_PERM_FILE | ACL_PERM_DIR},
	{ACL_WRITE_ATTRIBUTES,	"writeattr",	ACL_PERM_FILE | ACL_PERM_DIR},
	{ACL_READ_EXTATTRIBUTES, "readextattr",	ACL_PERM_FILE | ACL_PERM_DIR},
	{ACL_WRITE_EXTATTRIBUTES, "writeextattr", ACL_PERM_FILE | ACL_PERM_DIR},
	{ACL_READ_SECURITY,	"readsecurity",	ACL_PERM_FILE | ACL_PERM_DIR},
	{ACL_WRITE_SECURITY,	"writesecurity", ACL_PERM_FILE | ACL_PERM_DIR},
	{ACL_CHANGE_OWNER,	"chown",	ACL_PERM_FILE | ACL_PERM_DIR},
	{(acl_perm_t)0, NULL, 0}
};

static struct {
	acl_flag_t	flag;
	char		*name;
	int		flags;
} acl_flags[] = {
	{ACL_ENTRY_FILE_INHERIT, 	"file_inherit",		ACL_PERM_DIR},
	{ACL_ENTRY_DIRECTORY_INHERIT,	"directory_inherit",	ACL_PERM_DIR},
	{ACL_ENTRY_LIMIT_INHERIT,	"limit_inherit",	ACL_PERM_FILE | ACL_PERM_DIR},
	{ACL_ENTRY_ONLY_INHERIT,	"only_inherit",		ACL_PERM_DIR},
	{(acl_flag_t)0, NULL, 0}
};


char *
uuid_to_name(uuid_t *uu) 
{
  int is_gid = -1;
  struct group *tgrp = NULL;
  struct passwd *tpass = NULL;
  char *name = NULL;
  uid_t the_id;

#define MAXNAMETAG (MAXLOGNAME + 6) /* + strlen("group:") */
  name = (char *) malloc(MAXNAMETAG);
  
  if (NULL == name) {
	  // err(1, "malloc");
	NSLog(@"ERROR: malloc failed");
	exit(-1);
	}

	int f_numericonly = 0;

	if (!f_numericonly) {
  if (0 != mbr_uuid_to_id(*uu, &the_id, &is_gid))
	  goto errout;
	}
  
  switch (is_gid) {
  case ID_TYPE_UID:
	  tpass = getpwuid(the_id);
	  if (!tpass) {
		  goto errout;
	  }
	  snprintf(name, MAXNAMETAG, "%s:%s", "user", tpass->pw_name);
	  break;
  case ID_TYPE_GID:
	  tgrp = getgrgid((gid_t)the_id);
	  if (!tgrp) {
		  goto errout;
	  }
	  snprintf(name, MAXNAMETAG, "%s:%s", "group", tgrp->gr_name);
	  break;
  default:
		goto errout;
  }
  return name;
 errout:
 	snprintf(name, MAXNAMETAG, "<UNKNOWN>");
	
/*	
	// mbr_uuid_to_string() is defined in membershipPriv.h.. that we don't have access to
	if (0 != mbr_uuid_to_string(*uu, name)) {
		fprintf(stderr, "Unable to translate qualifier on ACL\n");
		strcpy(name, "<UNKNOWN>");
	}*/
  return name;
}


@interface REPrettyPrint (Private)

-(void)appendStatDevId:(NSString*)stdev devname:(NSString*)devname;


-(void)dumpReadlink;
-(void)dumpAlias;
-(void)statDev;
-(void)statMode;
-(void)statLinks;
-(void)statNode;  
-(void)statUser;
-(void)statGroup;
-(void)statRDev;
-(void)statTime;
-(void)statSizeAndStuff;
-(void)dumpFinderInfo;
-(void)dumpAttr;
-(void)dumpXattr;
-(void)dumpACL;
-(void)dumpNSFileManager;


- (BOOL)getFSRef:(FSRef *)aFsRef;
- (BOOL)getFSSpec:(FSSpec *)aFSSpec;

- (BOOL)finderInfoFlags:(UInt16*)aFlags type:(OSType*)aType creator:(OSType*)aCreator;

-(void)dumpSpotlightInfo;
@end

@implementation REPrettyPrint

-(id)initWithPath:(NSString*)path {
	self = [super init];
    if(self) {
		m_debug_sections = NO;
		// m_debug_sections = YES;
		m_debug = NO;
		m_path = [path copy];
		m_result = [[NSMutableAttributedString alloc] init];
		m_font1 = nil;
		m_font2 = nil;
		m_font3 = nil;

		{
			NSString* fontname1 = @"BitstreamVeraSansMono-Roman";
			NSString* fontname2 = @"Monaco";
			float fontsize = 12;
			NSFont* font = [NSFont fontWithName:fontname1 size:fontsize];
			if(font == nil) {
				font = [NSFont fontWithName:fontname2 size:fontsize];
			}
			if(font == nil) {
				font = [NSFont systemFontOfSize: fontsize];
			}
			m_font1 = [font retain];
		}
		{
			m_font2 = [[[NSFontManager sharedFontManager] convertFont:m_font1 
				toHaveTrait:NSBoldFontMask] retain];
		}
		{
			NSString* fontname1 = @"BitstreamVeraSansMono-Roman";
			NSString* fontname2 = @"Monaco";
			float fontsize = 16;
			NSFont* font = [NSFont fontWithName:fontname1 size:fontsize];
			if(font == nil) {
				font = [NSFont fontWithName:fontname2 size:fontsize];
			}
			NSFont* font2 = [[[NSFontManager sharedFontManager] convertFont:font
				toHaveTrait:NSBoldFontMask] retain];
			if(font2) font = font2;
			if(font == nil) {
				font = [NSFont labelFontOfSize: fontsize];
			}
			m_font3 = [font retain];
		}
		m_attr1 = [[NSDictionary dictionaryWithObjectsAndKeys:
			m_font1, NSFontAttributeName, 
			[NSColor grayColor], NSForegroundColorAttributeName, 
			nil
		] retain];
		m_attr2 = [[NSDictionary dictionaryWithObjectsAndKeys:
			m_font2, NSFontAttributeName, 
			[NSColor blackColor], NSForegroundColorAttributeName, 
			nil
		] retain];
		m_attr3 = [[NSDictionary dictionaryWithObjectsAndKeys:
			m_font2, NSFontAttributeName, 
			[NSColor whiteColor], NSForegroundColorAttributeName, 
			[NSColor redColor], NSBackgroundColorAttributeName, 
			nil
		] retain];
		{
			NSColor* fg_color = [NSColor whiteColor];
			NSColor* bg_color = [NSColor colorWithCalibratedWhite:0.6 alpha:1.0];
			m_attr4 = [[NSDictionary dictionaryWithObjectsAndKeys:
				m_font3, NSFontAttributeName, 
				fg_color, NSForegroundColorAttributeName, 
				bg_color, NSBackgroundColorAttributeName, 
				nil
			] retain];
		}
    }
    return self;
}

-(void)appendText:(NSString*)s {
	NSAttributedString* as = [[[NSAttributedString alloc] 
		initWithString:s attributes:m_attr1] autorelease];
	[m_result appendAttributedString:as];
}

-(void)appendValue:(NSString*)s {
	NSAttributedString* as = [[[NSAttributedString alloc] 
		initWithString:s attributes:m_attr2] autorelease];
	[m_result appendAttributedString:as];
}

-(void)appendImportantValue:(NSString*)s {
	NSAttributedString* as = [[[NSAttributedString alloc] 
		initWithString:s attributes:m_attr3] autorelease];
	[m_result appendAttributedString:as];
}

-(void)appendHeadlineText:(NSString*)s {
	NSAttributedString* as = [[[NSAttributedString alloc] 
		initWithString:s attributes:m_attr4] autorelease];
	[m_result appendAttributedString:as];
}

-(void)obtain {
	if(m_debug) NSLog(@"%s", _cmd);

	m_append_to_result = YES;
	[m_result deleteCharactersInRange:NSMakeRange(0, [m_result length])];
	[m_result beginEditing];
	
	if(m_append_to_result) {
		[self appendPath];
		[self appendURL];
	}

	if(m_debug_sections) { NSLog(@"section: readlink"); }
	[self dumpReadlink];
	[self dumpAlias];

	/*
	dump the stat64 struct
	*/
	if(m_append_to_result) {
		[self appendText:@"\n\n"];
		[self appendHeadlineText:@"stat64 - file status\n"];
	}
	if(m_debug_sections) { NSLog(@"section: stat64"); }
	[self statDev];                    
	[self statMode];
	[self statLinks];
	[self statNode];
	[self statUser];
	[self statGroup];
	[self statRDev];  
	[self statTime];  
	[self statSizeAndStuff];

	if(m_append_to_result) {
		[self appendText:@"\n\n"];
		[self appendHeadlineText:@"attr - attributes\n"];
	}
	if(m_debug_sections) { NSLog(@"section: attr"); }
	[self dumpAttr];

	if(m_append_to_result) {
		[self appendText:@"\n\n"];
		[self appendHeadlineText:@"xattr - extended attributes\n"];
	}
	if(m_debug_sections) { NSLog(@"section: xattr"); }
	[self dumpXattr];

	if(m_append_to_result) {
		[self appendText:@"\n\n"];
		[self appendHeadlineText:@"acl - access control lists\n"];
	}
	if(m_debug_sections) { NSLog(@"section: acl"); }
	[self dumpACL];
	
	if(m_append_to_result) {
		[self appendText:@"\n\n"];
		[self appendHeadlineText:@"finfo - finder info\n"];
	}
	if(m_debug_sections) { NSLog(@"section: finder"); }
	[self dumpFinderInfo];

	if(m_append_to_result) {
		[self appendText:@"\n\n"];
		[self appendHeadlineText:@"nsfilemanager - fileAttributesAtPath\n"];
	}
	if(m_debug_sections) { NSLog(@"section: nsfilemanager"); }
	[self dumpNSFileManager];

	if(m_append_to_result) {
		[self appendText:@"\n\n"];
		[self appendHeadlineText:@"spotlight\n"];
	}
	if(m_debug_sections) { NSLog(@"section: spotlight"); }
	[self dumpSpotlightInfo];

	if(m_append_to_result) {
		[self appendText:@"\n\n"];                                          
		[self appendHeadlineText:@"end of report\n"];
		[self appendText:@"\n"];
	}
	if(m_debug_sections) { NSLog(@"section: DONE"); }

	[m_result endEditing];

	if(m_debug) NSLog(@"%s %@", _cmd, m_result);
}

-(void)appendPath {
	[self appendText:@"path: "];
	[self appendValue:[NSString stringWithFormat:@"%@\n", m_path]];
}

-(void)appendURL {
	NSURL* url = [NSURL fileURLWithPath:m_path];

	[self appendText:@"url: "];
	[self appendValue:[NSString stringWithFormat:@"%@\n", url]];
}

-(void)dumpReadlink {
	const char* read_path = [m_path UTF8String];
	NSString* link_path = nil;

	if(m_debug) NSLog(@"is_link");
	char path[PATH_MAX + 4];
	int l = readlink(read_path, path, sizeof(path) - 1);
	if(l != -1) {
		path[l] = 0;
		if(m_debug) NSLog(@"%s", path);
		
		BOOL length_not_zero = (path[0] != 0);
		if(length_not_zero) {
			link_path = [NSString stringWithFormat:@"%s", path];
		}
	}

	if(m_append_to_result) {
		if(link_path != nil) {
			[self appendText:@"readlink: "];
			[self appendValue:link_path];
			[self appendText:@"\n"];
		}
	}
}

-(void)dumpAlias {

	FSRef ref;
	OSStatus error = 0;

	error = FSPathMakeRef((const UInt8 *)[m_path fileSystemRepresentation], &ref, NULL);	
	if(error) {
		NSLog(@"%s ERROR making FSRef", _cmd);
		return;
	}
	

	Boolean isAlias;
	Boolean isFolder;

	error = FSResolveAliasFileWithMountFlags(&ref, false, &isFolder, &isAlias, kResolveAliasFileNoUI);
	if(error != noErr) {
		NSLog(@"%s ERROR occured calling FSResolveAliasFileWithMountFlags", _cmd);
		return;
	}
	if(!isAlias) {
		// this is not an alias file, so we don't output anything
		return;
	}

	NSURL* target_url = [(NSURL *)CFURLCreateFromFSRef(NULL, &ref) autorelease];
	if(target_url == nil) {
		NSLog(@"%s ERROR occurred creating NSURL from FSRef", _cmd);
		return;
	}
	
	NSString* target_path = [target_url path];
	if(target_path == nil) {
		NSLog(@"%s ERROR occurred creating NSString from NSURL", _cmd);
		return;
	}

	[self appendText:@"alias: "];
	if(isFolder) {
		[self appendValue:@"folder"];
	} else {
		[self appendValue:@"file"];
	}
	[self appendText:@" refers to "];
	[self appendValue:target_path];
	[self appendText:@"\n"];
	
}

-(void)statDev {	
	const char* stat_path = [m_path UTF8String];
	struct stat64 st;
	int rc = lstat64(stat_path, &st);
	if(rc == -1) {
		NSLog(@"%s ERROR: lstat() rc: %i", _cmd, rc);
		return;
	}
	
	int stdev = st.st_dev;
	if(m_debug) NSLog(@"ID of device containing file: %i", stdev);
	
	const int capacity = 200;
	char device_name[capacity];
	devname_r(st.st_dev, S_IFBLK, device_name, capacity - 1);
	device_name[capacity-1] = 0;
	if(m_debug) NSLog(@"device name: %s", device_name);
	
	if(m_append_to_result) {
		[self appendText:@"st_dev:   "];
		[self appendValue:[NSString stringWithFormat:@"%i", stdev]];
		[self appendText:@"  devname: "];
		[self appendValue:[NSString stringWithFormat:@"%s\n", device_name]];
	}
}

-(void)statMode {	
	const char* stat_path = [m_path UTF8String];
	struct stat64 st;
	int rc = lstat64(stat_path, &st);
	if(rc == -1) {
		NSLog(@"%s ERROR: stat() rc: %i", _cmd, rc);
		return;
	}

	int mode = st.st_mode;
	if(m_debug) NSLog(@"Mode of file: %o", mode);

/*	mode |= S_ISUID;
	mode |= S_ISGID;
	mode |= S_ISVTX;
	mode = 0xffffffff;
	mode = 0; */

	{
		NSString* modeoct = [NSString stringWithFormat:@"%o", mode];

		[self appendText:@"st_mode:  "];
		[self appendValue:modeoct];
		[self appendText:@"  (octal)\n"];
	}

	{
		// anything outside the lower 16 bit is unknown
		int unknown_mode = mode & (~0xffff);
		if(unknown_mode) {
			NSString* modeoct = [NSString stringWithFormat:@"%o", unknown_mode];
			[self appendText:@"    where "];
			[self appendImportantValue:modeoct];
			[self appendText:@" is "];
			[self appendImportantValue:@"UNKNOWN"];
			[self appendText:@"\n"];
		}
	}
    
	{
		// here we dump "type of file"
#if 0	
	 #define S_IFMT 0170000           /* type of file */
     #define        S_IFIFO  0010000  /* named pipe (fifo) */
     #define        S_IFCHR  0020000  /* character special */
     #define        S_IFDIR  0040000  /* directory */
     #define        S_IFBLK  0060000  /* block special */
     #define        S_IFREG  0100000  /* regular */
     #define        S_IFLNK  0120000  /* symbolic link */
     #define        S_IFSOCK 0140000  /* socket */
     #define        S_IFWHT  0160000  /* whiteout */
#endif
		const char* s0 = NULL;                                      
		const char* s1 = NULL;
		int filetype = mode & S_IFMT;
		bool unusual = YES;
		switch(filetype) {
		case S_IFIFO:  s0 = "S_IFIFO";  s1 = "named pipe (fifo)"; break;
	    case S_IFCHR:  s0 = "S_IFCHR";  s1 = "character special"; break;
		case S_IFDIR:  s0 = "S_IFDIR";  s1 = "directory"; unusual = NO; break;
	    case S_IFBLK:  s0 = "S_IFBLK";  s1 = "block special";     break;
	    case S_IFREG:  s0 = "S_IFREG";  s1 = "regular file";  unusual = NO; break;
	    case S_IFLNK:  s0 = "S_IFLNK";  s1 = "symbolic link";     break;
	    case S_IFSOCK: s0 = "S_IFSOCK"; s1 = "socket";            break;
	    case S_IFWHT:  s0 = "S_IFWHT";  s1 = "whiteout";          break;
		}

		NSString* modeoct = [NSString stringWithFormat:@"%o", filetype];

		if((s0 != NULL) && (s1 != NULL)) {
			[self appendText:@"    where "];
			if(unusual) {
				[self appendImportantValue:modeoct];
			} else {
				[self appendValue:modeoct];
			}
			[self appendText:@" is filetype "];
			if(unusual) {
				[self appendImportantValue:[NSString stringWithFormat:@"%s", s0]];
			} else {
				[self appendValue:[NSString stringWithFormat:@"%s", s0]];
			}
			[self appendText:@" - "];
			if(unusual) {
				[self appendImportantValue:[NSString stringWithFormat:@"%s", s1]];
			} else {
				[self appendValue:[NSString stringWithFormat:@"%s", s1]];
			}
		} else {
			[self appendText:@"   filetype: "];
			[self appendImportantValue:modeoct];
			[self appendText:@"  bits: "];
			[self appendImportantValue:@"UNKNOWN"];
		}
		[self appendText:@"\n"];
	}

	{
#if 0
     #define S_ISUID 0004000  /* set user id on execution */
     #define S_ISGID 0002000  /* set group id on execution */
     #define S_ISVTX 0001000  /* save swapped text even after use */
#endif
		if(mode & S_ISUID) {
			NSString* modeoct = [NSString stringWithFormat:@"%o", S_ISUID];
			[self appendText:@"    where "];
			[self appendImportantValue:modeoct];
			[self appendText:@" is "];
			[self appendImportantValue:@"S_ISUID"];
			[self appendText:@" - set user id on execution\n"];
		}
		if(mode & S_ISGID) {
			NSString* modeoct = [NSString stringWithFormat:@"%o", S_ISGID];
			[self appendText:@"    where "];
			[self appendImportantValue:modeoct];
			[self appendText:@" is "];
			[self appendImportantValue:@"S_ISGID"];
			[self appendText:@" - set group id on execution\n"];
		}
		if(mode & S_ISVTX) {
			NSString* modeoct = [NSString stringWithFormat:@"%o", S_ISVTX];
			[self appendText:@"    where "];
			[self appendImportantValue:modeoct];
			[self appendText:@" is "];
			[self appendImportantValue:@"S_ISVTX"];
			[self appendText:@" - save swapped text even after use\n"];
		}
	}
	{
#if 0
     #define S_IRUSR 0000400  /* read permission, owner */
     #define S_IWUSR 0000200  /* write permission, owner */
     #define S_IXUSR 0000100  /* execute/search permission, owner */
#endif
		int unix_mode = mode & 0777;
		NSString* modeoct = [NSString stringWithFormat:@"%o", unix_mode];
		[self appendText:@"    where "];
		[self appendValue:modeoct];
		[self appendText:@" is posix permissions\n"];
	}
	
}

-(void)statLinks {	
	const char* stat_path = [m_path UTF8String];
	struct stat64 st;
	int rc = lstat64(stat_path, &st);
	if(rc == -1) {
		NSLog(@"%s ERROR: stat() rc: %i", _cmd, rc);
		return;
	}

	int link_count = st.st_nlink;
	if(m_debug) NSLog(@"Number of hard links: %i", link_count);

	if(m_append_to_result) {
		[self appendText:@"st_nlink: "];
		[self appendValue:[NSString stringWithFormat:@"%i", link_count]];
		[self appendText:@"  number of hard links\n"];
	}
}

-(void)statNode {	
	const char* stat_path = [m_path UTF8String];
	struct stat64 st;
	int rc = lstat64(stat_path, &st);
	if(rc == -1) {
		NSLog(@"%s ERROR: stat() rc: %i", _cmd, rc);
		return;
	}

	int inode = st.st_ino;
	if(m_debug) NSLog(@"File serial number: %i", inode);

	if(m_append_to_result) {
		[self appendText:@"st_ino:   "];
		[self appendValue:[NSString stringWithFormat:@"%i", inode]];
		[self appendText:@"  file serial number\n"];
	}
}

-(void)statUser {
	const char* stat_path = [m_path UTF8String];
	struct stat64 st;
	int rc = lstat64(stat_path, &st);
	if(rc == -1) {
		NSLog(@"%s ERROR: stat() rc: %i", _cmd, rc);
		return;
	}

	int v = st.st_uid;
	if(m_debug) NSLog(@"UID: %i", v);

	NSString* username = nil;

	/*
	char* s = user_from_uid(st.st_uid, 0);
	*/
	struct passwd* pw = getpwuid(st.st_uid);
	if(pw != NULL)  {
		username = [NSString stringWithFormat:@"%s", pw->pw_name];
	} else {
		NSLog(@"ERROR: no passwd for UID: %i", v);
	}
	
	if(m_debug) {
		NSLog(@"User name: %@", username);
	}

	if(m_append_to_result) {
		[self appendText:@"st_uid:   "];
		[self appendValue:[NSString stringWithFormat:@"%i", st.st_uid]];
		if(username != nil) {
			[self appendText:@"   user id: "];
			[self appendValue:username];
		} else {
			[self appendText:@"   "];
			[self appendImportantValue:@"no username for UID!"];
		}
		[self appendText:@"\n"];
	}
}

-(void)statGroup {
	const char* stat_path = [m_path UTF8String];
	struct stat64 st;
	int rc = lstat64(stat_path, &st);
	if(rc == -1) {
		NSLog(@"%s ERROR: stat() rc: %i", _cmd, rc);
		return;
	}

	int v = st.st_gid;
	if(m_debug) NSLog(@"GID: %i", v);
	
	/*
	char* s = group_from_gid(st.st_gid, 0);
	*/
	struct group* gr = getgrgid(st.st_gid);
	if(gr == NULL)  {
		NSLog(@"ERROR: no group for GID: %i", v);
		return;
	}
	
	if(m_debug) NSLog(@"Group name: %s", gr->gr_name);

	if(m_append_to_result) {
		[self appendText:@"st_gid:   "];
		[self appendValue:[NSString stringWithFormat:@"%i", st.st_gid]];
		[self appendText:@"   group id: "];
		[self appendValue:[NSString stringWithFormat:@"%s\n", gr->gr_name]];
	}
}

-(void)statRDev {	
	const char* stat_path = [m_path UTF8String];
	struct stat64 st;
	int rc = lstat64(stat_path, &st);
	if(rc == -1) {
		NSLog(@"%s ERROR: stat() rc: %i", _cmd, rc);
		return;
	}
	
	int v = st.st_rdev;
	if(m_debug) NSLog(@"Device ID: 0x%x", v);
	
	if(m_append_to_result) {
		NSString* s = @"0";
		if(v != 0) s = [NSString stringWithFormat:@"0x%x", v];
		[self appendText:@"st_rdev:  "];
		[self appendValue:s];
		[self appendText:@"  device id\n"];
	}
}

-(void)statTime {
	const char* stat_path = [m_path UTF8String];
	struct stat64 st;
	int rc = lstat64(stat_path, &st);
	if(rc == -1) {
		NSLog(@"%s ERROR: stat() rc: %i", _cmd, rc);
		return;
	}

	const char* format = "%Y-%m-%d %T, %B";
	int capacity = 100;
	char buffer[capacity];

	NSString* s_atime = nil;
	NSString* s_mtime = nil;
	NSString* s_ctime = nil;
	NSString* s_btime = nil;
	/*
	TODO: identify the oldest date and suffix it with "oldest"
	TODO: identify the newest date and suffix it with "newest"
	TODO: identify future dates and color them red with "future" as suffix
	*/
	{
		struct timespec ts = st.st_atimespec;
		struct tm tm;
		localtime_r(&ts.tv_sec, &tm);
		strftime(buffer, capacity, format, &tm);
		buffer[capacity-1] = 0;
		if(m_debug) NSLog(@"atime: %s   time of last access", buffer);
		s_atime = [NSString stringWithFormat:@"%s", buffer];
	}
	{
		struct timespec ts = st.st_mtimespec;
		struct tm tm;
		localtime_r(&ts.tv_sec, &tm);
		strftime(buffer, capacity, format, &tm);
		buffer[capacity-1] = 0;
		if(m_debug) NSLog(@"mtime: %s   time of last data modification", buffer);
		s_mtime = [NSString stringWithFormat:@"%s", buffer];
	}
	{
		struct timespec ts = st.st_ctimespec;
		struct tm tm;
		localtime_r(&ts.tv_sec, &tm);
		strftime(buffer, capacity, format, &tm);
		buffer[capacity-1] = 0;
		if(m_debug) NSLog(@"ctime: %s   time of last status change", buffer);
		s_ctime = [NSString stringWithFormat:@"%s", buffer];
	}
	{
		struct timespec ts = st.st_birthtimespec;
		struct tm tm;
		localtime_r(&ts.tv_sec, &tm);
		strftime(buffer, capacity, format, &tm);
		buffer[capacity-1] = 0;
		if(m_debug) NSLog(@"btime: %s   time of file creation(birth)", buffer);
		s_btime = [NSString stringWithFormat:@"%s", buffer];
	}

	if(m_append_to_result) {
		[self appendTimeDesc:@"st_atimespec:     " value:s_atime 
			desc2:@"                  time of last access"]; 
		[self appendTimeDesc:@"st_mtimespec:     " value:s_mtime 
			desc2:@"                  time of last data modification"]; 
		[self appendTimeDesc:@"st_ctimespec:     " value:s_ctime 
			desc2:@"                  time of last status change"]; 
		[self appendTimeDesc:@"st_birthtimespec: " value:s_btime 
			desc2:@"                  time of file creation"]; 
	}
}

-(void)appendTimeDesc:(NSString*)desc value:(NSString*)value desc2:(NSString*)desc2 {
	[self appendText:desc2];
	[self appendText:@"\n"];
	[self appendText:desc];
	[self appendValue:value];
	[self appendText:@"\n"];
}

-(void)statSizeAndStuff {
	const char* stat_path = [m_path UTF8String];
	struct stat64 st;
	int rc = lstat64(stat_path, &st);
	if(rc == -1) {
		NSLog(@"%s ERROR: stat() rc: %i", _cmd, rc);
		return;
	}

	{
		uint64_t v_bytes = st.st_size;
		uint64_t v = v_bytes;
		const char* name = "bytes";
		BOOL print_size = NO;
		if(v > 1024 * 10) { 
			v >>= 10;
			name = "KB";
			print_size = YES;
		}
		if(v > 1024 * 10) { 
			v >>= 10;
			name = "MB";
			print_size = YES;
		}
		if(v > 1024 * 10) { 
			v >>= 10;
			name = "GB";
			print_size = YES;
		}
		if(v > 1024 * 10) { 
			v >>= 10;
			name = "TB";
			print_size = YES;
		}
		[self appendText:@"st_size:      "];
		[self appendValue:[NSString stringWithFormat:@"%llu", v_bytes]];
		if(print_size) {
			[self appendText:[NSString stringWithFormat:@"  file size, in bytes (%llu %s)\n", v, name]];
		} else {
			[self appendText:@"  file size, in bytes\n"];
		}
	}
	{
		int v = st.st_blocks;
		if(m_debug) NSLog(@"blocks: %i  blocks allocated for file", v);

		if(m_append_to_result) {
			[self appendMiscText:@"st_blocks:    " 
			             value:[NSString stringWithFormat:@"%i", v] 
						  text:@"  blocks allocated for file"];
		}
	}
	{
		int v = st.st_blksize;
		if(m_debug) NSLog(@"blocksize: %i  optimal blocksize for I/O", v);

		if(m_append_to_result) {
			[self appendMiscText:@"st_blksize:   " 
			             value:[NSString stringWithFormat:@"%i", v] 
						  text:@"  optimal blocksize for I/O"];
		}
	}
	{
		unsigned int v = st.st_flags;
		if(m_debug) NSLog(@"flags: 0x%x  user defined flags for file", v);
		char* s = fflagstostr(v);

		if(m_append_to_result) {
			[self appendText:@"st_flags:     "];
			if(v != 0) {
				[self appendImportantValue:[NSString stringWithFormat:@"0x%x", v]];
			} else {
				[self appendValue:@"0"];
			}
			[self appendText:@"  fflagstostr: "];
			NSString* flags_s = @"none";
			if(s) {
				BOOL is_not_empty_string = (s[0] != 0);
				if(is_not_empty_string) {
					flags_s = [NSString stringWithFormat:@"%s", s];
				}
			}
			if(v != 0) {
				[self appendImportantValue:flags_s];
			} else {
				[self appendValue:flags_s];
			}
			[self appendText:@"\n"];
		}

		if(s) {
			if(m_debug) NSLog(@"flags: %s", s);
			free(s);
		}
	}
	{
		unsigned int v = st.st_gen;
		if(m_debug) NSLog(@"gen: 0x%x  file generation number", v);

		if(m_append_to_result) {
			[self appendMiscText:@"st_gen:       " 
			             value:[NSString stringWithFormat:@"%i", v] 
						  text:@"  file generation number"];
		}
	}
	{
		unsigned int v = st.st_lspare;
		if(m_debug) NSLog(@"lspare: 0x%x  reserved field", v);

		if(m_append_to_result) {
			NSString* s = @"0";
			if(v != 0) s = [NSString stringWithFormat:@"0x%x", v];
			[self appendMiscText:@"st_lspare:    " 
			             value:s
						  text:@"  reserved field"];
		}
	}
	{
		unsigned long long v = st.st_qspare[0];
		if(m_debug) NSLog(@"lspare[0]: 0x%qx  reserved field", v);

		if(m_append_to_result) {
			NSString* s = @"0";
			if(v != 0) s = [NSString stringWithFormat:@"0x%qx", v];
			[self appendMiscText:@"st_qspare[0]: " 
			             value:s
						  text:@"  reserved field"];
		}
	}
	{
		unsigned long long v = st.st_qspare[1];
		if(m_debug) NSLog(@"lspare[1]: 0x%qx  reserved field", v);

		if(m_append_to_result) {
			NSString* s = @"0";
			if(v != 0) s = [NSString stringWithFormat:@"0x%qx", v];
			[self appendMiscText:@"st_qspare[1]: " 
			             value:s
						  text:@"  reserved field"];
		}
	}
}

-(void)appendMiscText:(NSString*)desc value:(NSString*)value text:(NSString*)desc2 {
	[self appendText:desc];
	[self appendValue:value];
	[self appendText:desc2];
	[self appendText:@"\n"];
}


- (BOOL)getFSRef:(FSRef *)aFsRef
{
	NSURL* url = [NSURL fileURLWithPath:m_path];
	// NSLog(@"%s url=%@", _cmd, url);
	return CFURLGetFSRef( (CFURLRef)url, aFsRef ) != 0;
}

- (BOOL)getFSSpec:(FSSpec *)aFSSpec
{
	FSRef			aFSRef;

	return [self getFSRef:&aFSRef] && (FSGetCatalogInfo( &aFSRef, kFSCatInfoNone, NULL, NULL, aFSSpec, NULL ) == noErr);
}

- (BOOL)finderInfo:(FInfo*)theInfo {
	/*
	we really shouldn't use FSSpec.. but instead use FSRef
	http://www.cocoadev.com/index.pl?FinderFlags
	*/
	FSSpec theFSSpec;
	if( [self getFSSpec:&theFSSpec] == NO) return NO;
	return (FSpGetFInfo( &theFSSpec, theInfo) == noErr );
}

-(void)dumpFinderInfo { // use SetFile to change these options
	/*
	http://developer.apple.com/documentation/Carbon/Reference/Finder_Interface/Reference/reference.html
	
	TODO: Finder.h has LOT's of structs that needs to be dumped as well.
	such as: FXInfo, DInfo, DXInfo, ExtendedFileInfo, ExtendedFolderInfo, FolderInfo
	what is the difference of FileInfo and FInfo?
	
	TODO: dump resource fork
	
	TODO: this code only print's info for files. 
	I guess we will have to do special code to deal with folders?
	
	
	TODO: I have made no effort in validating that names of the fdFlags
	are the right ones. Double check with SetFile/GetFileInfo man pages.
	*/


/*	UInt16 v_flags;
	OSType v_type;
	OSType v_creator;
	SInt16 v_fdFldr */
	// BOOL ok = [self finderInfoFlags:&v_flags type:&v_type creator:&v_creator];

	struct FInfo theInfo;
	BOOL ok = [self finderInfo:&theInfo];
	if(!ok) {
		if(m_debug) NSLog(@"%s - no finder info", _cmd);

		[self appendText:@"none\n"];
		return;
	}
	
	unsigned int v_flags = theInfo.fdFlags;
	OSType v_type = theInfo.fdType;
	OSType v_creator = theInfo.fdCreator;
	int point_v = theInfo.fdLocation.v;
	int point_h = theInfo.fdLocation.h;
	int v_fdfldr = theInfo.fdFldr;
	
	if(m_debug) NSLog(@"finder flags: %08x", _cmd, v_flags);
	if(m_debug) NSLog(@"finder location: %i %i", _cmd, point_v, point_h);
	if(m_debug) NSLog(@"finder fdfldr: %08x", _cmd, v_fdfldr);

	const char* names[] = {
		"kIsOnDesk",
		// "kColor",
		"kIsExtensionHidden",
		"kRequireSwitchLaunch",
		"kIsShared",
		"kHasNoINITs",
		"kHasBeenInited",
		"AOCE",
		"kHasCustomIcon",
		"kIsStationery",
		"kNameLocked",
		"kHasBundle",
		"kIsInvisible",
		"kIsAlias"
	};
	const int number_of_names = sizeof(names) / sizeof(const char*);
	
	unsigned int v = v_flags;
	int states[] = {
		v & kIsOnDesk,
		// v & kColor,
		v & 0x0010, // extension is hidden
		v & 0x0020, // reserved, was kRequireSwitchLaunch
		v & kIsShared,
		v & kHasNoINITs,
		v & kHasBeenInited,
		v & 0x0200, // reserved, was AOCE
		v & kHasCustomIcon,
		v & kIsStationery,
		v & kNameLocked,
		v & kHasBundle,
		v & kIsInvisible,
		v & kIsAlias
	};
	const int number_of_states = sizeof(states) / sizeof(int);
	
	STATIC_CHECK(number_of_states == number_of_names);

	if(m_debug) NSLog(@"type code: %@", NSFileTypeForHFSTypeCode(v_type));
	if(m_debug) NSLog(@"creator code: %@", NSFileTypeForHFSTypeCode(v_creator));

	[self appendText:@"fdType:     "];
	[self appendValue:NSFileTypeForHFSTypeCode(v_type)];     
	[self appendText:@"   file type\nfdCreator:  "];                 
	[self appendValue:NSFileTypeForHFSTypeCode(v_creator)];
	[self appendText:@"   program that created this file"];

	[self appendText:@"\nfdFlags:    "];
	NSString* s = @"0";
	if(v_flags != 0) s = [NSString stringWithFormat:@"0x%04x", (int)v_flags];
	[self appendValue:s];
	int vcount = 0;
	if(v & kColor) {
		int color = (v & kColor) >> 1;
		if(vcount == 0) [self appendText:@"   "];
		if(vcount != 0) [self appendText:@", "];
		[self appendValue:[NSString stringWithFormat:@"kColor(%i)", color]];
		vcount++;
	}
	// printf("\n\n\n");
	for(int i=0; i<number_of_names; ++i) {
		int state = states[i];
		// printf("%i ", state);
		if(state) {
			if(vcount == 0) [self appendText:@"   "];
			if(vcount != 0) [self appendText:@", "];
			[self appendValue:[NSString stringWithFormat:@"%s", names[i]]];
			vcount++;
		}
	}
	// printf("\n\n\n");

	[self appendText:@"\nfdLocation: v="];
	[self appendValue:[NSString stringWithFormat:@"%i", point_v]];
	[self appendText:@" h="];
	[self appendValue:[NSString stringWithFormat:@"%i", point_h]];
	[self appendText:@"  icon position\nfdFldr:     "];
	[self appendValue:[NSString stringWithFormat:@"%i", v_fdfldr]];
	[self appendText:@"        icon window\n"];
}


/*
There are LOTs of info that can be obtained via getattrlist
http://developer.apple.com/mac/library/documentation/Darwin/Reference/ManPages/man2/getattrlist.2.html

TODO: obtain it all!
*/
-(void)dumpAttr {
	const char* filename = [m_path UTF8String];

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

	int err = getattrlist(filename, &al, &buf, sizeof(AttrBuffer), FSOPT_NOFOLLOW);
	if(err) {
		[self appendText:@"none\n"];
		return;
	}

	{
		unsigned long long v = buf.file_total_length;
		[self appendText:@"ATTR_FILE_TOTALSIZE:     "];
		[self appendValue:[NSString stringWithFormat:@"%llu", v]];
	}
	{
		unsigned long long v = buf.file_total_allocsize;
		[self appendText:@"\nATTR_FILE_ALLOCSIZE:     "];
		[self appendValue:[NSString stringWithFormat:@"%llu", v]];
	}
	{
		unsigned long long v = buf.file_data_length;
		[self appendText:@"\nATTR_FILE_DATALENGTH:    "];
		[self appendValue:[NSString stringWithFormat:@"%llu", v]];
	}
	{
		unsigned long long v = buf.file_data_allocsize;
		[self appendText:@"\nATTR_FILE_DATAALLOCSIZE: "];
		[self appendValue:[NSString stringWithFormat:@"%llu", v]];
	}
	{
		unsigned long long v = buf.file_rsrc_length;
		[self appendText:@"\nATTR_FILE_RSRCLENGTH:    "];
		[self appendValue:[NSString stringWithFormat:@"%llu", v]];
	}
	{
		unsigned long long v = buf.file_rsrc_allocsize;
		[self appendText:@"\nATTR_FILE_RSRCALLOCSIZE: "];
		[self appendValue:[NSString stringWithFormat:@"%llu", v]];
	}

	[self appendText:@"\n"];
}

-(void)dumpXattr {
	const char* filename = [m_path UTF8String];

	ssize_t buffer_size = listxattr(filename, NULL, 0, XATTR_NOFOLLOW);
	if(buffer_size <= 0) {
		if(m_debug) NSLog(@"%s no xattr found", _cmd);
		[self appendText:@"none\n"];
		return;
	}

	char* buffer = (char*)malloc(buffer_size);

	size_t bytes_read = listxattr(filename, buffer, buffer_size, XATTR_NOFOLLOW);
	if(bytes_read != buffer_size) {
		NSLog(@"%s mismatch in buffer size", _cmd);
	}

	if(m_debug) NSLog(@"%s bytes_read: %i", _cmd, (int)bytes_read);

	int index = 0;
	char *name = buffer;
	for(; name < buffer+buffer_size; name += strlen(name) + 1, index++) {
		int size = getxattr(filename, name, 0, 0, 0, XATTR_NOFOLLOW);
		
		if(m_debug) NSLog(@"row: %i  size: %i  name: %s", index, (int)size, name);

		NSString* s1 = [NSString stringWithFormat:@"xattr[%i]  bytes: ", index];
		NSString* s2 = [NSString stringWithFormat:@"%i", (int)size];
		NSString* s3 = [NSString stringWithFormat:@"%s", name];
		[self appendText:s1];
		[self appendValue:s2];     
		[self appendText:@"  name: "];    
		[self appendValue:s3];
		[self appendText:@"\n"];
		
		if(size > 0) {
			char* buf2 = (char*)malloc(size+1);
			int size2 = getxattr(filename, name, buf2, size, 0, XATTR_NOFOLLOW);
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
	}
	
	free(buffer);
}

-(void)dumpACL {
	const char* filename = [m_path UTF8String];


	NSFileManager* fm = [NSFileManager defaultManager];
	BOOL isdir = NO;
	BOOL ok = [fm fileExistsAtPath:m_path isDirectory:&isdir];
	if(ok == NO) {
		NSLog(@"%s ERROR: we can't determine if this is a dir: %@", _cmd, m_path);
	}


	acl_t acl = acl_get_link_np(filename, ACL_TYPE_EXTENDED);

	acl_entry_t dummy;
	if (acl && acl_get_entry(acl, ACL_FIRST_ENTRY, &dummy) == -1) {
		acl_free(acl);
		acl = NULL;
		if(m_debug) NSLog(@"%s NO ACL", _cmd);

		[self appendText:@"none\n"];
		return;
	}

	if(acl == NULL) {
		if(m_debug) NSLog(@"%s ACL is NULL", _cmd);

		[self appendText:@"none\n"];
		return;
	}

	if(m_debug) NSLog(@"%s we have ACL", _cmd);

	acl_entry_t	entry = NULL;
	int		index;
	uuid_t		*applicable;
	char		*name = NULL;
	acl_tag_t	tag;
	acl_flagset_t	flags;
	acl_permset_t	perms;
	char		*type;
	int		i, first;

	for (index = 0;
	     acl_get_entry(acl, entry == NULL ? ACL_FIRST_ENTRY : ACL_NEXT_ENTRY, &entry) == 0;
	     index++) {

		/*
		TODO: we should be able to print invalid ACL's,
		so we can't have these "continue"'s here.
		*/
		
		if ((applicable = (uuid_t *) acl_get_qualifier(entry)) == NULL)
			continue;
		if (acl_get_tag_type(entry, &tag) != 0)
			continue;
		if (acl_get_flagset_np(entry, &flags) != 0)
			continue;
		if (acl_get_permset(entry, &perms) != 0)
			continue;
			
		/*
		TODO: print the uuid
		*/
		name = uuid_to_name(applicable);
		acl_free(applicable);

		BOOL unknown = NO;
		switch(tag) {
		case ACL_EXTENDED_ALLOW:
			type = "allow";
			break;
		case ACL_EXTENDED_DENY:
			type = "deny";
			break;
		default:
			type = "unknown";
			unknown = YES;
		}

		/*
		TODO: acl_get_flag_np() have many more flags
		than just ACL_ENTRY_INHERITED, we should print them as well.
		*/
		int inherited = acl_get_flag_np(flags, ACL_ENTRY_INHERITED);

		[self appendText:[NSString stringWithFormat:@"acl[%i].name:  ", index]];
		[self appendValue:[NSString stringWithFormat:@"%s", name]];
		[self appendText:@"  inherited: "];
		[self appendValue:(inherited ? @"yes" : @"no")];
		[self appendText:@"  type: "];
		if(unknown) {
			[self appendImportantValue:
				[NSString stringWithFormat:@"unknown (tag=%i)", (int)tag]
			];
		} else {
			[self appendValue:[NSString stringWithFormat:@"%s", type]];
		}


		if(m_debug) {
			(void)printf(" %d: %s%s %s ",
			    index,
			    name,
			    inherited ? " inherited" : "",
			    type);
		}

		if (name)
			free(name);
		

		[self appendText:[NSString stringWithFormat:@"\nacl[%i].perms: ", index]];
		int pcount = 0;
		for (i = 0, first = 0; acl_perms[i].name != NULL; i++) {
			if (acl_get_perm_np(perms, acl_perms[i].perm) == 0)
				continue;
			if (!(acl_perms[i].flags & (isdir ? ACL_PERM_DIR : ACL_PERM_FILE)))
				continue;
			if(m_debug) {
				(void)printf("%s%s", first++ ? "," : "", acl_perms[i].name);
			}
			
			if(pcount != 0) [self appendText:@", "];
			[self appendValue:[NSString stringWithFormat:@"%s", acl_perms[i].name]];
			pcount++;
		}
		if(pcount == 0) {
			[self appendValue:@"none"];
		}
		
		[self appendText:[NSString stringWithFormat:@"\nacl[%i].flags: ", index]];
		int fcount = 0;
		for (i = 0, first = 0; acl_flags[i].name != NULL; i++) {
			if (acl_get_flag_np(flags, acl_flags[i].flag) == 0)
				continue;
			if (!(acl_flags[i].flags & (isdir ? ACL_PERM_DIR : ACL_PERM_FILE)))
				continue;
			if(m_debug) {
				(void)printf("%s%s", first++ ? "," : "", acl_flags[i].name);
			}

			if(fcount != 0) [self appendText:@", "];
			[self appendValue:[NSString stringWithFormat:@"%s", acl_flags[i].name]];
			fcount++;
		}
		if(fcount == 0) {
			[self appendValue:@"none"];
		}
		[self appendText:@"\n"];
		
		if(m_debug) {
			printf("\n");
		}
		
     	if(m_debug) NSLog(@"%s index: %i", _cmd, index);
	}
	
	if(m_debug) NSLog(@"%s done", _cmd);

	acl_free(acl);
}

-(void)dumpNSFileManager {
	NSFileManager* fm = [NSFileManager defaultManager];
	
	NSDictionary* fileAttributes = [fm fileAttributesAtPath:m_path traverseLink:YES];
	if(m_debug) NSLog(@"fileAttributesAtPath: %@", fileAttributes);

	if(m_append_to_result) {
		if([fileAttributes count] < 1) {
			[self appendText:@"none\n"];
		} else {
			id thing;
			NSEnumerator* en = [fileAttributes keyEnumerator];
			while(thing = [en nextObject]) {
				id key = thing;
				thing = [fileAttributes objectForKey:key];
				[self appendValue:[NSString stringWithFormat:@"%@", key]];
				[self appendText:[NSString stringWithFormat:@": "]];
				[self appendValue:[NSString stringWithFormat:@"%@", thing]];
				[self appendText:[NSString stringWithFormat:@"\n"]];
			}
		}
	}
	
	NSString* displayname = [fm displayNameAtPath:m_path];
	// TODO: output this in the report
	if(m_debug) NSLog(@"displayNameAtPath: %@", displayname);

	const char* sysrep = [fm fileSystemRepresentationWithPath:m_path];
	// TODO: output this in the report
	if(m_debug) NSLog(@"fileSystemRepresentationWithPath: %s", sysrep);
}

-(void)dumpSpotlightInfo {
	/*
	http://developer.apple.com/MacOsX/spotlight.html
	
	prompt> mdls TODO.txt
	...
	huge list of attributes
	...
	prompt>
	
	
	http://developer.apple.com/documentation/Carbon/Reference/MetadataAttributesRef/Reference/CommonAttrs.html#//apple_ref/doc/uid/TP40001694
	*/
	
	CFStringRef path = (CFStringRef)m_path;

	MDItemRef item = MDItemCreate(kCFAllocatorDefault, path);
	if(item == 0) {
		[self appendText:[NSString stringWithFormat:@"none\n"]];
		return;
	}

	/*
	BOOM: spotlight is a trouble maker. It crashes/hangs/etc.. very often
	and right now I'm investigating how spotlight manages to crash
	the parent process! sigh
	
	If you pass NULL to MDItemCopyAttributeNames() it will kill
	parent process as well!
	*/
	CFArrayRef attributeNames = MDItemCopyAttributeNames(item);
	
	NSArray* array = (NSArray*)attributeNames;
	// NSLog(@"%s %@", _cmd, array);
	
	NSEnumerator *e = [array objectEnumerator];
    id arrayObject;
    
    NSMutableString *info = [NSMutableString stringWithCapacity:50];
    CFTypeRef ref;
    
    while ((arrayObject = [e nextObject]))
    {
        ref = 
        MDItemCopyAttribute(item, (CFStringRef)[arrayObject description]);
    
        //cast to get an NSObject for convenience
        NSObject* tempObject = (NSObject*)ref;
        
		id thing1 = [arrayObject description];
		id thing2 = [tempObject description];
		if(thing1 == nil) thing1 = @"nil";
		if(thing2 == nil) thing2 = @"nil";
        [info appendString:thing1];
        [info appendString:@" = "];
        [info appendString:thing2];
        [info appendString:@"\n"];

		[self appendValue:[NSString stringWithFormat:@"%@", thing1]];
		[self appendText:[NSString stringWithFormat:@": "]];
		[self appendValue:[NSString stringWithFormat:@"%@", thing2]];
		[self appendText:[NSString stringWithFormat:@"\n"]];
    }

	if(m_debug) NSLog(@"%@", info);
}

-(NSAttributedString*)result {
	return [m_result copy];
}

-(void)dealloc {
	[m_path release];
	[m_result release];
	[m_font1 release];
	[m_font2 release];
	[m_font3 release];
	[m_attr1 release];
	[m_attr2 release];
	[m_attr3 release];
	[m_attr4 release];
	
    [super dealloc];
}

@end
