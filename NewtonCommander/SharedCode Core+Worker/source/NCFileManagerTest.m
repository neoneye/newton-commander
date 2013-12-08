//
//  NSFileManager+PathExtensionsTest.m
//  NCCore
//
//  Created by Simon Strandgaard on 22/05/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "NSFileManager+ResolvePathTest.h"
#import <NCCore/NSFileManager+ResolvePath.h>


@implementation NSFileManager_ResolvePathTest

-(NSString*)nc_readlink:(NSString*)path {
	const char* read_path = [path fileSystemRepresentation];
	char buffer[PATH_MAX + 4];
	int l = readlink(read_path, buffer, sizeof(buffer) - 1);
	if(l != -1) {
		buffer[l] = 0;
		return [NSString stringWithUTF8String:buffer];
	}
	return nil;
}


-(void)testStringByResolvingSymlink1 {
	/*
	on Mac OS X 10.6
	"/tmp" is a symlink pointing at "private/tmp"
	*/
	{
		NSString* path = @"/tmp";
		NSString* expected = @"private/tmp";
		NSString* actual = [self nc_readlink:path];
		STAssertEqualObjects(actual, expected, @"Expected '%@', but got '%@'", expected, actual);
	}
	{
		NSString* path = @"/tmp";
		NSString* expected = @"/tmp";
		/*
		NOTE: Apple's stringByResolvingSymlinksInPath removes "/private" from the path,
		which makes stringByResolvingSymlinksInPath not suitable for us to use
		*/
		NSString* actual = [path stringByResolvingSymlinksInPath];
		STAssertEqualObjects(actual, expected, @"Expected '%@', but got '%@'", expected, actual);
	}
	{
		/*
		NOTE: Apple's destinationOfSymbolicLinkAtPath doesn't remove "/private" from the path,
		which means that destinationOfSymbolicLinkAtPath works the same way as readlink()
		*/
		NSString* path = @"/tmp";
		NSString* actual = [[NSFileManager defaultManager]
			destinationOfSymbolicLinkAtPath:path
			error:NULL];

		NSString* expected = @"private/tmp";
		STAssertEqualObjects(actual, expected, @"Expected '%@', but got '%@'", expected, actual);
	}
}

-(void)testStringByResolvingSymlink2 {
	/*
	on Mac OS X 10.6
	"/usr/X11R6" is a symlink pointing at "X11"
	*/
	{
		NSString* path = @"/usr/X11R6";
		NSString* expected = @"X11";
		NSString* actual = [self nc_readlink:path];
		STAssertEqualObjects(actual, expected, @"Expected '%@', but got '%@'", expected, actual);
	}
	{
		NSString* path = @"/usr/X11R6";
		NSString* expected = @"/usr/X11";
		NSString* actual = [path stringByResolvingSymlinksInPath];
		STAssertEqualObjects(actual, expected, @"Expected '%@', but got '%@'", expected, actual);
	}
}

-(void)testStringByResolvingSymlink3 {
	NSString* path = @"/non_existing_dir";
	NSString* actual = [self nc_readlink:path];
	STAssertNil(actual, @"invalid paths should not return anything");                     
}

-(void)testNormalizedPath1 {
	NSString* path = @"/";
	NSString* expected = @"/";
	NSString* actual = [[NSFileManager defaultManager] nc_resolvePath:path];
	STAssertEqualObjects(actual, expected, @"Expected '%@', but got '%@'", expected, actual);
}

-(void)testNormalizedPath2 {
	NSString* path = @"/usr";
	NSString* expected = @"/usr";
	NSString* actual = [[NSFileManager defaultManager] nc_resolvePath:path];
	STAssertEqualObjects(actual, expected, @"Expected '%@', but got '%@'", expected, actual);
}

-(void)testNormalizedPath3 {
	NSString* path = @"/usr/share/../share";
	NSString* expected = @"/usr/share";
	NSString* actual = [[NSFileManager defaultManager] nc_resolvePath:path];
	STAssertEqualObjects(actual, expected, @"Expected '%@', but got '%@'", expected, actual);
}

-(void)testNormalizedPath4 {
	NSString* path = @"/usr/./share";
	NSString* expected = @"/usr/share";
	NSString* actual = [[NSFileManager defaultManager] nc_resolvePath:path];
	STAssertEqualObjects(actual, expected, @"Expected '%@', but got '%@'", expected, actual);
}

