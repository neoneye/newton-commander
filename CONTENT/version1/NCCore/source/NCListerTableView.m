//
//  NCListerTableView.m
//  NCCore
//
//  Created by Simon Strandgaard on 03/02/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "NCLog.h"
#import "NCTimeProfiler.h"
#import "NCListerTableView.h"
#import "NCLister.h"
#import "NSGradient+PredefinedGradients.h"

#if 0
// was named logic_for_page_up1
void logic_for_page_up(NSRange range, int row, int rows, int* out_row, int* out_toprow) {
	if(row != range.location) {
		row = range.location;
	} else {
		row = range.location - range.length;
		if(row < 0) row = 0;
	}
	if((row < 0) || (row >= rows)) return;
	
	if(out_row) *out_row = row;
	if(out_toprow) *out_toprow = row;
}
#else
// was named logic_for_page_up2
void logic_for_page_up(NSRange range, int row, int rows, int* out_row, int* out_toprow) {
	int offset = row - (int)range.location;
	// int toprow = row - offset;
	int toprow = (int)range.location;

	int next_toprow = toprow - (int)range.length;
	if(toprow == 0) {
		toprow = 0;
		row = 0;
	} else
	if(next_toprow < 0) {
		toprow = 0;
		row = offset;
	} else {
		row -= (int)range.length;
		toprow = next_toprow;
	}
	if(row < 0) row = 0;
	if((row < 0) || (row >= rows)) return;
	
	if(out_row) *out_row = row;
	if(out_toprow) *out_toprow = toprow;
}
#endif

#if 0
void logic_for_page_down1(NSRange range, int row, int rows, int* out_row, int* out_botrow) {
	int rangeend = range.location + range.length - 1;
	if(row != rangeend) {
		row = rangeend;
	} else {
		row = rangeend + range.length;
		if(row >= rows) row = rows - 1;
	}
	if((row < 0) || (row >= rows)) return;

	if(out_row) *out_row = row;
	if(out_botrow) *out_botrow = row;
}

void logic_for_page_down2(NSRange range, int row, int rows, int* out_row, int* out_botrow) {
	int botrow = (int)range.location + (int)range.length - 1;
	int offset = botrow - row;

	int next_botrow = botrow + (int)range.length;
	if(botrow == rows - 1) {
		botrow = rows - 1;
		row = rows - 1;
	} else
	if(next_botrow >= rows - 1) {
		botrow = rows - 1;
		row = rows - 1 - offset;
	} else {
		row += (int)range.length;
		botrow = next_botrow;
	}
	if(row < 0) row = 0;
	if((row < 0) || (row >= rows)) return;
	
	if(out_row) *out_row = row;
	if(out_botrow) *out_botrow = botrow;
}
#endif

void logic_for_page_down3(NSRange range, int row, int rows, int* out_row, int* out_visiblerow) {

	int next_row = row + (int)range.length;
	int next_visiblerow = (int)range.location + (int)range.length;

	int botrow = (int)range.location + (int)range.length - 1;
	int offset = botrow - row;
	int visiblerow = botrow;

	int change = 0;

	int next_botrow = botrow + (int)range.length;
	if(botrow == rows - 1) {
		visiblerow = rows - 1;
		row = rows - 1;
		change = 1;
	} else
	if(next_botrow >= rows - 1) {
		visiblerow = rows - (int)range.length + 1;
		row = rows - 1 - offset;
		change = 2;
	} else {
		row = next_row;
		visiblerow = next_visiblerow;
		change = 3;
	}
	if(row < 0) row = 0;
	if((row < 0) || (row >= rows)) return;
	
	// LOG_DEBUG(@"#%i", change);
	
	if(out_row) *out_row = row;
	if(out_visiblerow) *out_visiblerow = visiblerow;
}



@interface NCListerTableView (Private)
- (BOOL)isThisPanelActive;

-(void)ofmRepeatEvent:(NSEvent*)event selector:(SEL)sel notification:(NSNotification*)note;
-(void)repeatEvent:(NSEvent*)event selector:(SEL)sel0 shiftSelector:(SEL)sel1;

-(void)popupContextMenuMode:(int)left_or_right;

-(void)nc__moveUp;
-(void)nc__moveUpAndModifySelection;
-(void)nc__moveDown;
-(void)nc__moveDownAndModifySelection;


@end

