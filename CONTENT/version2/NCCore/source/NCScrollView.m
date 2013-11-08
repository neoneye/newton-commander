//
//  NCScrollView.m
//  NCCore
//
//  Created by Simon Strandgaard on 05/08/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "NCScrollView.h"


@implementation NCScrollView

- (void)drawRect:(NSRect)rect{
	[super drawRect: rect];

	if([self hasVerticalScroller] && [self hasHorizontalScroller]){
		NSRect vframe = [[self verticalScroller]frame];
		NSRect hframe = [[self horizontalScroller]frame];
		NSRect corner;
		corner.origin.x = NSMaxX(hframe);
		corner.origin.y = NSMinY(hframe);
		corner.size.width = NSWidth(vframe);
		corner.size.height = NSHeight(hframe);

		[[NSColor colorWithCalibratedRed:0.597 green:0.607 blue:0.607 alpha:1.000] set];
		NSRectFill(corner);
	}
}
@end
