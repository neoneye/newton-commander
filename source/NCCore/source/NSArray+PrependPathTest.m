//
//  NSArray+PrependPathTest.m
//  NCCore
//
//  Created by Simon Strandgaard on 22/05/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "NSArray+PrependPathTest.h"
#import "NSArray+PrependPath.h"

@implementation NSArray_PrependPathTest

-(void)test1 {
	NSArray* expected = [NSArray arrayWithObjects:@"x/a", @"x/b", nil];
	NSArray* actual = [[NSArray arrayWithObjects:@"a", @"b", nil] prependPath:@"x"];
	STAssertEqualObjects(actual, expected, @"Paths are not equal. Expected %@, but got %@", expected, actual);
}

-(void)test2 {
	NSArray* expected = [NSArray arrayWithObjects:@"a", @"b", nil];
	NSArray* actual = [[NSArray arrayWithObjects:@"a", @"b", nil] prependPath:@""];
	STAssertEqualObjects(actual, expected, @"Paths are not equal. Expected %@, but got %@", expected, actual);
}

-(void)test3 {
	NSArray* expected = [NSArray arrayWithObjects:@"/a", @"/b", nil];
	NSArray* actual = [[NSArray arrayWithObjects:@"a", @"b", nil] prependPath:@"/"];
	STAssertEqualObjects(actual, expected, @"Paths are not equal. Expected %@, but got %@", expected, actual);
}

-(void)test4 {
	NSArray* expected = [NSArray arrayWithObjects:@"./a", @"./b", nil];
	NSArray* actual = [[NSArray arrayWithObjects:@"a", @"b", nil] prependPath:@"."];
	STAssertEqualObjects(actual, expected, @"Paths are not equal. Expected %@, but got %@", expected, actual);
}

@end
