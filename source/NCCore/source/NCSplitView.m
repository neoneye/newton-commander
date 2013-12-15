//
//  NCSplitView.m
//  NCCore
//
//  Created by Simon Strandgaard on 18/04/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NCSplitView.h"
#import "NSGradient+PredefinedGradients.h"


@implementation NCSplitView

- (CGFloat)dividerThickness {
	// return 3;         
	// return 7;
	return 9;
}

- (void)drawDividerInRect:(NSRect)aRect {
	int footer_height0 = 24;
	int footer_height1 = footer_height0 + 1;
	BOOL draw_black = NO;
	BOOL draw_gray = NO;
	BOOL draw_pathfinder = NO;
	BOOL remove_footer_left = NO;
	BOOL remove_footer_right = NO;
	// draw_black = YES;
	// draw_gray = YES;    
	draw_pathfinder = YES;
	
	NSColor* color_footer_left = nil;
	NSColor* color_footer_right = nil;
	
	
	color_footer_left = [NSColor colorWithCalibratedWhite:0.1 alpha:1.000];
	
	/*
	TODO: change footer style depending on the mainwindow state.
	If it's a list-list state then only draw the left footer line.
	if it's a list-info state then draw both left and right footer lines.
	*/
	remove_footer_left = YES;
	remove_footer_right = YES;
	
	
	if(draw_black) {
		NSGradient* g = [NSGradient blackDividerGradient];
	    [g drawInRect:aRect angle:0.0];
	}
	if(draw_gray) {
		NSGradient* g = [[NSGradient alloc] initWithColorsAndLocations:
			[NSColor colorWithCalibratedWhite:0.184 alpha:1.000], 0.0,
			[NSColor colorWithCalibratedWhite:0.363 alpha:1.000], 0.5,
			[NSColor colorWithCalibratedWhite:0.184 alpha:1.000], 1.0,
			nil];
	    [g drawInRect:aRect angle:0.0];
	}
	if(draw_pathfinder) {
		[[NSColor colorWithCalibratedWhite:0.333 alpha:1.000] set];
		NSRectFill(aRect);
		NSDrawWindowBackground(NSInsetRect(aRect, 1, 0));
	}
	if(remove_footer_left) {
		NSRect slice, junk;
		NSDivideRect(aRect, &slice, &junk, footer_height0, NSMaxYEdge);
		NSDivideRect(slice, &slice, &junk, 1, NSMinXEdge);
		NSDrawWindowBackground(slice);
	}
	if(remove_footer_right) {
		NSRect slice, junk;
		NSDivideRect(aRect, &slice, &junk, footer_height0, NSMaxYEdge);
		NSDivideRect(slice, &slice, &junk, 1, NSMaxXEdge);
		NSDrawWindowBackground(slice);
	}
	if(color_footer_left) {
		NSRect slice, junk;
		NSDivideRect(aRect, &slice, &junk, footer_height1, NSMaxYEdge);
		NSDivideRect(slice, &slice, &junk, 1, NSMinXEdge);
		NSDivideRect(slice, &junk, &slice, 1, NSMaxYEdge);
		[color_footer_left set];
		NSRectFill(slice);
		[[NSColor colorWithCalibratedRed:0.390 green:0.403 blue:0.403 alpha:1.000] set];
		NSRectFill(junk);
	}
	if(color_footer_right) {
		NSRect slice, junk;
		NSDivideRect(aRect, &slice, &junk, footer_height1, NSMaxYEdge);
		NSDivideRect(slice, &slice, &junk, 1, NSMaxXEdge);
		NSDivideRect(slice, &junk, &slice, 1, NSMaxYEdge);
		[color_footer_right set];
		NSRectFill(slice);
		[[NSColor colorWithCalibratedRed:0.390 green:0.403 blue:0.403 alpha:1.000] set];
		NSRectFill(junk);
	}
}
@end
