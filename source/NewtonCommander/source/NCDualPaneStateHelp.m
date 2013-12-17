//
//  NCDualPaneStateHelp.m
//  NewtonCommander
//
//  Created by Simon Strandgaard on 02/08/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "NCLog.h"
#import "NCDualPane.h"
#import "NCDualPaneStateList.h"
#import "NCDualPaneStateHelp.h"
#import "NCMainWindowController.h"


@implementation NCDualPaneStateHelp

@synthesize side = m_side;

- (id)initWithSide:(NCSide)side {
    self = [super init];
	if(self) {
		m_side = side;
	}
    return self;
}

-(NSString*)description { 
	return (m_side == NCSideLeft) ? @"ListHelp" : @"HelpList";
}

- (void)keyDown:(NSEvent *)event {
	NSString* s = [event charactersIgnoringModifiers];
	unichar key = [s characterAtIndex:0];
	switch(key) {
	case NSF1FunctionKey: {
		LOG_DEBUG(@"hide panel");
		if([self side] == NCSideLeft) {
			[self changeState:[[self dualPane] stateLeftList]];
		} else {
			[self changeState:[[self dualPane] stateRightList]];
		}
		return; }
	default: 
		LOG_DEBUG(@"unknown key pressed\n\n%@", event);
	}
	
	[super keyDown:event];
}

// YES if the left panel is a lister panel that is active
-(BOOL)leftActive {
	return ([self side] == NCSideLeft);
}

// YES if the right panel is a lister panel that is active
-(BOOL)rightActive {
	return ([self side] != NCSideLeft);
}

-(NSString*)identifier {
	return (m_side == NCSideLeft) ? @"ListHelp" : @"HelpList";
}

@end
