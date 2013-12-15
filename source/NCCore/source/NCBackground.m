//
//  NCBackground.m
//  NCCore
//
//  Created by Simon Strandgaard on 01/02/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NCBackground.h"


@implementation NCBackground

@synthesize isActive = m_is_active;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect {

	NSColor* color = nil;
	if(m_is_active) {
		color = [NSColor colorWithCalibratedRed:0.35
			                           green:0.55
			                            blue:0.8
			                           alpha:1.0];
		
		// [[NSColor blueColor] set];
	} else {
		color = [NSColor colorWithCalibratedRed:0.83
			                           green:0.83
			                            blue:0.83
			                           alpha:1.0];
		// [[NSColor grayColor] set];
	}
	[color set];

	NSRectFill(rect);
}

@end
