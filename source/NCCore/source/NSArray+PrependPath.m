//
//  NSArray+PrependPath.m
//  NCCore
//
//  Created by Simon Strandgaard on 17/05/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NSArray+PrependPath.h"


@implementation NSArray (NCPrependPath)

-(NSArray*)prependPath:(NSString*)path {
	NSMutableArray* result = [NSMutableArray arrayWithCapacity:[self count]];
	for(NSString* name in self) {
		[result addObject:[path stringByAppendingPathComponent:name]];
	}
	return [result copy];
}

@end
