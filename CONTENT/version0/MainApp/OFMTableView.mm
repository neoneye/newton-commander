/*********************************************************************
OFMTableView.mm - NSTableView with different keybindings

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>

IDEA: rename to something better, such as:
 1. FileList_TableView
 2. Lister_TableView
 3. DirList_TableView

IDEA: move some of the table logic from OFMPane into this class.

TODO: don't alloc NSColor's in drawRow:clipRect: it's slowing it down.

*********************************************************************/
#include "OFMTableView.h"

void logic_for_page_up1(NSRange range, int row, int rows, int* out_row, int* out_toprow) {
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

void logic_for_page_up2(NSRange range, int row, int rows, int* out_row, int* out_toprow) {
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
	
	// NSLog(@"#%i", change);
	
	if(out_row) *out_row = row;
	if(out_visiblerow) *out_visiblerow = visiblerow;
}






@interface OFMTableView (Private)

-(void)ofmRepeatEvent:(NSEvent*)event selector:(SEL)sel notification:(NSNotification*)note;
@end

@implementation OFMTableView

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
		if(count < 3) waittime = 0.015;
		else
		if(count < 5) waittime = 0.0075;
		else
		if(count < 8) waittime = 0.005;
		else
		if(count < 14) waittime = 0.002;
		else
		if(count < 25) waittime = 0.001;

		NSDate* date = [NSDate dateWithTimeIntervalSinceNow:
			waittime];
        xevent = [NSApp nextEventMatchingMask:NSAnyEventMask
			untilDate:date 
			inMode:NSDefaultRunLoopMode 
			dequeue:YES
		];
	}
}

-(void)keyDown:(NSEvent*)event {
	NSString* s = [event charactersIgnoringModifiers];

	id del = [self delegate];
	
	unichar key = [s characterAtIndex:0];
	switch(key) {
	case 9: {
		SEL sel = @selector(tableViewTabAway:);
		if([del respondsToSelector:sel]) {
			[del performSelector:sel withObject:
				[NSNotification notificationWithName:@"TAB" object:self]];
		}
		return; }
	case 13: {
		SEL sel = @selector(tableViewHitEnter:);
		if([del respondsToSelector:sel]) {
			[del performSelector:sel withObject:
				[NSNotification notificationWithName:@"ENTER" object:self]];
		}
		return; }
	case 32: {
		[self ofmRepeatEvent:event 
		           selector:@selector(tableViewHitSpace:)
		       notification:[NSNotification 
			notificationWithName:@"SPACE" object:self]
		];
		return; }
/*	case 127: {
		SEL sel = @selector(tableViewParentDir:);
		if([del respondsToSelector:sel]) {
			[del performSelector:sel withObject:
				[NSNotification notificationWithName:@"BACKSPACE" object:self]];
		}
		return; }*/
	case 63273: {
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
		return; }
	case 63275: {
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
		return; }
	case 63276: {
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
		return; }
	case 63277: {
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
		return; }
	case 63232: {
		if([event modifierFlags] & NSCommandKeyMask) {
			SEL sel = @selector(tableViewParentDir:);
			if([del respondsToSelector:sel]) {
				[del performSelector:sel withObject:
					[NSNotification notificationWithName:@"CMD+ARROWUP" object:self]];
			}
			return;
		} 
		[self ofmRepeatEvent:event 
		           selector:@selector(tableViewArrowUp:)
		       notification:[NSNotification 
			notificationWithName:@"ARROWUP" object:self]
		];
		return; }
	case 63233: {
		[self ofmRepeatEvent:event 
		           selector:@selector(tableViewArrowDown:)
		       notification:[NSNotification 
			notificationWithName:@"ARROWDOWN" object:self]
		];
		return; }
	case 63234: {
		NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
		    [NSNumber numberWithBool:NO], @"right", nil];
		SEL sel = @selector(tableViewShowMenu:);
		if([del respondsToSelector:sel]) {
			[del performSelector:sel withObject:
				[NSNotification notificationWithName:@"ARROW_LEFT" object:self userInfo:dict]];
		}
		return; }
	case 63235: {
		NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
		    [NSNumber numberWithBool:YES], @"right", nil];
		SEL sel = @selector(tableViewShowMenu:);
		if([del respondsToSelector:sel]) {
			[del performSelector:sel withObject:
				[NSNotification notificationWithName:@"ARROW_RIGHT" object:self userInfo:dict]];
		}
		return; }
