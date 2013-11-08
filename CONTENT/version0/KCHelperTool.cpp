/*
 *  KCHelperTool.cpp
 *  OrthodoxFileManager
 *
 *  Created by Simon Strandgaard on 20/07/09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */
#include <netinet/in.h>
#include <stdio.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <unistd.h>
#include <spawn.h>

#include <CoreServices/CoreServices.h>

#include "BetterAuthorizationSampleLib.h"

#include "KCHelperCommon.h"


static OSStatus DoGetVersion(
	AuthorizationRef			auth,
    const void *                userData,
	CFDictionaryRef				request,
	CFMutableDictionaryRef      response,
    aslclient                   asl,
    aslmsg                      aslMsg
)
    // Implements the kKCHelperGetVersionCommand.  Returns the version number of 
    // the helper tool.
{	
	OSStatus					retval = noErr;
	CFNumberRef					value;
    static const int kCurrentVersion = 17;          // something very easy to spot

	// Pre-conditions

	assert(auth != NULL);
    // userData may be NULL
	assert(request != NULL);
	assert(response != NULL);
    // asl may be NULL
    // aslMsg may be NULL

    // Add them to the response.

	value = CFNumberCreate(NULL, kCFNumberIntType, &kCurrentVersion);
	if (value == NULL) {
		retval = coreFoundationUnknownErr;
    } else {
        CFDictionaryAddValue(response, CFSTR(kKCHelperGetVersionResponse), value);
	}

	if (value != NULL) {
		CFRelease(value);
	}

	return retval;
}


