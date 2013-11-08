/*********************************************************************
CopyRsrcTests.m - can we copy resource fork data correct

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#import "Tester.h"
#import <SenTestingKit/SenTestingKit.h>

@interface CopyRsrcTests : SenTestCase {
	Tester* t;
}
@end

@implementation CopyRsrcTests

-(void)setUp {
	t = [[Tester tester] retain];
}

-(void)tearDown {
	[t release];
}

-(void)test000CopyEmptyFileWithRsrc {
	NSString* name = @"test.txt";
	[t makeFile:name data:[NSData data]];
	[t setRsrcData:[t randomDataOfSize:4567] file:name];
	[t copyFile:name];
	STAssertTrue([t compareContentFile:name], @"content should be identical");
	STAssertTrue([t compareRsrcForFile:name], @"resource-fork should be identical");
}

-(void)test001CompareDifferentRsrc {
	NSString* name = @"test.txt";
	[t makeFile:name data:[NSData data]];
	[t copyFile:name];
	[t setRsrcData:[t randomDataOfSize:4567] file:name];
	STAssertTrue([t compareContentFile:name], @"content should be identical");
	STAssertFalse([t compareRsrcForFile:name], @"resource-fork should be different");
}

#if 0
// yes it's possible to create huge resource forks!
-(void)test002CopyHugeRsrc {
	NSString* name = @"test.txt";
	[t makeFile:name data:[NSData data]];
	[t setRsrcData:[t randomDataOfSize:1024*1024*64] file:name];
	// [t copyFile:name toPath:@"/tmp/huge.txt"];
	[t copyFile:name];
	STAssertTrue([t compareContentFile:name], @"content should be identical");
	STAssertTrue([t compareRsrcForFile:name], @"resource-fork should be identical");
}
#endif

@end