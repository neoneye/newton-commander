//
// zombie.m
// Newton Commander
//

/*
PROBLEM: ensure that our process dies when the frontend process dies.
At first I used NSWorkspaceDidTerminateApplicationNotification
but that requires the Cocoa framework, which is not appropriate
for tools that runs as root.

SOLUTION: kqueue
This seems to be the most reliable solution. Requires no polling.

see 
http://developer.apple.com/technotes/tn/tn2050.html

see
http://developer.apple.com/documentation/CoreFoundation/Reference/CFFileDescriptorRef/Reference/reference.html
*/
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "zombie.h"                     
#import "NCLog.h"
#include <unistd.h>
#include <sys/event.h>


void noteProcDeath(
	CFFileDescriptorRef fdref, 
	CFOptionFlags callBackTypes, 
	void* info) 
{
	// LOG_DEBUG(@"noteProcDeath... ");

    struct kevent kev;
    int fd = CFFileDescriptorGetNativeDescriptor(fdref);
    kevent(fd, NULL, 0, &kev, 1, NULL);
    // take action on death of process here
	unsigned int dead_pid = (unsigned int)kev.ident;

    CFFileDescriptorInvalidate(fdref);
    CFRelease(fdref); // the CFFileDescriptorRef is no longer of any use in this example

	int our_pid = getpid();
	/*
	when our parent dies we die as well.. 
	this is actually the way our worker process is supposed to die.
	*/
	LOG_INFO(@"exit! parent process (pid %u) died. no need for us (pid %i) to stick around", dead_pid, our_pid);
	exit(EXIT_SUCCESS);
}


void suicide_if_we_become_a_zombie() {
	int parent_pid = getppid();
	// int our_pid = getpid();
	// LOG_ERROR(@"suicide_if_we_become_a_zombie(). parent process (pid %u) that we monitor. our pid %i", parent_pid, our_pid);

    int fd = kqueue();
    struct kevent kev;
    EV_SET(&kev, parent_pid, EVFILT_PROC, EV_ADD|EV_ENABLE, NOTE_EXIT, 0, NULL);
    kevent(fd, &kev, 1, NULL, 0, NULL);
    CFFileDescriptorRef fdref = CFFileDescriptorCreate(kCFAllocatorDefault, fd, true, noteProcDeath, NULL);
    CFFileDescriptorEnableCallBacks(fdref, kCFFileDescriptorReadCallBack);
    CFRunLoopSourceRef source = CFFileDescriptorCreateRunLoopSource(kCFAllocatorDefault, fdref, 0);
    CFRunLoopAddSource(CFRunLoopGetMain(), source, kCFRunLoopDefaultMode);
    CFRelease(source);
}
