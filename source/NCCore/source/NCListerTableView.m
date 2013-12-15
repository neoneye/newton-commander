//
//  NCListerTableView.m
//  NCCore
//
//  Created by Simon Strandgaard on 03/02/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


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

-(void)popupContextMenuMode:(int)left_or_right;

-(void)nc__moveUp;
-(void)nc__moveUpAndModifySelection;
-(void)nc__moveDown;
-(void)nc__moveDownAndModifySelection;

-(void)nc__pageUp:(NSEvent*)event;
-(void)nc__pageDown:(NSEvent*)event;

-(void)jumpToTop:(id)sender;
-(void)jumpToBottom:(id)sender;

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

-(float)waitTimeForCount:(NSInteger)count {
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
	return waittime;
}

-(void)repeatinglyMoveUpWithEvent:(NSEvent*)event {
	NSEvent* xevent = event;
	for(NSInteger count=0; ; ++count) {
		NSEventType event_type = [xevent type];
		if(event_type == NSKeyUp) {
			break;
		}
		
		BOOL shiftPressed = (([NSEvent modifierFlags] & NSShiftKeyMask) != 0);
		if (shiftPressed) {
			[self nc__moveUpAndModifySelection];
		} else {
			[self nc__moveUp];
		}
		float waittime = [self waitTimeForCount:count];
		NSDate* date = [NSDate dateWithTimeIntervalSinceNow:waittime];
        xevent = [NSApp nextEventMatchingMask:NSAnyEventMask
									untilDate:date
									   inMode:NSDefaultRunLoopMode
									  dequeue:YES];
	}
}

-(void)repeatinglyMoveDownWithEvent:(NSEvent*)event {
	NSEvent* xevent = event;
	for(NSInteger count=0; ; ++count) {
		NSEventType event_type = [xevent type];
		if(event_type == NSKeyUp) {
			break;
		}
		
		BOOL shiftPressed = (([NSEvent modifierFlags] & NSShiftKeyMask) != 0);
		if (shiftPressed) {
			[self nc__moveDownAndModifySelection];
		} else {
			[self nc__moveDown];
		}
		float waittime = [self waitTimeForCount:count];
		
		NSDate* date = [NSDate dateWithTimeIntervalSinceNow:waittime];
        xevent = [NSApp nextEventMatchingMask:NSAnyEventMask
									untilDate:date
									   inMode:NSDefaultRunLoopMode
									  dequeue:YES];
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
} */


// TODO: why is initWithCoder invoked.. this class should only be instantiated by NCLister.. so it should not happen.. why?
/*- (id)initWithCoder:(NSCoder *)coder {
	NSAssert(nil, @"should never be invoked");
	return nil;
}*/


- (BOOL)becomeFirstResponder {
	// LOG_DEBUG(@"%s", _cmd);

	[m_lister activateTableView:self];
	return [super becomeFirstResponder];
}

-(void)keyDown:(NSEvent*)event {
	// LOG_DEBUG(@"self: %@ (%08x) -  key down: %@", self, (void*)self, m_lister);
	BOOL is_command_modifier = (([event modifierFlags] & NSCommandKeyMask) != 0);

	unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0];
	switch(key) {
	case NSCarriageReturnCharacter: {
		if(is_command_modifier) {
			[m_lister navigateInOrParentAction:self];
		} else {
			[m_lister navigateInOrBackAction:self];
		}
		return; }
	case NSDeleteCharacter: {
		if(is_command_modifier) {
			[m_lister navigateParentAction:self];
		} else {
			[m_lister navigateBackAction:self];
		}
		return; }
	case NSBackTabCharacter: 
	case NSTabCharacter: {
		[m_lister tabKeyPressed:self];
		return; }
	case NSHomeFunctionKey: {
		[self jumpToTop:self];
		return; }
	case NSEndFunctionKey: {
		[self jumpToBottom:self];
		return; }
	case NSPageUpFunctionKey: {
		[self nc__pageUp:event];
		return; }
	case NSPageDownFunctionKey: {
		[self nc__pageDown:event];
		return; }
	case NSUpArrowFunctionKey: {
		if(is_command_modifier) {
			[m_lister navigateBackAction:self];
			return;
		}
		[self repeatinglyMoveUpWithEvent:event];
		return; }
	case NSDownArrowFunctionKey: {
		/*if(is_command_modifier) {
			[m_lister navigateInOrBackAction:self];
			return;
		}*/
		[self repeatinglyMoveDownWithEvent:event];
		return; }
		
	case NSLeftArrowFunctionKey: { 
		[m_lister showLeftContextMenu:self];
		return; }
	case NSRightArrowFunctionKey: { 
		[m_lister showRightContextMenu:self];
		return; }
		
/*	default:
		LOG_DEBUG(@"NCListerTableView: keydown: unknown key=%i\n", key);*/
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

	id <NCListerTableViewDelegate> del = nil;
	id tableViewDelegate = [self delegate];
	if ([tableViewDelegate conformsToProtocol:@protocol(NCListerTableViewDelegate)]) {
		del = (id <NCListerTableViewDelegate>)tableViewDelegate;
	}
	
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
			/*
			TODO: invoked [m_lister switchToPrevTab:self], however performKeyEquivalent for some reason
			operates with a m_lister that is set to nil. It's because initWithCoder: is being called,
			and m_lister is not being assigned to any value. initWithCoder should not be invoked at
			all, because only NCLister is supposed to create instances of this class.
			*/
			// LOG_DEBUG(@"self: %@ (%08x) -  switch to prev tab: %@", self, (void*)self, m_lister);
			if([del respondsToSelector:@selector(switchToPrevTab:)]) {
				[del switchToPrevTab:self];
			}
		} else {
			if([del respondsToSelector:@selector(switchToNextTab:)]) {
				[del switchToNextTab:self];
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

		if([del respondsToSelector:@selector(closeTab:)]) {
			[del closeTab:self];
		}
		
		return YES; }
	}

	return NO;
}

