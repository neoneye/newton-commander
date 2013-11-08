/*********************************************************************
main.mm - program for launching JuxtaFile within Terminal.app

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#include <Foundation/Foundation.h>

int main(int argc, const char** argv) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    // NSLog(@"Lets start it");

	NSString* script_source = @""
	"on run argv\n"
	"  set dir_to_open to item 1 of argv\n"
/*	"  tell application \"Finder\"\n"
	"    activate\n"
	"    display dialog \"The argument is \" & dir_to_open\n"
	"  end tell\n"
*/	"  tell application \"OrthodoxFileManager\"\n"
	"    activate\n"
	"    open dir_to_open\n"
	"  end tell\n"
	"end run\n";

	// NSLog(@"script: %@", script_source);

	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* dir_to_open = [fm currentDirectoryPath];

	NSArray* task_args = [NSArray arrayWithObjects:@"-", dir_to_open, nil];

	NSTask* t = [[[NSTask alloc] init] autorelease];
	NSPipe* p = [NSPipe pipe];
	[t setLaunchPath:@"/usr/bin/osascript"];
	[t setArguments:task_args];
	[t setStandardInput:p];
	NSFileHandle* fh = [p fileHandleForWriting];
	[t launch];
	[fh writeData:[script_source dataUsingEncoding:NSUTF8StringEncoding
	allowLossyConversion:YES]];
	[fh closeFile];
	[t waitUntilExit];

	// NSLog(@"done");
	
    [pool drain];
    return 0;
}
