//
//  NCDualPane.m
//  Newton Commander
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "NCLog.h"
#import "NCDualPane.h"
#import "NCDualPaneState.h"
#import "NCDualPaneStateList.h"
#import "NCDualPaneStateView.h"
#import "NCDualPaneStateInfo.h"
#import "NCDualPaneStateHelp.h"
#import "NCMainWindowController.h"


@implementation NCDualPane

-(void)setup {
	
	NCMainWindowController* wc = self.windowController;
	NSAssert(wc, @"windowcontroller must be initialized before setup");

	{
		NCDualPaneStateList* state_list = [[NCDualPaneStateList alloc] initWithSide:NCSideLeft];
		NCDualPaneStateHelp* state_help = [[NCDualPaneStateHelp alloc] initWithSide:NCSideLeft];
		NCDualPaneStateInfo* state_info = [[NCDualPaneStateInfo alloc] initWithSide:NCSideLeft];
		NCDualPaneStateView* state_view = [[NCDualPaneStateView alloc] initWithSide:NCSideLeft];
	
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
		NCDualPaneStateList* state_list = [[NCDualPaneStateList alloc] initWithSide:NCSideRight];
		NCDualPaneStateHelp* state_help = [[NCDualPaneStateHelp alloc] initWithSide:NCSideRight];
		NCDualPaneStateInfo* state_info = [[NCDualPaneStateInfo alloc] initWithSide:NCSideRight];
		NCDualPaneStateView* state_view = [[NCDualPaneStateView alloc] initWithSide:NCSideRight];
	
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

	NCDualPaneState* old_state = self.state;
	NSResponder* fr = [[self.windowController window] firstResponder];

	_state = new_state;
	[self setNextResponder:self.state];

	[self.windowController stateDidChange:new_state oldResponder:fr oldState:old_state];
}

-(void)tabKeyPressed:(id)sender {
	[self.state tabKeyPressed:sender];
}

// YES if the left panel is a lister panel that is active
-(BOOL)leftActive {
	return [self.state leftActive];
}

// YES if the right panel is a lister panel that is active
-(BOOL)rightActive {
	return [self.state rightActive];
}

-(void)saveState {
	NSString* ident = [self.state identifier];
	// LOG_DEBUG(@"saving state: %@", ident);
	[[NSUserDefaults standardUserDefaults] setObject:ident forKey:@"DualPaneState"];
}

-(void)loadState {
	NSString* ident = [[NSUserDefaults standardUserDefaults] stringForKey:@"DualPaneState"];
	
	NCDualPaneState* found_state = nil;
	
	NSArray* states = [NSArray arrayWithObjects:
		_stateLeftList,
		_stateLeftHelp,
		_stateLeftInfo,
		_stateLeftView,
		_stateRightList,
		_stateRightHelp,
		_stateRightInfo,
		_stateRightView,
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
