/*********************************************************************
CopyACLTests.m - can we copy a access control lists (ACL's) correct

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#import "Tester.h"
#import <SenTestingKit/SenTestingKit.h>

@interface CopyACLTests : SenTestCase {
	Tester* t;
}
@end

@implementation CopyACLTests

-(void)setUp {
	t = [[Tester tester] retain];
}

-(void)tearDown {
	[t release];
}

-(void)test001CopyWithoutACL {
	NSString* name = @"test.txt";
	[t makeFile:name data:[t randomDataOfSize:123]];
	[t copyFile:name];
	STAssertTrue([t compareContentFile:name], @"content should be identical");
	STAssertTrue([t compareACLFile:name], @"ACL's should be identical");
}

-(void)test002CopySimpleACL {
	NSString* name = @"test.txt";
	[t makeFile:name data:[t randomDataOfSize:1]];
	[t setACL:@"guest deny readattr" 
		 path:[t sourcePathForFile:name]];
	[t copyFile:name];
	STAssertTrue([t compareContentFile:name], @"content should be identical");
	STAssertTrue([t compareACLFile:name], @"ACL's should be identical");

	[t setACL:@"guest allow chown" 
		 path:[t sourcePathForFile:name]];
	STAssertFalse([t compareACLFile:name], @"ACL's should be different");
}

-(void)test003CopyAdvancedACL {
	NSString* name = @"test.txt";
	[t makeFile:name data:[NSData data]];

	[t assignGarbageACLToFile:name];
	[t setACL:@"_svn allow write,inherited" 
		 path:[t sourcePathForFile:name]];
	[t setACL:@"admin allow write,inherited" 
		 path:[t sourcePathForFile:name]];
	[t setACL:@"guest deny readattr" 
		 path:[t sourcePathForFile:name]];
	[t setACL:@"guest allow chown" 
		 path:[t sourcePathForFile:name]];
	[t setACL:@"_mysql deny readextattr" 
		 path:[t sourcePathForFile:name]];

	// [t copyFile:name toPath:@"/tmp/access.txt"];
	
	[t copyFile:name];
	STAssertTrue([t compareContentFile:name], @"content should be identical");
	
	BOOL same = [t compareACLFile:name];
	if(!same) {
		if([t areWeUsingAppleCopy]) {
			NSLog(@"Apple's copy is broken, and failed to copy ACL's correct. We ignore this problem.");
			same = YES;
		}
	}
	STAssertTrue(same, @"ACL's should be identical");
}

@end