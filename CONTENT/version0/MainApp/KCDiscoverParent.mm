/*********************************************************************
KCDiscoverParent.mm - acts as peer with the KCList process

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>

IDEA: since we transfer data as NSData, we should monitor how
many bytes that are transfered between frontend/backend.

*********************************************************************/
#include "KCDiscoverParent.h"

@implementation KCDiscoverParent

-(id)init {
	self = [super init];
    if(self) {
		m_delegate = nil;
    }
    return self;
}

-(void)setDelegate:(id)delegate { m_delegate = delegate; }
-(id)delegate { return m_delegate; }

-(int)parentPingSync:(int)value {
	NSLog(@"KCDiscoverParent got pinged");
	return value + 1;
}

-(oneway void)parentWeAreRunning:(in bycopy NSString*)name 
	processId:(in bycopy NSNumber*)pid
{
	if([m_delegate respondsToSelector:@selector(parentWeAreRunning:processId:)]) {
		[m_delegate parentWeAreRunning:name processId:pid];
	}
}

-(oneway void)parentWeHaveName:(in bycopy NSData*)data transactionId:(int)tid {
	// NSLog(@"%s received %i bytes", _cmd, (int)[data length]);
	if([m_delegate respondsToSelector:
		@selector(parentWeHaveName:transactionId:)]) {
		[m_delegate parentWeHaveName:data transactionId:tid];
	}
}

-(oneway void)parentWeHaveType:(in bycopy NSData*)data transactionId:(int)tid {
	// NSLog(@"%s received %i bytes", _cmd, (int)[data length]);
	if([m_delegate respondsToSelector:
		@selector(parentWeHaveType:transactionId:)]) {
		[m_delegate parentWeHaveType:data transactionId:tid];
	}
}

-(oneway void)parentWeHaveStat:(in bycopy NSData*)data transactionId:(int)tid {
	// NSLog(@"%s received %i bytes", _cmd, (int)[data length]);
	if([m_delegate respondsToSelector:
		@selector(parentWeHaveStat:transactionId:)]) {
		[m_delegate parentWeHaveStat:data transactionId:tid];
	}
}

-(oneway void)parentWeHaveAlias:(in bycopy NSData*)data transactionId:(int)tid {
	// NSLog(@"%s received %i bytes", _cmd, (int)[data length]);
	if([m_delegate respondsToSelector:
		@selector(parentWeHaveAlias:transactionId:)]) {
		[m_delegate parentWeHaveAlias:data transactionId:tid];
	}
}

-(oneway void)parentCompletedTransactionId:(int)tid {
	if([m_delegate respondsToSelector:@selector(parentCompletedTransactionId:)]) {
		[m_delegate parentCompletedTransactionId:tid];
	}
}

@end
