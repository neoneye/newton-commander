/*********************************************************************
KCHelperCommon.h - Definitions that tell BAS about your commands
BAS == BetterAuthorizationSample

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#include "KCHelperCommon.h"

/*
	I originally generated the "SampleAuthorizationPrompts.strings" file by running 
	the following command in Terminal.  genstrings doesn't notice that the 
	CFCopyLocalizedStringFromTableInBundle is commented out, which is good for 
	my purposes.
	
    $ genstrings SampleCommon.c -o en.lproj

    CFCopyLocalizedStringFromTableInBundle(CFSTR("GetUIDsPrompt"),          "SampleAuthorizationPrompts", b, "prompt included in authorization dialog for the GetUIDs command")
    CFCopyLocalizedStringFromTableInBundle(CFSTR("LowNumberedPortsPrompt"), "SampleAuthorizationPrompts", b, "prompt included in authorization dialog for the LowNumberedPorts command")
*/

/*
    IMPORTANT
    ---------
    This array must be exactly parallel to the kKCHelperCommandProcs array 
    in "KCHelperTool.c".
*/

const BASCommandSpec kKCHelperCommandSet[] = {
    {	kKCHelperGetVersionCommand,             // commandName
        NULL,                                   // rightName           -- never authorize
        NULL,                                   // rightDefaultRule	   -- not applicable if rightName is NULL
        NULL,									// rightDescriptionKey -- not applicable if rightName is NULL
        NULL                                    // userData
	},

    {	kKCHelperStartListCommand,         // commandName
        kKCHelperStartListRightName,       // rightName
        "allow",                                // rightDefaultRule    -- by default, anyone can acquire this right
        "StartListPrompt",	 				// rightDescriptionKey -- key for custom prompt in "KCHelperAuthorizationPrompts.strings
        NULL                                    // userData
	},

    {	kKCHelperStopListCommand,         // commandName
        kKCHelperStopListRightName,       // rightName
        "allow",                                // rightDefaultRule    -- by default, anyone can acquire this right
        "StopListPrompt",	 				// rightDescriptionKey -- key for custom prompt in "KCHelperAuthorizationPrompts.strings
        NULL                                    // userData
	},

    {	NULL,                                   // the array is null terminated
        NULL, 
        NULL, 
        NULL,
        NULL
	}
};

