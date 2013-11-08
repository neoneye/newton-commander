//
//  CombinedButtonAndPopUpCell.m
//  demo
//
//  Created by Simon Strandgaard on 12/05/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import "CombinedButtonAndPopUpCell.h"
#import "CombinedButtonAndPopUp.h"


@interface CombinedButtonAndPopUpCell ()
- (BOOL)trackMouseForButtonEvent:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView;
-(void)sendActionToTarget;
@end

@implementation CombinedButtonAndPopUpCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	NSLog(@"%s", _cmd);
	
	BOOL highlight_button = m_button_down; 
	BOOL highlight_popup = [self isHighlighted];
	
	CGRect bounds = NSRectToCGRect(cellFrame);
	CGRect bounds_inner = CGRectInset(bounds, 5, 5);
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];

    // If we have focus, draw a focus ring around the entire cellFrame (inset it a little so it looks nice).
    if ([self showsFirstResponder]) {
		// showsFirstResponder is set for us by the NSControl that is drawing us.
        NSRect focusRingFrame = cellFrame;
		[NSGraphicsContext saveGraphicsState];
		NSSetFocusRingStyle(NSFocusRingOnly);
		[[NSBezierPath bezierPathWithRect: NSInsetRect(focusRingFrame,4,4)] fill];
		[NSGraphicsContext restoreGraphicsState];
    }

	{
		NSRect r = NSInsetRect(cellFrame, 5, 5);
		NSImage* image = [NSImage imageNamed:@"combined_button_and_popup"];
	    [image setFlipped:[controlView isFlipped]];
	    [image drawInRect:r fromRect:NSMakeRect(0,0,[image size].width, [image size].height) operation:NSCompositeSourceOver fraction:1.0];
	    
	}

	{
		CGRect r = bounds_inner;

		if(highlight_button) {
			CGContextSetRGBFillColor( context, 0.5, 0.5, 0.5, 0.8 );
	    	CGContextFillRect( context, r );
		} else {
			// CGContextSetRGBFillColor( context, 0.7, 0.7, 0.7, 1.0 );
	    	// CGContextFillRect( context, r );
		}
	}

	{
		CGRect slice, remain;

		CGRectDivide(bounds_inner, &slice, &remain, 30, CGRectMaxXEdge);
		CGRect r = CGRectInset(slice, 2, 2);

		if(highlight_popup){
			CGContextSetRGBFillColor( context, 0.2, 0.2, 0.9, 0.8 );
	    	CGContextFillRect( context, r );
		} else {
			// CGContextSetRGBFillColor( context, 0.2, 0.2, 0.2, 1.0 );
	    	// CGContextFillRect( context, r );
		}
	}

	{
		NSString* s = [self titleOfSelectedItem];
		
		NSPoint point = NSMakePoint(
			NSMinX(cellFrame)+20,
			([controlView isFlipped] ? NSMaxY(cellFrame) - 28 : NSMinY(cellFrame)+4)
		);
	    NSMutableDictionary *stringAttributes = [NSMutableDictionary dictionaryWithCapacity:2];
	    [stringAttributes setObject:[NSFont messageFontOfSize:12.0] forKey:NSFontAttributeName];
	    [stringAttributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	    [s drawAtPoint:point withAttributes: stringAttributes]; 
	    
	}
}

static inline BOOL PointIsInPopUpArea(NSPoint locationInCellFrame, NSRect cellFrame) {
    BOOL hit = NO;
    if(NSPointInRect(locationInCellFrame, cellFrame)) {
		NSRect slice, remain;
		NSDivideRect(cellFrame, &slice, &remain, 30, NSMaxXEdge);
	    if(NSPointInRect(locationInCellFrame, slice)) {
			hit = YES;
		}
    }
    return hit;
}

static inline BOOL PointIsInButtonArea(NSPoint locationInCellFrame, NSRect cellFrame) {
    BOOL hit = NO;
    if(NSPointInRect(locationInCellFrame, cellFrame)) {
		NSRect slice, remain;
		NSDivideRect(cellFrame, &slice, &remain, 30, NSMaxXEdge);
	    if(NSPointInRect(locationInCellFrame, remain)) {
			hit = YES;
		}
    }
    return hit;
}

- (BOOL)trackMouseForButtonEvent:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView {
    NSEvent* currentEvent = theEvent;

    // Track mouse dragged events until mouse up.  Always enter atleast once.    
    do {
        NSPoint mousePoint = [controlView convertPoint: [currentEvent locationInWindow] fromView:nil];

		switch ([currentEvent type]) {
		case NSLeftMouseDown:
		case NSLeftMouseDragged:
			// For each movement, update the position of the hour hand by adjusting our time.
			
			m_button_down = PointIsInButtonArea(mousePoint, cellFrame);
		
        	[(NSControl *)controlView updateCell: self];

			break;
	    default:
			// If we find anything other than a mouse dragged (mouse up) we are done.
			return YES;
		}
    } while (currentEvent = [[controlView window] nextEventMatchingMask:(NSLeftMouseDraggedMask  | NSLeftMouseUpMask) untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES]);

    return YES;
}


- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)flag {
    NSPoint locationInCellFrame = [controlView convertPoint:[theEvent locationInWindow] fromView:nil];
    
    if(PointIsInPopUpArea(locationInCellFrame, cellFrame)) {
		NSLog(@"%s a", _cmd);
		
		/*
		TODO: is there a better way to show the popup?
		*/
		[super trackMouse:theEvent inRect:cellFrame ofView:controlView untilMouseUp:flag];
		// [NSMenu popUpContextMenu:[self menu] withEvent:theEvent forView:controlView];
		// [self attachPopUpWithFrame:cellFrame inView:controlView];
		
    } else
    if(PointIsInButtonArea(locationInCellFrame, cellFrame)) {
		NSLog(@"%s b", _cmd);
		
		/*
		We wait for mouseup inside the cell. Only if trigger if it's inside.
		*/
		m_button_down = YES;
		[(NSControl *)[self controlView] updateCell: self];

		[self trackMouseForButtonEvent:theEvent inRect:cellFrame ofView:controlView];

		if(m_button_down) {
			[self sendActionToTarget];
		}

		m_button_down = NO;
		[(NSControl *)[self controlView] updateCell: self];
		
    } else {
		NSLog(@"%s c", _cmd);

		// this happens when the user press arrow_down or arrow_up, all other keys than spacebar
		
		/*
		TODO: is there a better way to show the popup?
		*/
		[super trackMouse:theEvent inRect:cellFrame ofView:controlView untilMouseUp:flag];
		// [NSMenu popUpContextMenu:[self menu] withEvent:theEvent forView:controlView];
		// [self attachPopUpWithFrame:cellFrame inView:controlView];
    }
    
    return YES;
}

-(void)sendActionToTarget {
	NSLog(@"%s enter", _cmd);
    if ([self target] && [self action]) {
		NSLog(@"%s send action", _cmd);
        [(NSControl *)[self controlView] sendAction:[self action] to:[self target]];
    }
}

- (void)performClick:(id)sender {
    // Use the space bar to trigger the action.
	// TODO: use shift+spacebar to show the menu

	// Tell our control view to redisplay us.
	[(NSControl *)[self controlView] updateCell: self];

	// For this example, we just send the action whenever the time changes.
	// Usually you would only want to send an action in response to user events.
	[self sendActionToTarget];
}

@end
