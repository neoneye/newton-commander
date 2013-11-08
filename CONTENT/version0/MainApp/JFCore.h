//
//  JFCore.h
//  OrthodoxFileManager
//
//  Created by Simon Strandgaard on 16/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "JFCoreProtocol.h"

@class AppDelegate;

@interface JFCore : NSObject <JFCoreProtocol> {
	AppDelegate* m_appdelegate;
}
-(void)initAppDelegate;
-(void)run;

-(void)setBookmarkMenu:(NSMenu*)menu;

-(IBAction)reloadTab:(id)sender;
-(IBAction)swapTabs:(id)sender;
-(IBAction)mirrorTabs:(id)sender;
-(IBAction)cycleInfoPanes:(id)sender;
-(IBAction)revealInFinder:(id)sender;
-(IBAction)revealInfoInFinder:(id)sender;
-(IBAction)openFile:(id)sender;
-(IBAction)selectCenterRow:(id)sender;
-(IBAction)renameAction:(id)sender;
-(IBAction)mkdirAction:(id)sender;
-(IBAction)mkfileAction:(id)sender;
-(IBAction)deleteAction:(id)sender;
-(IBAction)moveAction:(id)sender;
-(IBAction)newCopyAction:(id)sender;
-(IBAction)copyAction:(id)sender;
-(IBAction)helpAction:(id)sender;
-(IBAction)viewAction:(id)sender;
-(IBAction)changeFontSizeAction:(id)sender;
-(IBAction)restartDiscoverTaskAction:(id)sender;
-(IBAction)forceCrashDiscoverTaskAction:(id)sender;     
-(IBAction)hideShowDiscoverStatWindowAction:(id)sender;
-(IBAction)hideShowReportStatWindowAction:(id)sender;
-(IBAction)debugInspectCacheAction:(id)sender;          
-(IBAction)debugSeparatorAction:(id)sender;             
-(IBAction)debugAction:(id)sender;             
-(IBAction)selectAllAction:(id)sender;
-(IBAction)selectNoneAction:(id)sender;
-(IBAction)selectAllOrNoneAction:(id)sender;
-(IBAction)invertSelectionAction:(id)sender;
-(IBAction)copyCurrentPathStringToClipboardAction:(id)sender;
-(IBAction)openDiffToolAction:(id)sender;
-(IBAction)openCurrentPathInTerminalAction:(id)sender;  
-(IBAction)showReportAction:(id)sender;
-(IBAction)installCommandlineToolAction:(id)sender;
-(IBAction)installKCHelperAction:(id)sender;
-(IBAction)launchDiscoverAction:(id)sender;
-(IBAction)showPreferencesPanel:(id)sender;
-(IBAction)showBookmarkPreferencesPanel:(id)sender;
-(IBAction)showAboutPanel:(id)sender;
-(IBAction)donateMoneyAction:(id)sender;
-(IBAction)visitWebsiteAction:(id)sender;

-(void)application:(NSApplication*)sender openFiles:(NSArray*)filenames;

@end
