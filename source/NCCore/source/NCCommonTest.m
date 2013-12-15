//
//  NCCommonTest.m
//  NCCore
//
//  Created by Simon Strandgaard on 22/05/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "NCCommonTest.h"
#import "NCCommon.h"


@implementation NCCommonTest

-(void)test1 {
	NSString* expected = @"0 B";
	NSString* actual = NCSuffixStringForBytes(0);
	STAssertEqualObjects(actual, expected, @"Expected %@, but got %@", expected, actual);
}

-(void)test2 {
	NSString* expected = @"999 B";
	NSString* actual = NCSuffixStringForBytes(999);
	STAssertEqualObjects(actual, expected, @"Expected %@, but got %@", expected, actual);
}

-(void)test3 {
	NSString* expected = @"1.00 KB";
	NSString* actual = NCSuffixStringForBytes(1000);
	STAssertEqualObjects(actual, expected, @"Expected %@, but got %@", expected, actual);
}

-(void)test4 {
	NSString* expected = @"1.23 KB";
	NSString* actual = NCSuffixStringForBytes(1234);
	STAssertEqualObjects(actual, expected, @"Expected %@, but got %@", expected, actual);
}

-(void)test5 {
	NSString* expected = @"1.00 MB";
	NSString* actual = NCSuffixStringForBytes(1000000);
	STAssertEqualObjects(actual, expected, @"Expected %@, but got %@", expected, actual);
}

-(void)test6 {
	NSString* expected = @"1.00 GB";
	NSString* actual = NCSuffixStringForBytes(1000000000);
	STAssertEqualObjects(actual, expected, @"Expected %@, but got %@", expected, actual);
}

-(void)test7 {
	NSString* expected = @"1.00 TB";
	NSString* actual = NCSuffixStringForBytes(1000000000000);
	STAssertEqualObjects(actual, expected, @"Expected %@, but got %@", expected, actual);
}

-(void)test101 {
	NSString* expected = @"0";
	NSString* actual = NCSpacedStringForBytes(0);
	STAssertEqualObjects(actual, expected, @"Expected %@, but got %@", expected, actual);
}

-(void)test102 {
	NSString* expected = @"999";
	NSString* actual = NCSpacedStringForBytes(999);
	STAssertEqualObjects(actual, expected, @"Expected %@, but got %@", expected, actual);
}

-(void)test103 {
	NSString* expected = @"1 000";
	NSString* actual = NCSpacedStringForBytes(1000);
	STAssertEqualObjects(actual, expected, @"Expected %@, but got %@", expected, actual);
}

-(void)test104 {
	NSString* expected = @"1 000 000";
	NSString* actual = NCSpacedStringForBytes(1000000);
	STAssertEqualObjects(actual, expected, @"Expected %@, but got %@", expected, actual);
}

@end