@implementation NCListerTableView

@synthesize lister = m_lister;
@synthesize backgroundColor = m_background_color;
@synthesize firstRowBackgroundColor = m_first_row_background_color;
@synthesize oddRowBackgroundColor = m_odd_row_background_color;
@synthesize evenRowBackgroundColor = m_even_row_background_color;
@synthesize selectedRowBackgroundColor = m_selected_row_background_color;
@synthesize firstRowBackgroundInactiveColor = m_first_row_background_inactive_color;
@synthesize oddRowBackgroundInactiveColor = m_odd_row_background_inactive_color;
@synthesize evenRowBackgroundInactiveColor = m_even_row_background_inactive_color;
@synthesize selectedRowBackgroundInactiveColor = m_selected_row_background_inactive_color;
@synthesize cursorRowBackgroundColor = m_cursor_row_background_color;
@synthesize cursorRowBackgroundInactiveColor = m_cursor_row_background_inactive_color;


-(id)initWithFrame:(NSRect)frame lister:(NCLister*)lister {
    self = [super initWithFrame:frame];
	if (self) {
		NSAssert(lister, @"lister must not be nil");
		[self setLister:lister];
		
		[self adjustThemeForDictionary:[NCListerTableView whiteTheme]];
	}
	return self;
}

-(void)ofmRepeatEvent:(NSEvent*)event selector:(SEL)sel notification:(NSNotification*)note {
	id del = [self delegate];
	if([del respondsToSelector:sel]) {
		// ok
	} else
	if([self respondsToSelector:sel]) {
		del = self;
	} else {
		return;
	}

	NSEvent* xevent = event;
	for(int count=0; ; ++count) {
		NSEventType event_type = [xevent type];
		if(event_type == NSKeyUp) {
			break;
		}
		[del performSelector:sel withObject:note];

		float waittime = 0.0001;
		if(count == 0) waittime = 0.25;
		else
		if(count < 10) waittime = 0.015;
		else
		if(count < 30) waittime = 0.0075;
		else
		if(count < 80) waittime = 0.005;
		else
		if(count < 130) waittime = 0.002;
		else
		if(count < 240) waittime = 0.001;

		NSDate* date = [NSDate dateWithTimeIntervalSinceNow:
			waittime];
        xevent = [NSApp nextEventMatchingMask:NSAnyEventMask
			untilDate:date 
			inMode:NSDefaultRunLoopMode 
			dequeue:YES
		];
	}
}

-(void)repeatEvent:(NSEvent*)event selector:(SEL)sel0 shiftSelector:(SEL)sel1 {
	id del = [self delegate];
	if([del respondsToSelector:sel0] && [del respondsToSelector:sel1]) {
		// ok
	} else
	if([self respondsToSelector:sel0] && [self respondsToSelector:sel1]) {
		del = self;
	} else {
		return;
	}

	NSEvent* xevent = event;
	for(int count=0; ; ++count) {
		NSEventType event_type = [xevent type];
		if(event_type == NSKeyUp) {
			break;
		}
		
		BOOL is_shift = (([NSEvent modifierFlags] & NSShiftKeyMask) != 0);
		SEL sel = is_shift ? sel1 : sel0;
		
		[del performSelector:sel];

		float waittime = 0.0001;
		if(count == 0) waittime = 0.25;
		else
		if(count < 10) waittime = 0.015;
		else
		if(count < 30) waittime = 0.0075;
		else
		if(count < 80) waittime = 0.005;
		else
		if(count < 130) waittime = 0.002;
		else
		if(count < 240) waittime = 0.001;

		NSDate* date = [NSDate dateWithTimeIntervalSinceNow:
			waittime];
        xevent = [NSApp nextEventMatchingMask:NSAnyEventMask
			untilDate:date 
			inMode:NSDefaultRunLoopMode 
			dequeue:YES
		];
	}
}


/*- (void)awakeFromNib
{
	[super awakeFromNib];
	LOG_DEBUG(@"NCListerTableView %s", _cmd);
} */

/*- (id)initWithFrame:(NSRect)frame 
{
    self = [super initWithFrame:frame];
    if (self) 
	{
		LOG_DEBUG(@"NCListerTableView %s %@", _cmd, self);
    }
    return self;
}*/