-(void)testNormalizedPath5 {
	NSString* path = @"/usr/X11R6";
	NSString* expected = @"/usr/X11";
	NSString* actual = [[NSFileManager defaultManager] nc_resolvePath:path];
	STAssertEqualObjects(actual, expected, @"Expected '%@', but got '%@'", expected, actual);
}

@end


@implementation NSFileManager_ResolvePathTest_UsingTempdir

-(void)setUp {
	/*
	create a temporary dir, seen on Matt Gallagher's blog
	http://cocoawithlove.com/2009/07/temporary-files-and-folders-in-cocoa.html
	*/
	NSString* tempDirectoryTemplate =
	    [NSTemporaryDirectory() stringByAppendingPathComponent:@"NewtonCommander_PathExtensionsTest.XXXXXX"];
	const char* tempDirectoryTemplateCString = [tempDirectoryTemplate fileSystemRepresentation];
	char* tempDirectoryNameCString = (char *)malloc(strlen(tempDirectoryTemplateCString) + 1);
	strcpy(tempDirectoryNameCString, tempDirectoryTemplateCString);
	char* result = mkdtemp(tempDirectoryNameCString);
	NSAssert((result != NULL), @"cannot create tempdir for testing");
	NSString* tempDirectoryPath =
	    [[NSFileManager defaultManager]
	        stringWithFileSystemRepresentation:tempDirectoryNameCString
	        length:strlen(result)];
	free(tempDirectoryNameCString);

	
	m_temp_dir = [tempDirectoryPath retain];
	NSAssert(m_temp_dir, @"must always run this test inside a sandbox dir");
	// NSLog(@"setup has created the dir: '%@'", tempDirectoryPath);
}

-(NSString*)mkdir:(NSString*)name {
	NSAssert(name, @"must not be nil");
	NSAssert(m_temp_dir, @"must always run this test inside a sandbox dir");

	NSString* path = [m_temp_dir stringByAppendingPathComponent:name];
	BOOL ok = [[NSFileManager defaultManager] 
		createDirectoryAtPath:path 
		withIntermediateDirectories:NO 
		attributes:nil 
		error:NULL
	];
	if(!ok) {
		NSLog(@"couldn't create dir '%@' inside '%@'", name, m_temp_dir);
		NSAssert(nil, @"faild to create dir");
	}
	return path;
}

-(NSString*)mkfile:(NSString*)name {
	NSAssert(name, @"must not be nil");
	NSAssert(m_temp_dir, @"must always run this test inside a sandbox dir");

	NSString* path = [m_temp_dir stringByAppendingPathComponent:name];
	BOOL ok = [[NSFileManager defaultManager] 
		createFileAtPath:path
		contents:[NSData data]
		attributes:nil
	];
	if(!ok) {
		NSLog(@"couldn't create file '%@' inside '%@'", name, m_temp_dir);
		NSAssert(nil, @"faild to create file");
	}
	return path;
}

-(NSString*)mklink:(NSString*)name dest:(NSString*)dest {
	NSAssert(name, @"must not be nil");                 
	NSAssert(dest, @"must not be nil");
	NSAssert(m_temp_dir, @"must always run this test inside a sandbox dir");

	NSString* path = [m_temp_dir stringByAppendingPathComponent:name];
	BOOL ok = [[NSFileManager defaultManager] 
		createSymbolicLinkAtPath:path 
		withDestinationPath:dest 
		error:NULL
	];
	if(!ok) {
		NSLog(@"couldn't create link '%@' inside '%@'  target: '%@'", name, m_temp_dir, dest);
		NSAssert(nil, @"faild to create link");
	}
	return path;
}

