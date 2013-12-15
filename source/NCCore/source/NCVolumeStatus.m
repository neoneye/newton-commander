//
//  NCVolumeStatus.m
//  NCCore
//
//  Created by Simon Strandgaard on 04/08/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NCVolumeStatus.h"
#import "NCCommon.h"


@interface NCVolumeStatus ()

@property (nonatomic) BOOL active;

-(void)updateTooltip;
@end

@implementation NCVolumeStatus

@synthesize active = _active;
@synthesize capacity = _capacity;
@synthesize available = _available;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.active = YES;
		self.capacity = 100000000;
		self.available = 25000000;
    }
    return self;
}

-(id)initWithCoder:(NSCoder*)coder {
	// our superclass supports NSCoding
    self = [super initWithCoder:coder];
    if (self) {
		self.active = YES;
		self.capacity = 100000000;
		self.available = 25000000;
    }
    return self;
}

- (void)setCapacity:(unsigned long long)n {
	_capacity = n;
	[self setNeedsDisplay:YES];
	[self updateTooltip];
}

- (void)setAvailable:(unsigned long long)n {
	_available = n;
	[self setNeedsDisplay:YES];
	[self updateTooltip];
}

-(void)activate {
	self.active = YES;
    [self setNeedsDisplay:YES];
}

-(void)deactivate {
	self.active = NO;
    [self setNeedsDisplay:YES];
}

-(void)updateTooltip {
	unsigned long long capacity = _capacity;
	unsigned long long available = _available;
	long long used = capacity - available;
	NSString* tooltip = nil;
	if(used < 0) {
		// something is wrong. one cannot use a negative amount of diskspace, just show the info as it is.
		tooltip = [NSString stringWithFormat:
			@"avail: %llu  capacity: %llu", 
			available, 
			capacity
		];
	} else {
		int usage = (capacity > 0) ? (used * 100 / capacity) : 0;
		tooltip = [NSString stringWithFormat:
			@"%i %% used [%@] of the capacity [%@]. Available space [%@].", 
			usage, 
			NCSuffixStringForBytes(used), 
			NCSuffixStringForBytes(capacity),
			NCSuffixStringForBytes(available)
		];
	}
	[self setToolTip:tooltip];
}

- (void)drawRect:(NSRect)dirtyRect {
	NSRect rect = [self bounds];
	
	NSColor* color_left = [NSColor colorWithCalibratedRed:0.0 green:1.0 blue:0.0 alpha:1.000];
	NSColor* color_right = [NSColor colorWithCalibratedRed:0.0 green:1.0 blue:0.0 alpha:1.000];
	NSColor* color_top = [NSColor colorWithCalibratedRed:0.0 green:1.0 blue:0.0 alpha:1.000];
	NSColor* color_bottom = [NSColor colorWithCalibratedRed:0.0 green:1.0 blue:0.0 alpha:1.000];
	
	color_top = [NSColor colorWithCalibratedRed:0.071 green:0.074 blue:0.074 alpha:1.000];
	color_bottom = [NSColor colorWithCalibratedRed:0.390 green:0.403 blue:0.403 alpha:1.000];
	color_right = [NSColor colorWithCalibratedRed:0.390 green:0.403 blue:0.403 alpha:1.000];
	color_left = [NSColor colorWithCalibratedRed:0.103 green:0.106 blue:0.106 alpha:1.000];
	color_right = nil;
	// color_bottom = nil;    /**/

    NSGradient* grad = [[NSGradient alloc] initWithColorsAndLocations:
		[NSColor colorWithCalibratedWhite:0.151 alpha:1.000], 0.0,
		[NSColor colorWithCalibratedWhite:0.144 alpha:1.000], 0.3,
		[NSColor colorWithCalibratedWhite:0.160 alpha:1.000], 0.6,
		[NSColor colorWithCalibratedWhite:0.209 alpha:1.000], 1.0,
		nil];
    [grad drawInRect:rect angle:90.0];

	if(color_left) {
		NSRect slice, junk;
		NSDivideRect(rect, &slice, &junk, 1, NSMinXEdge);
		[color_left set];
		NSRectFill(slice);
	}
	if(color_right) {
		NSRect slice, junk;
		NSDivideRect(rect, &slice, &junk, 1, NSMaxXEdge);
		[color_right set];
		NSRectFill(slice);
	}
	if(color_top) {
		NSRect slice, junk;
		NSDivideRect(rect, &slice, &junk, 1, NSMaxYEdge);
		[color_top set];
		NSRectFill(slice);
	}
	if(color_bottom) {
		NSRect slice, junk;
		NSDivideRect(rect, &slice, &junk, 1, NSMinYEdge);
		[color_bottom set];
		NSRectFill(slice);
	}
	
	NSColor* fill_color_active = [NSColor colorWithCalibratedRed:0.000 green:0.411 blue:0.964 alpha:1.000];
	NSColor* fill_color_inactive = [NSColor colorWithCalibratedRed:0.479 green:0.480 blue:0.479 alpha:1.000];
	NSColor* fill_color = self.active ? fill_color_active : fill_color_inactive;

	if(_available <= _capacity) {
		unsigned long long used = _capacity - _available;
		double percent = (_capacity > 1) ? (double)used / (double)_capacity : 0;
		NSRect rect2 = NSInsetRect(rect, 6, 6);
		NSRect slice, junk;
		NSDivideRect(rect2, &slice, &junk, NSWidth(rect2) * percent, NSMinXEdge);
		[fill_color set];
		NSRectFill(slice); 
	}
	/**/


	NSColor *txtColor = [NSColor whiteColor];

	NSShadow* shadow = [[NSShadow alloc] init];
	CGFloat shadowAlpha = 0.8;
	[shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.2 alpha:shadowAlpha]];
	[shadow setShadowOffset:NSMakeSize(0, -1)];
	[shadow setShadowBlurRadius:1.0];


	NSFont *txtFont = [NSFont boldSystemFontOfSize:11];
	NSDictionary *txtDict = [NSDictionary dictionaryWithObjectsAndKeys:
        txtFont, NSFontAttributeName, 
		txtColor, NSForegroundColorAttributeName, 
		shadow, NSShadowAttributeName, 
		nil];

	NSString* s = NCSuffixStringForBytes(_available);
	NSAttributedString* as = [[NSAttributedString alloc]
	        initWithString:s attributes:txtDict];


	NSAttributedString* title = as;
	NSSize textSize = [title size];

	NSRect frame = NSInsetRect(rect, 8, 8);

	frame.origin.x += (NSWidth(frame) - textSize.width) / 2.0;
	frame.origin.y += (NSHeight(frame) - textSize.height) / 2.0;
	frame.size.height = textSize.height;

	[title drawAtPoint: frame.origin];

}

@end
