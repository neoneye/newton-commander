//
//  NCDualPane.h
//  NewtonCommander
//
//  Created by Simon Strandgaard on 18/02/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NCMainWindowController;
@class NCDualPaneState;
@class NCDualPaneStateList;
@class NCDualPaneStateHelp;
@class NCDualPaneStateInfo;
@class NCDualPaneStateView;


/*


NCDualPane job is to makes sure that all the events are dispatched to 
the NCDualPaneStateXXX that is currently active.

NCDualPane sits always in the responder chain like this:

   1. NSTableView
   2. NCXXXPanelController
   3. NCDualPane               <-------- this is our class
   4. NCDualPaneStateXXX
   5. NSWindow

Keyboard events are first delivered to the first responder (Here it's NSTableView),
If the first responder cannot deal with the keyboard event, then the event is
send to the NSTableView's next responder (Here it's NCXXXPanelController).
And the event is send further down the chain in case nobody deals with the event.


*/
@interface NCDualPane : NSResponder {
	NCDualPaneState* m_state;
	
	NCDualPaneStateList* m_state_left_list;
	NCDualPaneStateHelp* m_state_left_help;
	NCDualPaneStateInfo* m_state_left_info;
	NCDualPaneStateView* m_state_left_view;
	NCDualPaneStateList* m_state_right_list;
	NCDualPaneStateHelp* m_state_right_help;
	NCDualPaneStateInfo* m_state_right_info;
	NCDualPaneStateView* m_state_right_view;

	NCMainWindowController* m_windowcontroller;
}
@property(readonly, assign) NCDualPaneState* state;
@property(nonatomic, retain) NCDualPaneStateList* stateLeftList;
@property(nonatomic, retain) NCDualPaneStateHelp* stateLeftHelp;
@property(nonatomic, retain) NCDualPaneStateInfo* stateLeftInfo;
@property(nonatomic, retain) NCDualPaneStateView* stateLeftView;
@property(nonatomic, retain) NCDualPaneStateList* stateRightList;
@property(nonatomic, retain) NCDualPaneStateHelp* stateRightHelp;
@property(nonatomic, retain) NCDualPaneStateInfo* stateRightInfo;
@property(nonatomic, retain) NCDualPaneStateView* stateRightView;
@property(nonatomic, retain) NCMainWindowController* windowController;

-(void)setup;
-(void)shutdown;

-(void)setNextResponderForLeftAndRightStates:(NSResponder *)aResponder;

-(void)changeState:(NCDualPaneState*)newState;

-(void)tabKeyPressed:(id)sender;

// YES if the left panel is a lister panel that is active
-(BOOL)leftActive;

// YES if the right panel is a lister panel that is active
-(BOOL)rightActive;

-(void)saveState;
-(void)loadState;

@end
