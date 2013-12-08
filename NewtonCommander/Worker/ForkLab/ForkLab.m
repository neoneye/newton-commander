/*

this program starts 5 nested processes.
Lets refer to them as:  P0, P1, P2, P3, P4

P0 is the process group leader.. it sleeps for 100 seconds
P1, P2, P3 all exit immediately after having started their child process
P4 is the grand child and runs for 100 seconds

PROBLEM: when I look in Activity Monitor I can see that P4 has
been reparented to be a child of the "init" process.
I would expect it to be reparented to the P0 process.

How can I control the reparenting?


*/

#import <Foundation/Foundation.h>

int main (int argc, const char * argv[]) {
	const char* exec_path = argv[0];

	// printf("PARENT: exec_path: %s\n", exec_path);
	printf("getpgrp: %i\n", getpgrp());
	
	for(int i=0; i<argc; i++) {
		printf("argv[%i]=%s\n", i, argv[i]);
	}

	int n = 0;
	if(argc >= 2) {
		
		const char* value_str = argv[1];
		int value = strtol(value_str, NULL, 10);
		if((errno == EINVAL) || (errno == ERANGE)) {
			printf("ERROR: strtol failed to parse string: \"%s\"", value_str);
			return 1;
		}
		
		n = value;
	}

	int process_group_id = getpid();
	if(argc >= 3) {
		
		const char* value_str = argv[2];
		int value = strtol(value_str, NULL, 10);
		if((errno == EINVAL) || (errno == ERANGE)) {
			printf("ERROR: strtol failed to parse string: \"%s\"", value_str);
			return 1;
		}
		
		process_group_id = value;
	}
	
	if(n >= 4) {
		printf("the desired nesting level has been reached. the end\n");
		sleep(100);
		return 0;
	}
	
	if(n == 0) {
		printf("will setpgid\n");
		if(setpgid(0, getpid()) < 0) {
            perror ("setpgid 1");
            exit (1);
		}
		setsid();
		
	} else {

		if(setpgid(0, process_group_id) < 0) {
            perror ("setpgid 2");
            exit (1);
		}

/*		if( setpgid(0,0) < 0) {
			perror("setpgid 2");
			exit(1);
		}*/

		printf("did setpgid\n");
	}

	int n1 = n + 1;
	

    pid_t pid = fork();
    if (pid == -1) { 
		/* fork error - cannot create child */
		perror("Demo program");
		exit(1);
	}
    else if (pid == 0) 
	{
        /* code for child */
        printf("CHILD:\n");


		char argv1[20];
		argv1[0] = 0;
		snprintf(argv1, 10, "%i", n1);

		char argv2[20];
		argv2[0] = 0;
		snprintf(argv2, 10, "%i", process_group_id);

		execl(exec_path, exec_path, argv1, argv2, NULL);
		_exit(1);
	}
	/* code for parent */ 
	printf("PARENT: Pid of latest child is %d\n", pid);
	
	if(n > 0) {
		printf("ourpid=%i. childpid=%i, n=%i. quitting parent.. should cause reparenting\n", getpid(), pid, n);
		return 0;
	}

	
	printf("will wait\n");

	// wait(0);
	sleep(100);
	
	printf("did wait\n");


    // insert code here...
    return 0;
}
