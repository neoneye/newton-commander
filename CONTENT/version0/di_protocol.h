/*********************************************************************
di_protocol.h - communication between Discover.app and Main.app

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#ifndef __OPCODERS_ORTHODOXFILEMANAGER_DISCOVER_PROTOCOL_H__
#define __OPCODERS_ORTHODOXFILEMANAGER_DISCOVER_PROTOCOL_H__

#include <Foundation/Foundation.h>


enum {
	kListToolIsAliasUnknown = 0,
	kListToolIsAliasNoDeterminedByStat64,
	kListToolIsAliasNoDeterminedByGDE,
	kListToolIsAliasErrorBadFilename,
	kListToolIsAliasErrorBadFSRef,
	kListToolIsAliasErrorResolvingAlias,
	
	/*
	FSResolveAliasFileWithMountFlags doesn't like the .HFS dirs
	and responds with a file-not-found (-43 = fnfErr) error.
	We just ignore it.
	*/
	kListToolIsAliasErrorFileNotFound,
	
	/*
	FSResolveAliasFileWithMountFlags has completed successfully.
	It turned out that the file was not an alias after all.
	*/
	kListToolIsAliasNo,
	
	/*
	FSResolveAliasFileWithMountFlags has completed successfully.
	The alias links to a file.
	*/
	kListToolIsAliasYesFile,

	/*
	FSResolveAliasFileWithMountFlags has completed successfully.
	The alias links to a dir.
	*/
	kListToolIsAliasYesFolder
};


@protocol DiscoverChildProtocol

-(int)childPingSync:(int)value;
-(oneway void)childForceCrash;

-(oneway void)childRequestPath:(in bycopy NSString*)path transactionId:(int)tid;

@end


@protocol DiscoverParentProtocol

-(int)parentPingSync:(int)value;


-(oneway void)parentWeAreRunning:(in bycopy NSString*)name processId:(in bycopy NSNumber*)pid;


/*
phase 1.  a NSData object is delivered to the GUI process.
It contains an NSArray of filename strings, this seems to be the 
fastest attribute to obtain from Apple's filesystem without
getting too long timeouts.
*/
-(oneway void)parentWeHaveName:(in bycopy NSData*)data transactionId:(int)tid;

/*
phase 2.  a NSData object contains a vector of unsigned int's.
This is fairly fast to obtain because we use GetDirectoryEntries.
However it doesn't resolve links, so we don't know if it points
to a file or a dir. Nor does it resolve aliases.

the length is  
[m_filenames count] * sizeof(unsigned int);
*/
-(oneway void)parentWeHaveType:(in bycopy NSData*)data transactionId:(int)tid;

/*
phase 3.  stat64 data are delivered as a byte sequence 
with lots of "struct stat64".

the length is  
[m_filenames count] * sizeof(struct stat64);

This is slow to obtain. In the "/net" dir it does a 10 second timeout!
*/
-(oneway void)parentWeHaveStat:(in bycopy NSData*)data transactionId:(int)tid;

/*
phase 4.  isAlias data is a vector of unsigned int's

the length is
[m_filenames count] * sizeof(unsigned int);

This is slow to obtain. In the "/net" dir it does a 10 second timeout!
*/
-(oneway void)parentWeHaveAlias:(in bycopy NSData*)data transactionId:(int)tid;

/*
phase 5.  called when we are done processing data
*/
// -(oneway void)parentWeAreDone;
-(oneway void)parentCompletedTransactionId:(int)tid;

@end


#endif // __OPCODERS_ORTHODOXFILEMANAGER_DISCOVER_PROTOCOL_H__