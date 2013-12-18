//
// signal.h
// Newton Commander
//

void setup_signals();


/*
PURPOSE: we start a 30 second watchdog for every runloop operation, just to 
make sure that we don't get stuck in some hang/crash/infinite loop.

The filesystem on Mac OS X sometimes can time out for over 10 seconds, 
especially on Mac OS X 10.5 and earlier it was necessary to kill these 
jobs that was hanging. Because of these hangs I figured that file system
code must be run in a a separate process, so that it can be terminated
when it times out and we restart the process.


Start the watchdog timer.  If you don't call DisableWatchdog before the 
timer expires, the process will die with a SIGALRM.

If the watchdog has already been started, but has not been triggered, 
another call to start_watchdog() will extend the watchdog time.
A single call to stop_watchdog() will cancel all preceding start's.

This function must be placed before a piece of code that 
potentially can timeout.
*/
void start_watchdog();

/*
Stops the watchdog timer.

This function must be placed after a piece of code that 
potentially can timeout.
*/
void stop_watchdog();
