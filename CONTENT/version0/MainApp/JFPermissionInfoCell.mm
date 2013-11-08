/*********************************************************************
JFPermissionInfoCell.mm - experimental posix permission indicator cell
Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#include "JFPermissionInfoCell.h"

@interface JFPermissionInfoCell (Private)
-(void)initOurStuff;
@end

@implementation JFPermissionInfoCell

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
	m_colors[0] = [NSColor colorWithCalibratedRed:0.304 green:0.643 blue:0.693 alpha:1.000];
	m_colors[1] = [NSColor colorWithCalibratedRed:0.235 green:0.211 blue:0.227 alpha:1.000];
	m_colors[2] = [NSColor colorWithCalibratedRed:0.172 green:0.148 blue:0.165 alpha:1.000];
	m_colors[3] = [NSColor colorWithCalibratedRed:0.304 green:0.643 blue:0.693 alpha:1.000];
	m_colors[4] = [NSColor colorWithCalibratedRed:0.235 green:0.211 blue:0.227 alpha:1.000];
	m_colors[5] = [NSColor colorWithCalibratedRed:0.172 green:0.148 blue:0.165 alpha:1.000];
	m_colors[6] = [NSColor colorWithCalibratedRed:0.304 green:0.643 blue:0.693 alpha:1.000];
	m_colors[7] = [NSColor colorWithCalibratedRed:0.235 green:0.211 blue:0.227 alpha:1.000];
	m_colors[8] = [NSColor colorWithCalibratedRed:0.172 green:0.148 blue:0.165 alpha:1.000];
	
	for(int i=0; i<9; ++i) [m_colors[i] retain];
	
	m_permissions = 0777;
}

-(void)setPermissions:(NSUInteger)perm {
	m_permissions = perm;
}

-(void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	NSRect r0 = NSInsetRect(cellFrame, 6, 0);


	int perm = m_permissions;
	int mask = 0400;

	for(int i=0; i<9; ++i) {
		int v = perm & mask;
		
		mask >>= 1;

		if(v) {
			[m_colors[i] set];
		} else {
			continue;
		}

		float a, b;

/*		a = static_cast<float>(i) / (9.f + 1.f);
		b = 1.f / (9.f + 1.f);
		if(i > 2) a += 0.05f;
		if(i > 5) a += 0.05f;*/
		a = static_cast<float>(i) / 9.f;
		b = 1.f / 9.f;
		
		NSRect r = r0;
		r.origin.x = NSWidth(r0) * a + NSMinX(r0);
		r.size.width = NSWidth(r0) * b;
		r = NSIntersectionRect(NSIntegralRect(r), r0);
		NSRectFill(r);
	}
}

-(void)dealloc {
	for(int i=0; i<9; ++i) [m_colors[i] release];

    [super dealloc];
}

@end
