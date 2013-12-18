//
//  NCDualPane.h
//  Newton Commander
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
@interface NCDualPane : NSResponder

@property(readonly, weak) NCDualPaneState* state;
@property(nonatomic, strong) NCDualPaneStateList* stateLeftList;
@property(nonatomic, strong) NCDualPaneStateHelp* stateLeftHelp;
@property(nonatomic, strong) NCDualPaneStateInfo* stateLeftInfo;
@property(nonatomic, strong) NCDualPaneStateView* stateLeftView;
@property(nonatomic, strong) NCDualPaneStateList* stateRightList;
@property(nonatomic, strong) NCDualPaneStateHelp* stateRightHelp;
@property(nonatomic, strong) NCDualPaneStateInfo* stateRightInfo;
@property(nonatomic, strong) NCDualPaneStateView* stateRightView;
@property(nonatomic, strong) NCMainWindowController* windowController;

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
