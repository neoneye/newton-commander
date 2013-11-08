/*********************************************************************
CopyFlagTests.m - can we copy the stat64 flags correct

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#import "Tester.h"
#import <SenTestingKit/SenTestingKit.h>

@interface CopyFlagTests : SenTestCase {
	Tester* t;
}
@end

@implementation CopyFlagTests

-(void)setUp {
	t = [[Tester tester] retain];
}

-(void)tearDown {
	[t release];
}

-(void)test201CopyEmptyFileWithNodumpFlag {
	NSString* name = @"test.txt";
	[t makeFile:name data:[NSData data]];
	[t setFlags:0x00000001 file:name];
	[t copyFile:name];    
	STAssertTrue([t compareContentFile:name], @"content should be identical");
	STAssertTrue([t compareFlagsFile:name], @"flags should be identical");
}

/*
// if a regular user flags his file with the UCHG flag
// then the file must be removed by the super user.. with "sudo rm"!
// so we don't run this test, because it's so annoying to 
// clean up with sudo afterwards.
-(void)test202CopyEmptyFileWithImmutableFlag {
	NSString* name = @"test.txt";
	[t makeFile:name data:[NSData data]];
	[t setFlags:0x00000002 file:name];
	[t copyFile:name];    
	STAssertTrue([t compareContentFile:name], @"content should be identical");
	STAssertTrue([t compareFlagsFile:name], @"flags should be identical");
}/**/

/*
// if a regular user flags his file with the UAPPND flag
// then the file must be removed by the super user.. with "sudo rm"!
// so we don't run this test, because it's so annoying to 
// clean up with sudo afterwards.
-(void)test203CopyEmptyFileWithAppendFlag {
	NSString* name = @"test.txt";
	[t makeFile:name data:[NSData data]];
	[t setFlags:0x00000004 file:name];
	[t copyFile:name];    
	STAssertTrue([t compareContentFile:name], @"content should be identical");
	STAssertTrue([t compareFlagsFile:name], @"flags should be identical");
}/**/

-(void)test204CopyEmptyFileWithOpaqueFlag {
	NSString* name = @"test.txt";
	[t makeFile:name data:[NSData data]];
	[t setFlags:0x00000008 file:name];
	[t copyFile:name];    
	STAssertTrue([t compareContentFile:name], @"content should be identical");
	STAssertTrue([t compareFlagsFile:name], @"flags should be identical");
}

-(void)test205CopyEmptyFileWithNounlinkFlag {
	NSString* name = @"test.txt";
	[t makeFile:name data:[NSData data]];
	[t setFlags:0x00000010 file:name];
	[t copyFile:name];    
	STAssertTrue([t compareContentFile:name], @"content should be identical");
	STAssertTrue([t compareFlagsFile:name], @"flags should be identical");
}

-(void)test206CopyEmptyFileWithUnknownFlag {
	NSString* name = @"test.txt";
	[t makeFile:name data:[NSData data]];
	[t setFlags:0x00000020 file:name];
	[t copyFile:name];    
	STAssertTrue([t compareContentFile:name], @"content should be identical");
	STAssertTrue([t compareFlagsFile:name], @"flags should be identical");
}

-(void)test207CopyEmptyFileWithUnknownFlag {
	NSString* name = @"test.txt";
	[t makeFile:name data:[NSData data]];
	[t setFlags:0x00000040 file:name];
	[t copyFile:name];    
	STAssertTrue([t compareContentFile:name], @"content should be identical");
	STAssertTrue([t compareFlagsFile:name], @"flags should be identical");
}

-(void)test208CopyEmptyFileWithUnknownFlag {
	NSString* name = @"test.txt";
	[t makeFile:name data:[NSData data]];
	[t setFlags:0x00000080 file:name];
	[t copyFile:name];    
	STAssertTrue([t compareContentFile:name], @"content should be identical");
	STAssertTrue([t compareFlagsFile:name], @"flags should be identical");
}

-(void)test209CopyEmptyFileWithUnknownFlag {
	NSString* name = @"test.txt";
	[t makeFile:name data:[NSData data]];
	[t setFlags:0x00000100 file:name];
	[t copyFile:name];    
	STAssertTrue([t compareContentFile:name], @"content should be identical");
	STAssertTrue([t compareFlagsFile:name], @"flags should be identical");
}

-(void)test210CopyEmptyFileWithUnknownFlag {
	NSString* name = @"test.txt";
	[t makeFile:name data:[NSData data]];
	[t setFlags:0x00000200 file:name];
	[t copyFile:name];    
	STAssertTrue([t compareContentFile:name], @"content should be identical");
	STAssertTrue([t compareFlagsFile:name], @"flags should be identical");
}

-(void)test211CopyEmptyFileWithUnknownFlag {
	NSString* name = @"test.txt";
	[t makeFile:name data:[NSData data]];
	[t setFlags:0x00000400 file:name];
	[t copyFile:name];    
	STAssertTrue([t compareContentFile:name], @"content should be identical");
	STAssertTrue([t compareFlagsFile:name], @"flags should be identical");
}

-(void)test212CopyEmptyFileWithUnknownFlag {
	NSString* name = @"test.txt";
	[t makeFile:name data:[NSData data]];
	[t setFlags:0x00000800 file:name];
	[t copyFile:name];    
	STAssertTrue([t compareContentFile:name], @"content should be identical");
	STAssertTrue([t compareFlagsFile:name], @"flags should be identical");
}

-(void)test213CopyEmptyFileWithUnknownFlag {
	NSString* name = @"test.txt";
	[t makeFile:name data:[NSData data]];
	[t setFlags:0x00001000 file:name];
	[t copyFile:name];    
	STAssertTrue([t compareContentFile:name], @"content should be identical");
	STAssertTrue([t compareFlagsFile:name], @"flags should be identical");
}

-(void)test214CopyEmptyFileWithUnknownFlag {
	NSString* name = @"test.txt";
	[t makeFile:name data:[NSData data]];
	[t setFlags:0x00002000 file:name];
	[t copyFile:name];    
	STAssertTrue([t compareContentFile:name], @"content should be identical");
	STAssertTrue([t compareFlagsFile:name], @"flags should be identical");
}

-(void)test215CopyEmptyFileWithUnknownFlag {
	NSString* name = @"test.txt";
	[t makeFile:name data:[NSData data]];
	[t setFlags:0x00004000 file:name];
	[t copyFile:name];    
	STAssertTrue([t compareContentFile:name], @"content should be identical");
	STAssertTrue([t compareFlagsFile:name], @"flags should be identical");
}

-(void)test216CopyEmptyFileWithHiddenFlag {
	NSString* name = @"test.txt";
	[t makeFile:name data:[NSData data]];
	[t setFlags:0x00008000 file:name];
	[t copyFile:name];
	STAssertTrue([t compareContentFile:name], @"content should be identical");
	STAssertTrue([t compareFlagsFile:name], @"flags should be identical");
}

-(void)test250CopyEmptyFileWithFlagFailure {
	NSString* name = @"test.txt";
	[t makeFile:name data:[NSData data]];
	[t setFlags:0x0000ff00 file:name];
	[t copyFile:name];
	[t setFlags:0x00008000 file:name];
	STAssertTrue([t compareContentFile:name], @"content should be identical");
	STAssertFalse([t compareFlagsFile:name], @"flags should NOT be identical");
}

@end