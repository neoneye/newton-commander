//
//  NCPermissionCell.m
//  NCCore
//
//  Created by Simon Strandgaard on 24/05/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NCLog.h"
#import "NCTimeProfiler.h"
#import "NCPermissionCell.h"


@interface NCPermissionCell (Private)
-(NSAttributedString*)appendElipsisToString:(NSAttributedString*)aString
	maxWidth:(float)maxwidth;

-(NSAttributedString*)pretty:(NSUInteger)bits;
-(NSAttributedString*)prettyOctal:(NSUInteger)bits;
-(void)rebuildStrings;

@end

@implementation NCPermissionCell

@synthesize rbit = m_rbit;
@synthesize wbit = m_wbit;
@synthesize xbit = m_xbit;
@synthesize dash = m_dash;
@synthesize value1 = m_value1;
@synthesize value2 = m_value2;
@synthesize value3 = m_value3;
@synthesize value4 = m_value4;
@synthesize value5 = m_value5;
@synthesize value6 = m_value6;
@synthesize value7 = m_value7;


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

	[self rebuildStrings];
	
	NSUInteger orig_bits = [self integerValue];
	
	NSAttributedString* rwx = [self pretty:7];
	float rwx_width = [rwx size].width;
	//float r_width = [m_rbit size].width;
	float w_width = [m_wbit size].width;
	float x_width = [m_xbit size].width;
	float dash_width = [m_dash size].width;
	float spacing = rwx_width * 0.5;
	
	NSUInteger bits = orig_bits;
/*	NSAttributedString* s0 = [self pretty:bits&7];
	NSAttributedString* s1 = [self pretty:(bits>>3)&7];
	NSAttributedString* s2 = [self pretty:(bits>>6)&7]; */
	NSAttributedString* s0 = (bits & 0400) ? m_rbit : m_dash;
	NSAttributedString* s1 = (bits & 0200) ? m_wbit : m_dash;
	NSAttributedString* s2 = (bits & 0100) ? m_xbit : m_dash;
	NSAttributedString* s3 = (bits & 0040) ? m_rbit : m_dash;
	NSAttributedString* s4 = (bits & 0020) ? m_wbit : m_dash;
	NSAttributedString* s5 = (bits & 0010) ? m_xbit : m_dash;
	NSAttributedString* s6 = (bits & 0004) ? m_rbit : m_dash;
	NSAttributedString* s7 = (bits & 0002) ? m_wbit : m_dash;
	NSAttributedString* s8 = (bits & 0001) ? m_xbit : m_dash;
	
	float width1 = (bits & 0200) ? w_width : dash_width;
	float width2 = (bits & 0100) ? x_width : dash_width;
	float width4 = (bits & 0020) ? w_width : dash_width;
	float width5 = (bits & 0010) ? x_width : dash_width;
	float width7 = (bits & 0002) ? w_width : dash_width;
	float width8 = (bits & 0001) ? x_width : dash_width;

	float padding_left = [self paddingLeft];
	float padding_right = [self paddingRight];
	float offset_y = [self offsetY];

	float max_width = NSWidth(frame) - (padding_left + padding_right);
	// s = [self appendElipsisToString:s maxWidth:max_width];
	
	if(rwx_width * 3 + spacing * 2 > max_width) {
		spacing = rwx_width * 0.25;
	}
	if(rwx_width * 3 + spacing * 2 > max_width) {
		spacing = rwx_width * 0.1;
	}
	if(rwx_width * 3 + spacing * 2 > max_width) {
		spacing = 2;
	}
	if(rwx_width * 3 + spacing * 2 > max_width) {
		spacing = 1;
	}
	if(rwx_width * 3 + spacing * 2 > max_width) {
		spacing = 0;
	}
	BOOL overflow = (rwx_width * 3 + spacing * 2 > max_width);

	NSPoint point = NSMakePoint(
		frame.origin.x + padding_left,
		frame.origin.y + offset_y
	);
	
