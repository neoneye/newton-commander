/*********************************************************************
KCDiscover.h - encapsulates the background DiscoverApp in a thread

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#ifndef __OPCODERS_KEYBOARDCOMMANDER_DISCOVERAPP_WRAPPER_H__
#define __OPCODERS_KEYBOARDCOMMANDER_DISCOVERAPP_WRAPPER_H__
                        
enum {
	DISCOVER_TIMESTAMPS_REQUEST = 0,
	DISCOVER_TIMESTAMPS_INITIATED,
	DISCOVER_TIMESTAMPS_HAS_NAME,
	DISCOVER_TIMESTAMPS_HAS_TYPE,
	DISCOVER_TIMESTAMPS_HAS_STAT,
	DISCOVER_TIMESTAMPS_HAS_ALIAS,
	DISCOVER_TIMESTAMPS_COMPLETED,
	DISCOVER_NUMBER_OF_TIMESTAMPS,
};

@class KCDiscoverThread;

@interface KCDiscover : NSObject {
	NSString* m_name;
	NSString* m_path_to_child_executable;
	id m_delegate;

	AuthorizationRef m_auth;

	
	NSThread* m_thread;
	
	/*
	all method calls for m_discover_thread must be made with
	performSelector:onThread:withObject:waitUntilDone:modes:
	*/
	KCDiscoverThread* m_discover_thread;
	
	double m_timestamps[DISCOVER_NUMBER_OF_TIMESTAMPS];
}
-(id)initWithName:(NSString*)name path:(NSString*)path auth:(AuthorizationRef)auth;

-(void)setDelegate:(id)delegate;                    
-(id)delegate;

-(void)start;

-(void)requestPath:(NSString*)path transactionId:(int)tid;

@end

@interface NSObject (KCDiscoverDelegate)
-(void)discoverDidLaunch;
-(void)discoverIsNowProcessingTheRequest;

// a NSData object containing a string-array
-(void)discoverHasName:(NSData*)data transactionId:(int)tid;

// a byte sequence of unsigned int's
-(void)discoverHasType:(NSData*)data transactionId:(int)tid;

// a byte sequence with lots of "struct stat64"
-(void)discoverHasStat:(NSData*)data transactionId:(int)tid;

// a byte sequence of unsigned int's
-(void)discoverHasAlias:(NSData*)data transactionId:(int)tid;
@end


#endif // __OPCODERS_KEYBOARDCOMMANDER_DISCOVERAPP_WRAPPER_H__