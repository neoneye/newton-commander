/*********************************************************************
system_GDE.cpp - Class wrapper for the arcane getdirentries api
Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#include "system_GDE.h"


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


namespace {
	
static char* const collectdirentries_d_type_names[] = {
	"DT_UNKNOWN", // 0
	"DT_FIFO",    // 1
	"DT_CHR",     // 2
	NULL,         // 3 undefined
	"DT_DIR",     // 4
	NULL,         // 5 undefined
	"DT_BLK",     // 6
	NULL,         // 7 undefined
	"DT_REG",     // 8
	NULL,         // 9 undefined
	"DT_LNK",     // 10
	NULL,         // 11 undefined
	"DT_SOCK",    // 12
	NULL,         // 13 undefined
	"DT_WHT"      // 14
};

} // namespace

void SystemGetDirEntries::process_error() {
	printf("failed with error '%s' (%i)\n", strerror(run_error), run_error);
}

void SystemGetDirEntries::process_dirent(
	unsigned long long d_inode,
	u_int16_t d_reclen,
	u_int8_t d_type,
	u_int8_t d_namlen,
	const char* d_name,
	const char* pretty_d_type) 
{
	printf(
		"entry: %s %8llu %s %u %u %u\n", 
		d_name,
		d_inode,
		pretty_d_type,
		(unsigned int)d_type,
		(unsigned int)d_reclen,
		(unsigned int)d_namlen
	);
}


void SystemGetDirEntries::PrintDirEnt(
	bool firstCall, 
	off_t fileOffset, 
	const char *offsetFieldName, 
	struct dirent *ent /*, 
	uint32_t indent, 
	uint32_t verbose, 
	bool raw*/ )
{
    char            tmp[32];
    // const char *    typeStr;
    // size_t          enumIndex;
    
    assert(offsetFieldName != NULL);
    assert(ent != NULL);
    
    // if (verbose == 0) {
        // Print as columns.
        
        // if ( raw || (ent->d_ino != 0) ) {
			
			unsigned int d_type_index = ent->d_type;
			const char* d_type_name = NULL;
			if(d_type_index <= 14) {
				d_type_name = collectdirentries_d_type_names[d_type_index];
			}
			if(d_type_name == NULL) {
                snprintf(tmp, sizeof(tmp), "%u", d_type_index);
                d_type_name = tmp;
			}
			process_dirent(
				ent->d_ino,
				ent->d_reclen,
				ent->d_type,
				ent->d_namlen,
				ent->d_name,
				d_type_name
			);
/*        }
    } else {
        // Print as individual records.

        if ( ! firstCall ) {
            fprintf(stdout, "\n");
        }
        FPUDec(offsetFieldName, sizeof(fileOffset), &fileOffset, indent, strlen(kDirEntFieldSpacer), verbose, NULL);
        FPPrintFields(kDirEntFieldDesc, ent, sizeof(*ent), indent, verbose);
    }*/
}

