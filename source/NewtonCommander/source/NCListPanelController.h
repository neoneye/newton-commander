//
//  NCListPanelController.h
//  NewtonCommander
//
//  Created by Simon Strandgaard on 25/01/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class NCTabArray;
@protocol NCCopyOperationProtocol;
@protocol NCMoveOperationProtocol;

@protocol NCPanelControllerDelegate <NSObject>
@optional
-(void)tabKeyPressed:(id)sender;
-(void)switchToNextTab:(id)sender;
-(void)switchToPrevTab:(id)sender;
-(void)closeTab:(id)sender;
-(void)clickToActivatePanel:(id)sender;
-(void)workingDirDidChange:(id)sender;
-(void)tabViewItemsDidChange:(id)sender;
@end

@interface NCListPanelController : NSViewController

@property (weak) NSObject <NCPanelControllerDelegate> *delegate;

-(id)initAsLeftPanel:(BOOL)is_left_panel;


-(IBAction)newTab:(id)sender;

-(IBAction)selectAllOrNone:(id)sender;


-(void)saveTabState;

-(void)reload;

-(void)saveColumnLayout;
-(void)loadColumnLayout;

-(void)enterRenameMode;

-(IBAction)activatePanel:(id)sender;
-(IBAction)deactivatePanel:(id)sender;

-(NSString*)workingDir;
-(void)setWorkingDir:(NSString*)s;

-(NSString*)currentName;
-(NSArray*)selectedNamesOrCurrentName;

-(void)showGotoFolderSheet;

-(void)syncItemsWithController;

-(void)switchToUser:(int)user_id;

-(id<NCCopyOperationProtocol>)copyOperation;
-(id<NCMoveOperationProtocol>)moveOperation;

@end
