//
//  NCPathControl.m
//  NCCore
//
//  Created by Simon Strandgaard on 02/08/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

/*
NSPathControl alternatives


UKFilePathView
http://github.com/uliwitness/UliKit/blob/master/UKFilePathView.h

GCJumpBar
http://cocoacontrols.com/platforms/mac-os-x/controls/gcjumpbar

subclassing NSPathControl and providing a custom NSPathComponentCell. (www.binarynights.com)
http://www.cocoabuilder.com/archive/cocoa/226871-design-advice-bread-crumbs-nspathcontrol.html

*/

#import "NCPathControl.h"
#import "NSGradient+PredefinedGradients.h"


@implementation NCPathControl

@synthesize path = m_path;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		self.path = @"/test/long/path";
		[self rebuild];
    }
    return self;
}

-(id)initWithCoder:(NSCoder*)coder {
	// our superclass supports NSCoding
    if (self = [super initWithCoder: coder]) {
        [self setPath:[coder decodeObjectForKey: @"path"]];
		if(self.path == nil) {
			self.path = @"/test/long/path";
		}
		[self rebuild];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder*)coder {
	// our superclass supports NSCoding
	[super encodeWithCoder:coder];
	
    [coder encodeObject:m_path  forKey:@"path"];
}

/*-(id)copyWithZone:(NSZone*)zone {
	NCPathControl* cell = (NCPathControl*)[super copyWithZone:zone];

	if(cell) {
		cell->m_path = [m_path retain];
	}

	return cell;
}*/

- (void)setPath:(NSString*)value {
    if (value != m_path) {
        m_path = value;
    }
	[self rebuild];
	[self setNeedsDisplay:YES];
}

-(void)rebuild {
	NSString* path = m_path;
	if(!path) return;
	
	id cell = [[NCPathCell alloc] init];
	[self setCell:cell]; /**/

	NSMutableArray* ary = [NSMutableArray array];
	
	NSCharacterSet* charset = [NSCharacterSet controlCharacterSet];
	
	NSArray* components = [path pathComponents];

	int n = [components count];
	int i = 0;
	for(__strong NSString* component in components) {
		NCPathComponentCell* cc = [[NCPathComponentCell alloc] init];
		[cc setImage:nil];

		// filter out control characters
		component = [[component componentsSeparatedByCharactersInSet:charset] componentsJoinedByString:@"?"];
		
		// TODO: use the path.. don't use apple.com
		[cc setURL:[NSURL URLWithString:@"http://www.apple.com"]];
		[cc setTitle: component];
		[ary addObject: cc];

		if(i == n - 1) {
			[cc setLast:YES];
		}

		NSColor *txtColor = [NSColor whiteColor];

		// Add shadow attribute
		NSShadow* shadow = [[NSShadow alloc] init];
		CGFloat shadowAlpha = 0.8;
		
		if(i == n - 1 && m_active) {
			[shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.2 alpha:shadowAlpha]];
			[cc setActive:YES];
		} else {
			[shadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:shadowAlpha]];
			txtColor = [[NSColor textColor] colorWithAlphaComponent:0.75];
		}
		[shadow setShadowOffset:NSMakeSize(0, -1)];
		[shadow setShadowBlurRadius:1.0];

	
		NSFont *txtFont = [NSFont boldSystemFontOfSize:11];
		NSDictionary *txtDict = [NSDictionary dictionaryWithObjectsAndKeys:
		        txtFont, NSFontAttributeName, 
			txtColor, NSForegroundColorAttributeName, 
			shadow, NSShadowAttributeName, 
			nil];
			
		if(i == 0) {
			component = @"";
			[cc setFirst:YES];
		}
			
		NSAttributedString *attrStr = [[NSAttributedString alloc]
		        initWithString:component attributes:txtDict];
		[cc setAttributedStringValue:attrStr];

	
		i++;
	}


	[self setPathComponentCells: ary];
}

-(void)activate {
	m_active = YES;
	[self rebuild];
    [self setNeedsDisplay:YES];
}

-(void)deactivate {
	m_active = NO;
	[self rebuild];
    [self setNeedsDisplay:YES];
}

@end



@implementation NCPathCell