static OSStatus DoStartList(
	AuthorizationRef			auth,
    const void *                userData,
	CFDictionaryRef				request,
	CFMutableDictionaryRef      response,
    aslclient                   asl,
    aslmsg                      aslMsg
)
{	
	OSStatus retval = noErr;
    int      err = 0;
    int      junk = 0;
	
	// Pre-conditions
	
	assert(auth != NULL);
    // userData may be NULL
	assert(request != NULL);
	assert(response != NULL);
    // asl may be NULL
    // aslMsg may be NULL


	/*
	obtain the frontend's process id, that the KCList process 
	should belong to.
	*/
	int actual_pid = -1;
	int err_actual_pid = 0x1000;
	if(!err) do {
		CFNumberRef num = (CFNumberRef)CFDictionaryGetValue(
			request, CFSTR(kKCHelperFrontendProcessId));
		if(num == NULL) {
			err_actual_pid |= 0x0001;
			break;
		}

		// ensure that it's a CFNumber
		if(CFGetTypeID(num) != CFNumberGetTypeID() ) {
			// not a string
			err_actual_pid |= 0x0002;
			break;
		}

		// ensure we get integers
		if(CFNumberIsFloatType(num)) {
			err_actual_pid |= 0x0004;
			break;
		}

		// obtain the value
		Boolean ok = CFNumberGetValue(num, kCFNumberIntType, &actual_pid);
		if(!ok) {
			err_actual_pid |= 0x0008;
			break;
		}
		
		// we have successfully obtained a valid integer
		err_actual_pid = 0;
		
	} while(0);
	
	if(err_actual_pid) {
		err = -1;
		junk = asl_log(asl, aslMsg, ASL_LEVEL_DEBUG, "failed to obtain frontend_pid. error-code=0x%08x", err_actual_pid);
	    assert(junk == 0);
	} else {
		junk = asl_log(asl, aslMsg, ASL_LEVEL_DEBUG, "we have obtained frontend_pid=%i", actual_pid);
	    assert(junk == 0);/**/
	}


	CFStringRef connection_name = NULL;
	if(!err) {
		connection_name = (CFStringRef)CFDictionaryGetValue(request, CFSTR(kKCHelperFrontendConnectionName));

		if(connection_name == NULL) {
			// no key found
			err = -1;
		}
	}

	// ensure that it's a CFString
	if(!err) {
		if(CFGetTypeID(connection_name) != CFStringGetTypeID() ) {
			// not a string
			err = -1;
		}
	}
	
#define CONNAME_MAX 100
	char actual_connection_name[CONNAME_MAX];
	
	// convert CFString to a C string
	if(!err) {
		Boolean ok = CFStringGetCString(
			connection_name,
			actual_connection_name,
			CONNAME_MAX,
			kCFStringEncodingUTF8
		);
		
		if(!ok) {
			// conversion failed
			err = -1;
		}
	}
	
	

	
	
	CFStringRef assigned_name = NULL;
	if(!err) {
		assigned_name = (CFStringRef)CFDictionaryGetValue(request, CFSTR(kKCHelperAssignNameToListProcess));

		if(assigned_name == NULL) {
			// no key found
			err = -1;
		}
	}

	// ensure that it's a CFString
	if(!err) {
		if(CFGetTypeID(assigned_name) != CFStringGetTypeID() ) {
			// not a string
			err = -1;
		}
	}
	
#define ASSNAME_MAX 100
	char actual_assigned_name[ASSNAME_MAX];
	
	// convert CFString to a C string
	if(!err) {
		Boolean ok = CFStringGetCString(
			assigned_name,
			actual_assigned_name,
			ASSNAME_MAX,
			kCFStringEncodingUTF8
		);
		
		if(!ok) {
			// conversion failed
			err = -1;
		}
	}
	
	

	/*
	TODO: we must NOT use a path provided by the user.
	It may be used to to gain root access by a hijacker
	*/
	CFStringRef path = NULL;
	if(!err) {
		path = (CFStringRef)CFDictionaryGetValue(request, CFSTR(kKCHelperPathToListProgram));

		if(path == NULL) {
			// no key found
			err = -1;
		}
	}

	// ensure that it's a CFString
	if(!err) {
		if(CFGetTypeID(path) != CFStringGetTypeID() ) {
			// not a string
			err = -1;
		}
	}
	
	char actual_path[PATH_MAX];

	// convert CFString to a C string
	if(!err) {
		Boolean ok = CFStringGetCString(
			path,
			actual_path,
			PATH_MAX,
			kCFStringEncodingUTF8
		);
		
		if(!ok) {
			// conversion failed
			err = -1;
		}
	}

	// ensure that the path points to a file
	if(!err) {
		struct stat st;
		err = stat(actual_path, &st);
		if(!err) {
			if(!S_ISREG(st.st_mode)) {
				// not a regular file
				err = -1;
			}
		}
	}

#if 0
	/*
	start the process as root
	
	DANGER! We don't use this code stub, it has serious problems.
	we keep it around for compatibility reasons, because
	at the time of writing 24 jul 2009 the posix_spawn()
	is relative new in Mac Os X. 
	
	PROBLEM: The strings are not satitized.
	PROBLEM: system() is easy to hijack.
	*/
	if(!err) {
#define COMMAND_STR_MAX  (PATH_MAX + CONNAME_MAX + ASSNAME_MAX + 20)
		char command_str[COMMAND_STR_MAX];
		snprintf(
			command_str, 
			COMMAND_STR_MAX, 
			"%s %s %s %i &", 
			actual_path,           // is sanitized
			actual_assigned_name,  // NOT sanitized
			actual_connection_name, // NOT sanitized
	  		actual_pid
		);

		err = asl_log(asl, aslMsg, ASL_LEVEL_DEBUG, "cmd=%s", command_str);
	    assert(err == 0);

		system(command_str); // <----- DANGER!!
	}
#endif


#if 1
	/*
	start the process as root
	no need to sanitize anything, thanks to posix_spawn.
	*/
	if(!err) {
		char buffer[20];
		sprintf(buffer, "%i", actual_pid);
		
		const char* spawn_path = actual_path;
		char* const spawn_args[] = {
			"somepath", 
			actual_assigned_name,
			actual_connection_name,
			buffer,
			0
		};
		pid_t spawned_pid;
		err = posix_spawn(
			&spawned_pid, 
			spawn_path, 
			NULL, 
			NULL, 
			spawn_args, 
			NULL
		);
		if(err) {
			junk = asl_log(asl, aslMsg, ASL_LEVEL_ERR, "failed to spawn process. err=%i errno=%i", err, errno);
		    assert(junk == 0);
		} else {
			junk = asl_log(asl, aslMsg, ASL_LEVEL_DEBUG, "process spawned successfully. pid=%i", spawned_pid);
		    assert(junk == 0);
		}
	}
#endif

	return retval;
}


