//
//  AppDelegate.m
//  Kill
//
//  Created by Simon Strandgaard on 04/06/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import "AppDelegate.h"
#import "Logger.h"
#include <sys/types.h>
#include <pwd.h>
#include <grp.h>


@interface AppDelegate ()
-(void)popupateUserButton;
-(void)startWorker;      
-(void)stopWorker;
-(void)statusAppend:(NSString*)aString;
-(void)logAppend:(NSString*)aString;
@end

@implementation AppDelegate

@synthesize window = m_window;
@synthesize statusTextView = m_status_textview;
@synthesize logTextView = m_log_textview;
@synthesize switchUserPopUpButton = m_switch_user_popupbutton;
@synthesize workerParent = m_worker_parent;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 

	[Logger setupCocoaApp:@"Kill"];

	[self popupateUserButton];
	
	[self startWorker];
}

-(void)startWorker {
	NSMenuItem* mi = [m_switch_user_popupbutton selectedItem];
	int tag = [mi tag];
	int uid = tag;
	
	
	if(self.workerParent) {
		// already started, so we do nothing
		return;
	}
	
	[self statusAppend:@"starting up\n"];
	self.workerParent = [[[WorkerParent alloc] init] autorelease];
	self.workerParent.delegate = self;
	self.workerParent.path = [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"worker"];

	// self.workerParent.uid = -2; // run as nobody
	// self.workerParent.uid = 0; // run as root
	// self.workerParent.uid = 510; // run as johndoe
	// self.workerParent.uid = 503; // run as testuser1
	self.workerParent.uid = uid; // run as the user selected via the popupbutton
	[self.workerParent start];
	
	[self pingAction:self];
}

-(void)stopWorker {
	if(!self.workerParent) {
		// already stopped, so we do nothing
		return;
	}
	
	self.workerParent.delegate = nil;
	[self.workerParent stop];
	self.workerParent = nil;
}

-(void)popupateUserButton {
	const char* username = getlogin();
	// LOG_DEBUG(@"username: %s", username);

	NSPopUpButton* button = m_switch_user_popupbutton;
	NSMenu* menu = [button menu];
	[menu removeAllItems];

	NSMenuItem* found_mi = nil;
	struct passwd *pw;
	setpwent();
	while ((pw = getpwent())) {
		NSString* title = [NSString stringWithFormat:@"%s | %d", pw->pw_name, pw->pw_uid];
		if([title hasPrefix:@"_"]) continue; // ignore all accounts that starts with underscore
		NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""] autorelease];
		[mi setTag:pw->pw_uid];
		
		if(strcmp(username, pw->pw_name) == 0) {
			// LOG_DEBUG(@"found a match: %@", mi);
			found_mi = mi;
		}
		
		[menu addItem:mi];
	}
	endpwent();

	[button selectItem:found_mi];
}

-(IBAction)switchUserAction:(id)sender {
	NSMenuItem* mi = [sender selectedItem];
	int tag = [mi tag];
	LOG_DEBUG(@"mi: %@  tag: %i", mi, tag);
	
	[self restartAction:nil];
}

-(IBAction)killParentAction:(id)sender {
	LOG_DEBUG(@"kill parent");
	abort();
}

-(IBAction)sigkillChildAction:(id)sender {
	int pid = self.workerParent.childProcessIdentifier;
	if(pid == 0) {
		[self statusAppend:@"refuses to sigkill when pid is zero\n"];
		return;
	}
	[self statusAppend:[NSString stringWithFormat:@"kill pid: %i ... ", pid]];
	LOG_DEBUG(@"before sigkill pid: %i ... ", pid);
	int rc = kill(pid, SIGKILL);
	LOG_DEBUG(@"after sigkill pid: %i ... ", pid);
	if(rc != 0) {
		[self statusAppend:[NSString stringWithFormat:@"failed. errno: %i  %s\n", errno, strerror(errno)]];
		return;
	}
	[self statusAppend:@"OK\n"];
}

