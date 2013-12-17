//
//  NCMainWindow.m
//  NCCore
//
//  Created by Simon Strandgaard on 21/06/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NCMainWindow.h"


@implementation NCMainWindow

-(void)sendEvent:(NSEvent*)event {
//	NSLog(@"%s %@", _cmd, event);
	if([event type] == NSFlagsChanged) {
		id del = [self delegate];
		if([del respondsToSelector:@selector(flagsChangedInWindow:)]) {
			[del flagsChangedInWindow:self];
		}
	}
	[super sendEvent:event];
}


@end
