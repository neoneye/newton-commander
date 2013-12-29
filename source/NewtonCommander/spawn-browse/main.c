//
// main.m
// spawn-browse
//
// Run these commands to enable SETUID
//   sudo chown -h root:wheel spawn-browse
//   sudo chmod -h 111 spawn-browse
//   sudo chmod -h u+s spawn-browse
//
// Start without arguments, prints how-to-use help
//   ./spawn-browse
//
// Start with a "no" argument, runs without changing the user
//   ./spawn-browse no
//
// Start with an integer argument, runs as the user 0 (root)
//   ./spawn-browse 0
//

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>
#include <string.h>

void print_usage()
{
	const char *usage =
	"USAGE\n"
	"\n"
	"Start as same user as the current user\n"
	"spawn-browse -1\n"
	"\n"
	"Start as another user than the current user\n"
	"spawn-browse 123\n";
	printf("%s", usage);
}

void print_whoami()
{
	printf(
			"whoami\n"
			 " real / effective uid: %i / %i\n"
			 " real / effective gid: %i / %i\n",
			 getuid (),
			 geteuid(),
			 getgid (),
			 getegid()
			 );
}

void switch_to_user(uid_t run_as_uid) {
	print_whoami();
	printf("will switch to user %d\n", (int)run_as_uid);
	if(setreuid((uid_t)run_as_uid, (uid_t)run_as_uid)) {
		if(errno == EPERM) {
			/*
			 TODO: somehow notify our parent process, letting it know that we failed to switch user.
			 */
			printf("main() - ERROR: we don't have permission to change user! maybe setuid wasn't set?");
			exit(EXIT_FAILURE);
		}
		/*
		 TODO: somehow notify our parent process, letting it know that we failed to switch user.
		 */
		printf("main() - ERROR: change user failed!!! maybe setuid wasn't set?");
		exit(EXIT_FAILURE);
	}
	printf("did switch to user %d\n", (int)run_as_uid);
	print_whoami();
}

void maybe_switch_to_user(const char *argument_string) {
	/*
	 The argument_string can either be "no" or an integer.
	 If it is "no" then we will not attempt to switch user.
	 If it is an integer then we will attempt to switch user.
	 */
	int rc = strncmp("no", argument_string, 2);
	int should_switch_user = (rc != 0);
	if (should_switch_user) {
		long run_as_uid = strtol(argument_string, NULL, 10);
		if((run_as_uid == 0) && (errno == EINVAL)) {
			printf("ERROR: interpreting argument[0]. The value must be a signed integer.");
			exit(EXIT_FAILURE);
		}
		switch_to_user((uid_t)run_as_uid);
	}
}

int main(int argc, const char * argv[])
{
	if(argc < 2) {
		print_usage();
		return EXIT_FAILURE;
	}
	
	// Obtain the user id from argument 1
	maybe_switch_to_user(argv[1]);
	
	printf("hello\n\n");
    return EXIT_SUCCESS;
}