/*+ (Class)pathComponentCellClass {
  return [MyPathCell class];
} */

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
/*    NSGradient* grad = [[[NSGradient alloc] initWithColorsAndLocations:
		[NSColor colorWithCalibratedWhite:0.769 alpha:1.000], 0.0,
		[NSColor colorWithCalibratedWhite:0.663 alpha:1.000], 0.5,
		[NSColor colorWithCalibratedWhite:0.584 alpha:1.000], 1.0,
		nil] autorelease];
    [grad drawInRect:cellFrame angle:90.0]; */
/*    NSGradient* grad = [[[NSGradient alloc] initWithColorsAndLocations:
		[NSColor colorWithCalibratedWhite:0.538 alpha:1.000], 0.0,
		[NSColor colorWithCalibratedWhite:0.568 alpha:1.000], 0.053,
		[NSColor colorWithCalibratedWhite:0.598 alpha:1.000], 0.105,
		[NSColor colorWithCalibratedWhite:0.607 alpha:1.000], 0.157,
		[NSColor colorWithCalibratedWhite:0.620 alpha:1.000], 0.211,
		[NSColor colorWithCalibratedWhite:0.620 alpha:1.000], 0.947,
		[NSColor colorWithCalibratedWhite:0.300 alpha:1.000], 0.947,
		[NSColor colorWithCalibratedWhite:0.300 alpha:1.000], 1.0,
		nil] autorelease];
    [grad drawInRect:cellFrame angle:90.0]; */
    NSGradient* grad = [[NSGradient alloc] initWithColorsAndLocations:
		[NSColor colorWithCalibratedWhite:0.538 alpha:1.000], 0.0,
		[NSColor colorWithCalibratedWhite:0.568 alpha:1.000], 0.053,
		[NSColor colorWithCalibratedWhite:0.598 alpha:1.000], 0.105,
		[NSColor colorWithCalibratedWhite:0.607 alpha:1.000], 0.157,
		[NSColor colorWithCalibratedWhite:0.620 alpha:1.000], 0.211,
		[NSColor colorWithCalibratedWhite:0.620 alpha:1.000], 1.0,
		nil];
    [grad drawInRect:cellFrame angle:90.0]; /**/

/*	[[NSColor colorWithCalibratedWhite:0.447 alpha:1.000] set];
	NSRectFill(cellFrame); */

/*	[[NSColor redColor] set];
	NSRectFill(cellFrame); */
	
/*	NSRect r  = NSInsetRect(cellFrame, 2, 2);
	[[NSColor blueColor] set];
	NSRectFill(r);
	[super drawWithFrame:r inView:controlView]; */
	[self drawInteriorWithFrame:cellFrame inView:controlView];
}

@end


@implementation NCPathComponentCell

-(BOOL)isActive {
	return m_active;
}

-(void)setActive:(BOOL)value {
	m_active = value;
}

-(BOOL)isFirst {
	return m_first;
}

-(void)setFirst:(BOOL)value {
	m_first = value;
}

-(BOOL)isLast {
	return m_last;
}

