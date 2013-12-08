//
//  NSArray+PrependPath.m
//  NCCore
//
//  Created by Simon Strandgaard on 17/05/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

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
