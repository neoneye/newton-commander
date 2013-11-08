//
//  NCTabBar.m
//  NCCore
//
//  Created by Simon Strandgaard on 24/01/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "NCTabBar.h"


@implementation NCTabBar

@synthesize selectedIndex = m_selected_index;
@synthesize numberOfTabs = m_number_of_tabs;
@synthesize isActive = m_is_active;

-(BOOL)acceptsFirstResponder {
	return NO;
	NSLog(@"%s NCTabBar", _cmd);
	return YES;
}

- (void)keyDown:(NSEvent *)theEvent {
	// NSLog(@"NCTabBar %s %@", _cmd, theEvent);
	NSLog(@"NCTabBar %s", _cmd);
	[super keyDown:theEvent];
}

- (void)awakeFromNib
{
	// NSLog(@"NCTabBar %s", _cmd);
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		m_selected_index = 2;
		m_number_of_tabs = 4;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super initWithCoder:decoder]) != nil)
	{
		m_selected_index = 0;
		m_number_of_tabs = 1;
	}
	return self;
}

- (void)drawRect:(NSRect)rect {
	NSRect r = [self bounds];

	NSMutableDictionary* attr0 = [[[NSMutableDictionary alloc] init] autorelease];
	[attr0 setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	[attr0 setObject:[NSFont boldSystemFontOfSize:14] forKey:NSFontAttributeName];

	NSMutableDictionary* attr1 = [[[NSMutableDictionary alloc] init] autorelease];
	[attr1 setObject:[NSColor colorWithCalibratedRed:0.8
		                           green:0.8
		                            blue:0.85
		                           alpha:1.0] forKey:NSForegroundColorAttributeName];
	[attr1 setObject:[NSFont systemFontOfSize:14] forKey:NSFontAttributeName];

	{
		NSColor* color = nil;
		if(m_is_active) {
			color = [NSColor colorWithCalibratedRed:0.5
				                           green:0.61
				                            blue:0.78
				                           alpha:1.0];
		
			// [[NSColor blueColor] set];
		} else {
			color = [NSColor colorWithCalibratedRed:0.83
				                           green:0.83
				                            blue:0.83
				                           alpha:1.0];
			// [[NSColor grayColor] set];
		}
		[color set];
		NSRectFill(NSIntegralRect(r));
	}
	
	int n = m_number_of_tabs;
	int i = 0;
	int selected_index = m_selected_index;
	for(; i < n; i++) {

		NSRect r0 = NSMakeRect(
			NSMinX(r) + NSHeight(r) * i, 
			NSMinY(r),
			NSHeight(r),
			NSHeight(r)
		);
		NSRect r1 = NSInsetRect(r0, 4, 4);

		NSUInteger tab_index = i + 1;
		NSString* s = [NSString stringWithFormat:@"%lu", tab_index];
		NSMutableDictionary* attr = (i == selected_index) ? attr0 : attr1;
		NSAttributedString* as = [[[NSAttributedString alloc] 
			initWithString:s attributes:attr] autorelease];

		NSRect boundingRect = [as boundingRectWithSize:r0.size options:0];

		
		NSColor* color = nil;
		if(m_is_active) {
			if(i == selected_index) {
				color = [NSColor whiteColor];
			} else {
				color = [NSColor colorWithCalibratedRed:0.15
						                           green:0.25
						                            blue:0.45
						                           alpha:1.0];
			}
		} else {
			if(i == selected_index) {
				color = [NSColor colorWithCalibratedRed:0.95
						                           green:0.95
						                            blue:0.95
						                           alpha:1.0];
			} else {
				color = [NSColor colorWithCalibratedRed:0.4
						                           green:0.4
						                            blue:0.4
						                           alpha:1.0];
			}
		}
		[color set];

		NSRectFill(NSIntegralRect(r1));


		NSPoint rectCenter;
		rectCenter.x = r0.size.width / 2 + r0.origin.x;
		rectCenter.y = r0.size.height / 2;

		NSPoint drawPoint = rectCenter;
		drawPoint.x -= boundingRect.size.width / 2;
		drawPoint.y -= boundingRect.size.height / 2;

		drawPoint.x = roundf(drawPoint.x);
		drawPoint.y = roundf(drawPoint.y);

		[as drawAtPoint:drawPoint];

	}
}

-(void)mouseDown:(NSEvent*)event {

	NSPoint loc1 = [event locationInWindow];
	NSPoint point1 = [self convertPoint:loc1 fromView:nil];
	NSRect bounds = [self bounds];

	do {
		NSEventType event_type = [event type];
		if(event_type == NSLeftMouseUp) {
			float v = (point1.x - NSMinX(bounds))  / NSHeight(bounds);
			// NSLog(@"%s click %.3f %.3f", _cmd, point1.x, v);
			m_selected_index = (int)floorf(v);
		 	[self setNeedsDisplay:YES];
			break;
		}
		
		if(event_type == NSKeyDown) {
			unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0];
			if(key == 27) {
				// escape key: Cancel the current action
				break;
			} else {
				// discard all other keyevents than escape
			}
			continue;
		}
		
		if ((event_type == NSLeftMouseDragged) ||
		 	(event_type == NSLeftMouseDown))
		{
			//TRACE("drag");

			NSPoint loc = [event locationInWindow];
			NSPoint point = [self convertPoint:loc fromView:nil];
			NSPoint diff = NSMakePoint(
				point1.x - point.x,
				point1.y - point.y
			);

			// distance from mousedown location
			float dist = diff.x * diff.x + diff.y * diff.y;

			if(dist > 4) {
				
				break;
			}


		} else {
			// discard all other events
		}
        event = [[self window] nextEventMatchingMask:NSAnyEventMask];
	} while(event);

	
}

/*- (void)keyDown:(NSEvent *)event {
	// NSLog(@"%s %@", _cmd, theEvent);
	
	NSString *characters;
	characters = [event characters];

	unichar character;
	character = [characters characterAtIndex: 0];

	if (character == NSLeftArrowFunctionKey) {
		if(m_selected_index > 0) {
			m_selected_index -= 1;
		 	[self setNeedsDisplay:YES];
		}
		return;

	}
	
	if (character == NSRightArrowFunctionKey) {
		if(m_selected_index < 3) {
			m_selected_index += 1;
		 	[self setNeedsDisplay:YES];
		}
		return;
	}

	[super keyDown:event];
}/**/

+(NSString*)testInfo {
	return @"NCTabBar test";
}

-(IBAction)newTab:(id)sender {
	// NSLog(@"%s tabbar", _cmd);
	m_selected_index += 1;
	m_number_of_tabs += 1;
	if(m_selected_index >= m_number_of_tabs) m_selected_index = m_number_of_tabs - 1;
 	[self setNeedsDisplay:YES];
}

-(IBAction)switchToNextTab:(id)sender {
	m_selected_index += 1;
	if(m_selected_index >= m_number_of_tabs) m_selected_index = 0;
 	[self setNeedsDisplay:YES];
}

-(IBAction)switchToPrevTab:(id)sender {
	m_selected_index -= 1;
	if(m_selected_index < 0) m_selected_index = m_number_of_tabs - 1;
 	[self setNeedsDisplay:YES];
}

-(void)closeTab:(id)sender {
	m_number_of_tabs -= 1;
	if(m_number_of_tabs < 1) m_number_of_tabs = 1;
	if(m_selected_index >= m_number_of_tabs) m_selected_index = m_number_of_tabs - 1;
 	[self setNeedsDisplay:YES];
}

@end
