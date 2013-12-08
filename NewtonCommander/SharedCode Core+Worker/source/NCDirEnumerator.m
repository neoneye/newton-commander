/*********************************************************************
NCDirEnumerator.m - wrapper for the arcane getdirentries api
Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>

This is an objc wrapper around getdirentries() code found in the
Apple's FSMegaInfo sample project.
http://developer.apple.com/SampleCode/FSMegaInfo/index.html


Sadly getdirentries() has been deprecated starting with Mac OS X 10.6.
Apple writes in the getdirentries manpage, that: getdirentries() should 
rarely be used directly; instead, opendir(3) and readdir(3) should be used.
HOWEVER. readdir() cannot show cloaked files, e.g. 
/.journal
/.journal_info_block
/␀␀␀␀HFS+ Private Data
/.HFS+ Private Directory Data
I dunno if readdir() is as fast as getdirentries(), probably not, since
getdirentries is more lowlevel.
I could separate it out into a dedicated process, named CloakFinder,
so that the main program doesn't use any deprecated code. And only cloakFinder
uses legacy code. This way when getdirentries finally gets removed by apple
it will not affect our main program.
Alternatively I could just check for existence of the common cloaked files.

*********************************************************************/
#import "NCDirEnumerator.h"
#import "NCFileManager.h"
#import "NCLog.h"

#include <sys/dirent.h>
#include <sys/stat.h>
#include <dirent.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <assert.h>
#include <fcntl.h>
#include <stddef.h>
#include <unistd.h>
#include <sys/errno.h>



@implementation NCDirEntry

@synthesize inode = m_inode;
@synthesize name = m_name;
@synthesize direntType = m_dirent_type;

-(NSString*)description {
	return [NSString stringWithFormat:@"%08i:%02i - '%@'", (int)m_inode, (int)m_dirent_type, m_name];
}

@end


@interface NCDirEnumerator (Private)
-(id)initWithPath:(NSString*)path;
-(void)setupWithPath:(NSString*)path;
-(void)teardown;

@end

@implementation NCDirEnumerator

/*
IDEA: add an error: return argument, so that I can determine the cause of the problem
(without having to look through the logs with Console.app)

+(NCDirEnumerator*)enumeratorWithPath:(NSString*)path error:(NSError**)err;
*/
+(NCDirEnumerator*)enumeratorWithPath:(NSString*)path {
	return [[[NCDirEnumerator alloc] initWithPath:path] autorelease];
}

-(id)initWithPath:(NSString*)path {
	if (self = [super init]) {
		m_exhausted = NO;
		m_err = 0;
		m_buf = NULL;
		m_bufsize = 0;
		m_fd = -1;
		m_cursor = 0;
		m_limit = 0;

		[self setupWithPath:path];

		if (m_err != 0) {
			LOG_WARNING(@"NCDirEnumerator failed to init: %@", [NCFileManager errnoString:m_err]);
			[self teardown];
			return nil;
		}
        
	}
	return self;
}

-(void)dealloc {
	[self teardown];
	[super dealloc];
}

-(void)setupWithPath:(NSString*)path {
	const char* path1 = [path fileSystemRepresentation];

    // If we're using the default buffer size, get it from stat.
    if ( (m_err == 0) && (m_bufsize == 0) ) {
        struct stat sb;
        
        m_err = stat(path1, &sb);
        if (m_err < 0) {
            m_err = errno;
			return;
        }

        m_bufsize = (int) sb.st_blksize;
    }

	if(m_bufsize <= 0) {
		m_err = 12345;
		return;
	}
    
    // Allocate the buffer.
    if (m_err == 0) {
        m_buf = (char *) malloc(m_bufsize);
        if (m_buf == NULL) {
            m_err = ENOMEM;
        }
    }
    
    // Open the directory.
    if (m_err == 0) {
        m_fd = open(path1, O_RDONLY);
        if (m_fd < 0) {
            m_err = errno;
        }
    }
}

-(void)teardown {
	int junk;
    if(m_fd != -1) {
        junk = close(m_fd);
        assert(junk == 0);
		m_fd = -1;
    }
	if(m_buf != NULL) {
    	free(m_buf);
		m_buf = NULL;
	}
	m_exhausted = YES;
}

- (id)nextObject {
	if(m_exhausted) {
		return nil;
	}
		
	/*
	Check for expected termination or loop until we run out of entries.
	*/
	if (m_cursor == m_limit) {
	    long base;
		/*
		getdirentries() is marked as __OSX_AVAILABLE_BUT_DEPRECATED, but is the only
		way to go to gather info about ghosted dirs..
		thus this code generates a warning and there is only 1 thing we can do about it
		GCC_WARN_ABOUT_DEPRECATED_FUNCTIONS = NO
		*/
		int bytesRead = getdirentries(m_fd, m_buf, m_bufsize, &base);
		if (bytesRead < 0) {
			m_err = errno;
			m_exhausted = YES;
			return nil;
		}
		if (bytesRead == 0) {
			// end of the directory has been reached
			m_exhausted = YES;
			return nil;
		}

		m_limit  = m_buf + bytesRead;
		m_cursor = m_buf;
	}

    struct dirent* thisEnt = (struct dirent*)m_cursor;

    /*
	Check for unexpected termination, that is, running off the 
    end of the buffer.  There are two checks here.  The first 
    checks that we have enough buffer space to read a meaningful 
    thisEnt->d_reclen.  The second checks that, given that record 
    length, the entire record fits in the buffer.
	*/
	if(((m_cursor + offsetof(struct dirent, d_reclen) + sizeof(thisEnt->d_reclen)) > m_limit)
		|| ((m_cursor + thisEnt->d_reclen) > m_limit) ) {
		LOG_ERROR(@"dirent not fully contained within buffer");
		m_err = EINVAL;
		m_exhausted = YES;
		return nil; 
	}

    m_cursor += thisEnt->d_reclen;

	NCDirEntry* entry = [[[NCDirEntry alloc] init] autorelease];
	[entry setInode:(thisEnt->d_ino)];
	[entry setName:[NSString stringWithUTF8String:(thisEnt->d_name)]];
	[entry setDirentType:thisEnt->d_type];
	return entry;
}

@end
