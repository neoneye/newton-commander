//
//  NSMutableArray+Shuffling.m
//  NCCore
//
//  Created by Simon Strandgaard on 09/07/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NSMutableArray+Shuffling.h"


@implementation NSMutableArray (Shuffling)

-(void)shuffle {
	static BOOL seeded = NO;
	if(!seeded) {
		seeded = YES;
		srandom(time(NULL));
	}

	NSUInteger count = [self count];
	for (NSUInteger i = 0; i < count; ++i) {
	    // Select a random element between i and end of array to swap with.
	    int nElements = count - i;
	    int n = (random() % nElements) + i;
	    [self exchangeObjectAtIndex:i withObjectAtIndex:n];
	}
}

@end
