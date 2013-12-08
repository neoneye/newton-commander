//
//  Logger.h
//  SharedCode Core+Worker
//
//  Created by Simon Strandgaard on 28/07/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#include <Foundation/Foundation.h>
#include <asl.h>

/*
Write text to the systemwide log file. 
Logger is a strange singleton class, ... read on ...

The Newton Commander application consists of 2 programs:
 program 1. NCMainApp
 program 2. NCWorker

This singleton class can be initialized in several ways depending on 
which program it's used in. If it's NCWorker then the singleton should 
be initialized with the setupWorkerApp function as soon as possible within 
void main(). If it's the NCMainApp then invoke setupCocoaApp.
*/
@interface Logger : NSObject {
	aslclient m_aslclient;
	aslmsg	  m_aslmsg;
}
-(id)initWithName:(NSString*)name useStderr:(BOOL)use_stderr;

// the setupMethods must be invoked as the very first thing, since it 
// controls how the singleton are initialized
+(void)setupCocoaApp:(NSString*)logName;
+(void)setupWorkerApp:(NSString*)logName;
+(void)setShared:(Logger*)instance;


+(Logger*)shared;

+(void)sharedSourceFile:(const char*)sourceFile 
	functionName:(const char*)functionName 
	lineNumber:(int)lineNumber 
	level:(int)level
	format:(NSString*)format, ...;   // not sure if NS_FORMAT_FUNCTION(5,6) is needed

-(void)message:(NSString*)message
	funcname:(NSString*)funcname
	filename:(NSString*)filename
    level:(int)level
	line:(int)line;

@end


/*
Usage:
LOG_ERROR(@"Houston, we have a problem");
LOG_WARNING(@"The code is %@", @"42 (AGENT X)");
LOG_INFO(@"VALUE: %i\n", 1234);
*/
#define LOG_ERROR(s,...) \
    [Logger sharedSourceFile:__FILE__ functionName:__PRETTY_FUNCTION__ lineNumber:__LINE__ level:ASL_LEVEL_ERR format:(s),##__VA_ARGS__]

#define LOG_WARNING(s,...) \
    [Logger sharedSourceFile:__FILE__ functionName:__PRETTY_FUNCTION__ lineNumber:__LINE__ level:ASL_LEVEL_WARNING format:(s),##__VA_ARGS__]

#define LOG_INFO(s,...) \
    [Logger sharedSourceFile:__FILE__ functionName:__PRETTY_FUNCTION__ lineNumber:__LINE__ level:ASL_LEVEL_INFO format:(s),##__VA_ARGS__]

#define LOG_DEBUG(s,...) \
    [Logger sharedSourceFile:__FILE__ functionName:__PRETTY_FUNCTION__ lineNumber:__LINE__ level:ASL_LEVEL_DEBUG format:(s),##__VA_ARGS__]
