//
//  NCWorkerParent.h
//  WorkerParent
//
//  Created by Simon Strandgaard on 08/06/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#include <Foundation/Foundation.h>

#import "WorkerCommand.h"


/*
you should call this from within the main() function of your app, just before NSApplicationMain.
The reason for this code is to prevent GDB from choking whenever there is a SIGPIPE.
SIGPIPE happens whenever the child-worker dies. In this case we want the parent process to continue.
*/
#define PREPARE_WORKER_PARENT_IN_MAIN \
	signal(SIGPIPE, SIG_IGN); // Ignore SIGPIPE so that program does not abnormally exit







@class WorkerParent;
@class WorkerParentThread;


@protocol WorkerParentDelegate <NSObject>

-(void)childDidStartForWorkerParent:(WorkerParent*)aWorkerParent;

-(void)childDidStopForWorkerParent:(WorkerParent*)aWorkerParent;

-(void)workerParent:(WorkerParent*)aWorkerParent inspectRequest:(NSDictionary*)aResponseDictionary;

-(void)workerParent:(WorkerParent*)aWorkerParent inspectResponse:(NSDictionary*)aResponseDictionary success:(BOOL)isSuccess;

@end


/*
WorkerParent controls a worker child process. This is the only class you should
deal with in the parent process.

Features:
 - Robust against crashes in the child process
 - Child process can run as a different user, e.g. root or johndoe or nobody
 - Bidirectional communication: Commands can be send both ways
 - Child process will stop running when parent process stops running
 - Parent process is notified when child process stops running

Suggested usage:
Don't subclass WorkerParent, instead create a class that implements 
the the delegate protocol and set it as the delegate.

Biggest problem: Process group
The child process doesn't run in same process group as the parent process, 
because we are using AuthorizationExecuteWithPrivileges().
Process groups works well when using the SETUID bit, however it is not
allowed in the Mac App Store.
I have also tried using a lauchagent based on the BetterAuthenticationSample (BAS),
however it is really complicated and doesn't run in the same process group neither.
Sadly no elegant solution to this. I'm using the best approach
with AEWP IMHO.
*/
@interface WorkerParent : NSObject {
	id<WorkerParentDelegate> m_delegate;
	NSString *m_path; // path to executable
	WorkerParentThread *m_thread;
	NSString *m_identifier;
	int m_uid;
	int m_child_process_identifier;
	int m_child_user_identifier;
	NSMutableDictionary* m_commands;
}
@property (nonatomic, assign) id<WorkerParentDelegate> delegate;
@property (nonatomic, retain) NSString *path;  // path to executable
@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, assign) int uid;
@property (nonatomic, assign) int childProcessIdentifier;
@property (nonatomic, assign) int childUserIdentifier;
@property (nonatomic, retain) NSMutableDictionary* commands;

-(void)start;   

-(void)stop;

-(void)request:(NSDictionary*)dict;
-(void)requestCommand:(NSString*)commandName;

-(void)forwardResponse:(id)unarchivedData;

-(void)registerCommand:(NSString*)command block:(WorkerDictionaryBlock)aBlock;
-(void)registerDefaultCommands;

@end
