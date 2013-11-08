/*********************************************************************
re_protocol.h - communication between Report.app and Main.app

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#ifndef __OPCODERS_ORTHODOXFILEMANAGER_REPORT_PROTOCOL_H__
#define __OPCODERS_ORTHODOXFILEMANAGER_REPORT_PROTOCOL_H__

#include <Cocoa/Cocoa.h>


@protocol ReportChildProtocol

-(int)childPingSync:(int)value;

-(oneway void)childRequestPath:(in bycopy NSString*)path;

@end


@protocol ReportParentProtocol

-(oneway void)parentWeAreRunning:(in bycopy NSString*)name;

-(oneway void)parentWeHaveData:(in bycopy NSData*)data forPath:(in bycopy NSString*)path;

@end


#endif // __OPCODERS_ORTHODOXFILEMANAGER_REPORT_PROTOCOL_H__