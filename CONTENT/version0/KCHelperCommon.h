/*********************************************************************
KCHelperCommon.h - Definitions that tell BAS about your commands
BAS == BetterAuthorizationSample

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#ifndef __OPCODERS_KEYBOARDCOMMANDER_KCHELPERCOMMON_H__
#define __OPCODERS_KEYBOARDCOMMANDER_KCHELPERCOMMON_H__

#include "BetterAuthorizationSampleLib.h"

/////////////////////////////////////////////////////////////////

// Commands supported by the KCHelper tool


// "GetVersion" gets the version of the helper tool.  This never requires authorization.

#define kKCHelperGetVersionCommand        "GetVersion"

    // authorization right name (none)
    
    // request keys (none)
    
    // response keys
    
	#define kKCHelperGetVersionResponse			"Version"                   // CFNumber


// "StartList" starts the KCList program under root permissions.

#define kKCHelperStartListCommand           "StartList"

    // authorization right name
    
    #define	kKCHelperStartListRightName					"com.opcoders.kc.StartList"

    // request keys

    #define kKCHelperFrontendProcessId	"FrontendProcessId" // CFNumber (required)

    #define kKCHelperFrontendConnectionName	"FrontendConnectionName" // CFString (required)

    #define kKCHelperAssignNameToListProcess	"AssignNameToListProcess" // CFString (required)

    #define kKCHelperPathToListProgram	"PathToListProgram" // CFString (required)
    
    // response keys (none)
    



// "StopList" attempts to stop the KCList program that runs under root permissions. Only if it's orphanted it will agree to die.

#define kKCHelperStopListCommand           "StopList"

    // authorization right name
    #define	kKCHelperStopListRightName					"com.opcoders.kc.StopList"

    // request keys
    #define kKCHelperListProcessId	"ListProcessId" // CFNumber (required)

    // response keys (none)




// The kKCHelperCommandSet is used by both the app and the tool to communicate the set of 
// supported commands to the BetterAuthorizationSampleLib module.

extern const BASCommandSpec kKCHelperCommandSet[];

#endif // __OPCODERS_KEYBOARDCOMMANDER_KCHELPERCOMMON_H__
