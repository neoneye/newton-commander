//
//  CMOperationController.m
//  worker
//
//  Created by Simon Strandgaard on 20/05/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import "CMOperationController.h"
#import "CMTraversalObject.h"
#import "CMScanner.h"
#import "CMOperation.h"
#import "CMPrintHierarchy.h"
#import "OnigRegexp.h"


@interface CMOperationController ()
-(void)performScan;
-(void)performOperation;
-(void)printObjects:(NSArray*)anArray;
@end

@implementation CMOperationController

@synthesize operationType = m_operation_type;
@synthesize sourceDir = m_source_dir;
@synthesize targetDir = m_target_dir;
@synthesize nameArray = m_name_array;
@synthesize operationDelegate = m_operation_delegate;
@synthesize traversalObjectArray = m_traversal_object_array;
@synthesize excludeFilePatternArray = m_exclude_file_pattern_array;
@synthesize excludeDirectoryPatternArray = m_exclude_directory_pattern_array;
@synthesize excludeFileRegexpArray = m_exclude_file_regexp_array;
@synthesize excludeDirectoryRegexpArray = m_exclude_directory_regexp_array;

-(void)run {
	NSAssert([m_source_dir isAbsolutePath], @"source_dir must be absolute");
	NSAssert([m_target_dir isAbsolutePath], @"target_dir must be absolute");
	
	self.traversalObjectArray = nil;

	{
		NSMutableArray* patterns = [NSMutableArray arrayWithCapacity:[self.excludeFilePatternArray count]];
		for(id thing in self.excludeFilePatternArray) {
			if(![thing isKindOfClass:[NSString class]]) {
				NSLog(@"not a NSString");
				continue;
			}
			NSString* pattern = (NSString*)thing;
			OnigRegexp* regexp = [OnigRegexp compile:pattern];
			[patterns addObject:regexp];
		}
		self.excludeFileRegexpArray = [NSArray arrayWithArray:patterns];
		// NSLog(@"%s regexps: %@", _cmd, patterns);
	}
	{
		NSMutableArray* patterns = [NSMutableArray arrayWithCapacity:[self.excludeDirectoryPatternArray count]];
		for(id thing in self.excludeDirectoryPatternArray) {
			if(![thing isKindOfClass:[NSString class]]) {
				NSLog(@"not a NSString");
				continue;
			}
			NSString* pattern = (NSString*)thing;
			OnigRegexp* regexp = [OnigRegexp compile:pattern];
			[patterns addObject:regexp];
		}
		self.excludeDirectoryRegexpArray = [NSArray arrayWithArray:patterns];
		// NSLog(@"%s regexps: %@", _cmd, patterns);
	}
	
	[self performScan];
	[self printObjects:self.traversalObjectArray];
	[self performOperation];
}

-(void)performScan {
	NSLog(@"%s BEFORE", _cmd);
	CMScanner* scanner = [[[CMScanner alloc] init] autorelease];
	scanner.excludeFileRegexpArray = self.excludeFileRegexpArray;
	scanner.excludeDirectoryRegexpArray = self.excludeDirectoryRegexpArray;

	/*
	IDEA: detect hardlinks
	IDEA: detect symlinks across different mounts
	IDEA: detect if there enough disk space
	IDEA: determine wether there are files/dirs to be excluded
	*/
	
	for(NSString* name in self.nameArray) {
		NSString* path = [m_source_dir stringByAppendingPathComponent:name];
		[scanner scanItem:path];
	}

	self.traversalObjectArray = [scanner traversalObjects];
	NSLog(@"%s AFTER", _cmd);
}

-(void)performOperation {
	NSLog(@"%s BEFORE", _cmd);
	NSArray* objects = self.traversalObjectArray;


	CMOperation* v = [[[CMOperation alloc] init] autorelease];
	v.operationType = m_operation_type;
	v.sourcePath = m_source_dir;
	v.targetPath = m_target_dir;
	v.delegate = m_operation_delegate;

	BOOL success = NO;

	@try {
		for(CMTraversalObject* obj in objects) { [obj accept:v]; }
		success = YES;
	}
	@catch ( NSException *e ) {
		NSLog(@"%s exception occured: %@", _cmd, e);
	}

	if(success) {
		NSLog(@"%s operation completed", _cmd);
	} else {
		NSLog(@"%s operation failed", _cmd);
	}
	NSLog(@"%s AFTER", _cmd);
}

-(void)printObjects:(NSArray*)anArray {
	CMPrintHierarchy* v = [[[CMPrintHierarchy alloc] init] autorelease];
	for(CMTraversalObject* obj in anArray) { [obj accept:v]; }
	NSLog(@"%s\n%@", _cmd, v.result);
}

@end