-(void)swipeWithEvent:(NSEvent*)event {
	// NSLog(@"%s. deltaX: %f  deltaY: %f", _cmd, [event deltaX], [event deltaY]);

	BOOL swipe_left = ([event deltaX] > 0.9);
	BOOL swipe_right = ([event deltaX] < -0.9);
	BOOL swipe_up = ([event deltaY] > 0.9);
	
	if(swipe_left)  { [m_lister switchToPrevTab:self]; }
	if(swipe_right) { [m_lister switchToNextTab:self]; }
	if(swipe_up)    { [m_lister navigateBackAction:self]; }
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
	

	// TODO: alternating row colors should be added to preferences panel so user can change it
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

	[NSCursor setHiddenUntilMouseMoves:YES];
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

	[NSCursor setHiddenUntilMouseMoves:YES];
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

	[NSCursor setHiddenUntilMouseMoves:YES];
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

	[NSCursor setHiddenUntilMouseMoves:YES];
}

-(void)nc__pageUp:(NSEvent*)event {
	BOOL repeat = [event isARepeat];
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

	[NSCursor setHiddenUntilMouseMoves:YES];
}

-(void)nc__pageDown:(NSEvent*)event {
	BOOL repeat = [event isARepeat];
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

	[NSCursor setHiddenUntilMouseMoves:YES];
}

-(void)jumpToTop:(id)sender {
	int row = [self numberOfRows];
	if(row <= 0) return;
	row = 0;
	
	[self scrollRowToVisible:row];
	
	NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:row];
	[self selectRowIndexes:indexes byExtendingSelection:NO];
	[NSCursor setHiddenUntilMouseMoves:YES];
}

-(void)jumpToBottom:(id)sender {
	int row = [self numberOfRows];
	if(row <= 0) return;
	row -= 1;
	
	[self scrollRowToVisible:row];
	
	NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:row];
	[self selectRowIndexes:indexes byExtendingSelection:NO];
	[NSCursor setHiddenUntilMouseMoves:YES];
}

/*
- (void)editColumn:(NSInteger)columnIndex row:(NSInteger)rowIndex withEvent:(NSEvent *)theEvent select:(BOOL)flag {
	LOG_DEBUG(@"%s will call editColumn", _cmd);
	[super editColumn:columnIndex row:rowIndex withEvent:theEvent select:flag];
} */


#pragma mark -
#pragma mark Color settings

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

@end
