//
//  NCListerTableTextCell.m
//  NCCore
//
//  Created by Simon Strandgaard on 11/03/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NCLog.h"
#import "NCTimeProfiler.h"
#import "NCListerTableTextCell.h"


@interface NCListerTableTextCell (Private)
-(NSAttributedString*)appendElipsisToString:(NSAttributedString*)aString
	maxWidth:(float)maxwidth;

- (void)drawInRoundedRect:(NSRect)rect;

@end

@implementation NCListerTableTextCell

@synthesize rounded = m_rounded;


/*
Ensure that the string is able to render within the
specified max-width. Text outside the max-width is removed.
If there is overflow then an ellipsis char is appended.
*/
-(NSAttributedString*)appendElipsisToString:(NSAttributedString*)aString
	maxWidth:(float)maxwidth 
{
	{
		float w = [aString size].width;
		if(w <= maxwidth) {
			return aString;
		}
	}

	static NSString* ellipsis = nil;
    if(ellipsis == nil) {
		const unichar ellipsis_char = 0x2026;
		ellipsis = [[NSString alloc] initWithCharacters:&ellipsis_char length:1];
    }

	NSMutableAttributedString* ms = [aString mutableCopy];
	int truncate_begin = [ms length] - 1;
	for(int i=0; (i<100) && (truncate_begin >= 2); ++i) {
		float w = [ms size].width;
		if(w < maxwidth) break;
		truncate_begin--;
		NSRange range = NSMakeRange(truncate_begin, 2);
		[ms replaceCharactersInRange:range withString:ellipsis];
	}
	return ms;
}


- (void)drawInteriorWithFrame:(NSRect)frame inView:(NSView *)view {
	// return;
	if(m_rounded) {
		[self drawInRoundedRect:frame];
		return;
	}
	//uint64_t t0 = mach_absolute_time();

	id obj = [self objectValue];
	if([obj isKindOfClass:[NSImage class]]) {
		NSImage* image = (NSImage*)obj;
		int sign = [view isFlipped] ? (+1) : (-1);
        NSSize imageSize = [image size];
		NSRect imageFrame = NSMakeRect(
			floorf(NSMinX(frame) + (NSWidth(frame) - imageSize.width) / 2),
			floorf(NSMinY(frame) + (NSHeight(frame) + sign * imageSize.height) / 2),
			imageSize.width,
			imageSize.height
		);
		[image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
		return;
	}

	[[NSGraphicsContext currentContext] saveGraphicsState];
	
	[[NSGraphicsContext currentContext] setShouldAntialias:[self antiAlias]];


	NSAttributedString* s = nil;
	{
		NSMutableDictionary* attr = [[NSMutableDictionary alloc] init];
		id obj = [self color0];
		if(obj) [attr setObject:obj forKey:NSForegroundColorAttributeName];

		obj = [self font];
		if(obj) [attr setObject:obj forKey:NSFontAttributeName];

		s = [[NSAttributedString alloc] 
			initWithString:[self stringValue] attributes:attr];
	}
	// NSAttributedString* s = [self attributedStringValue];

	float padding_left = [self paddingLeft];
	float padding_right = [self paddingRight];
	float offset_y = [self offsetY];

	float max_width = NSWidth(frame) - (padding_left + padding_right);
	s = [self appendElipsisToString:s maxWidth:max_width];

	NSPoint point = NSMakePoint(
		frame.origin.x + padding_left,
		frame.origin.y + offset_y
	);
	
	if([self alignment] == NSRightTextAlignment) {
		point.x = NSMaxX(frame) - [s size].width - padding_right;
	}
	
	point.x = floorf(point.x);
	point.y = floorf(point.y);
	
	[s drawAtPoint:point];

	[[NSGraphicsContext currentContext] restoreGraphicsState];

	//uint64_t t1 = mach_absolute_time();
	//double elapsed0 = subtract_times(t1, t0);
	// LOG_DEBUG(@"%.6fs", elapsed0);
}

- (void)drawInRoundedRect:(NSRect)rect {
	//uint64_t t0 = mach_absolute_time();
	NSString* s = [self stringValue];

	[[NSGraphicsContext currentContext] saveGraphicsState];
	
	[[NSGraphicsContext currentContext] setShouldAntialias:[self antiAlias]];
	

	NSString* fontname = @"Helvetica";
	float fontsize = 18;


	NSColor* shadow_color = [NSColor colorWithCalibratedWhite:0.85 alpha:1]; 
	NSColor* text_color = [NSColor colorWithCalibratedWhite:0.25 alpha:1]; 
	NSColor* fill_color = [NSColor colorWithCalibratedWhite:0.6 alpha:1]; 


	NSFont* font = [NSFont fontWithName:fontname size:fontsize];
		font = [[NSFontManager sharedFontManager] convertFont:font 
			toHaveTrait:NSBoldFontMask];
	if(!font) {
		font = [NSFont systemFontOfSize:fontsize];
	}

	NSMutableDictionary* attr = [[NSMutableDictionary alloc] init];
	[attr setObject:text_color forKey:NSForegroundColorAttributeName];
	[attr setObject:font forKey:NSFontAttributeName];


	NSShadow* shadow = [[NSShadow alloc] init];
	[shadow setShadowOffset:NSMakeSize(0, -1)];
	[shadow setShadowBlurRadius:1];
	[shadow setShadowColor:shadow_color];
	[attr setValue:shadow forKey:NSShadowAttributeName];

	
	NSAttributedString* as = [[NSAttributedString alloc] 
		initWithString:s attributes:attr];


	float padding_left = 17;
	float padding_right = 16;
	float margin_right = 8;
	NSSize textsize = [as size];

	BOOL align_right = YES;
//	BOOL align_right = NO;

	NSRect shape_rect = NSInsetRect(rect, 0, 2);
	shape_rect.size.height += 1;
	shape_rect.size.width = textsize.width + padding_left + padding_right;

	NSRect f = rect;   
	NSRect b = rect;   
	
	NSPoint point = NSMakePoint(
		rect.origin.x + padding_left,
		NSMinY(rect) + (NSHeight(f) - textsize.height) / 2
	);

	// compensate for helvetica vertical centering issue
	point.y += 0;

	if(align_right) {
		float extra = NSWidth(b) - NSWidth(shape_rect) - margin_right;
		shape_rect.origin.x += extra;
		point.x += extra;
	}
	
	// draw a rounded rect
	float r = NSHeight(shape_rect) * 0.5;
    NSBezierPath* shape = [NSBezierPath bezierPath];
    [shape appendBezierPathWithRoundedRect:shape_rect xRadius:r yRadius:r];
	[fill_color set]; 
	[shape fill];

	[as drawAtPoint:point];

	[[NSGraphicsContext currentContext] restoreGraphicsState];

	//uint64_t t1 = mach_absolute_time();
	//double elapsed0 = subtract_times(t1, t0);
	// LOG_DEBUG(@"%.6fs", elapsed0);
}

- (void)xhighlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	if(flag) {
		[[NSColor greenColor] set];
		NSRectFill(cellFrame);
	}
	
}

/*
- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent {
	NSLog(@"%s", _cmd);
}
 */

@end
