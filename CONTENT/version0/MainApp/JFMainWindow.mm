/*********************************************************************
JFMainWindow.mm - a NSWindow with special keyboard event handler

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#import "JFMainWindow.h"

@interface JFMainWindow (Private)

@end

@implementation JFMainWindow

-(void)sendEvent:(NSEvent*)event {
	
	if([event type] == NSFlagsChanged) {
		// NSLog(@"%s %@", _cmd, event);

		NSUInteger flags = [event modifierFlags];
/*		BOOL is_cmd = ((flags & NSCommandKeyMask) != 0);
		BOOL is_alt = ((flags & NSAlternateKeyMask) != 0);
		BOOL is_ctrl = ((flags & NSControlKeyMask) != 0);
		BOOL is_shft = ((flags & NSShiftKeyMask) != 0);
		
		NSLog(@"%s cmd: %i  alt: %i  ctrl: %i  shift: %i  (flags: %08x)", _cmd, is_cmd, is_alt, is_ctrl, is_shft, flags); */

		id del = [self delegate];
		if([del respondsToSelector:@selector(mainWindow:flagsChanged:)]) {
			[del mainWindow:self flagsChanged:flags];
		}

	}
	
	[super sendEvent:event];
}

@end