static OSStatus DoStopList(
	AuthorizationRef			auth,
    const void *                userData,
	CFDictionaryRef				request,
	CFMutableDictionaryRef      response,
    aslclient                   asl,
    aslmsg                      aslMsg
)
{	
	OSStatus retval = noErr;
    int      err = 0;
    int      junk = 0;
	
	// Pre-conditions
	
	assert(auth != NULL);
    // userData may be NULL
	assert(request != NULL);
	assert(response != NULL);
    // asl may be NULL
    // aslMsg may be NULL


	/*
	obtain the KCList process id, that belongs to the calling
	frontend process 
	*/
	int actual_pid = -1;
	int err_actual_pid = 0x1000;
	if(!err) do {
		CFNumberRef num = (CFNumberRef)CFDictionaryGetValue(
			request, CFSTR(kKCHelperListProcessId));
		if(num == NULL) {
			err_actual_pid |= 0x0001;
			break;
		}

		// ensure that it's a CFNumber
		if(CFGetTypeID(num) != CFNumberGetTypeID() ) {
			// not a string
			err_actual_pid |= 0x0002;
			break;
		}

		// ensure we get integers
		if(CFNumberIsFloatType(num)) {
			err_actual_pid |= 0x0004;
			break;
		}

		// obtain the value
		Boolean ok = CFNumberGetValue(num, kCFNumberIntType, &actual_pid);
		if(!ok) {
			err_actual_pid |= 0x0008;
			break;
		}
		
		// we have successfully obtained a valid integer
		err_actual_pid = 0;
		
	} while(0);
	
	if(err_actual_pid) {
		err = -1;
		junk = asl_log(asl, aslMsg, ASL_LEVEL_DEBUG, "failed to obtain kclist_pid. error-code=0x%08x", err_actual_pid);
	    assert(junk == 0);
	} else {
		junk = asl_log(asl, aslMsg, ASL_LEVEL_DEBUG, "we have obtained kclist_pid=%i", actual_pid);
	    assert(junk == 0);/**/
	}

	
	/*
	sanitize the pid
	make sure that the pid is greater than 0
	
	if pid == 0 then the signal is send to all
	processes with the same group id as the sender.
	we don't want that to happen, since we are in the
	same group as launchd. I accidentially did that
	and it instantly crashed my computer!
	
	if pid == -1 then the signal is send to all
	non privileged processes. We don't want that.
	
	if pid == +1 then the signal is send to 
    the "launchd" process which is the first one
	that is executed when the computer boots and 
	we certainly don't want to signal it.
	*/
	if(actual_pid <= 1) {
		err = -1;
		
		junk = asl_log(asl, aslMsg, ASL_LEVEL_DEBUG, "the obtained kclist_pid (%i) is dangerous, will ignore it", err_actual_pid);
	    assert(junk == 0);
	}

	/*
	TODO: sanitize the PID, by checking that the processname+path
	corresponds to the KCList program. Because other programs
	may terminate if they receive a signal from a root user.
	*/


	
	/*
	we signal the KCList process that we want it to die unless
	it's still connected with a frontend process.
	*/
	if(!err) {
		junk = asl_log(asl, aslMsg, ASL_LEVEL_DEBUG, "will send signal to kclist_pid (%i)", err_actual_pid);
	    assert(junk == 0);
	
		kill(actual_pid, SIGUSR1);

		junk = asl_log(asl, aslMsg, ASL_LEVEL_DEBUG, "did send signal to kclist_pid (%i)", err_actual_pid);
	    assert(junk == 0);
	}

	return retval;
}


static const BASCommandProc kKCHelperCommandProcs[] = {
    DoGetVersion,
    DoStartList,
    DoStopList,
    NULL
};

int main(int argc, char **argv) {
    // Go directly into BetterAuthorizationSampleLib code.
	
    // IMPORTANT
    // BASHelperToolMain doesn't clean up after itself, so once it returns 
    // we must quit.
    
	return BASHelperToolMain(kKCHelperCommandSet, kKCHelperCommandProcs);
}