/*- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super initWithCoder:decoder]) != nil)
	{
		LOG_DEBUG(@"NCListerTableView %s %@", _cmd, self);

		NSFont* font = [NSFont systemFontOfSize:24];
		
		
		NSArray* ary = [self tableColumns];
		LOG_DEBUG(@"%s cols %@", _cmd, ary);
		id thing;
		NSEnumerator* en = [ary objectEnumerator];
		while(thing = [en nextObject]) {
			
			
			NSTextFieldCell* cell = [[[NSTextFieldCell alloc] initTextCell:@"xyz"] autorelease];
			[cell setFont:font];
			[cell setTextColor:[NSColor greenColor]];
			[thing setDataCell:cell];
			
			id datacell = [thing dataCell];
			
			if([datacell isKindOfClass:[NSTextFieldCell class]]) {
				NSTextFieldCell* cell = (NSTextFieldCell*)datacell;
				
				[cell setFont:font];
				LOG_DEBUG(@"%s ok", _cmd);
				
				continue;
			}

			
			// LOG_DEBUG(@"%s yes: %@", _cmd, datacell);
			
		}


	}
	return self;
} /**/

- (BOOL)becomeFirstResponder {
	// LOG_DEBUG(@"%s", _cmd);

	id del = [self delegate];
	SEL sel = @selector(activateTableView:);
	if([del respondsToSelector:sel]) {
		[del performSelector:sel withObject:self];
	}

	return [super becomeFirstResponder];
}

-(void)keyDown:(NSEvent*)event {
	NSString* s = [event charactersIgnoringModifiers];

	id del = [self delegate];
	
/*	id sv = [self enclosingScrollView];
	LOG_DEBUG(@"%s self: %@   del: %@    sv: %@", _cmd, self, del, sv); /**/

/*	BOOL is_shift_modifier   = (([event modifierFlags] & NSShiftKeyMask) != 0);
	// BOOL is_control_modifier = (([event modifierFlags] & NSControlKeyMask) != 0);

	if(is_shift_modifier) {
		LOG_DEBUG(@"%s shift", _cmd);
	}
	
	if(is_control_modifier) {
		LOG_DEBUG(@"%s control", _cmd);
	} */
	
	unichar key = [s characterAtIndex:0];
	switch(key) {
	case NSCarriageReturnCharacter: {
		SEL sel = @selector(navigateInOrBackAction:);
		if([event modifierFlags] & NSCommandKeyMask) {
			sel = @selector(navigateInOrParentAction:);
		}
		if([del respondsToSelector:sel]) {
			[del performSelector:sel withObject:self];
		}
		return; }
	case NSDeleteCharacter: {
		SEL sel = @selector(navigateBackAction:);
		if([event modifierFlags] & NSCommandKeyMask) {
			sel = @selector(navigateParentAction:);
		}
		if([del respondsToSelector:sel]) {
			[del performSelector:sel withObject:self];
		}
		return; }
/*	case 32: {
		[self ofmRepeatEvent:event 
		           selector:@selector(tableViewHitSpace:)
		       notification:[NSNotification 
			notificationWithName:@"SPACE" object:self]
		];
		return; }  */
	case NSBackTabCharacter: 
	case NSTabCharacter: {
		SEL sel = @selector(tabKeyPressed:);
		if([del respondsToSelector:sel]) {
			[del performSelector:sel withObject:self];
		}
		return; }
	case NSHomeFunctionKey: {
		SEL sel = @selector(tableViewJumpTop:);
		id d = del;
		if([d respondsToSelector:sel]) {
			// ok
		} else 
		if([self respondsToSelector:sel]) {	
			d = self;
		}
		if(d) {
			[d performSelector:sel withObject:
				[NSNotification notificationWithName:@"HOME" object:self]];
		}
		[NSCursor setHiddenUntilMouseMoves:YES];
		return; }
	case NSEndFunctionKey: {
		SEL sel = @selector(tableViewJumpBottom:);
		id d = del;
		if([d respondsToSelector:sel]) {
			// ok
		} else 
		if([self respondsToSelector:sel]) {	
			d = self;
		}
		if(d) {
			[d performSelector:sel withObject:
				[NSNotification notificationWithName:@"END" object:self]];
		}
		[NSCursor setHiddenUntilMouseMoves:YES];
		return; }
	case NSPageUpFunctionKey: {
		NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
		    [NSNumber numberWithBool:[event isARepeat]], @"repeat", nil];
		SEL sel = @selector(tableViewPageUp:);
		id d = del;
		if([d respondsToSelector:sel]) {
			// ok
		} else 
		if([self respondsToSelector:sel]) {	
			d = self;
		}
		if(d) {
			[d performSelector:sel withObject:
				[NSNotification notificationWithName:@"PAGEUP" object:self userInfo:dict]];
		}
		[NSCursor setHiddenUntilMouseMoves:YES];
		return; }
	case NSPageDownFunctionKey: {
		NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
		    [NSNumber numberWithBool:[event isARepeat]], @"repeat", nil];
		SEL sel = @selector(tableViewPageDown:);
		id d = del;
		if([d respondsToSelector:sel]) {
			// ok
		} else 
		if([self respondsToSelector:sel]) {	
			d = self;
		}
		if(d) {
			[d performSelector:sel withObject:
				[NSNotification notificationWithName:@"PAGEDOWN" object:self userInfo:dict]];
		}
		[NSCursor setHiddenUntilMouseMoves:YES];
		return; }
	case NSUpArrowFunctionKey: {
		SEL sel = @selector(navigateBackAction:);
		if([event modifierFlags] & NSCommandKeyMask) {
			if([del respondsToSelector:sel]) {
				[del performSelector:sel withObject:self];
				return;
			}
		}
		[self repeatEvent:event 
			selector:@selector(nc__moveUp) 
			shiftSelector:@selector(nc__moveUpAndModifySelection)];
		[NSCursor setHiddenUntilMouseMoves:YES];
		return; }
	case NSDownArrowFunctionKey: {
/*		SEL sel = @selector(navigateInOrBackAction:);
		if([event modifierFlags] & NSCommandKeyMask) {
			if([del respondsToSelector:sel]) {
				[del performSelector:sel withObject:self];
				return;
			}
		}*/
		[self repeatEvent:event 
			selector:@selector(nc__moveDown) 
			shiftSelector:@selector(nc__moveDownAndModifySelection)];
		[NSCursor setHiddenUntilMouseMoves:YES];
		return; }
		
	case NSLeftArrowFunctionKey: { 
		SEL sel = @selector(showLeftContextMenu:);
		if([del respondsToSelector:sel]) {
			[del performSelector:sel withObject:self];
		}
		return; }
	case NSRightArrowFunctionKey: { 
		SEL sel = @selector(showRightContextMenu:);
		if([del respondsToSelector:sel]) {
			[del performSelector:sel withObject:self];
		}
		return; }
		
