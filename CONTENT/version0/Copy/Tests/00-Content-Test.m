/*********************************************************************
CopyFileTests.m - can we copy a single file correct

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#import "Tester.h"
#import <SenTestingKit/SenTestingKit.h>

@interface ContentTest : SenTestCase {
	Tester* t;
}
@end

@implementation ContentTest

-(void)setUp {
	t = [[Tester tester] retain];
}

-(void)tearDown {
	[t release];
}

-(void)test000CopyEmptyFile {
	NSString* name = @"test.txt";
	[t makeFile:name data:[NSData data]];
	[t copyFile:name];
	STAssertTrue([t compareContentFile:name], @"content should be identical");
}

-(void)test001CopySmallFile {
	NSString* name = @"test.txt"; 
	[t makeFile:name data:[t randomDataOfSize:100]];
	[t copyFile:name];
	STAssertTrue([t compareContentFile:name], @"content should be identical");
}

-(void)test002CopyBigFile {
	NSString* name = @"test.txt"; 
	[t makeFile:name data:[t randomDataOfSize:1000*1000]];
	[t copyFile:name];
	STAssertTrue([t compareContentFile:name], @"content should be identical");
}

@end