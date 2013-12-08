//
//  AppDelegate.h
//  NewtonCommander
//
//  Created by Simon Strandgaard on 24/01/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NCMainWindowController;

@interface AppDelegate : NSObject <NSApplicationDelegate> {
	NCMainWindowController* myWindowController;

	IBOutlet NSMenu* m_bookmarks_menu;
}


-(IBAction)showHelp:(id)sender;

-(IBAction)showPreferencesPanel:(id)sender;
-(void)showLeftMenuPaneInPreferencesPanel:(id)sender;
-(void)showRightMenuPaneInPreferencesPanel:(id)sender;
-(void)showBookmarkPaneInPreferencesPanel:(id)sender;

@end
