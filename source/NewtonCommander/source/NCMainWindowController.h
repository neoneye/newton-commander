//
//  NCMainWindowController.h
//  NewtonCommander
//
//  Created by Simon Strandgaard on 25/01/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class NCListPanelController;
@class NCHelpPanelController;    
@class NCInfoPanelController;
@class NCViewPanelController;
@class NCDualPane;
@class NCDualPaneState;
@class NCToolbar;

@interface NCMainWindowController : NSWindowController {
	NCListPanelController* m_list_panel_controller_left;
	NCListPanelController* m_list_panel_controller_right;
	NCHelpPanelController* m_help_panel_controller_left;
	NCHelpPanelController* m_help_panel_controller_right;
	NCInfoPanelController* m_info_panel_controller_left;
	NCInfoPanelController* m_info_panel_controller_right;
	NCViewPanelController* m_view_panel_controller_left;
	NCViewPanelController* m_view_panel_controller_right;
	
	NSView* m_left_view;
	NSView* m_right_view;
	NSSplitView* m_split_view;
	
	NCDualPane* m_dualpane;
	
	NCToolbar* m_toolbar;
}
@property(assign) IBOutlet NSSplitView* splitView;
@property(assign) IBOutlet NSView* leftView;
@property(assign) IBOutlet NSView* rightView;
@property(nonatomic, retain) NCDualPane* dualPane;
@property(nonatomic, retain) NCToolbar* toolbar;
@property(nonatomic, readonly) NCListPanelController* listPanelControllerLeft;
@property(nonatomic, readonly) NCListPanelController* listPanelControllerRight;

-(void)stateDidChange:(NCDualPaneState*)snew oldResponder:(NSResponder*)resp oldState:(NCDualPaneState*)sold;

-(NSString*)activeWorkingDir;
-(void)setActiveWorkingDir:(NSString*)wdir;


-(void)fullReload;

-(void)save;

-(IBAction)changePermissionAction:(id)sender;
-(IBAction)copyAction:(id)sender;
-(IBAction)moveAction:(id)sender;
-(IBAction)makeDirAction:(id)sender;
-(IBAction)makeFileAction:(id)sender;
-(IBAction)makeLinkAction:(id)sender;
-(IBAction)deleteAction:(id)sender;
-(IBAction)gotoFolderAction:(id)sender;
-(IBAction)renameAction:(id)sender;

@end
