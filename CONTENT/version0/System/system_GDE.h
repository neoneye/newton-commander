/*********************************************************************
system_GDE.h - Class wrapper for the arcane getdirentries api
Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>

This is a c++ wrapper around getdirentries() code found in the
Apple's FSMegaInfo sample project.
http://developer.apple.com/SampleCode/FSMegaInfo/index.html

I have made as few changes as possible to the apple code.





In /Developer/SDKs/MacOSX10.5.sdk/usr/include/sys/dirent.h 
you will find the defines for d_type.

#define	DT_UNKNOWN	 0
#define	DT_FIFO		 1
#define	DT_CHR		 2
#define	DT_DIR		 4
#define	DT_BLK		 6
#define	DT_REG		 8
#define	DT_LNK		10
#define	DT_SOCK		12
#define	DT_WHT		14

*********************************************************************/
#ifndef __OPCODERS_KEYBOARDCOMMANDER_SYSTEM_GDE_H__
#define __OPCODERS_KEYBOARDCOMMANDER_SYSTEM_GDE_H__

#include <sys/types.h>

struct dirent;

enum {
	SystemGetDirEntriesTypeUnknown = 0,   // DT_UNKNOWN 0
	SystemGetDirEntriesTypeFifo,          // DT_FIFO    1 fifo (or socket?)
	SystemGetDirEntriesTypeChar,          // DT_CHR	    2 char special
	SystemGetDirEntriesTypeUnknown3,      // -          3 is not defined
	SystemGetDirEntriesTypeDir,           // DT_DIR	    4 directory
	SystemGetDirEntriesTypeUnknown5,      // -          5 is not defined
	SystemGetDirEntriesTypeBlock,         // DT_BLK	    6 block special
	SystemGetDirEntriesTypeUnknown7,      // -          7 is not defined
	SystemGetDirEntriesTypeFile,          // DT_REG	    8 regular file
	SystemGetDirEntriesTypeUnknown9,      // -          9 is not defined
	SystemGetDirEntriesTypeLink,          // DT_LNK	   10 symbolic link
	SystemGetDirEntriesTypeUnknown11,     // -         11 is not defined
	SystemGetDirEntriesTypeSocket,        // DT_SOCK   12 socket
	SystemGetDirEntriesTypeUnknown13,     // -         13 is not defined
	SystemGetDirEntriesTypeWhiteout,      // DT_WHT    14 whiteout
};

class SystemGetDirEntries {
public:
	int run_error;

	SystemGetDirEntries() : run_error(0) {}
	virtual ~SystemGetDirEntries() {}
	
	int run(const char* dirpath) {
		run_error = PrintGetDirEntriesInfo(dirpath /*, 0, 0 */);
		if(run_error != 0) process_error();
		return run_error;
	}
	
	virtual void process_error();/* {
		printf("failed with error '%s' (%i)\n", strerror(run_error), run_error);
	}*/


	/*
	this callback is invoked for each dirent record.
	
	"d_name" is an UTF8 string, where max length is 255 chars.
	*/
	virtual void process_dirent(
		unsigned long long d_inode,
		u_int16_t d_reclen,
		u_int8_t d_type,
		u_int8_t d_namlen,
		const char* d_name,
		const char* pretty_d_type);
/*	{
		printf(
			"entry: %s %8llu %s %u %u %u\n", 
			d_name,
			d_inode,
			pretty_d_type,
			(unsigned int)d_type,
			(unsigned int)d_reclen,
			(unsigned int)d_namlen
		);
	}*/


private:
	void PrintDirEnt(bool firstCall, off_t fileOffset, const char *offsetFieldName, struct dirent *ent /*, uint32_t indent, uint32_t verbose, bool raw*/ );

	int PrintGetDirEntriesInfo(const char* path /*, uint32_t indent, uint32_t verbose */);
		
};

#endif // __OPCODERS_KEYBOARDCOMMANDER_SYSTEM_GDE_H__
