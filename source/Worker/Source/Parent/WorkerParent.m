//
//  NCWorkerParent.m
//  WorkerParent
//
//  Created by Simon Strandgaard on 08/06/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "WorkerParent.h"
#import "WorkerParentThread.h"
#import "Logger.h"
#include <unistd.h>


@interface WorkerParent (Private)
+(NSString*)createIdentifier;
-(void)childDidStartCommand:(NSDictionary*)aDictionary;
-(void)childDidStopCommand:(NSDictionary*)aDictionary;
@end

@implementation WorkerParent

@synthesize delegate = m_delegate;
@synthesize path = m_path;
@synthesize identifier = m_identifier;
@synthesize uid = m_uid;
@synthesize childProcessIdentifier = m_child_process_identifier;
@synthesize childUserIdentifier = m_child_user_identifier;
@synthesize commands = m_commands;

-(id)init {
    self = [super init];
    if(self != nil) {
		// default behavior: run child process under the same user as WorkerParent
		m_uid = getuid();
		self.identifier = [WorkerParent createIdentifier];
		m_thread = nil;
		m_child_process_identifier = 0;       
		m_child_user_identifier = 0;

		self.commands = [NSMutableDictionary dictionaryWithCapacity:50];
		
		[self registerDefaultCommands];
    }
    return self;
}

-(void)registerCommand:(NSString*)command block:(WorkerDictionaryBlock)aBlock {
	[m_commands setObject:[WorkerCommand commandWithBlock:aBlock] forKey:command];
}

-(void)registerDefaultCommands {
	// LOG_DEBUG(@"BEFORE REGISTERING");
	
	[self registerCommand:kWorkerParentCommandChildDidStart block:^(NSDictionary* aDictionary){
		[self childDidStartCommand:aDictionary];
	}];

	[self registerCommand:kWorkerParentCommandChildDidStop block:^(NSDictionary* aDictionary){
		[self childDidStopCommand:aDictionary];
	}];

	[self registerCommand:@"no_such_command_in_child" block:^(NSDictionary* aDictionary){
		LOG_DEBUG(@"no_such_command_in_child: %@", aDictionary);
		// TODO: notify delegate that the command was not recognized by the child
	}];
	
	// TODO: add ping command

	// LOG_DEBUG(@"AFTER REGISTERING");
}

-(void)childDidStartCommand:(NSDictionary*)aDictionary {
	// LOG_DEBUG(@"dictionary: %@", aDictionary);
	do {
		id thing = [aDictionary objectForKey:@"child_process_identifier"];
		if(![thing isKindOfClass:[NSNumber class]]) {
			LOG_ERROR(@"child_process_identifier is not a number, but is: %@", thing);
			break;
		}
	
		NSNumber* value = (NSNumber*)thing;
		int v = [value integerValue];
		LOG_DEBUG(@"child process identifier: %i", v);
		self.childProcessIdentifier = v;
	} while(0);
	
	do {
		id thing = [aDictionary objectForKey:@"child_user_identifier"];
		if(![thing isKindOfClass:[NSNumber class]]) {
			LOG_ERROR(@"child_user_identifier is not a number, but is: %@", thing);
			break;
		}
	
		NSNumber* value = (NSNumber*)thing;
		int v = [value integerValue];
		LOG_DEBUG(@"child user identifier: %i", v);
		self.childUserIdentifier = v;
	} while(0);
	
	if([self.delegate respondsToSelector:@selector(childDidStartForWorkerParent:)]) {  
		[self.delegate childDidStartForWorkerParent:self];
	}
}

-(void)childDidStopCommand:(NSDictionary*)aDictionary {
	// LOG_DEBUG(@"dictionary: %@", aDictionary);
	self.childProcessIdentifier = 0;
	
	if([self.delegate respondsToSelector:@selector(childDidStopForWorkerParent:)]) {  
		[self.delegate childDidStopForWorkerParent:self];
	}
}


