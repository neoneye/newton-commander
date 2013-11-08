/*********************************************************************
cp_protocol.h - communication between Copy.app and Main.app

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#ifndef __OPCODERS_ORTHODOXFILEMANAGER_COPY_PROTOCOL_H__
#define __OPCODERS_ORTHODOXFILEMANAGER_COPY_PROTOCOL_H__

#include <Cocoa/Cocoa.h>


@protocol CopyChildProtocol

-(int)childPingSync:(int)value;


/*
USAGE:

NSString* dest_path = @"/tmp/dest_dir";
NSString* src_path = @"/tmp/src_dir";
NSArray* src_names = [NSArray arrayWithObjects:
	@"file1", @"file2", @"file3", nil];
NSDictionary* arguments = [NSDictionary dictionaryWithObjectsAndKeys:
    dest_path, @"DestPath",
    src_names, @"SrcNames", 
    src_path,  @"SrcPath", 
	nil
];
[m_child childRequest:arguments];
*/
-(oneway void)childRequest:(in bycopy NSDictionary*)arguments;

@end


@protocol CopyParentProtocol

-(oneway void)parentWeAreRunning:(in bycopy NSString*)name;


-(oneway void)parentResponse:(in bycopy NSDictionary*)response;

-(oneway void)parentError:(in bycopy NSDictionary*)errorinfo;

@end


#endif // __OPCODERS_ORTHODOXFILEMANAGER_COPY_PROTOCOL_H__