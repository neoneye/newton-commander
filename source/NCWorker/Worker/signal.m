//
// signal.m
// Newton Commander
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "signal.h"
#import "NCLog.h"


/*
one second should be enough for most operations
*/
#define kWatchdogTimeoutInSeconds 1


void start_watchdog() {
	/*
	IDEA: use setitimer (modern) instead of alarm (old)
	*/
	alarm(kWatchdogTimeoutInSeconds);
}

void stop_watchdog() {
	alarm(0);
}


void handle_sigalrm(int signo) {
	LOG_ERROR(@"exit! watchdog timed out");
	exit(EXIT_SUCCESS);
}

void setup_signals() {
	struct sigaction act;
	sigemptyset(&act.sa_mask);
	act.sa_flags = 0;

	// we use it as our watchdog 
	act.sa_handler = handle_sigalrm;
	if(sigaction(SIGALRM, &act, NULL) == -1) {
		LOG_ERROR(@"exit! can't install SIGALRM handler");
		exit(EXIT_FAILURE);
	}
}