/*	case NSDeleteCharacter:
	case NSBackspaceCharacter:
	case NSDeleteFunctionKey:
		// pressing Delete (or Backspace) removes the selected bricks
		// TRACE("delete pressed");
		// [self delete:self];
		return;*/
/*	default:
		NSLog(@"OFMTableView keydown: unknown key=%i\n", key);/**/
	}
	
	BOOL is_ascii = ((key >= 33) && (key <= 127));
	if(is_ascii && (key != 47)) {
		// NSLog(@"%s key ascii", _cmd);
		NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
		    [NSNumber numberWithInt:key], @"key", nil];
		SEL sel = @selector(tableViewEnterAscii:);
		if([del respondsToSelector:sel]) {
			[del performSelector:sel withObject:
				[NSNotification notificationWithName:@"ASCII_KEY" object:self userInfo:dict]];
		}
		return; 
	}

	[super keyDown:event];
}

#if 0
- (void)highlightSelectionInClipRect:(NSRect)clipRect
{
   NSColor *evenColor   // empirically determined color, matches iTunes etc.
      = [NSColor colorWithCalibratedRed:0.929
            green:0.953 blue:0.996 alpha:1.0];
   NSColor *oddColor  = [NSColor greenColor];
   
   float rowHeight
      = [self rowHeight] + [self intercellSpacing].height;
   NSRect visibleRect = [self visibleRect];
   NSRect highlightRect;
   
   highlightRect.origin = NSMakePoint(
      NSMinX(visibleRect),
      (int)(NSMinY(clipRect)/rowHeight)*rowHeight);
   highlightRect.size = NSMakeSize(
      NSWidth(visibleRect),
      rowHeight - [self intercellSpacing].height);
   
   while (NSMinY(highlightRect) < NSMaxY(clipRect))
   {
      NSRect clippedHighlightRect
         = NSIntersectionRect(highlightRect, clipRect);
      int row = (int)
         ((NSMinY(highlightRect)+rowHeight/2.0)/rowHeight);

      NSColor *rowColor
         = (((row - 1) / 3) & 1) ? evenColor : oddColor;
		if(row == 0) rowColor = [NSColor redColor];

      [rowColor set];
      NSRectFill(clippedHighlightRect);
      highlightRect.origin.y += rowHeight;
   }
   
   [super highlightSelectionInClipRect: clipRect];
}
#endif

-(void)drawRow:(int)rowIndex clipRect:(NSRect)clipRect {
	/*
	TODO: don't alloc NSColor's in drawRow:clipRect: it's slowing it down.
	*/

	// switch color for every 3 row
	if((rowIndex > 0) && ([self isRowSelected: rowIndex] == NO)){
		NSColor* color = nil;
		if(((rowIndex - 1) / 3) & 1) {
		// if((rowIndex - 1) & 4) {
			// color = [NSColor colorWithCalibratedWhite:0.96 alpha:1.0];
			color = [[NSColor controlAlternatingRowBackgroundColors] objectAtIndex:1];
		} else {
			// color = [NSColor colorWithCalibratedWhite:0.96 alpha:1.0];
/*			color = [NSColor colorWithCalibratedRed:0.86
			                           green:0.91
			                            blue:0.94
			                           alpha:1.0];*/
			color = [[NSColor controlAlternatingRowBackgroundColors] objectAtIndex:0];
		}
		[color set];
		NSRectFill([self rectOfRow: rowIndex]);
	} else {
/*		[[NSColor redColor] set];
		NSRectFill([self rectOfRow: rowIndex]);*/
	}
	[super drawRow: rowIndex clipRect: clipRect];
}

/*- (void)drawBackgroundInClipRect:(NSRect)clipRect {
	// paint drop shadow under the list to make it look more polished
	[[NSColor redColor] set];
	NSRectFill(clipRect);
}*/