/*	default:
		LOG_DEBUG(@"NCListerTableView: keydown: unknown key=%i\n", key);/**/
	}
	
	[super keyDown:event];
}

// ask our delegate wether this panel is active
-(BOOL)isThisPanelActive {
	BOOL is_active = NO;
	id obj = [self delegate];
	SEL sel = @selector(isActiveTableView);
	if([obj respondsToSelector:sel]) {
		NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:sel]];
		[inv setSelector:sel];
		[inv invokeWithTarget:obj];
		[inv getReturnValue:&is_active];
	}
	return is_active;
}

- (BOOL)performKeyEquivalent:(NSEvent*)event {
	// LOG_DEBUG(@"%s %@ %@", _cmd, self, event);


	
	if(![self isThisPanelActive]) {
		// LOG_DEBUG(@"%s this panel is not not active", _cmd);
		return [super performKeyEquivalent:event];
	}
	
	// LOG_DEBUG(@"%s this panel is active", _cmd);
	
	id del = [self delegate];
/*	id sv = [self enclosingScrollView];
	LOG_DEBUG(@"%s self: %@   del: %@    sv: %@", _cmd, self, del, sv);*/

	BOOL is_shift_modifier   = (([event modifierFlags] & NSShiftKeyMask) != 0);
	BOOL is_control_modifier = (([event modifierFlags] & NSControlKeyMask) != 0);
	BOOL is_command_modifier = (([event modifierFlags] & NSCommandKeyMask) != 0);
	BOOL is_alt_modifier = (([event modifierFlags] & NSAlternateKeyMask) != 0);
	
/*	if(is_shift_modifier) {
		LOG_DEBUG(@"%s shift", _cmd);
	}

	if(is_control_modifier) {
		LOG_DEBUG(@"%s control", _cmd);
	} */

	switch([event keyCode]) {
	case 48: { // triggered for CTRL+TAB and CTRL+SHIFT+TAB
		// LOG_DEBUG(@"%s ctrl tab, ctrl shift tab", _cmd);
		if(is_command_modifier) {
			return NO;
		}
		if(is_alt_modifier) {
			return NO;
		}
		if(!is_control_modifier) {
			return NO;
		}
		if(is_shift_modifier) {
			SEL sel = @selector(switchToPrevTab:);
			if([del respondsToSelector:sel]) {
				[del performSelector:sel withObject:self];
			}
		} else {
			SEL sel = @selector(switchToNextTab:);
			if([del respondsToSelector:sel]) {
				[del performSelector:sel withObject:self];
			}
		}
		return YES; }

	case 13: {// CMD+W
		if(is_shift_modifier) {
			return NO;
		}
		if(is_alt_modifier) {
			return NO;
		}
		if(is_control_modifier) {
			return NO;
		}
		if(!is_command_modifier) {
			return NO;
		}
		// LOG_DEBUG(@"%s close tab", _cmd);

		SEL sel = @selector(closeTab:);
		if([del respondsToSelector:sel]) {
			[del performSelector:sel withObject:self];
		}
		
		return YES; }
	}

	return NO;
}

