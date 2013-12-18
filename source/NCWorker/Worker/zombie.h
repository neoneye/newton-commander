//
// zombie.h
// Newton Commander
//


/*
when our parent dies we die as well.. 

all the time we monitor the parent process
if it dies then we commit suicide, because we are no longer needed.

NOTE: this only work together with a CFRunLoopRun or NSRunLoop.
This suicide code only works then the process isn't busy doing 
something else in the runloop. Example: If you invoke sleep(100), then
the process will sleep for 100 seconds and thus the runloop will not
be executed in the meantime. Solution is NOT to invoke sleep but rather use 
[self performSelector: @selector(stop)
           withObject: nil
           afterDelay: 100.f];
This way the run loop will still work and we get killed correctly
when our parent dies. So remember that this code only works together with a runloop.
*/
void suicide_if_we_become_a_zombie();

