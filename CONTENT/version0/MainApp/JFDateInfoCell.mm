/*********************************************************************
JFDateInfoCell.h - experimental date span cell
Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#include "JFDateInfoCell.h"

@interface JFDateInfoCell (Private)
-(void)initOurStuff;
@end

@implementation JFDateInfoCell

-(id)init {
	if(self = [super init]) {
		[self initOurStuff];
	}
	return self;
}

-(id)initWithCoder:(NSCoder *)decoder {
	if(self = [super initWithCoder:decoder]) {
		[self initOurStuff];
	}
	return self;
}

-(void)initOurStuff {
	m_hidden = NO;
	m_error = 0;
	m_value0 = 0.0;
	m_value1 = 0.3333;
	m_value2 = 0.6666;
	m_value3 = 1.1;
	m_color0 = [[NSColor colorWithCalibratedWhite:0.25 alpha:1.0] retain];
	m_color1 = [[NSColor blackColor] retain];
	m_color2 = [[NSColor colorWithCalibratedRed:0.892 green:0.646 blue:0.096 alpha:1.000] retain];
	m_color3 = [[NSColor redColor] retain];
	m_color_error = [[NSColor grayColor] retain];
}

-(void)setHidden:(BOOL)v {
	m_hidden = v;
}

-(void)setError:(int)v {
	m_error = v;
}

-(void)setValue0:(float)v {
	m_value0 = v;
}

-(void)setValue1:(float)v {
	m_value1 = v;
}

-(void)setValue2:(float)v {
	m_value2 = v;
}

-(void)setValue3:(float)v {
	m_value3 = v;
}

-(void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	if(m_hidden) {
		// there is nothing to see.. so we do nothing
		return;
	}
	
	if(m_error) {
		[m_color_error set];
		NSRectFill(cellFrame);
		return;
	}
	
	float paddingx = 0;
	float paddingy = 3;

	{
		float a = m_value0;
		float b = m_value3;
		if(b < a) {
			b = m_value0;
			a = m_value3;
			[m_color3 set];
		} else {
			[m_color0 set];
		}
		b -= a;
	
		float c = -2;
		float d = 2;
		NSRect r = NSInsetRect(cellFrame, paddingx, paddingy);
		r.origin.x = NSWidth(cellFrame) * a + NSMinX(cellFrame) + c;
		r.size.width = NSWidth(cellFrame) * b + d;
		r = NSIntersectionRect(NSIntegralRect(r), cellFrame);
		NSRectFill(r);
	}
	{
		float a = m_value2;
		float b = 0;
		float c = -2;
		float d = 2;
		NSRect r = NSInsetRect(cellFrame, paddingx, paddingy);
		r.origin.x = NSWidth(cellFrame) * a + NSMinX(cellFrame) + c;
		r.size.width = NSWidth(cellFrame) * b + d;
		r.size.height *= 0.5;
		r = NSIntersectionRect(NSIntegralRect(r), cellFrame);
		[m_color1 set];
		NSRectFill(r);
	}
	{
		float a = m_value1;
		float b = 0;
		float c = -2;
		float d = 2;
		NSRect r = NSInsetRect(cellFrame, paddingx, paddingy);
		r.origin.x = NSWidth(cellFrame) * a + NSMinX(cellFrame) + c;
		r.size.width = NSWidth(cellFrame) * b + d;
		r = NSIntersectionRect(NSIntegralRect(r), cellFrame);
		[m_color2 set];
		NSRectFill(r);
	}
	{
		float a = m_value2;
		float b = 0;
		float c = -2;
		float d = 2;
		NSRect r = NSInsetRect(cellFrame, paddingx, paddingy);
		r.origin.x = NSWidth(cellFrame) * a + NSMinX(cellFrame) + c;
		r.size.width = NSWidth(cellFrame) * b + d;
		r.size.height *= 0.5;
		r.origin.y += r.size.height;
		r = NSIntersectionRect(NSIntegralRect(r), cellFrame);
		[m_color1 set];
		NSRectFill(r);
	}
}

-(void)dealloc {
	[m_color0 release];           
	[m_color1 release];           
	[m_color2 release];           
	[m_color3 release];           
	[m_color_error release];
    [super dealloc];
}

@end
