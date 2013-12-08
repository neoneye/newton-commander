//
//  NCDirEnumeratorTest.m
//  NCCore
//
//  Created by Simon Strandgaard on 22/05/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "NCDirEnumeratorTest.h"
#import <NCCore/NCDirEnumerator.h>

@implementation NCDirEnumeratorTest

-(void)test1 {
	NCDirEnumerator* e = [NCDirEnumerator enumeratorWithPath:@"/"];
	STAssertNotNil(e, @"must always return an enumerator for a valid path");

	BOOL has_tmp = NO;    
	BOOL has_home = NO;  
	BOOL has_usr = NO;
	BOOL has_bin = NO;
	NCDirEntry* entry;
	while ( (entry = (NCDirEntry*)[e nextObject]) ) {
		NSString* name = [entry name];
		if([name isEqual:@"tmp"]) { has_tmp = YES; }
		if([name isEqual:@"home"]) { has_home = YES; }
		if([name isEqual:@"usr"]) { has_usr = YES; }
		if([name isEqual:@"bin"]) { has_bin = YES; }
	}
	
	STAssertTrue(has_tmp, @"the root dir is expected to have a /tmp dir");
	STAssertTrue(has_home, @"the root dir is expected to have a /home dir");
	STAssertTrue(has_usr, @"the root dir is expected to have a /usr dir");
	STAssertTrue(has_bin, @"the root dir is expected to have a /bin dir");
}

-(void)test2 {
	NCDirEnumerator* e = [NCDirEnumerator enumeratorWithPath:@"/usr"];
	STAssertNotNil(e, @"must always return an enumerator for a valid path");

	BOOL has_lib = NO;    
	BOOL has_share = NO;  
	BOOL has_include = NO;
	NCDirEntry* entry;
	while ( (entry = (NCDirEntry*)[e nextObject]) ) {
		NSString* name = [entry name];
		if([name isEqual:@"lib"]) { has_lib = YES; }
		if([name isEqual:@"share"]) { has_share = YES; }
		if([name isEqual:@"include"]) { has_include = YES; }
	}
	
	STAssertTrue(has_lib, @"the /usr dir is expected to have a /lib dir");
	STAssertTrue(has_share, @"the /usr dir is expected to have a /share dir");
	STAssertTrue(has_include, @"the /usr dir is expected to have a /include dir");
}

-(void)test3 {
	NCDirEnumerator* e = [NCDirEnumerator enumeratorWithPath:@"/non_existing_dir"];
	STAssertNil(e, @"invalid paths should not return an enumerator");                     
}

@end