/*	if([self alignment] == NSRightTextAlignment) {
		point.x = NSMaxX(frame) - [s0 size].width - padding_right;
	} */
	NSPoint left_point = point;
	NSPoint middle_point = point;
	middle_point.x += rwx_width + spacing;
	NSPoint right_point = point;
	right_point.x += rwx_width + spacing + rwx_width + spacing;
	
	
	if(!overflow) {
		if(bits & 04000) {
			[[NSColor redColor] set];
			NSRect r = frame;
			r.origin.x = left_point.x;
			r.size.width = rwx_width;
			NSRectFill(NSInsetRect(r, -3, 1));
		}
		if(bits & 02000) {
			[[NSColor redColor] set];
			NSRect r = frame;
			r.origin.x = middle_point.x;
			r.size.width = rwx_width;
			NSRectFill(NSInsetRect(r, -3, 1));
		}
		if(bits & 01000) {
			[[NSColor redColor] set];
			NSRect r = frame;
			r.origin.x = right_point.x;
			r.size.width = rwx_width;
			NSRectFill(NSInsetRect(r, -3, 1));
		}
		{
			NSPoint p = left_point;
			p.x = floorf(p.x);
			p.y = floorf(p.y);
			[s0 drawAtPoint:p];
			p.x = p.x + (rwx_width - width1) / 2;
			p.x = roundf(p.x);
			[s1 drawAtPoint:p];
			p.x = left_point.x + rwx_width - width2;
			p.x = ceilf(p.x);
			[s2 drawAtPoint:p];
		}
		{
			NSPoint p = middle_point;
			p.x = floorf(p.x);
			p.y = floorf(p.y);
			[s3 drawAtPoint:p];
			p.x = p.x + (rwx_width - width4) / 2;
			p.x = roundf(p.x);
			[s4 drawAtPoint:p];
			p.x = middle_point.x + rwx_width - width5;
			p.x = ceilf(p.x);
			[s5 drawAtPoint:p];
		}
		{
			NSPoint p = right_point;
			p.x = floorf(p.x);
			p.y = floorf(p.y);
			[s6 drawAtPoint:p];
			p.x = p.x + (rwx_width - width7) / 2;
			p.x = roundf(p.x);
			[s7 drawAtPoint:p];
			p.x = right_point.x + rwx_width - width8;
			p.x = ceilf(p.x);
			[s8 drawAtPoint:p];
		}

	} else {
		// NSString* s = [NSString stringWithFormat:@"%3o", (int)orig_bits];
		// NSAttributedString* s3 = [[[NSAttributedString alloc] initWithString:s] autorelease];
		NSAttributedString* s = [self prettyOctal:orig_bits];
		
		point.x = floorf(point.x);
		point.y = floorf(point.y);
		[s drawAtPoint:point];
	}
	

	[[NSGraphicsContext currentContext] restoreGraphicsState];
	/*uint64_t t1 = mach_absolute_time();
	double elapsed0 = subtract_times(t1, t0);*/
	// LOG_DEBUG(@"%.6fs", elapsed0);
}

-(NSAttributedString*)pretty:(NSUInteger)bits {
	NSMutableAttributedString* s = [[NSMutableAttributedString alloc] init];
	[s appendAttributedString:((bits & 4) ? m_rbit : m_dash)];
	[s appendAttributedString:((bits & 2) ? m_wbit : m_dash)];
	[s appendAttributedString:((bits & 1) ? m_xbit : m_dash)];
	return s;
}

-(NSAttributedString*)prettyOctal:(NSUInteger)bits {
	NSMutableAttributedString* s = [[NSMutableAttributedString alloc] init];
	int i;
	for(i=0; i<3; i++) {
		NSAttributedString* as = m_dash;
		switch((bits >> ((2 - i) * 3)) & 7) {
		case 1: as = m_value1; break;
		case 2: as = m_value2; break;
		case 3: as = m_value3; break;
		case 4: as = m_value4; break;
		case 5: as = m_value5; break;
		case 6: as = m_value6; break;
		case 7: as = m_value7; break;
		}
		[s appendAttributedString:as];
	}
	return s;
}

-(void)rebuildStrings {
	NSColor* color0 = [self color0];
	NSColor* color1 = [self color1];
	NSFont* font = [self font];

	NSMutableDictionary* attr0 = [[NSMutableDictionary alloc] init];
	if(color0) [attr0 setObject:color0 forKey:NSForegroundColorAttributeName];
	if(font) [attr0 setObject:font forKey:NSFontAttributeName];
	NSMutableDictionary* attr1 = [[NSMutableDictionary alloc] init];
	if(color1) [attr1 setObject:color1 forKey:NSForegroundColorAttributeName];
	if(font) [attr1 setObject:font forKey:NSFontAttributeName];

	NSAttributedString* s_dash = [[NSAttributedString alloc] 
		initWithString:@"-" attributes:attr1];
	NSAttributedString* s_r = [[NSAttributedString alloc] 
		initWithString:@"r" attributes:attr0];
	NSAttributedString* s_w = [[NSAttributedString alloc] 
		initWithString:@"w" attributes:attr0];
	NSAttributedString* s_x = [[NSAttributedString alloc] 
		initWithString:@"x" attributes:attr0];
	NSAttributedString* s_1 = [[NSAttributedString alloc] 
		initWithString:@"1" attributes:attr0];
	NSAttributedString* s_2 = [[NSAttributedString alloc] 
		initWithString:@"2" attributes:attr0];
	NSAttributedString* s_3 = [[NSAttributedString alloc] 
		initWithString:@"3" attributes:attr0];
	NSAttributedString* s_4 = [[NSAttributedString alloc] 
		initWithString:@"4" attributes:attr0];
	NSAttributedString* s_5 = [[NSAttributedString alloc] 
		initWithString:@"5" attributes:attr0];
	NSAttributedString* s_6 = [[NSAttributedString alloc] 
		initWithString:@"6" attributes:attr0];
	NSAttributedString* s_7 = [[NSAttributedString alloc] 
		initWithString:@"7" attributes:attr0];
		
	[self setRbit:s_r];
	[self setWbit:s_w];
	[self setXbit:s_x];   
	[self setValue1:s_1];
	[self setValue2:s_2];
	[self setValue3:s_3];
	[self setValue4:s_4];
	[self setValue5:s_5];
	[self setValue6:s_6];
	[self setValue7:s_7];
	[self setDash:s_dash];
}

@end
