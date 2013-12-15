//
//  NCTableHeaderCell.m
//  cocoa_clickable_headercell
//
//  Created by Simon Strandgaard on 01/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NCTableHeaderCell.h"
#import "NSGradient+PredefinedGradients.h"


@implementation NCTableHeaderCell

@synthesize gradient = m_gradient;
@synthesize pressedGradient = m_pressed_gradient;
@synthesize selectedGradient = m_selected_gradient;
@synthesize selectedPressedGradient = m_selected_pressed_gradient;

@synthesize sortIndicator = m_sort_indicator;
@synthesize paddingCell = m_padding_cell;

- (id)initTextCell:(NSString*)s {
	if (![super initTextCell:s]) return nil;
	
	NSGradient* grad0 = [NSGradient tableHeaderGradient];
	NSGradient* grad1 = [NSGradient tableHeaderPressedGradient];
	NSGradient* grad2 = [NSGradient tableHeaderSelectedGradient];
	NSGradient* grad3 = [NSGradient tableHeaderSelectedPressedGradient];
	[self setGradient:grad0];
	[self setPressedGradient:grad1];
	[self setSelectedGradient:grad2];
	[self setSelectedPressedGradient:grad3];
	
	m_sort_indicator = 0;
	m_padding_cell = YES;
	
	return self;
}

-(id)copyWithZone:(NSZone*)zone {
	NCTableHeaderCell* cell = (NCTableHeaderCell*)[super copyWithZone:zone];
	cell->m_sort_indicator = m_sort_indicator;
	cell->m_padding_cell = m_padding_cell;
	cell->m_gradient = m_gradient;
	cell->m_pressed_gradient = m_pressed_gradient;
	cell->m_selected_gradient = m_selected_gradient;
	cell->m_selected_pressed_gradient = m_selected_pressed_gradient;
    return cell;
}


/*- (void)xdrawInteriorWithFrame:(NSRect)frame inView:(NSView *)view {
	[[NSColor redColor] set];
	NSRectFill(frame);
} */

- (void)drawInteriorWithFrame:(NSRect)frame inView:(NSView *)view {
	// LOG_DEBUG(@"%.2f %.2f %.2f %.2f", NSMinX(frame), NSMinY(frame), NSMaxX(frame), NSMaxY(frame));
	int state = [self state];
	BOOL is_highlighted = [self isHighlighted];
	if(![NSApp isActive]) {
		// This is the same behavior as in iTunes. 
		// When iTunes becomes inactive.. then nothing is hilighted
		is_highlighted = NO;
	}

	/*****************************************************
	fill the background
	*****************************************************/
	NSGradient* grad0 = [self gradient];
	NSGradient* grad1 = [self pressedGradient];
	NSGradient* grad2 = [self selectedGradient];
	NSGradient* grad3 = [self selectedPressedGradient];
    
	NSGradient* grad = grad0;
	if(state == NSOnState) grad = grad1;
	if(is_highlighted) {
		grad = grad2;
		if(state == NSOnState) grad = grad3;
	}

    [grad drawInRect:frame angle:90.0];
	
	if(m_padding_cell) {
		return;
	}

	/*****************************************************
	draw dividers between the cells
	*****************************************************/
	NSRect inner_frame = NSInsetRect(frame, 0, 1);
	NSRect junk, left, right;
	NSDivideRect(inner_frame, &left, &junk, 1, NSMinXEdge);
	NSDivideRect(inner_frame, &right, &junk, 1, NSMaxXEdge);
	if(is_highlighted) {
		[[NSColor colorWithCalibratedRed:0.683 green:0.730 blue:0.800 alpha:1.000] set];
	} else {
		[[NSColor colorWithCalibratedWhite:1.0 alpha:0.250] set];
	}
	[[NSBezierPath bezierPathWithRect:left] fill];
	[[NSColor colorWithCalibratedWhite:0.639 alpha:1.000] set];
	NSRectFill(right);
	
	
	
	/*****************************************************
	prepare for drawing text
	*****************************************************/
	NSRect rect = frame;
	
	NSString* s = [self stringValue];


	NSColor* shadow_color = [NSColor colorWithCalibratedWhite:0.85 alpha:1]; 
	// NSColor* color1 = [NSColor colorWithCalibratedWhite:0.125 alpha:1]; 
	NSColor* color1 = [NSColor colorWithCalibratedWhite:0.2 alpha:1]; 

	NSMutableDictionary* attr0 = [[NSMutableDictionary alloc] init];
	[attr0 setObject:color1 forKey:NSForegroundColorAttributeName];
	[attr0 setObject:[NSFont boldSystemFontOfSize:11] forKey:NSFontAttributeName];
	if(1) {
		[attr0 setObject:[NSFont boldSystemFontOfSize:13] forKey:NSFontAttributeName];
	}
	if(0) {
		[attr0 setObject:[NSFont boldSystemFontOfSize:18] forKey:NSFontAttributeName];
	}
	if(0) {
		NSFont* font = [NSFont fontWithName:@"Helvetica Bold" size:18];
		[attr0 setObject:font forKey:NSFontAttributeName];
	}
	

	NSShadow* shadow = [[NSShadow alloc] init];
	[shadow setShadowOffset:NSMakeSize(0, -1)];
	[shadow setShadowBlurRadius:1];
	[shadow setShadowColor:shadow_color];
	[attr0 setValue:shadow forKey:NSShadowAttributeName];


	/*****************************************************
	draw the text
	*****************************************************/
	NSAttributedString* as0 = [[NSAttributedString alloc] 
		initWithString:s attributes:attr0];
	NSSize size0 = [as0 size];

	NSString* ssort = (m_sort_indicator > 0) ? @"▲" : @"▼";
	NSAttributedString* as1 = [[NSAttributedString alloc] 
		initWithString:ssort attributes:attr0];
	NSSize size1 = [as1 size];

	float padding = 9;
	NSRect text_frame = NSInsetRect(rect, padding, 0);

	// draw the sort indicator
	if(m_sort_indicator != 0) {
		NSPoint point = NSMakePoint(
			NSMaxX(text_frame) - size1.width,
			NSMinY(text_frame) + (NSHeight(text_frame) - size1.height) / 2
		);
		[as1 drawAtPoint:point];
		text_frame.size.width -= size1.width + padding;
	}

	// draw the text
	BOOL is_right_aligned = ([self alignment] == NSRightTextAlignment);
	float point0_y = NSMinY(rect) + (NSHeight(rect) - size0.height) / 2;
	NSPoint point0 = NSMakePoint(NSMinX(text_frame), point0_y);
	if(is_right_aligned) {
		point0 = NSMakePoint(NSMaxX(text_frame) - size0.width, point0_y);
	}
	[as0 drawAtPoint:point0];
}

@end
