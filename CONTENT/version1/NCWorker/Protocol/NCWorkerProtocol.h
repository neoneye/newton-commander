/*********************************************************************
NCWorkerProtocol.h - communication between NewtonCommander.app and NCWorker.app

Copyright (c) 2010 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/


@protocol NCWorkerChildCallbackProtocol <NSObject>

-(int)handshakeAcknowledge:(int)value;

-(oneway void)requestData:(in bycopy NSData*)data;

@end


@protocol NCWorkerParentCallbackProtocol <NSObject>


-(oneway void)weAreRunning:(in bycopy NSString*)name;


-(oneway void)responseData:(in bycopy NSData*)data;

@end
