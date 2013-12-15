//
//  NCCommon.m
//  NCCore
//
//  Created by Simon Strandgaard on 18/03/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NCCommon.h"


NSString* NCSuffixStringForBytes( unsigned long long bytes ) {
	int parts = 1;
	int bytes1 = bytes % 1000;
	bytes /= 1000;
	if(bytes > 0) parts++;

	int bytes2 = bytes % 1000;
	bytes /= 1000;
	if(bytes > 0) parts++;

	int bytes3 = bytes % 1000;
	bytes /= 1000;
	if(bytes > 0) parts++;

	int bytes4 = bytes % 1000;
	bytes /= 1000;
	if(bytes > 0) parts++;

	int bytes5 = bytes;

	if(parts == 1) return [NSString stringWithFormat:@"%i B", bytes1];
	if(parts == 2) return [NSString stringWithFormat:@"%i.%02i KB", bytes2, (bytes1 / 10)];
	if(parts == 3) return [NSString stringWithFormat:@"%i.%02i MB", bytes3, (bytes2 / 10)];
	if(parts == 4) return [NSString stringWithFormat:@"%i.%02i GB", bytes4, (bytes3 / 10)];
	return [NSString stringWithFormat:@"%i.%02i TB", bytes5, (bytes4 / 10)];
}

NSString* NCSpacedStringForBytes( unsigned long long bytes ) {
	int parts = 1;
	int bytes1 = bytes % 1000;
	bytes /= 1000;
	if(bytes > 0) parts++;

	int bytes2 = bytes % 1000;
	bytes /= 1000;
	if(bytes > 0) parts++;

	int bytes3 = bytes % 1000;
	bytes /= 1000;
	if(bytes > 0) parts++;

	int bytes4 = bytes % 1000;
	bytes /= 1000;
	if(bytes > 0) parts++;

	int bytes5 = bytes;

	if(parts == 1) return [NSString stringWithFormat:@"%i", bytes1];
	if(parts == 2) return [NSString stringWithFormat:@"%i %03i", bytes2, bytes1];
	if(parts == 3) return [NSString stringWithFormat:@"%i %03i %03i", bytes3, bytes2, bytes1];
	if(parts == 4) return [NSString stringWithFormat:@"%i %03i %03i %03i", bytes4, bytes3, bytes2, bytes1];
	return [NSString stringWithFormat:@"%i %03i %03i %03i %03i", bytes5, bytes4, bytes3, bytes2, bytes1];
}




@implementation NCCommon

@end