/*
return value:
0 = success
otherwise it's an errno value
*/
int SystemGetDirEntries::PrintGetDirEntriesInfo(const char* path /*, uint32_t indent, uint32_t verbose */)
{
    int                 err;
    int                 junk;
    int                 bufSize;
    const char *        dirPath;
    char *              buf;
    int                 dirFD;
    bool                raw;
    
    buf = NULL;
    dirFD = -1;
    
    // Process -r argument.
    
    raw = true;
    
    // Process optional -bufSize argument.
    
    // st_blksize is a blksize_t; getdirentries's nbytes arg is an int;
    // so, I've chosen to use int to represent the buffer size.

    err = 0;
    bufSize = 0;                // indicates to use stat to get the buffer size
/*    if ( CommandArgsGetOptionalConstantString(args, "-bufSize") ) {
        err = CommandArgsGetInt(args, &bufSize);
        if ( (err == 0) && (bufSize <= 0) ) {
            err = EUSAGE;
        }
    }*/
    
    // Get directory path.
    
/*    if (err == 0) {
        err = CommandArgsGetString(args, &dirPath);
    } */
	dirPath = path;
    
    // If we're using the default buffer size, get it from stat.
    
    if ( (err == 0) && (bufSize == 0) ) {
        struct stat sb;
        
        err = stat(dirPath, &sb);
        if (err < 0) {
            err = errno;
        }
        if (err == 0) {
            bufSize = (int) sb.st_blksize;
            assert( ((blksize_t) bufSize) == sb.st_blksize);
        }
    }
    
    // Allocate the buffer.
    
    if (err == 0) {
        buf = (char *) malloc(bufSize);
        if (buf == NULL) {
            err = ENOMEM;
        }
    }
    
    // Open the directory.
    
    if (err == 0) {
        dirFD = open(dirPath, O_RDONLY);
        if (dirFD < 0) {
            err = errno;
        }
    }
    
    // Loop until we run out of entries.
    
    if (err == 0) {
        int     bytesRead;
        long    base;
        off_t   fileOffset;
        bool    first;
        
        first = true;
        fileOffset = 0;
        do {
            bytesRead = getdirentries(dirFD, buf, bufSize, &base);
            if (bytesRead < 0) {
                err = errno;
            } else if (bytesRead > 0) {
                char *          cursor;
                char *          limit;
                struct dirent * thisEnt;
                // Print each entry in the buffer.
                
/*                if (verbose > 1) {
                    if ( ! first ) {
                        fprintf(stdout, "\n");
                    }
                    first = false;
                    FPSDec("bytesRead", sizeof(bytesRead), &bytesRead, indent + kStdIndent, strlen(kDirEntFieldSpacer), verbose, NULL);
                    FPHex("base", sizeof(base), &base, indent + kStdIndent, strlen(kDirEntFieldSpacer), verbose, NULL);
                } */
                
                limit  = buf + bytesRead;
                cursor = buf;
                do {
                    // Check for expected termination.
                    
                    if (cursor == limit) {
                        // Exactly at end buffer, end of this block of dirents.
                        // This used to be a >= test, but there's no point doing 
                        // that because a) if this is the first iteration, the 
                        // check can't apply, and b) if this is a subsequent iteration, 
                        // the next check (that the dirent is entirely contained 
                        // within the buffer) would have stopped us on the previous 
                        // iteration.
                        break;
                    }
                    
                    // Check for unexpected termination, that is, running off the 
                    // end of the buffer.  There are two checks here.  The first 
                    // checks that we have enough buffer space to read a meaningful 
                    // thisEnt->d_reclen.  The second checks that, given that record 
                    // length, the entire record fits in the buffer.
                    
                    thisEnt = (struct dirent *) cursor;
                    if (   ((cursor + offsetof(struct dirent, d_reclen) + sizeof(thisEnt->d_reclen)) > limit)
                        || ((cursor + thisEnt->d_reclen) > limit) ) {
                        fprintf(stderr, "dirent not fully contained within buffer\n");
                        err = EINVAL;
                        break;
                    }
                    
                    // readdir checks that each entry starts at a multiple of 
                    // 4 bytes.  We implement roughly the same check by checking that 
                    // each entry is a multiple of 4 bytes long.  
                    
                    if ( (thisEnt->d_reclen & 3) != 0) {
                        static bool sPrinted;
                        
                        if ( ! sPrinted ) {
                            fprintf(stderr, "d_reclen is not a multiple of 4; readdir will be unhappy.\n");
                            sPrinted = true;
                        }
                    }
                    
                    // Print the entry.
                    
                    PrintDirEnt(first, fileOffset, "offset", thisEnt /*, indent + 0, verbose, raw */);
                    first = false;
                    fileOffset += thisEnt->d_reclen;
                    
                    cursor += thisEnt->d_reclen;
                } while (true);
            }
        } while ( (err == 0) && (bytesRead != 0) );
    }
    
    // Clean up.
    
    if (dirFD != -1) {
        junk = close(dirFD);
        assert(junk == 0);
    }
    free(buf);
    
	return err;
}
