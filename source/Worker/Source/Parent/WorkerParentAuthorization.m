//
//  WorkerParentAuthorization.m
//  Kill
//
//  Created by Simon Strandgaard on 11/06/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import "WorkerParentAuthorization.h"
#import "Logger.h"


@implementation WorkerParentAuthorization

+(WorkerParentAuthorization*)shared {
	static WorkerParentAuthorization* instance = nil;
	if(!instance) { instance = [[WorkerParentAuthorization alloc] init]; }
	return instance;
}

-(id)init {
    self = [super init];
    if(self != nil) {
		m_auth = NULL;
    }
    return self;
}

-(BOOL)createAuthorization {
	// IDEA: not thread-safe, maybe insert a @synchronized since we are using this class from different threads
	
    if(m_auth) {
        return YES;
	}

    {
	    OSStatus status = AuthorizationCreate(
			NULL, 
			kAuthorizationEmptyEnvironment,
	        kAuthorizationFlagDefaults, 
			&m_auth
		);
	    if(status != errAuthorizationSuccess) {
	        return NO;
		}
	}
    
    {
	    AuthorizationItem items = { kAuthorizationRightExecute, 0, NULL, 0 };
	    AuthorizationRights rights = { 1, &items };
	    AuthorizationFlags flags = kAuthorizationFlagDefaults | kAuthorizationFlagExtendRights | kAuthorizationFlagPreAuthorize | kAuthorizationFlagInteractionAllowed;
	    OSStatus status = AuthorizationCopyRights(
			m_auth, 
			&rights,
	        NULL, 
			flags, 
			NULL
		);
    
	    if(status != errAuthorizationSuccess) {
	        return NO;
		}
	}
    
	// authorization was successfully created
    return YES;
}

-(void)invalidateAuthorization {
    if(m_auth) {
        AuthorizationFree(m_auth, kAuthorizationFlagDestroyRights);
        m_auth = NULL;
    }
}

-(void)execute:(NSString*)executablePath arguments:(NSArray*)arguments {
	BOOL ok = [self createAuthorization];
	if(!ok) {
		LOG_ERROR(@"failed to obtain authorization");
		return;
	}
	AuthorizationRef auth = m_auth;

	
	int argc = [arguments count];
	if(argc > 100) {
		LOG_ERROR(@"too many arguments (%i). capacity is 100", argc);
		return;
	}
	
	char* argv[105];
	int i = 0;
	for(; i<argc; i++) {
		argv[i] = (char*)[[arguments objectAtIndex:i] UTF8String];
	}
	argv[i] = NULL;
	
	LOG_DEBUG(@"AuthorizationExecuteWithPrivileges before");
	/*
	here is the implementation of AuthorizationExecuteWithPrivileges()
	http://www.opensource.apple.com/source/libsecurity_authorization/libsecurity_authorization-36329/lib/trampolineClient.cpp
	*/
	OSStatus rc = AuthorizationExecuteWithPrivileges(
		auth,
	    [executablePath fileSystemRepresentation],
		kAuthorizationFlagDefaults, 
		argv,
	    NULL
	);
	LOG_DEBUG(@"AuthorizationExecuteWithPrivileges after");
	
	/*
	does this block the main-thread until the child worker task has started?
	the child worker will close stdin/stdout/stderr, which I guess is what
	causes the while loop to be ended
	*/
	// IDEA: maybe remove the while loop entirely
	if(rc == noErr) {
	} else {
		LOG_ERROR(@"aborted authorized exe: %i", (int)rc);
	}
}

@end