-(void)tableViewArrowUp:(NSNotification*)aNotification {
	int row_count = [self numberOfRows];
	if(row_count < 1) return;

	int row = [self selectedRow];
	row -= 1;
	if(row < 0) return;
	
	[self scrollRowToVisible:row];
	
	NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:row];
	[self selectRowIndexes:indexes byExtendingSelection:NO];
}

-(void)tableViewArrowDown:(NSNotification*)aNotification {
	int row_count = [self numberOfRows];
	if(row_count < 1) return;

	int row = [self selectedRow];
	row += 1;
	if(row >= row_count) return;
	
	[self scrollRowToVisible:row];
	
	NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:row];
	[self selectRowIndexes:indexes byExtendingSelection:NO];
}

-(void)tableViewPageUp:(NSNotification*)aNotification {
	// id thing1 = [aNotification object];
	// NSLog(@"%@", aNotification);

	id thing2 = [aNotification userInfo];
	thing2 = [thing2 objectForKey:@"repeat"];
	BOOL repeat = [thing2 boolValue];
	// NSLog(@"repeat: %i", (int)repeat);

	int rows = [self numberOfRows];
	int row = [self selectedRow];     
		
	NSRect r = [[self enclosingScrollView] documentVisibleRect];
	
	NSRange range = [self rowsInRect:r];
	// NSLog(@"%s %i %i", _cmd, (int)range.location, (int)range.length);

	int visiblerow = 0;
	int index = row;
	if(0) {
		logic_for_page_up1(range, row, rows, &index, &visiblerow);
	} else {
		logic_for_page_up2(range, row, rows, &index, &visiblerow);
	}

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
	// NSLog(@"%@", aNotification);

	id thing2 = [aNotification userInfo];
	thing2 = [thing2 objectForKey:@"repeat"];
	BOOL repeat = [thing2 boolValue];
	// NSLog(@"repeat: %i", (int)repeat);
	
	NSTableView* tv = self;
		
	int rows = [tv numberOfRows];
	int row = [tv selectedRow];     
	NSRect r = [[tv enclosingScrollView] documentVisibleRect];
	NSRange range = [tv rowsInRect:r];

	int visiblerow = 0;
	int index = row;
	if(0) {
		logic_for_page_down1(range, row, rows, &index, &visiblerow);
		[tv scrollRowToVisible:visiblerow];
	} else 
	if(0) {
		logic_for_page_down2(range, row, rows, &index, &visiblerow);
		[tv scrollRowToVisible:visiblerow];
	} else 
	if(1) {
		logic_for_page_down3(range, row, rows, &index, &visiblerow);
		[tv scrollRowToVisible:rows - 1];
		[tv scrollRowToVisible:visiblerow];
	}
	
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

-(NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
	return NSDragOperationCopy; // works with Textmate + Finder + Terminal + Pages
}

-(void)drawBackgroundImage
{
	if (m_background_image != nil)
	{
		NSRect visRect = [[self enclosingScrollView] documentVisibleRect];

		[m_background_image setFlipped:YES];
						
		NSSize s1 = [m_background_image size];
		NSSize s2 = [self frame].size;
		NSRect r1 = NSMakeRect(
			floorf((s2.width - s1.width) * 0.5f), 
			floorf((s2.height - s1.height) * 0.5f), 
			s1.width, 
			s1.height
		);
		NSRect r2 = NSMakeRect(
			0, 
			0, 
			s1.width, 
			s1.height
		);
		[m_background_image drawInRect:r1
			fromRect:r2
			operation:NSCompositeSourceOver
			fraction:1.0];
		[m_background_image setFlipped:NO];
	}
}

- (void)drawBackgroundInClipRect:(NSRect)clipRect
{	
	// drawing our background image in this method does not work all by itself,
	// because the clipping area has been set and not ALL the background
	// will update properly.  You also need to implement "drawRect" as well
	//
	[super drawBackgroundInClipRect:clipRect];
        
	[self drawBackgroundImage];
}

- (void)drawRect:(NSRect)drawRect {
	[self drawBackgroundImage];
	[super drawRect: drawRect];
}

-(void)setBackgroundImage:(NSImage*)image {
	[m_background_image autorelease];
	m_background_image = [image retain];
	[self setNeedsDisplay: YES];
}

@end
