/*********************************************************************
main.cpp - installer for the "kc" commandline tool into "/usr/bin/kc"
Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#include <unistd.h>
#include <stdio.h>
#include <assert.h>
#include <fcntl.h>
#include <sys/stat.h>


#define MAIN_PID_TOKEN1 "we have pid <"
#define MAIN_PID_TOKEN2 "> and maybe we are running as root"

#define EXECUTABLE_MODE (ACCESSPERMS & ~(S_IWGRP | S_IWOTH))


/*
returns 0 for success
returns -1 if the operation failed
*/
int copy_data(int fd_src, int fd_dest) {
	char buffer[65536];
	int	bytes_read;
	int retries = 5;
	
	do {
		bytes_read = read(fd_src, buffer, sizeof(buffer));
		if(bytes_read < 0) return -1;
		
		int bytes_to_write = bytes_read;
		char* ptr = buffer;
		while(bytes_to_write > 0) {
			int bytes = write(fd_dest, ptr, bytes_to_write);
			if(bytes < 0) return -1;
			if(bytes == 0) {
				retries -= 1;
				if(retries < 0) return -1;
			}

			bytes_to_write -= bytes;
			ptr += bytes;
		}
	} while(bytes_read != 0);             

	return 0;
}


int main(int argc, const char** argv) {

	// Print our PID so that the app can avoid creating zombies.
	printf(MAIN_PID_TOKEN1 "%ld" MAIN_PID_TOKEN2 "\n", (long)getpid());
	fflush(stdout);


	if(argc != 3) {
		printf("ERROR: two arguments expected: [copy_src_path, copy_dest_path]\n");
		return -1;
	}
	
	
	const char* copy_src_path  = argv[1]; // example: "/MyVolume/TheApp/MacOS/kc"
	const char* copy_dest_path = argv[2]; // example: "/usr/bin/kc"
	
	assert(copy_src_path != NULL);
	assert(copy_dest_path != NULL);

	// printf("copy from: %s\n", copy_src_path);
	// printf("copy to: %s\n", copy_dest_path);


	int err = 0;


	umask(S_IWGRP | S_IWOTH);
	
    err = setuid(0);
    if(err < 0) {
		printf("ERROR: setuid\n");
		return -1;
	}
	
	/*
	delete the file "/usr/bin/kc" if it exists.
	make sure before we delete it that it really is a file
	*/
	do {
		struct stat st;
	
		err = stat(copy_dest_path, &st);
		if(err < 0) {
			/*
			there is no file to stat which is good, because we then
			don't have to worry about overwriting anything.
			*/
			break;
		}
		if(S_ISREG(st.st_mode) == 0) {
			// refuse to unlink if it's not a regular file
			// would be terrible if we accidentially deleted a dir or something important
			printf("ERROR: stat copy_dest_path. "
				"Expected it to be a regular file: %s\n", 
				copy_dest_path
			);
			return -1;
		}

		// it is a regular file.. lets delete it
	    unlink(copy_dest_path);

	} while(false);
	

	/*
	copy the file
	*/
	int fd_src = -1;
	int fd_dest = -1;
	do {
		// open the file descriptors
		fd_src = open(copy_src_path, O_RDONLY);
		if(fd_src < 0) {
			printf("ERROR: cannot open copy_src_path file: %s\n", copy_src_path);
			err = -1;
			break;
		}
		fd_dest = open(copy_dest_path, O_CREAT | O_EXCL | O_WRONLY, EXECUTABLE_MODE);
		if(fd_dest < 0) {
			printf("ERROR: cannot open copy_dest_path file: %s\n", copy_dest_path);
			err = -1;
			break;
		}

		// both file descriptors are now valid and we can copy the data
		err = copy_data(fd_src, fd_dest);
		if(err != 0) {
			printf("ERROR: read/write error\n");
			break;
		}
		
	} while(false);

	// clean up
	if(fd_src != -1)  {
		int rc = close(fd_src);
		assert(rc == 0);
	}
	if(fd_dest != -1)  {
		int rc = close(fd_dest);
		assert(rc == 0);
	}

	if(err) {
		printf("FAILED\n");
		fflush(stdout);
	    return -1;
	}

	printf("OK\n");
	fflush(stdout);
    return 0;
}
