/*********************************************************************
JFSizeInfoCell.h - experimental size indicator cell
Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#include "JFSizeInfoCell.h"

@interface JFSizeInfoCell (Private)
-(void)initOurStuff;
@end

@implementation JFSizeInfoCell

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
	m_size = 12345;
	// m_color = [[NSColor blackColor] retain];
	// m_color = [[NSColor grayColor] retain];
	m_color = [[NSColor colorWithCalibratedWhite:0.25 alpha:1.0] retain];
	m_layout = kJFSizeInfoCellLayoutBarLeft;
}

-(void)setSize:(uint64_t)size {
	m_size = size;
}

-(void)setLayout:(JFSizeInfoCellLayout)layout {
	m_layout = layout;
}

-(void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	// float padding = 3;
	float padding = 0;
	
	float v = 0; 
	
	if(m_size > 0) {
		double lv = m_size;
		lv = log(lv);
		lv /= M_LN2; // same as lv /= log(2);
		lv -= 8;  // 8 bits is about 256 bytes 
		lv /= 25; // 33-8 bits is about 8 gigabytes
		if(lv < 0) lv = 0.01;
		if(lv > 1) lv = 1;
		v = static_cast<float>(lv);
	}

	float a, b, c;
	switch(m_layout){
	case kJFSizeInfoCellLayoutBarLeft: 
		a = 1 - v;
		b = v;
		c = 0;
		break;
	case kJFSizeInfoCellLayoutBarMiddle: 
		a = 0.5 - v * 0.5;
		b = v;
		c = 0;
		break;
	case kJFSizeInfoCellLayoutBarRight: 
		a = 0;
		b = v;
		c = 0;
		break;
	case kJFSizeInfoCellLayoutSparkLeft: 
		a = 1 - v;
		b = 0;
		c = 1;
		break;
	case kJFSizeInfoCellLayoutSparkRight: 
		a = v;
		b = 0;
		c = 1;
		break;
	default:
		a = 0;
		b = 1;
		c = 0;
	}
	
	NSRect r = NSInsetRect(cellFrame, padding, padding);
	r.origin.x = NSWidth(cellFrame) * a + NSMinX(cellFrame);
	r.size.width = NSWidth(cellFrame) * b + c;
	r = NSIntersectionRect(NSIntegralRect(r), cellFrame);
	[m_color set];
	NSRectFill(r);
}

-(void)dealloc {
	[m_color release];
    [super dealloc];
}

@end
