//
//  JFCore.mm
//  OrthodoxFileManager
//
//  Created by Simon Strandgaard on 16/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "JFCore.h"
#import "AppDelegate.h"


@implementation JFCore

-(id)init {
    self = [super init];
	if(self) {
		m_appdelegate = nil;
	}
    return self;
}

-(void)setBookmarkMenu:(NSMenu*)menu {
	// NSLog(@"%s %08x %08x", _cmd, menu, m_appdelegate);
	[m_appdelegate setBookmarkMenu:menu];
}

-(void)initAppDelegate {
	// NSLog(@"%s TEST", _cmd);
	
	NSAssert(m_appdelegate == nil, @"must not be already initialized");
	m_appdelegate = [[AppDelegate alloc] init];

	NSString* nibName = @"MainWindow";

	if(![NSBundle loadNibNamed:nibName owner:m_appdelegate]) {
		NSLog(@"cannot load!");
	}
	// NSLog(@"%s loaded successfully", _cmd);
}

-(void)start {
	NSAssert(m_appdelegate != nil, @"must be initialized");
	[m_appdelegate start];
}

-(IBAction)reloadTab:(id)sender {
	[m_appdelegate reloadTab:sender];
}

-(IBAction)swapTabs:(id)sender {
	[m_appdelegate swapTabs:sender];
}

-(IBAction)mirrorTabs:(id)sender {
	[m_appdelegate mirrorTabs:sender];
}

-(IBAction)cycleInfoPanes:(id)sender {
	[m_appdelegate cycleInfoPanes:sender];
}

-(IBAction)revealInFinder:(id)sender {
	[m_appdelegate revealInFinder:sender];
}

-(IBAction)revealInfoInFinder:(id)sender {
	[m_appdelegate revealInfoInFinder:sender];
}

-(IBAction)selectCenterRow:(id)sender {
	[m_appdelegate selectCenterRow:sender];
}

-(IBAction)renameAction:(id)sender {
	[m_appdelegate renameAction:sender];
}

-(IBAction)mkdirAction:(id)sender {
	[m_appdelegate mkdirAction:sender];
}

-(IBAction)mkfileAction:(id)sender {
	[m_appdelegate mkfileAction:sender];
}

-(IBAction)deleteAction:(id)sender {
	[m_appdelegate deleteAction:sender];
}

-(IBAction)moveAction:(id)sender {
	[m_appdelegate moveAction:sender];
}

-(IBAction)newCopyAction:(id)sender {
	[m_appdelegate newCopyAction:sender];
}

-(IBAction)betterCopyAction:(id)sender {
	[m_appdelegate betterCopyAction:sender];
}

-(IBAction)copyAction:(id)sender {
	[m_appdelegate copyAction:sender];
}

-(IBAction)helpAction:(id)sender {
	[m_appdelegate helpAction:sender];
}

-(IBAction)viewAction:(id)sender {
	[m_appdelegate viewAction:sender];
}

-(IBAction)editAction:(id)sender {
	[m_appdelegate editAction:sender];
}

-(IBAction)changeFontSizeAction:(id)sender {
	[m_appdelegate changeFontSizeAction:sender];
}

-(IBAction)restartDiscoverTaskAction:(id)sender {
	[m_appdelegate restartDiscoverTaskAction:sender];
}

-(IBAction)forceCrashDiscoverTaskAction:(id)sender {
	[m_appdelegate forceCrashDiscoverTaskAction:sender];
}

-(IBAction)hideShowDiscoverStatWindowAction:(id)sender {
	[m_appdelegate hideShowDiscoverStatWindowAction:sender];
}

-(IBAction)hideShowReportStatWindowAction:(id)sender {
	[m_appdelegate hideShowReportStatWindowAction:sender];
}

-(IBAction)debugInspectCacheAction:(id)sender {
	[m_appdelegate debugInspectCacheAction:sender];
}

-(IBAction)debugSeparatorAction:(id)sender {
	[m_appdelegate debugSeparatorAction:sender];
}

-(IBAction)debugAction:(id)sender {
	[m_appdelegate debugAction:sender];
}

-(IBAction)selectAllAction:(id)sender {
	[m_appdelegate selectAllAction:sender];
}

-(IBAction)selectNoneAction:(id)sender {
	[m_appdelegate selectNoneAction:sender];
}

-(IBAction)selectAllOrNoneAction:(id)sender {
	[m_appdelegate selectAllOrNoneAction:sender];
}

-(IBAction)invertSelectionAction:(id)sender {
	[m_appdelegate invertSelectionAction:sender];
}

-(IBAction)copyCurrentPathStringToClipboardAction:(id)sender {
	[m_appdelegate copyCurrentPathStringToClipboardAction:sender];
}

-(IBAction)openDiffToolAction:(id)sender {
	[m_appdelegate openDiffToolAction:sender];
}

-(IBAction)openCurrentPathInTerminalAction:(id)sender {
	[m_appdelegate openCurrentPathInTerminalAction:sender];
}

-(IBAction)showReportAction:(id)sender {
	[m_appdelegate showReportAction:sender];
}

-(IBAction)installCommandlineToolAction:(id)sender {
	[m_appdelegate installCommandlineToolAction:sender];
}

-(IBAction)installKCHelperAction:(id)sender {
	[m_appdelegate installKCHelperAction:sender];
}

-(IBAction)launchDiscoverAction:(id)sender {
	[m_appdelegate launchDiscoverAction:sender];
}

-(IBAction)showPreferencesPanel:(id)sender {
	[m_appdelegate showPreferencesPanel:sender];
}

-(IBAction)showBookmarkPreferencesPanel:(id)sender {
	[m_appdelegate showBookmarkPreferencesPanel:sender];
}

-(IBAction)showAboutPanel:(id)sender {
	[m_appdelegate showAboutPanel:sender];
}

-(IBAction)donateMoneyAction:(id)sender {
	[m_appdelegate donateMoneyAction:sender];
}

-(IBAction)visitWebsiteAction:(id)sender {
	[m_appdelegate visitWebsiteAction:sender];
}

-(void)application:(NSApplication*)sender openFiles:(NSArray*)filenames {
	[m_appdelegate application:sender openFiles:filenames];
}

@end