-(NSString*)mkalias:(NSString*)destname dest:(NSString*)srcname {
	NSAssert(srcname, @"must not be nil");                 
	NSAssert(destname, @"must not be nil");
	NSAssert(m_temp_dir, @"must always run this test inside a sandbox dir");

	NSString* destpath = [m_temp_dir stringByAppendingPathComponent:destname];
	NSURL* src = [NSURL fileURLWithPath:[m_temp_dir stringByAppendingPathComponent:srcname]];
	NSURL* dest = [NSURL fileURLWithPath:destpath];                                        

	NSData* data = [src bookmarkDataWithOptions:NSURLBookmarkCreationSuitableForBookmarkFile
	                  includingResourceValuesForKeys:nil
	                                   relativeToURL:nil
	                                           error:NULL];
	NSAssert(data, @"mkalias - no alias data");
	BOOL ok = [NSURL writeBookmarkData:data
	                toURL:dest
	              options:0
	                error:NULL];

	if(!ok) {
		NSLog(@"couldn't create alias '%@' inside '%@'  target: '%@'", srcname, m_temp_dir, destname);
		NSAssert(nil, @"faild to create alias");
	}
	return destpath;
}

-(void)test1 {
	NSString* path = [self mkdir:@"test_dir"];
	
	NSString* expected = path;
	NSString* actual = [[NSFileManager defaultManager] nc_resolvePath:path];
	expected = [expected stringByStandardizingPath];
	actual = [actual stringByStandardizingPath];
	STAssertEqualObjects(actual, expected, @"Expected '%@', but got '%@'", expected, actual);
}

-(void)test2 {
	NSString* path_dir = [self mkdir:@"test_dir"];
	NSString* path_link = [self mklink:@"test_link" dest:@"test_dir"];
	
	NSString* expected = path_dir;
	NSString* actual = [[NSFileManager defaultManager] nc_resolvePath:path_link];
	expected = [expected stringByStandardizingPath];
	actual = [actual stringByStandardizingPath];
	STAssertEqualObjects(actual, expected, @"Path mismatch");
}

-(void)testSymlink1 {
	NSString* path_dir = @"/usr/include";
	NSString* path_link = [self mklink:@"test_link" dest:@"/usr/include"];
	
	NSString* expected = path_dir;
	NSString* actual = [[NSFileManager defaultManager] nc_resolvePath:path_link];
	expected = [expected stringByStandardizingPath];
	actual = [actual stringByStandardizingPath];
	STAssertEqualObjects(actual, expected, @"Path mismatch");
}

-(void)testSymlink2 {
	[self mkdir:@"test_dir"];
	NSString* path_file = [self mkfile:@"test_dir/test_file"];
	NSString* path_link = [self mklink:@"test_link" dest:@"test_dir"];
	NSString* path_link2 = [path_link stringByAppendingPathComponent:@"test_file"];
	
	NSString* expected = path_file;
	NSString* actual = [[NSFileManager defaultManager] nc_resolvePath:path_link2];
	expected = [expected stringByStandardizingPath];
	actual = [actual stringByStandardizingPath];
	STAssertEqualObjects(actual, expected, @"Path mismatch");
}

-(void)testSymlinkCycle1 {
	NSString* path_link = [self mklink:@"test_link" dest:@"test_link"];
	NSString* actual = [[NSFileManager defaultManager] nc_resolvePath:path_link];
	STAssertNil(actual, @"paths containing loops should not return anything");                     
}

-(void)testAlias1 {
	NSString* path_dir = [self mkdir:@"test_dir"];
	NSString* path_link = [self mkalias:@"test_alias" dest:@"test_dir"];
	
	NSString* expected = path_dir;
	NSString* actual = [[NSFileManager defaultManager] nc_resolvePath:path_link];
	expected = [expected stringByStandardizingPath];
	actual = [actual stringByStandardizingPath];
	STAssertEqualObjects(actual, expected, @"Path mismatch");
}

-(void)testAlias2 {
	[self mkdir:@"test_dir"];
	NSString* path_file = [self mkfile:@"test_dir/test_file"];
	NSString* path_link = [self mkalias:@"test_alias" dest:@"test_dir"];
	NSString* path_link2 = [path_link stringByAppendingPathComponent:@"test_file"];
	
	NSString* expected = path_file;
	NSString* actual = [[NSFileManager defaultManager] nc_resolvePath:path_link2];
	expected = [expected stringByStandardizingPath];
	actual = [actual stringByStandardizingPath];
	STAssertEqualObjects(actual, expected, @"Path mismatch");
}

-(void)testAliasCycle1 {
	// the alias code refuses to create loops
	STAssertThrows([self mkalias:@"test_alias" dest:@"test_alias"], @"alias cycle");
}

@end
