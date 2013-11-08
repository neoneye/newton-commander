//
//  Logger.m
//  SharedCode Core+Worker
//
//  Created by Simon Strandgaard on 28/07/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "Logger.h"


@implementation Logger

static Logger* shared_instance = nil;

-(id)init {
	[self initWithName:@"noname" useStderr:YES];
	return self;
}

-(id)initWithName:(NSString*)name useStderr:(BOOL)use_stderr {
	if ((self = [super init]) != nil) {
		
		// make the messages visible in Xcode's console
		int options = use_stderr ? ASL_OPT_STDERR : 0U;
		m_aslclient = asl_open(NULL, NULL, options);
		
		// we don't want ASL to hide any messages for us
		asl_set_filter(m_aslclient, ASL_FILTER_MASK_UPTO(ASL_LEVEL_DEBUG));
		// asl_set_filter(m_aslclient, 0);

		m_aslmsg = asl_new(ASL_TYPE_MSG);
	    assert(m_aslmsg != NULL);

	    asl_set(m_aslmsg, ASL_KEY_SENDER, [name UTF8String]);
	    asl_set(m_aslmsg, ASL_KEY_FACILITY, "com.apple.console");
	}
	return self;
}

+(void)setupCocoaApp:(NSString*)logName {
	/*
	this is for executables that uses stdout/stderr and has a graphical user interface
	example of logName could be: Chrome
	*/
	[Logger setShared:[[Logger alloc] initWithName:logName useStderr:YES]];
}

+(void)setupWorkerApp:(NSString*)logName {
	/*
	this is for executables that doesn't use stdout/stderr 
	example of logName could be: ChromeSandboxWorker
	*/
	[Logger setShared:[[Logger alloc] initWithName:logName useStderr:NO]];
}

+(void)setShared:(Logger*)instance {
	@synchronized(self) {
		shared_instance = instance;
	}
}

+(Logger*)shared {
	@synchronized(self) {
	    if(!shared_instance) {
	        shared_instance = [[Logger allocWithZone:NULL] init];
	    }
	}
    return shared_instance;
}

+(void)sharedSourceFile:(const char*)sourceFile 
       functionName:(const char*)functionName 
       lineNumber:(int)lineNumber 
            level:(int)level
           format:(NSString*)format, ... {
	Logger* log = [self shared];

	va_list ap;

	va_start(ap,format);
	NSString* message = [[[NSString alloc] initWithFormat:format arguments:ap] autorelease];
	va_end(ap);

	NSString* funcname = [NSString stringWithUTF8String:functionName];
	NSString* path = [NSString stringWithUTF8String:sourceFile];
	NSString* filename = [path lastPathComponent];
	
	[log message:message funcname:funcname filename:filename level:level line:lineNumber];
}

-(void)message:(NSString*)message
	funcname:(NSString*)funcname
	filename:(NSString*)filename
    level:(int)level
	line:(int)line {
	NSString* s = [NSString stringWithFormat:@"%@:%d %@ --- %@", filename, line, funcname, message];
	asl_log(m_aslclient, m_aslmsg, level, "%s", [s UTF8String]);
}

@end
