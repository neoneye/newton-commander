//
//  NCDualPane.m
//  NewtonCommander
//
//  Created by Simon Strandgaard on 18/02/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "NCLog.h"
#import "NCDualPane.h"
#import "NCDualPaneState.h"
#import "NCDualPaneStateList.h"
#import "NCDualPaneStateView.h"
#import "NCDualPaneStateInfo.h"
#import "NCDualPaneStateHelp.h"
#import "NCMainWindowController.h"


@implementation NCDualPane

@synthesize state = m_state;
@synthesize stateLeftList  = m_state_left_list;
@synthesize stateLeftHelp  = m_state_left_help;
@synthesize stateLeftInfo  = m_state_left_info;
@synthesize stateLeftView  = m_state_left_view;
@synthesize stateRightList = m_state_right_list;
@synthesize stateRightHelp = m_state_right_help;
@synthesize stateRightInfo = m_state_right_info;
@synthesize stateRightView = m_state_right_view;
@synthesize windowController = m_windowcontroller;

-(void)setup {
	
	NCMainWindowController* wc = m_windowcontroller;
	NSAssert(wc, @"windowcontroller must be initialized before setup");

	{
		NCDualPaneStateList* state_list = [[[NCDualPaneStateList alloc] initWithSide:NCSideLeft] autorelease];
		NCDualPaneStateHelp* state_help = [[[NCDualPaneStateHelp alloc] initWithSide:NCSideLeft] autorelease];
		NCDualPaneStateInfo* state_info = [[[NCDualPaneStateInfo alloc] initWithSide:NCSideLeft] autorelease];
		NCDualPaneStateView* state_view = [[[NCDualPaneStateView alloc] initWithSide:NCSideLeft] autorelease];
	
		[state_list setDualPane:self];
		[state_help setDualPane:self];
		[state_info setDualPane:self];
		[state_view setDualPane:self];
		
		[self setStateLeftList:state_list];
		[self setStateLeftHelp:state_help];
		[self setStateLeftInfo:state_info];
		[self setStateLeftView:state_view];
	}

	{
		NCDualPaneStateList* state_list = [[[NCDualPaneStateList alloc] initWithSide:NCSideRight] autorelease];
		NCDualPaneStateHelp* state_help = [[[NCDualPaneStateHelp alloc] initWithSide:NCSideRight] autorelease];
		NCDualPaneStateInfo* state_info = [[[NCDualPaneStateInfo alloc] initWithSide:NCSideRight] autorelease];
		NCDualPaneStateView* state_view = [[[NCDualPaneStateView alloc] initWithSide:NCSideRight] autorelease];
	
		[state_list setDualPane:self];
		[state_help setDualPane:self];
		[state_info setDualPane:self];
		[state_view setDualPane:self];

		[self setStateRightList:state_list];
		[self setStateRightHelp:state_help];
		[self setStateRightInfo:state_info];
		[self setStateRightView:state_view];
	}

}

-(void)shutdown {
	[self setNextResponder:nil];
	[self changeState:nil];
	[self setStateLeftList:nil];
	[self setStateLeftHelp:nil];          
	[self setStateLeftInfo:nil];
	[self setStateLeftView:nil];
	[self setStateRightList:nil];
	[self setStateRightHelp:nil];
	[self setStateRightInfo:nil];
	[self setStateRightView:nil];
}

-(void)setNextResponderForLeftAndRightStates:(NSResponder *)aResponder {
	[[self stateLeftList]  setNextResponder:aResponder];
	[[self stateLeftHelp]  setNextResponder:aResponder];
	[[self stateLeftInfo]  setNextResponder:aResponder];
	[[self stateLeftView]  setNextResponder:aResponder];
	[[self stateRightList] setNextResponder:aResponder];
	[[self stateRightHelp] setNextResponder:aResponder];
	[[self stateRightInfo] setNextResponder:aResponder];
	[[self stateRightView] setNextResponder:aResponder];
}


-(BOOL)acceptsFirstResponder {
	return NO;
}

-(BOOL)becomeFirstResponder {
	return YES;
}

- (void)keyDown:(NSEvent *)theEvent {
	// LOG_DEBUG(@"NCDualPane %s %@", _cmd, theEvent);
	// LOG_DEBUG(@"NCDualPane %s", _cmd);
	[super keyDown:theEvent];
}

-(void)changeState:(NCDualPaneState*)new_state {
	// LOG_DEBUG(@"NCDualPane change state %s from %@ to %@", _cmd, m_state, new_state);

	NCDualPaneState* old_state = m_state;
	NSResponder* fr = [[m_windowcontroller window] firstResponder];

	m_state = new_state;
	[self setNextResponder:m_state];

	[m_windowcontroller stateDidChange:new_state oldResponder:fr oldState:old_state];
}

-(void)tabKeyPressed:(id)sender {
	[m_state tabKeyPressed:sender];
}

// YES if the left panel is a lister panel that is active
-(BOOL)leftActive {
	return [m_state leftActive];
}

// YES if the right panel is a lister panel that is active
-(BOOL)rightActive {
	return [m_state rightActive];
}

-(void)saveState {
	NSString* ident = [m_state identifier];
	// LOG_DEBUG(@"saving state: %@", ident);
	[[NSUserDefaults standardUserDefaults] setObject:ident forKey:@"DualPaneState"];
}

-(void)loadState {
	NSString* ident = [[NSUserDefaults standardUserDefaults] stringForKey:@"DualPaneState"];
	
	NCDualPaneState* found_state = nil;
	
	NSArray* states = [NSArray arrayWithObjects:
		m_state_left_list,
		m_state_left_help,
		m_state_left_info,
		m_state_left_view,
		m_state_right_list,
		m_state_right_help,
		m_state_right_info,
		m_state_right_view,
		nil
	];
	for(NCDualPaneState* state in states) {
		if([[state identifier] isEqual:ident]) {
			found_state = state;
			// LOG_DEBUG(@"found state: %@", state);
			break;
		}
	}

	if(!found_state) {
		LOG_DEBUG(@"didn't find a saved state");
		return;
	}
	[self changeState:found_state];
}

@end
