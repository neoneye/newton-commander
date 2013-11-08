/*********************************************************************
KCReadOnlyTextView.mm - NSTextView with different keybindings

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#include "KCReadOnlyTextView.h"

@implementation KCReadOnlyTextView

#if 0
/*
I can't figure out how one draws a focus ring around a NSTextView ? 
*/
- (BOOL)becomeFirstResponder {
	NSLog(@"%s", _cmd);
	[self setFocusRingType:NSFocusRingTypeExterior];                     
	// [self setFocusRingType:NSFocusRingTypeDefault];
	// [[self enclosingScrollView] setFocusRingType:NSFocusRingTypeExterior];
	// [[self enclosingScrollView] setFocusRingType:NSFocusRingTypeDefault];
	return YES;
}

- (BOOL)resignFirstResponder {
	NSLog(@"%s", _cmd);
	// [self setFocusRingType:NSFocusRingTypeNone];
	[[self enclosingScrollView] setFocusRingType:NSFocusRingTypeNone];
	return YES;
}
#endif

-(void)keyDown:(NSEvent*)event {
	id del = [self delegate];
	NSString* s = [event charactersIgnoringModifiers];
	unichar key = [s characterAtIndex:0];
	switch(key) {
	case 9: {
		// NSLog(@"KCReadOnlyTextView %s TAB", _cmd);
		SEL sel = @selector(readonlyTableviewTabAway:);
		if([del respondsToSelector:sel]) {
			[del performSelector:sel withObject:
				[NSNotification notificationWithName:@"TAB" object:self]];
		}
		return; }
	case 63273: {
		// NSLog(@"KCReadOnlyTextView %s HOME", _cmd);
		[self moveToBeginningOfDocument:nil];
		return; }
	case 63275: {
		// NSLog(@"KCReadOnlyTextView %s END", _cmd);
		[self moveToEndOfDocument:nil];
		return; }
/*	default:
		NSLog(@"KCReadOnlyTextView keydown: unknown key=%i\n", key);/**/
	}
	[super keyDown:event];
}

@end