-(void)swipeWithEvent:(NSEvent*)event {
	// NSLog(@"%s. deltaX: %f  deltaY: %f", _cmd, [event deltaX], [event deltaY]);

	id del = [self delegate];

	BOOL swipe_left = ([event deltaX] > 0.9);
	BOOL swipe_right = ([event deltaX] < -0.9);
	BOOL swipe_up = ([event deltaY] > 0.9);
	
	if(swipe_left) {
		SEL sel = @selector(switchToPrevTab:);
		if([del respondsToSelector:sel]) {
			[del performSelector:sel withObject:self];
		}
	}

	if(swipe_right) {
		SEL sel = @selector(switchToNextTab:);
		if([del respondsToSelector:sel]) {
			[del performSelector:sel withObject:self];
		}
	}

	if(swipe_up) {
		SEL sel = @selector(navigateBackAction:);
		// sel = @selector(navigateParentAction:);
		if([del respondsToSelector:sel]) {
			[del performSelector:sel withObject:self];
		}
	}
}

-(void)adjustThemeForDictionary:(NSDictionary*)dict {
	self.backgroundColor = [dict objectForKey:@"backgroundColor"]; 
	self.firstRowBackgroundColor = [dict objectForKey:@"firstRowBackgroundColor"]; 
	self.firstRowBackgroundInactiveColor = [dict objectForKey:@"firstRowBackgroundInactiveColor"]; 
	self.evenRowBackgroundColor = [dict objectForKey:@"evenRowBackgroundColor"]; 
	self.evenRowBackgroundInactiveColor = [dict objectForKey:@"evenRowBackgroundInactiveColor"]; 
	self.oddRowBackgroundColor = [dict objectForKey:@"oddRowBackgroundColor"]; 
	self.oddRowBackgroundInactiveColor = [dict objectForKey:@"oddRowBackgroundInactiveColor"]; 
	self.selectedRowBackgroundColor = [dict objectForKey:@"selectedRowBackgroundColor"]; 
	self.selectedRowBackgroundInactiveColor = [dict objectForKey:@"selectedRowBackgroundInactiveColor"]; 
	self.cursorRowBackgroundColor = [dict objectForKey:@"cursorRowBackgroundColor"]; 
	self.cursorRowBackgroundInactiveColor = [dict objectForKey:@"cursorRowBackgroundInactiveColor"]; 
}

