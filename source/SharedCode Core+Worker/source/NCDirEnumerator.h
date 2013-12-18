//
// NCDirEnumerator.h
// Newton Commander
//
// A wrapper for the arcane getdirentries api
// This is an objc wrapper around getdirentries() code found in the Apple's FSMegaInfo sample project.
// http://developer.apple.com/SampleCode/FSMegaInfo/index.html
//
#import <Foundation/Foundation.h>


/*
These enums corresponds to the defines found in
/Developer/SDKs/MacOSX10.5.sdk/usr/include/sys/dirent.h 
*/
enum {
	NCDirEntryTypeUnknown = 0,   // DT_UNKNOWN 0
	NCDirEntryTypeFifo,          // DT_FIFO    1 fifo (or socket?)
	NCDirEntryTypeChar,          // DT_CHR	   2 char special
	NCDirEntryTypeUnknown3,      // -          3 is not defined
	NCDirEntryTypeDir,           // DT_DIR	   4 directory
	NCDirEntryTypeUnknown5,      // -          5 is not defined
	NCDirEntryTypeBlock,         // DT_BLK	   6 block special
	NCDirEntryTypeUnknown7,      // -          7 is not defined
	NCDirEntryTypeFile,          // DT_REG	   8 regular file
	NCDirEntryTypeUnknown9,      // -          9 is not defined
	NCDirEntryTypeLink,          // DT_LNK	   10 symbolic link
	NCDirEntryTypeUnknown11,     // -          11 is not defined
	NCDirEntryTypeSocket,        // DT_SOCK    12 socket
	NCDirEntryTypeUnknown13,     // -          13 is not defined
	NCDirEntryTypeWhiteout,      // DT_WHT     14 whiteout
};


/*
wrapper around the "dirent" struct
*/
@interface NCDirEntry : NSObject {
	unsigned long long m_inode;
	NSString* m_name;
	unsigned char m_dirent_type;
}
@property unsigned long long inode;
@property(nonatomic, strong) NSString* name;
@property unsigned char direntType;

@end


/*
encapsulation of the BSD system call "getdirentries()" which is
defined in "dirent.h".

see:
man 2 getdirentries
*/
@interface NCDirEnumerator : NSEnumerator {
	int   m_err;
    char* m_buf;
	int   m_bufsize;
	int   m_fd;
    char* m_cursor;
    char* m_limit;
	BOOL  m_exhausted;
}

+(NCDirEnumerator*)enumeratorWithPath:(NSString*)path;

@end