-(IBAction)sigtermChildAction:(id)sender {
	int pid = self.workerParent.childProcessIdentifier;
	if(pid == 0) {
		[self statusAppend:@"refuses to sigterm when pid is zero\n"];
		return;
	}
	[self statusAppend:[NSString stringWithFormat:@"term pid: %i ... ", pid]];
	LOG_DEBUG(@"before sigterm pid: %i ... ", pid);
	int rc = kill(pid, SIGTERM);
	LOG_DEBUG(@"after sigterm pid: %i ... ", pid);
	if(rc != 0) {
		[self statusAppend:[NSString stringWithFormat:@"failed. errno: %i  %s\n", errno, strerror(errno)]];
		return;
	}
	[self statusAppend:@"OK\n"];
}

-(IBAction)sigintChildAction:(id)sender {
	int pid = self.workerParent.childProcessIdentifier;
	if(pid == 0) {
		[self statusAppend:@"refuses to sigint when pid is zero\n"];
		return;
	}
	[self statusAppend:[NSString stringWithFormat:@"int pid: %i ... ", pid]];
	LOG_DEBUG(@"before sigint pid: %i ... ", pid);
	int rc = kill(pid, SIGINT);
	// int rc = kill(pid, SIGPIPE);
	// int rc = kill(pid, SIGHUP);
	// int rc = kill(pid, SIGUSR1);
	LOG_DEBUG(@"after sigint pid: %i ... ", pid);
	if(rc != 0) {
		[self statusAppend:[NSString stringWithFormat:@"failed. errno: %i  %s\n", errno, strerror(errno)]];
		return;
	}
	[self statusAppend:@"OK\n"];
}

-(IBAction)restartAction:(id)sender {
	LOG_DEBUG(@"stop worker");
	[self stopWorker];
	
	LOG_DEBUG(@"start worker");
	[self startWorker];
}

-(IBAction)exitFailureChildAction:(id)sender {
	[self.workerParent requestCommand:@"force_exit_failure"];
}

-(IBAction)exitSuccessChildAction:(id)sender {
	[self.workerParent requestCommand:@"force_exit_success"];
}

-(IBAction)exceptionChildAction:(id)sender {
	[self.workerParent requestCommand:@"force_exception"];
}

-(IBAction)abortChildAction:(id)sender {
	[self.workerParent requestCommand:@"force_abort"];
}

-(IBAction)pingAction:(id)sender {
	[self.workerParent requestCommand:@"ping"];
}

-(IBAction)unknownAction:(id)sender {
	[self.workerParent requestCommand:@"unknown"];
}

-(IBAction)test1Action:(id)sender {
	[self.workerParent requestCommand:@"test1"];
}

-(IBAction)test2Action:(id)sender {
	[self.workerParent requestCommand:@"test2"];
}

-(void)workerParent:(WorkerParent*)aWorkerParent inspectRequest:(NSDictionary*)aResponseDictionary {
	[self logAppend:[NSString stringWithFormat:@"request: %@\n\n", aResponseDictionary]];
}

-(void)workerParent:(WorkerParent*)aWorkerParent inspectResponse:(NSDictionary*)aResponseDictionary success:(BOOL)isSuccess {
	if(isSuccess) {
		[self logAppend:[NSString stringWithFormat:@"response: %@\n\n", aResponseDictionary]];
	} else {
		[self logAppend:[NSString stringWithFormat:@"ERROR handling response: %@\n\n", aResponseDictionary]];
	}
}

-(void)childDidStartForWorkerParent:(WorkerParent*)aWorkerParent {
	[self statusAppend:[NSString stringWithFormat:@"child did start.\n  child_process_identifier: %i\n  child_user_identifier: %i\n", aWorkerParent.childProcessIdentifier, aWorkerParent.childUserIdentifier]];
}

-(void)childDidStopForWorkerParent:(WorkerParent*)aWorkerParent {
	[self statusAppend:[NSString stringWithFormat:@"child did stop\n"]];
}

-(void)statusAppend:(NSString*)aString {
	NSTextView* tv = self.statusTextView;
	[[[tv textStorage] mutableString] appendString: aString];
	NSRange the_end = NSMakeRange([[tv string] length], 0);
	[tv scrollRangeToVisible:the_end];
}

-(void)logAppend:(NSString*)aString {
	NSTextView* tv = self.logTextView;
	[[[tv textStorage] mutableString] appendString: aString];
	NSRange the_end = NSMakeRange([[tv string] length], 0);
	[tv scrollRangeToVisible:the_end];
}



@end