+(NSDictionary*)whiteTheme {
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSColor whiteColor],
		@"backgroundColor",
		
		[[NSColor controlAlternatingRowBackgroundColors] objectAtIndex:0],
		@"firstRowBackgroundColor",
		
		[[NSColor controlAlternatingRowBackgroundColors] objectAtIndex:1],
		@"evenRowBackgroundColor",
		
		[[NSColor controlAlternatingRowBackgroundColors] objectAtIndex:0],
		@"oddRowBackgroundColor",
		
		[NSColor colorWithCalibratedRed:0.907 green:0.116 blue:0.046 alpha:1.000],
		@"selectedRowBackgroundColor",
		
		[NSColor colorWithCalibratedWhite:0.94 alpha:1.0],
		@"firstRowBackgroundInactiveColor",
		
		[NSColor colorWithCalibratedWhite:0.87 alpha:1.0],
		@"evenRowBackgroundInactiveColor",
		
		[NSColor colorWithCalibratedWhite:0.94 alpha:1.0],
		@"oddRowBackgroundInactiveColor",
		
		[NSColor colorWithCalibratedRed:0.454 green:0.291 blue:0.287 alpha:1.000],
		@"selectedRowBackgroundInactiveColor",
		
		[NSGradient blueSelectedRowGradient],
		@"cursorRowBackgroundColor",
		
		[NSColor colorWithCalibratedWhite:0.4 alpha:1.000],
		@"cursorRowBackgroundInactiveColor",
		
		nil
	];
}

+(NSDictionary*)grayTheme {
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSColor colorWithCalibratedWhite:0.788 alpha:1.000],
		@"backgroundColor",
		
		[NSColor colorWithCalibratedWhite:0.788 alpha:1.000],
		@"firstRowBackgroundColor",
		
		[NSColor colorWithCalibratedWhite:0.839 alpha:1.000],
		@"evenRowBackgroundColor",
		
		[NSColor colorWithCalibratedWhite:0.788 alpha:1.000],
		@"oddRowBackgroundColor",
		
		[NSColor colorWithCalibratedRed:0.845 green:0.587 blue:0.202 alpha:1.000],
		// [NSColor colorWithCalibratedRed:0.907 green:0.116 blue:0.046 alpha:1.000],
		@"selectedRowBackgroundColor",
		
		[NSColor colorWithCalibratedWhite:0.788 alpha:1.000],
		@"firstRowBackgroundInactiveColor",
		
		[NSColor colorWithCalibratedWhite:0.839 alpha:1.000],
		@"evenRowBackgroundInactiveColor",
		
		[NSColor colorWithCalibratedWhite:0.788 alpha:1.000],
		@"oddRowBackgroundInactiveColor",
		
		[NSColor colorWithCalibratedRed:0.520 green:0.396 blue:0.191 alpha:1.000],
		// [NSColor colorWithCalibratedRed:0.454 green:0.291 blue:0.287 alpha:1.000],
		@"selectedRowBackgroundInactiveColor",
		
		[NSGradient blueSelectedRowGradient],
		@"cursorRowBackgroundColor",
		
		[NSColor colorWithCalibratedWhite:0.4 alpha:1.000],
		@"cursorRowBackgroundInactiveColor",
		
		nil
	];
}

+(NSDictionary*)blackTheme {
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSColor colorWithCalibratedWhite:0.243 alpha:1.000],
		@"backgroundColor",

		[NSColor colorWithCalibratedWhite:0.243 alpha:1.000],
		@"firstRowBackgroundColor",
		
		[NSColor colorWithCalibratedWhite:0.275 alpha:1.000],
		@"evenRowBackgroundColor",
		
		[NSColor colorWithCalibratedWhite:0.243 alpha:1.000],
		@"oddRowBackgroundColor",
		
		[NSColor colorWithCalibratedRed:0.907 green:0.116 blue:0.046 alpha:1.000],
		@"selectedRowBackgroundColor",
		
		[NSColor colorWithCalibratedWhite:0.243 alpha:1.000],
		@"firstRowBackgroundInactiveColor",
		
		[NSColor colorWithCalibratedWhite:0.275 alpha:1.000],
		@"evenRowBackgroundInactiveColor",
		
		[NSColor colorWithCalibratedWhite:0.243 alpha:1.000],
		@"oddRowBackgroundInactiveColor",
		
		// [NSColor colorWithCalibratedRed:0.454 green:0.291 blue:0.287 alpha:1.000],
		// [NSColor colorWithCalibratedRed:0.901 green:0.375 blue:0.284 alpha:1.000],
		// [NSColor colorWithCalibratedRed:0.842 green:0.350 blue:0.266 alpha:1.000],  
		// [NSColor colorWithCalibratedRed:0.738 green:0.307 blue:0.233 alpha:1.000],  
		[NSColor colorWithCalibratedRed:0.505 green:0.210 blue:0.159 alpha:1.000],
		@"selectedRowBackgroundInactiveColor",
		
		[NSGradient blueSelectedRowGradient],
		@"cursorRowBackgroundColor",
		
		[NSColor colorWithCalibratedRed:0.480 green:0.5 blue:0.52 alpha:1.000],
		@"cursorRowBackgroundInactiveColor",
		
		nil
	];
}

