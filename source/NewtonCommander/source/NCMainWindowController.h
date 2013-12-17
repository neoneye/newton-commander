//
//  NCMainWindowController.h
//  NewtonCommander
//
//  Created by Simon Strandgaard on 25/01/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class NCListPanelController;
@class NCDualPane;
@class NCDualPaneState;
@class NCToolbar;

@interface NCMainWindowController : NSWindowController

@property(nonatomic, strong) NCDualPane* dualPane;
@property(nonatomic, strong) NCToolbar* toolbar;
@property(nonatomic, readonly) NCListPanelController* listPanelControllerLeft;
@property(nonatomic, readonly) NCListPanelController* listPanelControllerRight;

+ (NCMainWindowController*)mainWindowController;


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
