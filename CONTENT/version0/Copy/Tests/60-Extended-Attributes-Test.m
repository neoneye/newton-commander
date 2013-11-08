/*********************************************************************
CopyXAttrTests.m - can we copy a extended attributes correct

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#import "Tester.h"
#import <SenTestingKit/SenTestingKit.h>

@interface CopyXAttrTests : SenTestCase {
	Tester* t;
}
@end

@implementation CopyXAttrTests

-(void)setUp {
	t = [[Tester tester] retain];
}

-(void)tearDown {
	[t release];
}

-(void)test100CopyEmptyFileWithAttributes {
	NSString* name = @"test.txt";
	[t makeFile:name data:[NSData data]];

	[t setXattr:@"myattrname1"
	      value:[@"myattrvalue1" dataUsingEncoding:NSUTF8StringEncoding]
		   file:name];

	[t setXattr:@"myattrname2"
	      value:[@"myattrvalue2" dataUsingEncoding:NSUTF8StringEncoding]
		   file:name];

	[t setXattr:@"myattrname3"
	      value:[@"myattrvalue3" dataUsingEncoding:NSUTF8StringEncoding]
		   file:name];

	[t setXattr:@"myattrname4"
	      value:[t randomDataOfSize:1000]
		   file:name];

	[t copyFile:name];
	STAssertTrue([t compareContentFile:name], @"content should be identical");
	STAssertTrue([t compareXAttrFile:name], @"xattr should be identical");
}

-(void)test101CompareAttributesFailure {
	NSString* name = @"test.txt";
	[t makeFile:name data:[NSData data]];

	[t setXattr:@"myattrname1"
	      value:[@"myattrvalue1" dataUsingEncoding:NSUTF8StringEncoding]
		   file:name];

	[t copyFile:name];

	[t setXattr:@"myattrname2"
	      value:[@"myattrvalue2" dataUsingEncoding:NSUTF8StringEncoding]
		   file:name];

	STAssertTrue([t compareContentFile:name], @"content should be identical");
	STAssertFalse([t compareXAttrFile:name], @"xattr should NOT be identical");
}

@end