+(NSString*)createIdentifier {
	static NSUInteger tag_counter = 0;                          
	NSUInteger pid = getpid();
	NSUInteger tag = tag_counter++; // autoincrement it
	return [NSString stringWithFormat:@"%lu_%lu", 
		(unsigned long)pid, (unsigned long)tag]; 
}

-(void)start {
	if(m_thread) return;

	NSParameterAssert(m_path);
	NSParameterAssert(m_delegate);
	NSParameterAssert(m_identifier);
	
	int pid = getpid();
	NSString* pid_str = [NSString stringWithFormat:@"%i", pid];

	NSString* cname = [NSString stringWithFormat:@"child_%@", m_identifier];
	NSString* pname = [NSString stringWithFormat:@"parent_%@", m_identifier];

	
	m_thread = [[WorkerParentThread alloc] 
		initWithWorker:self
		onThread:[NSThread currentThread] 
		path:m_path
		uid:m_uid
		parentProcessIdentifier:pid_str
		childName:cname
		parentName:pname
	];
	// IDEA: set user specified name here
	[m_thread setName:@"WorkerThread"];
	[m_thread start];
	

	[self requestCommand:kWorkerChildCommandStartup];
}

-(void)requestCommand:(NSString*)commandName {
	NSArray* keys = [NSArray arrayWithObjects:@"command", nil];
	NSArray* objects = [NSArray arrayWithObjects:commandName, nil];
	NSDictionary* dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	
	[self request:dict];
}

-(void)stop {
	LOG_ERROR(@"TODO: how to stop the worker?");
	// TODO: how to stop it
}


-(void)request:(NSDictionary*)dict {
	
	// start thread if not already started
	WorkerParentThread* t = m_thread; 
	if(!t) {
		[self start];
		t = m_thread;
		NSAssert(t, @"start is always supposed to initialize m_thread");
	}

	if ([self.delegate respondsToSelector:@selector(workerParent:inspectRequest:)]) {  
		[self.delegate workerParent:self inspectRequest:dict];
	}
	
	NSData* data = [NSArchiver archivedDataWithRootObject:dict];
	
	NSThread* thread = t;
	id obj = t;
	SEL sel = @selector(addRequestToQueue:);

	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:sel]];
	[inv setTarget:obj];
	[inv setSelector:sel];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	[inv setArgument:&data atIndex:2]; 
	[inv retainArguments];

	[inv performSelector:@selector(invoke) 
    	onThread:thread 
		withObject:nil 
		waitUntilDone:NO];
}

-(void)forwardResponse:(id)unarchivedData {
	NSDictionary* dict = nil;
	WorkerCommand* command = nil;
	
	do {
		if(![unarchivedData isKindOfClass:[NSDictionary class]]) {
			LOG_ERROR(@"ERROR: expected response to be a NSDictionary, but it wasnt. Ignoring the response!\nResponse: %@", unarchivedData);
			break; // ignore this response
		}
		dict = (NSDictionary*)unarchivedData;

		id value_command = [dict objectForKey:@"command"];
		if(![value_command isKindOfClass:[NSString class]]) {
			LOG_ERROR(@"ERROR: expected a string, but got %@. Ignoring this request!", NSStringFromClass([value_command class]));
			break;
		}
		NSString* command_name = (NSString*)value_command;

		id thing = [m_commands objectForKey:command_name];
		if(![thing isKindOfClass:[WorkerCommand class]]) {
			LOG_ERROR(@"ERROR: not a WorkerCommand for name: %@", command_name);
			break;
		}

		command = (WorkerCommand*)thing;
		
	} while(0);
	
	BOOL found_a_command = (command != nil);
	if ([self.delegate respondsToSelector:@selector(workerParent:inspectResponse:success:)]) {  
		[self.delegate workerParent:self inspectResponse:dict success:found_a_command];
	}

	[command run:dict];
}

@end
