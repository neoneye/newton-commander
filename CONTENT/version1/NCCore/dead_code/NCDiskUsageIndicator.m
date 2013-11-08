//
//  NCDiskUsageIndicator.m
//  NCCore
//
//  Created by Simon Strandgaard on 03/05/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#if 0
/*
Usage: in AppDelegate
*/
-(void)refreshVolumeInfo {
	NSString* wdir = [self activeWorkingDir];
	if(!wdir) {
		return;
	}

	NSFileManager* fm = [NSFileManager defaultManager];
	NSDictionary* dict = [fm attributesOfFileSystemForPath:wdir error:NULL];
	if(dict == nil) {
		return;
	}

	NSNumber* fs_capacity1 = [dict objectForKey:NSFileSystemSize];
	NSNumber* fs_avail1    = [dict objectForKey:NSFileSystemFreeSize];
	
	long long fs_capacity = 0;
	long long fs_avail = 0;
	
	if(fs_capacity1 != nil) {
		fs_capacity = [fs_capacity1 longLongValue];
	}
	if(fs_avail1 != nil) {
		fs_avail = [fs_avail1 longLongValue];
	}
	
	long long fs_used = fs_capacity - fs_avail;

	int usage = 0;
	float level = 0;
	
	if(fs_capacity > 0) {
		usage = fs_used * 100 / fs_capacity;
		level = fs_used * 10.f / fs_capacity + 0.25f;
	}
	
	NSString* tooltip = [NSString stringWithFormat:
		@"%i %% used [%@] of the capacity [%@]", 
		usage, 
		NCSuffixStringForBytes(fs_used), 
		NCSuffixStringForBytes(fs_capacity)
	];

	NSString* text = [NSString stringWithFormat:@"%@ available", NCSuffixStringForBytes(fs_avail)];
	
	[[m_toolbar diskUsage] setCapacity:fs_capacity];
	[[m_toolbar diskUsage] setAvailable:fs_avail];
	[m_toolbar setDiskUsageLabel:text];
	[m_toolbar setDiskUsageToolTip:tooltip];
}
#endif





#import "NCDiskUsageIndicator.h"
#import "NSGradient+PredefinedGradients.h"
#import "NCCommon.h"


@interface NSBezierPath (AFAdditions)
- (void)applyInnerShadow:(NSShadow *)shadow;
@end

@implementation NSBezierPath (AFAdditions)

- (void)applyInnerShadow:(NSShadow *)shadow {
        [NSGraphicsContext saveGraphicsState];
        
        NSShadow *shadowCopy = [shadow copy];
        
        NSSize offset = shadowCopy.shadowOffset;
        CGFloat radius = shadowCopy.shadowBlurRadius;
        
        NSRect bounds = NSInsetRect(self.bounds, -(ABS(offset.width) + radius), -(ABS(offset.height) + radius));
        
        offset.height += bounds.size.height;
        shadowCopy.shadowOffset = offset;
        
        NSAffineTransform *transform = [NSAffineTransform transform];
        [transform translateXBy:0 yBy:([[NSGraphicsContext currentContext] isFlipped] ? 1 : -1) * bounds.size.height];
        
        NSBezierPath *drawingPath = [NSBezierPath bezierPathWithRect:bounds];
        [drawingPath setWindingRule:NSEvenOddWindingRule];
        
        [drawingPath appendBezierPath:self];
        [drawingPath transformUsingAffineTransform:transform];
        
        [self addClip];
        [shadowCopy set];
        
        [[NSColor blackColor] set];
        [drawingPath fill];
        
        [shadowCopy release];
        
        [NSGraphicsContext restoreGraphicsState];
}

@end

@implementation NCDiskUsageIndicator

@synthesize capacity = m_capacity;
@synthesize available = m_available;

- (void)setCapacity:(unsigned long long)n {
	m_capacity = n;
	[self setNeedsDisplay:YES];
}

- (void)setAvailable:(unsigned long long)n {
	m_available = n;
	[self setNeedsDisplay:YES];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {

/*	[[NSColor redColor] set];
	NSRectFill(dirtyRect); 
	/**/

	float usage = 0.5;
	if(m_capacity > 0) {
		double avail = (double)m_available / (double)m_capacity;
		usage = 1.0 - avail;
	}


	NSGradient* grad2 = [NSGradient blueSelectedRowGradient];
	NSGradient* grad = [NSGradient grayDiskUsageGradient];
	// [grad drawInRect:[self bounds] angle:90.0]; 

	NSRect rect1 = [self bounds];
	rect1 = NSInsetRect(rect1, 5, 5);
	rect1.origin.x = round(rect1.origin.x);
	rect1.origin.y = round(rect1.origin.y);
	rect1 = NSIntegralRect(rect1);

	NSRect rect2 = rect1;
	rect2 = NSInsetRect(rect2, 1, 1);
	rect2.size.width = round(rect2.size.width * usage);

	rect1.origin.x += 0.5;
	rect1.origin.y += 0.5;
	rect2.origin.x += 0.5;
	rect2.origin.y += 0.5;

/*	NSShadow *shadow = [[NSShadow alloc] init];
	NSSize shOffset = { width: 0.0, height: -2.0};
	[shadow setShadowOffset:shOffset];
	// [shadow setShadowColor:[NSColor blueColor]];
	[shadow setShadowBlurRadius: 3];
	[shadow setShadowColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.7]];
*/

	if((NSWidth(rect1) < 1.5) || (NSHeight(rect1) < 1.5)) {
		return;
	}
	
	NSBezierPath* outerPath = [NSBezierPath bezierPathWithRoundedRect:rect1 xRadius:3.0 yRadius:3.0];

	// [NSGraphicsContext saveGraphicsState];
	// [shadow set];
    // [[NSColor blackColor] set];
	// [[NSColor whiteColor] setFill];
    // [outerPath setWindingRule:NSEvenOddWindingRule];
    // [outerPath fill];
	// [NSGraphicsContext restoreGraphicsState];

	[grad drawInBezierPath:outerPath angle:90.0];

	if((NSWidth(rect2) >= 1.5) && (NSHeight(rect2) >= 1.5)) {
		NSBezierPath* innerPath = [NSBezierPath bezierPathWithRoundedRect:rect2 xRadius:3.0 yRadius:3.0];
		[grad2 drawInBezierPath:innerPath angle:90.0];
	}
	
	// [outerPath applyInnerShadow:shadow];

	NSColor* strokeColor = [NSColor colorWithCalibratedWhite:0.403 alpha:1.000];
	[strokeColor setStroke];
	[outerPath stroke];

}

@end
