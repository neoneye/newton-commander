//
//  ToolTest.m
//  project
//
//  Created by Simon Strandgaard on 23/04/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import "ToolTest.h"
#import "Tool.h"
#import "OnigRegexp.h"
#import "ExpectResult.h"
#import "NSFileHandle+Expect.h"


@implementation ToolTest

-(void)test_regex {
	OnigRegexp* e = [OnigRegexp compile:@"x.z"];
	OnigResult* r = [e search:@"abcxyzdef"];
	
	STAssertNotNil(r, nil);
	STAssertEqualObjects([r body], @"xyz", nil);
	
}

-(void)xtest_expect {
	NSArray* arguments = [NSArray arrayWithObject:@"ftp.ruby-lang.org"];

	NSTask* task = [[[NSTask alloc] init] autorelease];
	[task setLaunchPath:@"/usr/bin/ftp"];

    NSPipe* readPipe = [NSPipe pipe];
    NSPipe* writePipe = [NSPipe pipe];

    [task setStandardInput: writePipe];
    [task setStandardOutput: readPipe];
    [task setArguments:arguments];

    [task launch];

	NSFileHandle* readHandle = [readPipe fileHandleForReading];
	NSFileHandle* writeHandle = [writePipe fileHandleForWriting];

	{
		NSString* pattern = @"^Name.*: ";
		[readHandle expect:pattern timeout:5 debug:YES];
		[writeHandle writeAsciiString:@"ftp\n"];
	}

	{
		NSString* pattern = @"word:";
		[readHandle expect:pattern timeout:5 debug:YES];
		[writeHandle writeAsciiString:@"guest@\n"];
	}

	{
		NSString* pattern = @"> ";
		[readHandle expect:pattern timeout:5 debug:YES];
		[writeHandle writeAsciiString:@"cd pub/ruby\n"];
	}

	{
		NSString* pattern = @"> ";
		[readHandle expect:pattern timeout:5 debug:YES];
		[writeHandle writeAsciiString:@"dir\n"];
	}

	{
		NSString* pattern = @"> ";
		ExpectResult* er = [readHandle expect:pattern timeout:5 debug:YES];

		NSLog(@"%s versions: %@", _cmd, er.bufferString);

		[writeHandle writeAsciiString:@"quit\n"];
	}
}

-(void)test_version {
	Tool* t = [[[Tool alloc] init] autorelease];

	[t start];
	
	
	{
		//NSLog(@"%s before expect", _cmd);
		
		ExpectResult* er = [t expect:@"PROMPT>"];
		STAssertNotNil(er, nil);
		NSString* s = [er bufferString];
		
		//NSLog(@"%s after expect", _cmd);
		//NSLog(@"%s %@", _cmd, s);
		
		OnigRegexp* e = [OnigRegexp compile:@"version (.+)"];
		OnigResult* r = [e search:s];
		STAssertNotNil(r, nil);
		STAssertEqualObjects([r body], @"version 0.1", nil);
	}
	
	
	[t stop];
}

-(void)test_ping {
	Tool* t = [[[Tool alloc] init] autorelease];

	[t start];
	
	
	{
		//NSLog(@"%s before expect", _cmd);
		
		ExpectResult* er = [t expect:@"PROMPT>"];
		NSString* s = [er bufferString];
		
		//NSLog(@"%s after expect", _cmd);
		//NSLog(@"%s %@", _cmd, s);
		
		STAssertNotNil(s, nil);
	}

	{
		[t write:@"ping\n"];
	}

	{
		//NSLog(@"%s before expect", _cmd);
		
		ExpectResult* er = [t expect:@"PROMPT>"];
		STAssertNotNil(er, nil);
		NSString* s = [er bufferString];
		
		//NSLog(@"%s after expect", _cmd);
		//NSLog(@"%s %@", _cmd, s);

		OnigRegexp* e = [OnigRegexp compile:@"it works"];
		OnigResult* r = [e search:s];
		STAssertNotNil(r, nil);
		STAssertEqualObjects([r body], @"it works", nil);
	}
	
	
	[t stop];
}

@end
