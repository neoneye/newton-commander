//
//  WorkerChild.h
//  Kill
//
//  Created by Simon Strandgaard on 05/06/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#include <Foundation/Foundation.h>

#import "WorkerShared.h"
#import "WorkerCommand.h"

@class WorkerChild;

@protocol WorkerChildPlugin <NSObject>
-(void)prepareWorkerChild:(WorkerChild*)aWorkerChild;
@end


@interface WorkerChild : NSObject <WorkerChildCallbackProtocol> {
	NSConnection* m_connection;
	NSString* m_child_name;
	NSString* m_parent_name;
	id <WorkerParentCallbackProtocol> m_parent;
	BOOL m_connection_established;
	
	id <WorkerChildPlugin> m_plugin;
	
	int m_ping_count;
	
	NSMutableDictionary* m_commands;
}
@property (nonatomic, retain) id <WorkerChildPlugin> plugin;
@property (nonatomic, retain) NSMutableDictionary* commands;

-(id)initWithChildName:(NSString*)cname parentName:(NSString*)pname className:(NSString*)aClassName;
-(void)initConnection;
-(void)connectToParent;

-(void)registerCommand:(NSString*)command block:(WorkerDictionaryBlock)aBlock;
-(void)registerDefaultCommands;

-(void)runPingCommand;
-(void)runStartupCommand;

-(void)didEnterRunloop;

-(void)stop;

-(void)deliverResponse:(NSDictionary*)dict;

@end



/*
the is all you need in your main(). 
This creates an instance of WorkerChild and establishes a connection to the WorkerParent.

NOTE: in order for log messages to be visible in Console.app, 
you must first add the the logger_name to /etc/asl.conf, e.g. if the logger_name is FireFox
then /etc/asl.conf should have these lines appended to the bottom
# save everything from FireFox
? [= Sender FireFox] store
? [= Sender FireFoxWorker] store


NOTE: The class_name must conform to the WorkerChildPlugin protocol.
An instance of class_name will be created. 
*/
int worker_child_main(int argc, const char * argv[], const char* logger_name, const char* class_name);


