/*********************************************************************
KCDiscoverParent.h - acts as peer with the KCList process
Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>

Any good reason to have this extra level of redirection?
I really can't remember.

*********************************************************************/
#ifndef __OPCODERS_KEYBOARDCOMMANDER_DISCOVER_PARENT_H__
#define __OPCODERS_KEYBOARDCOMMANDER_DISCOVER_PARENT_H__

#include "../di_protocol.h"

@interface KCDiscoverParent : NSObject <DiscoverParentProtocol> {
	id m_delegate;
}
-(void)setDelegate:(id)delegate;
-(id)delegate;

@end

@interface NSObject (KCDiscoverParentDelegate)
-(int)parentPingSync:(int)value;
-(void)parentWeAreRunning:(NSString*)name processId:(NSNumber*)pid;

// a NSData object containing a string-array
-(void)parentWeHaveName:(NSData*)data transactionId:(int)tid;

// a byte sequence of unsigned int's
-(void)parentWeHaveType:(NSData*)data transactionId:(int)tid;

// a byte sequence with lots of "struct stat64"
-(void)parentWeHaveStat:(NSData*)data transactionId:(int)tid;

// a byte sequence of unsigned int's
-(void)parentWeHaveAlias:(NSData*)data transactionId:(int)tid;

-(void)parentCompletedTransactionId:(int)tid;
@end


#endif // __OPCODERS_KEYBOARDCOMMANDER_DISCOVER_PARENT_H__