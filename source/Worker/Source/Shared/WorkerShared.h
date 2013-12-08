/*********************************************************************
WorkerShared.h - protocols for communication between parent/child process

Copyright (c) 2010 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/


@protocol WorkerChildCallbackProtocol <NSObject>

-(int)handshakeAcknowledge:(int)value;

-(oneway void)requestData:(in bycopy NSData*)data;

@end


@protocol WorkerParentCallbackProtocol <NSObject>

// TODO: investigate wether "name" can be removed
-(oneway void)weAreRunning:(in bycopy NSString*)name childPID:(int)pid childUID:(int)uid;

-(oneway void)responseData:(in bycopy NSData*)data;

@end
