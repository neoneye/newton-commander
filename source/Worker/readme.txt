project: Worker
copyright: Simon Strandgaard <simon@opcoders.com> 2009-2011

== TODO

SIGPIPE

Is it possible to send a signal to a child process, even when the child runs as root ?
I'm very interested in sending SIGKILL, but all I get is operation not permitted
How does BASH terminate things started with sudo ?  e.g. I can CTRL-C anything and it just works.
Alternative timeout with SIGALRM, so when the worker idles too long it will exit automatically

how to kill the child process?
I have already had this functionality before, it was relative straightforward using NSTask.
However with AEWP then it's complex!
PROBLEM: the child process was started with root privileges. In order to kill it externally 
one either has to use process-groups or use run a "kill" using AEWP.
Processgroups are so difficult that I don't think I will have much luck with it.
AEWP is so ugly that I don't like it, but I guess I have to go that way :-(
A lot of info here about process groups
http://www.cocoadev.com/index.pl?NSTaskTermination


investigate how to shutdown the thread and in a way so that we dont crash and leak as little as possible.


investigate wether we are leaking or not when restarting the child process


make "real" use of the command system in the WorkerParent
I have not yet a WorkerParent command for all the commands visible in the user-interface,
so whenever you tap a button, you see an error, because I have not implemented the command.


insert timeout logic into WorkerParent, so if a request is taking too long, then notify the caller
that the operation cannot be completed.


find suitable sandboxing settings on Lion.


XPC.. I cannot use XPC, since XPC is supposed to be stateless



integrate it back into Newton Commander.. where it is supposed to replace NCWorker.


integrate it with the new copymove component, so that we can test progressbars.



== NICE to have

maybe in the parent use SIGCHLD to monitor if a child process terminated or stopped.


make the protocols optional


add more buttons for stopping the worker gracefully/brutally


look at exit code of child process, was it EXIT_SUCCESS or EXIT_FAILURE.
sent some meaningful error message to the delegate.. isn't it always an error if the child exits?


somehow notify our parent process, letting it know that we failed to switch user.


move out user_switching code to a separate file


we write way too much to the log.. 
when the connection has been established we don't want to write more to the log


have a "transaction id" on every request/response


when the child is unavailable then show it in the UI.


when the child worker becomes ready, then update the UI so it's clear that it's up and running


measure start up time, so that we always can get a performance report.
it involves at least 2 different trampoline processes, AEWP and worker-trampoline,
so it is incredibly slow.


profile all requests, so that you always can look at the response and tell how long time
the request have taken.


use a watchdog to protect against hangups.. maybe a 1 minute alarm is good
This watchdog could be specified via the commandline, e.g:  NewtonCommanderHelper --watchdog=60


force exit by alarm()
force exit by assert()


watchdog, that kills the child if it has becomed non-responsive


a ping command that measures how long time a ping takes


somehow redirect stdin/stdout/stderr from child process to worker process


is there a way to programmatically update /etc/asl.conf
so it contains entries for my app?
hmm, doesn't seem so. One must manually edit /etc/asl.conf



== IDEAS

maybe rename from WorkerParent to WorkerController
maybe rename from WorkerParentDelegate to WorkerControllerDelegate

maybe rename MyWorkerPlugin to MyWorkerService



== NOTES

Purpose with the project is to solve these scenarios:

SCENARIO#1
In order to browse folders mounted with MacFuse, one must be logged in as the
user that did the mounting. If you try browse as another user then you will
not see any content of the folder.

SCENARIO#2
Some folder on the Mac are blocked for access by no other than root.
You must be logged in as root in order to browse these folders. 
If you try browse as another user then you will not see any content of the folder.

SCENARIO#3
When working with the file system you sometimes experience operations that
hangs forever or times out. The only way to really "cancel" a hang, is by
killing the worker-process.

At first I used a launch agent, based on the BAS sample project, but later I switched over
to using the setuid bit, to easily switch to another user. This had the benefit that the
process would run in the process hierarchy as a child of the cocoa app.
It worked great, but sadly the setuid bit is not allowed in the appstore!
I had to do a major rework of the code to use AuthorizationExecuteWithPrivileges instead.
AEWP is not allowed neither, but I have seen other apps using it, so I guess it's
kind of a gray area. AEWP is being used by Transmit.
Thus we run our child process with AEWP.. hoping that Apple let us through to the Mac App Store.

Things are more complicated because we use AEWP. It was absolute simplest with setuid.
AEWP can only start processes that runs as root. AEWP cannot start processes as different users,
so I have to use a trampoline process that is responsible for switching-user.
Obtaining the process-identifier of the child process is also more complicated.

The setuid code was in-secure though, because everybody would be able to
run the helper as root. It's more secure with AEWP.

