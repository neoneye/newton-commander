//
//  NCDualPaneStateList.m
//  NewtonCommander
//
//  Created by Simon Strandgaard on 18/02/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "NCLog.h"
#import "NCDualPane.h"
#import "NCDualPaneStateList.h"
#import "NCDualPaneStateHelp.h"
#import "NCDualPaneStateInfo.h"
#import "NCDualPaneStateView.h"
#import "NCMainWindowController.h"


@interface NCDualPaneStateList (Private)

@end

@implementation NCDualPaneStateList

@synthesize side = m_side;

- (id)initWithSide:(NCSide)side {
    self = [super init];
	if(self) {
		m_side = side;
	}
    return self;
}

/*-(void)dealloc {
	LOG_DEBUG(@"NCDualPaneStateList %s", _cmd);
    [super dealloc];
}*/

-(NSString*)description { 
	return (m_side == NCSideLeft) ? @"ListList0" : @"ListList1";
}

- (void)keyDown:(NSEvent *)event {
	// LOG_DEBUG(@"%@", event);

	NSString* s = [event charactersIgnoringModifiers];
	unichar key = [s characterAtIndex:0];
	switch(key) {
	case NSF1FunctionKey: {
		LOG_DEBUG(@"show help in the opposite panel");
		if([self side] == NCSideLeft) {
			[self changeState:[[self dualPane] stateLeftHelp]];
		} else {
			[self changeState:[[self dualPane] stateRightHelp]];
		}
		return; }
	case NSF2FunctionKey: {
		LOG_DEBUG(@"TODO: show menu for opposite panel");
		return; }
	case NSF3FunctionKey: {
		LOG_DEBUG(@"view details in the opposite panel");
		if([self side] == NCSideLeft) {
			[self changeState:[[self dualPane] stateLeftView]];
		} else {
			[self changeState:[[self dualPane] stateRightView]];
		}
		return; }
	case NSF4FunctionKey: {
		LOG_DEBUG(@"edit in the opposite panel");
		if([self side] == NCSideLeft) {
			[self changeState:[[self dualPane] stateLeftInfo]];
		} else {
			[self changeState:[[self dualPane] stateRightInfo]];
		}
		return; }
	case NSDeleteFunctionKey: {
		// LOG_DEBUG(@"delete selected items");
		[[[self dualPane] windowController] deleteAction:self];
		return; }
/*	case NSF5FunctionKey: {
		if([self side] == NCSideLeft) {
			LOG_DEBUG(@"TODO: copy from left to right");
		} else {
			LOG_DEBUG(@"TODO: copy from right to left");
		}
		return; }
	case NSF6FunctionKey: {
		if([self side] == NCSideLeft) {
			LOG_DEBUG(@"TODO: move from left to right");
		} else {
			LOG_DEBUG(@"TODO: move from right to left");
		}
		return; }
	case NSF7FunctionKey: {
		LOG_DEBUG(@"mkdir in this panel");
		return; }
	case NSF8FunctionKey: {
		LOG_DEBUG(@"delete in this panel");
		return; } */
	default: 
		LOG_DEBUG(@"unknown key pressed\n\n%@", event);
	}
	
	[super keyDown:event];
}


-(void)tabKeyPressed:(id)sender {
	if([self side] == NCSideLeft) {
		[self changeState:[[self dualPane] stateRightList]];
	} else {
		[self changeState:[[self dualPane] stateLeftList]];
	}
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
	return (m_side == NCSideLeft) ? @"SourceTarget" : @"TargetSource";
}

@end