- (void)drawRect:(NSRect)rect {
	//uint64_t t0 = mach_absolute_time();
	[super drawRect:rect];
	//uint64_t t1 = mach_absolute_time();
	//double elapsed0 = subtract_times(t1, t0);
	// LOG_DEBUG(@"%.6fs", elapsed0);
}


- (void)drawBackgroundInClipRect:(NSRect)rect {	
	[self.backgroundColor set];
	NSRectFill(rect);
}

-(void)drawRow:(NSInteger)rowIndex clipRect:(NSRect)clipRect {


	int fcode = [m_lister listerTableView:self formatCodeForRow:rowIndex];
	BOOL is_selected = (fcode == 1);
	BOOL is_active = [self isThisPanelActive];
	

	// switch color for every 3 row
	int group_row = 0; // don't alternate colors
	group_row = 1; // alternate colors
	// group_row = 2;  // alternate for every 2 row
	// group_row = 3;  // alternate for every 3 row
	
	id color = nil;

	if(![self isRowSelected: rowIndex]) {
		BOOL is_odd_row = NO;
		if(group_row > 0) is_odd_row = (((rowIndex - 1) / group_row) & 1);
		BOOL is_first_row = (rowIndex == 0);
		if(is_active) {
			if(is_selected) {
				color = self.selectedRowBackgroundColor;
			} else 
			if(is_first_row) {
				color = self.firstRowBackgroundColor;
			} else 
			if(is_odd_row) {
				color = self.oddRowBackgroundColor;
			} else {
				color = self.evenRowBackgroundColor;
			}
		} else {
			if(is_selected) {
				color = self.selectedRowBackgroundInactiveColor;
			} else 
			if(is_first_row) {
				color = self.firstRowBackgroundInactiveColor;
			} else 
			if(is_odd_row) {
				color = self.oddRowBackgroundInactiveColor;
			} else {
				color = self.evenRowBackgroundInactiveColor;
			}
		}

	} else {
		if(is_active) {
			color = self.cursorRowBackgroundColor;
		} else {
			color = self.cursorRowBackgroundInactiveColor;
		}
	}

	if([color isKindOfClass:[NSColor class]]) {
		NSColor* c = (NSColor*)color;
		[c set];
		NSRectFill([self rectOfRow: rowIndex]);
	} else
	if([color isKindOfClass:[NSGradient class]]) {
		NSGradient* g = (NSGradient*)color;
    	[g drawInRect:[self rectOfRow: rowIndex] angle:90.0];
	}
	
	[super drawRow: rowIndex clipRect: clipRect];
}

-(void)nc__moveUp {
	int row_count = [self numberOfRows];
	if(row_count < 1) return;

	int row = [self selectedRow];
	int row1 = row - 1;
	
	// move to previous row if possible
	if(row1 >= 0) {
		[self scrollRowToVisible:row1];
		NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:row1];
		[self selectRowIndexes:indexes byExtendingSelection:NO];
	}
}

-(void)nc__moveUpAndModifySelection {
	int row_count = [self numberOfRows];
	if(row_count < 1) return;

	int row = [self selectedRow];
	int row1 = row - 1;
	
	// move to previous row if possible
	if(row1 >= 0) {
		[self scrollRowToVisible:row1];
		NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:row1];
		[self selectRowIndexes:indexes byExtendingSelection:NO];
	}
	
	// modify selection
	id del = [self delegate];
	SEL sel = @selector(tableView:markRow:);
	if([del respondsToSelector:sel]) {
		[del tableView:self markRow:row];
	}
}

-(void)nc__moveDown {
	// LOG_DEBUG(@"%s", _cmd);
	int row_count = [self numberOfRows];
	if(row_count < 1) return;
	int row = [self selectedRow];
	int row1 = row + 1;
	
	// move to next row if possible
	if(row1 < row_count) {
		[self scrollRowToVisible:row1];
		NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:row1];
		[self selectRowIndexes:indexes byExtendingSelection:NO];
	}
}

