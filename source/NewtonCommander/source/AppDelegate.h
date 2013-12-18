//
//  AppDelegate.h
//  Newton Commander
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
