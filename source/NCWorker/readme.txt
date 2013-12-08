Newton Commander - Worker process
Copyright 2010 - Simon Strandgaard <simon@opcoders.com>


== PURPOSE ==

The set of goals for our worker process are:

1. Responsive
   - no spinning beachballs in the UI
   - resistent against the many timeouts in Apple's filesystem code
   - provide data as fast as possible
2. Sudo
   - must be able to browse dirs as Admin
   - must be able to browse MacFUSE volumes as the user that mounted the volume
3. Show as much data as possible
   - apparently Apple is hiding some dirs (rixstep's getdirentries hack)
4. Be nice
   - operations can be cancelled (by killing the task)
   - don't let an attacker take over the privileged worker program
   - don't let any zombie processes run wild


== SOCKETS vs. MACH PORTS ==

the reason we use sockets (rather than mach ports) is that we need to communicate
between two processes running with different permissions. 
parent process is a GUI application where UID is a user account.
child process is a commandline program where UID is may be root.
IPC between different user accounts is NOT possible with mach ports,
thus we use sockets (hard earned knowledge).



== TODO ==

 1. switch user
 4. killable.. how to code it?  how did I do it in the past?
 5. discover hang in the NSTask
 6. thread to restart worker-task
 7. profile the code
 5. measure performance of task/thread start and handshake


== IDEAS == 

Use a transaction ID. This is necessary because some calls have several callbacks that are
invoked as a sequence.

I don't like the hard-fail errors that happens when the handshake goes wrong.
If I somehow could improve the robustness of the handshake and make it 
easier to debug the handshake, then things would be much better.

output a UML activity diagram showing what the different threads are doing simultaneous

worker-task to operate in different modes:
 list mode:  list content of directories
 info mode:  gather details about files
 xfer mode:  transfer files (move/copy)
 attr mode:  change attributes of files
 watch mode:  monitor changes in the file system

create a tmp log file per worker. In case something goes wrong then
use the log to see what went wrong

transcript log of all operations

performance log of all operations


== AUTHENTICATION == 

How do we only run the worker for a user that has granted permissions for it to run.
If it's a SETUID process then it's very difficult. And I have yet to realize how to 
do it properly.