-(void)nc__moveDownAndModifySelection {
	// LOG_DEBUG(@"%s", _cmd);
	int row_count = [self numberOfRows];
	if(row_count < 1) return;
	int row = [self selectedRow];
	int row1 = row + 1;
	
	// move to next row if possible
	if(row1 < row_count) {
		[self scrollRowToVisible:row1];
		NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:row1];
		[self selectRowIndexes:indexes byExtendingSelection:NO];
	}
	
	// modify selection
	id del = [self delegate];
	SEL sel = @selector(tableView:markRow:);
	if([del respondsToSelector:sel]) {
		[del tableView:self markRow:row];
	}
}

-(void)tableViewPageUp:(NSNotification*)aNotification {
	// id thing1 = [aNotification object];
	// LOG_DEBUG(@"%@", aNotification);

	id thing2 = [aNotification userInfo];
	thing2 = [thing2 objectForKey:@"repeat"];
	BOOL repeat = [thing2 boolValue];
	// LOG_DEBUG(@"repeat: %i", (int)repeat);

	int rows = [self numberOfRows];
	int row = [self selectedRow];     
		
	NSRect r = [[self enclosingScrollView] documentVisibleRect];
	
	NSRange range = [self rowsInRect:r];
	// LOG_DEBUG(@"%s %i %i", _cmd, (int)range.location, (int)range.length);

	int visiblerow = 0;
	int index = row;
	logic_for_page_up(range, row, rows, &index, &visiblerow);

	[self scrollRowToVisible:visiblerow];

	if((index == 0) && (repeat)) {
		/*
		we don't want to hit the top 
		when holding in pageup for a longer period.
		This way we don't have to watch out
		if we are hitting the top, and reposition
		the selected row near the middle.
		*/
		return;
	}
	
	NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:index];
	[self selectRowIndexes:indexes byExtendingSelection:NO];
}

-(void)tableViewPageDown:(NSNotification*)aNotification {
	// id thing1 = [aNotification object];
	// LOG_DEBUG(@"%@", aNotification);

	id thing2 = [aNotification userInfo];
	thing2 = [thing2 objectForKey:@"repeat"];
	BOOL repeat = [thing2 boolValue];
	// LOG_DEBUG(@"repeat: %i", (int)repeat);
	
	NSTableView* tv = self;
		
	int rows = [tv numberOfRows];
	int row = [tv selectedRow];     
	NSRect r = [[tv enclosingScrollView] documentVisibleRect];
	NSRange range = [tv rowsInRect:r];

	int visiblerow = 0;
	int index = row;
/*	if(0) {
		logic_for_page_down1(range, row, rows, &index, &visiblerow);
		[tv scrollRowToVisible:visiblerow];
	} else 
	if(0) {
		logic_for_page_down2(range, row, rows, &index, &visiblerow);
		[tv scrollRowToVisible:visiblerow];
	} else 
	if(1) { */
		logic_for_page_down3(range, row, rows, &index, &visiblerow);
		[tv scrollRowToVisible:rows - 1];
		[tv scrollRowToVisible:visiblerow];
	// }
	
	if((index == rows-1) && (repeat)) {
		/*
		we don't want to hit the bottom 
		when holding in pagedown for a longer period.
		This way we don't have to watch out
		if we are hitting the bottom, and reposition
		the selected row near the middle.
		*/
		return;
	}
	
	NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:index];
	[tv selectRowIndexes:indexes byExtendingSelection:NO];
}

-(void)tableViewJumpTop:(NSNotification*)aNotification {
	// id thing = [aNotification object];
	int row = [self numberOfRows];
	if(row <= 0) return;
	row = 0;
	
	[self scrollRowToVisible:row];
	
	NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:row];
	[self selectRowIndexes:indexes byExtendingSelection:NO];
}

-(void)tableViewJumpBottom:(NSNotification*)aNotification {
	// id thing = [aNotification object];
	int row = [self numberOfRows];
	if(row <= 0) return;
	row -= 1;
	
	[self scrollRowToVisible:row];
	
	NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:row];
	[self selectRowIndexes:indexes byExtendingSelection:NO];
}

/*
- (void)editColumn:(NSInteger)columnIndex row:(NSInteger)rowIndex withEvent:(NSEvent *)theEvent select:(BOOL)flag {
	LOG_DEBUG(@"%s will call editColumn", _cmd);
	[super editColumn:columnIndex row:rowIndex withEvent:theEvent select:flag];
} /**/

@end
