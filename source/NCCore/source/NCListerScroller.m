//
//  NCListerScroller.m
//  NCCore
//
//  Created by Simon Strandgaard on 15/02/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NCListerScroller.h"


@implementation NCListerScroller

- (void)drawRect:(NSRect)rect {
	[super drawRect:rect];


	NSRect r1 = [self bounds];
	[[NSColor grayColor] set];

	float values[] = { 0.1, 0.3, 0.35, 0.7, 0.8, 0.81, 0.82, 0.83, 0.86 };
	int number_of_values = sizeof(values) / sizeof(float);
	
	/*
	draw markers for every selected file
	*/
	int i=0;
	for(; i<number_of_values; i++) {
		
		float value = values[i];
		
		NSRect r = r1;
		r.origin.x = floorf(r.origin.x + 3);
		r.size.width = floorf(r.size.width - 5);
		r.origin.y = floorf(r1.origin.y + r1.size.height * value);
		r.size.height = 1;
	
		NSRectFill(r);
	}
	
	
	[self drawKnob];
}

@end
