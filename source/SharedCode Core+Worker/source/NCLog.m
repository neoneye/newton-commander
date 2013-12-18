//
// NCLog.m
// Newton Commander
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "NCLog.h"


@implementation NCLog

static NCLog* shared_instance = nil;

-(id)init {
	return [self initWithName:@"noname" useStderr:YES];
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

+(void)setupNewtonCommander {
	[NCLog setShared:[[NCLog alloc] initWithName:@"Newton Commander" useStderr:YES]];
}

+(void)setupWorker {
	[NCLog setShared:[[NCLog alloc] initWithName:@"NewtonCommanderHelper" useStderr:NO]];
}

+(void)setShared:(NCLog*)instance {
	@synchronized(self) {
		shared_instance = instance;
	}
}

+(NCLog*)shared {
	@synchronized(self) {
	    if(!shared_instance) {
	        shared_instance = [[NCLog allocWithZone:NULL] init];
	    }
	}
    return shared_instance;
}

+(void)sharedSourceFile:(const char*)sourceFile 
       functionName:(const char*)functionName 
       lineNumber:(int)lineNumber 
            level:(int)level
           format:(NSString*)format, ... {
	NCLog* log = [self shared];

	va_list ap;

	va_start(ap,format);
	NSString* message = [[NSString alloc] initWithFormat:format arguments:ap];
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