-(void)setLast:(BOOL)value {
	m_last = value;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	NSGradient* grad = nil;
	if(m_active) {
		grad = [NSGradient blueSelectedRowGradient];
	} else {
		grad = [NSGradient pathControlGradient];
	} /**/


	CGFloat indent = NSHeight(cellFrame) / 4.0;

	NSBezierPath *strokePath0 = [NSBezierPath bezierPath];
	if([self isLast]) {
		[strokePath0
		   moveToPoint:NSMakePoint(NSMaxX(cellFrame), NSMinY(cellFrame))];
		[strokePath0 
		   lineToPoint:NSMakePoint(NSMaxX(cellFrame), NSMaxY(cellFrame))];  
	} else {
		[strokePath0 
		   moveToPoint:NSMakePoint(NSMaxX(cellFrame) - indent - 1, NSMinY(cellFrame))];
		[strokePath0 
		   lineToPoint:NSMakePoint(NSMaxX(cellFrame) + indent - 1, NSMidY(cellFrame))];
		[strokePath0 
		   lineToPoint:NSMakePoint(NSMaxX(cellFrame) - indent - 1, NSMaxY(cellFrame))];  
	}

	NSBezierPath *strokePath1 = [NSBezierPath bezierPath];
	if([self isLast]) {
		[strokePath1 
		   moveToPoint:NSMakePoint(NSMaxX(cellFrame), NSMinY(cellFrame))];
		[strokePath1 
		   lineToPoint:NSMakePoint(NSMaxX(cellFrame), NSMaxY(cellFrame))];  
	} else {
		[strokePath1 
		   moveToPoint:NSMakePoint(NSMaxX(cellFrame) - indent + 1, NSMinY(cellFrame))];
		[strokePath1 
		   lineToPoint:NSMakePoint(NSMaxX(cellFrame) + indent + 1, NSMidY(cellFrame))];
		[strokePath1 
		   lineToPoint:NSMakePoint(NSMaxX(cellFrame) - indent + 1, NSMaxY(cellFrame))];  
	}

	NSBezierPath *strokePath = [NSBezierPath bezierPath];
	if([self isLast]) {
		[strokePath 
		   moveToPoint:NSMakePoint(NSMaxX(cellFrame), NSMinY(cellFrame))];
		[strokePath 
		   lineToPoint:NSMakePoint(NSMaxX(cellFrame), NSMaxY(cellFrame))];  
	} else {
		[strokePath 
		   moveToPoint:NSMakePoint(NSMaxX(cellFrame) - indent, NSMinY(cellFrame))];
		[strokePath 
		   lineToPoint:NSMakePoint(NSMaxX(cellFrame) + indent, NSMidY(cellFrame))];
		[strokePath 
		   lineToPoint:NSMakePoint(NSMaxX(cellFrame) - indent, NSMaxY(cellFrame))];  
	}

	NSBezierPath *fillPath = [strokePath0 copy];
	if([self isFirst]) {
		[fillPath 
		   lineToPoint:NSMakePoint(NSMinX(cellFrame), NSMaxY(cellFrame))];
		[fillPath 
		   lineToPoint:NSMakePoint(NSMinX(cellFrame), NSMinY(cellFrame))];
	} else {
		[fillPath 
		   lineToPoint:NSMakePoint(NSMinX(cellFrame) - indent + 1, NSMaxY(cellFrame))];
		[fillPath 
		   lineToPoint:NSMakePoint(NSMinX(cellFrame) + indent + 1, NSMidY(cellFrame))];
		[fillPath 
		   lineToPoint:NSMakePoint(NSMinX(cellFrame) - indent + 1, NSMinY(cellFrame))];
	}
	[fillPath closePath];

	if((![self isActive]) && (![self isFirst])) {
		NSBezierPath* bp = [NSBezierPath bezierPath];
		[bp 
		   moveToPoint:NSMakePoint(NSMinX(cellFrame) - indent + 1, NSMaxY(cellFrame))];
		[bp 
		   lineToPoint:NSMakePoint(NSMinX(cellFrame) + indent + 1, NSMidY(cellFrame))];
		[bp 
		   lineToPoint:NSMakePoint(NSMinX(cellFrame) - indent + 1, NSMinY(cellFrame))];
		// [[NSColor colorWithCalibratedRed:0.146 green:0.251 blue:0.383 alpha:1.000] setStroke];
		[[NSColor colorWithCalibratedWhite:1.0 alpha:0.5] setStroke];
		[bp setLineWidth:1.0];
		[bp stroke];
	}

	// [[NSColor colorWithCalibratedWhite:0.0 alpha:0.2] setStroke];
	[[NSColor colorWithCalibratedWhite:0.285 alpha:1.000] setStroke];
	[strokePath setLineWidth:1.0];
	[strokePath stroke];

	if((![self isActive]) && (![self isFirst])) {
		NSBezierPath* bp = [NSBezierPath bezierPath];
		[bp 
		   moveToPoint:NSMakePoint(NSMinX(cellFrame) - indent + 1, NSMaxY(cellFrame))];
		[bp 
		   lineToPoint:NSMakePoint(NSMinX(cellFrame) + indent + 1, NSMidY(cellFrame))];
		[bp 
		   lineToPoint:NSMakePoint(NSMinX(cellFrame) - indent + 1, NSMinY(cellFrame))];
		// [[NSColor colorWithCalibratedRed:0.146 green:0.251 blue:0.383 alpha:1.000] setStroke];
		[[NSColor colorWithCalibratedWhite:1.0 alpha:0.5] setStroke];
		[bp setLineWidth:1.0];
		[bp stroke];
	}

	if([self isActive]) {
		NSBezierPath* bp = [NSBezierPath bezierPath];
		[bp 
		   moveToPoint:NSMakePoint(NSMinX(cellFrame) - indent + 1, NSMaxY(cellFrame))];
		[bp 
		   lineToPoint:NSMakePoint(NSMinX(cellFrame) + indent + 1, NSMidY(cellFrame))];
		[bp 
		   lineToPoint:NSMakePoint(NSMinX(cellFrame) - indent + 1, NSMinY(cellFrame))];
		// [[NSColor colorWithCalibratedRed:0.146 green:0.251 blue:0.383 alpha:1.000] setStroke];
		// [[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] setStroke];
		// [[NSColor colorWithCalibratedRed:0.146 green:0.251 blue:0.383 alpha:1.0] setStroke];
		// [[NSColor colorWithCalibratedRed:0.1 green:0.15 blue:0.2 alpha:1.0] setStroke];
		[[NSColor colorWithCalibratedRed:0.2 green:0.3 blue:0.4 alpha:1.0] setStroke];
		[bp setLineWidth:1.0];
		[bp stroke];
	}

	[grad drawInBezierPath:fillPath angle:90.0];


	
	if(!m_active) {
		// [[NSColor colorWithCalibratedWhite:1.0 alpha:0.8] setStroke];
		// [strokePath1 stroke];
	}

	// if([self isLast]) {
	if([self isActive]) {
		NSBezierPath* bp = [NSBezierPath bezierPath];
		[bp 
		   moveToPoint:NSMakePoint(floorf(NSMaxX(cellFrame)) + 0.5, NSMinY(cellFrame))];
		[bp 
		   lineToPoint:NSMakePoint(floorf(NSMaxX(cellFrame)) + 0.5, NSMaxY(cellFrame))];  
		// [[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] setStroke];
		[[NSColor colorWithCalibratedRed:0.146 green:0.251 blue:0.383 alpha:1.000] setStroke];
		[bp setLineWidth:1.0];
		[bp stroke];
	}

	// if([self isLast]) {
	if([self isActive]) {
		NSBezierPath* bp = [NSBezierPath bezierPath];
		[bp 
		   moveToPoint:NSMakePoint(NSMinX(cellFrame) - indent + 0, NSMaxY(cellFrame))];
		[bp 
		   lineToPoint:NSMakePoint(NSMinX(cellFrame) + indent + 0, NSMidY(cellFrame))];
		[bp 
		   lineToPoint:NSMakePoint(NSMinX(cellFrame) - indent + 0, NSMinY(cellFrame))];
		// [[NSColor colorWithCalibratedRed:0.146 green:0.251 blue:0.383 alpha:1.000] setStroke];
		// [[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] setStroke];
		[[NSColor colorWithCalibratedRed:0.146 green:0.251 blue:0.383 alpha:1.000] setStroke];
		[bp setLineWidth:1.0];
		// [bp stroke];
	}

	[self drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void) drawInteriorWithFrame:(NSRect)frame inView:(NSView *)control
{
	NSAttributedString* title = [self attributedStringValue];
	NSSize textSize = [title size];

	// CGFloat indent = NSHeight(frame) / 3.0;
	CGFloat indent = 8;
/*	if([self isFirst]) {
		indent = 8;
	} */
	
	frame.origin.x += indent;
	frame.origin.y += (frame.size.height - textSize.height) / 2.0;
	frame.size.height = textSize.height;

	if([self isFirst]) {
		frame.origin.y += 1;
	}

	if(![self isFirst]) {
		frame.origin.x += 1;
	}
	
	[title drawAtPoint: frame.origin];
}

- (NSSize) cellSize;
{
	NSAttributedString* title = [self attributedStringValue];
	NSSize textSize = [title size];
/*	if([self isFirst]) {
		textSize.width += 16;
	} else {
		textSize.width += 16;
	} */
	textSize.width += 16;
/*	if([self isLast]) {
		textSize.width += 4;
	} */
	
	return textSize;
}

@end
