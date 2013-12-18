//
// exception.h
// Newton Commander
//


/*
we don't want to generate a crashreport whenever our daemon 
raises an exception related to distributed-objects, such
as NSPortTimeoutException.
instead we just want to die.

If we don't install any exception handler then when an exception is thrown our
program will generate a crash report. We don't want that we just want it to die
normally.


05/06/10 13.50.04	NCWorkerChild[550]	*** Terminating app due to uncaught exception 'TEST EXCEPTION', reason: 'foo is invalid'
*** Call stack at first throw:
(
	0   CoreFoundation                      0x980cc40a __raiseError + 410
	1   libobjc.A.dylib                     0x90d45509 objc_exception_throw + 56
	2   CoreFoundation                      0x980cc138 +[NSException raise:format:arguments:] + 136
	3   CoreFoundation                      0x980cc0aa +[NSException raise:format:] + 58
	4   NCWorkerChild                       0x0000272e -[Main stop] + 44
	5   Foundation                          0x9263aad9 __NSFireDelayedPerform + 537
	6   CoreFoundation                      0x98037edb __CFRunLoopRun + 8059
	7   CoreFoundation                      0x98035864 CFRunLoopRunSpecific + 452
	8   CoreFoundation                      0x9803b7a4 CFRunLoopRun + 84
	9   NCWorkerChild                       0x00002871 main + 309
	10  NCWorkerChild                       0x0000268d start + 53
)
05/06/10 13.50.06	ReportCrash[552]	Saved crash report for NCWorkerChild[550] version ??? (???) to /Users/neoneye/Library/Logs/DiagnosticReports/NCWorkerChild_2010-06-05-135006_Simon-Strandgaards-Mac-mini-3.crash

*/
void install_exception_handler();


void raise_test_exception();