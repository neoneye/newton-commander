/*
 *  CMFunctions.h
 *  worker
 *
 *  Created by Simon Strandgaard on 29/05/11.
 *  Copyright 2011 opcoders.com. All rights reserved.
 *
 */
#ifndef __COPYMOVE_FUNCTIONS_H__
#define __COPYMOVE_FUNCTIONS_H__

#include <sys/stat.h>


int copy_data_fd(int read_fd, int write_fd, unsigned long long* result_bytes_copied);


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

void nc_copyfile_fd(const struct stat *from_st, int from_fd, int to_fd, int flags);


#endif // __COPYMOVE_FUNCTIONS_H__
