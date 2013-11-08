//
//  demoAppDelegate.m
//  demo
//
//  Created by Simon Strandgaard on 23/01/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "demoAppDelegate.h"
#import <PSMTabBarControl/PSMTabBarControl.h>

@implementation demoAppDelegate

@synthesize window;

- (void)awakeFromNib {
	[m_psmtabbar awakeFromNib];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	
	// PSMTabBarControl* tabbar = [[PSMTabBarControl alloc] initWithFrame:NSMakeRect(0, 0, 400, 22)];
	m_psmtabbar2 = [[PSMTabBarControl alloc] initWithFrame:NSMakeRect(0, 0, 400, 22)];
	[[window contentView] addSubview:m_psmtabbar2];
	[m_psmtabbar2 setTabView:m_tabview];
	[m_tabview setDelegate:m_psmtabbar2]; /**/
	
	[m_psmtabbar2 setShowAddTabButton:YES];
    [[m_psmtabbar2 addTabButton] setTarget:self];
    [[m_psmtabbar2 addTabButton] setAction:@selector(addNewTab:)];

	// [m_psmtabbar2 setTearOffStyle:PSMTabBarTearOffAlphaWindow];
	// [m_psmtabbar2 setAllowsScrubbing:YES];
	
	
	[m_psmtabbar setShowAddTabButton:YES];
	[m_psmtabbar setUseOverflowMenu:YES];
	[m_psmtabbar setAlwaysShowActiveTab:YES];
	[m_psmtabbar setHideForSingleTab:NO];
	[m_psmtabbar setCellMaxWidth:200];
	[m_psmtabbar setCellMinWidth:100];
	[m_psmtabbar setCellOptimumWidth:150];
	[m_psmtabbar setSizeCellsToFit:YES];
	[m_psmtabbar setOrientation:PSMTabBarHorizontalOrientation];
	[m_psmtabbar hideTabBar:NO animate:NO];
	[m_psmtabbar setStyleNamed:@"Metal"];
	

	// hook up add tab button
	[[m_psmtabbar addTabButton] setTarget:self];
	[[m_psmtabbar addTabButton] setAction:@selector(addNewTab:)];

    // remove any tabs present in the nib
    NSArray *existingItems = [m_tabview tabViewItems];
    NSEnumerator *e = [existingItems objectEnumerator];
    NSTabViewItem *item;
    while (item = [e nextObject]) {
       [m_tabview removeTabViewItem:item];
    }

/*	[m_psmtabbar setTabView:m_tabview];
	[m_tabview setDelegate:m_psmtabbar]; */
	// [m_psmtabbar setPartnerView:m_tabview];
	
	// [m_psmtabbar update:YES];
	[m_psmtabbar update:NO];
	
	[self addNewTab:self];
	[self addNewTab:self];
}

- (IBAction)addNewTab:(id)sender
{
    NSTabViewItem *newItem = [[[NSTabViewItem alloc] initWithIdentifier:@"ident"] autorelease];
    [newItem setLabel:@"Untitled"];
    [m_tabview addTabViewItem:newItem];
    [m_tabview selectTabViewItem:newItem];
	[m_psmtabbar update:NO];
}


@end
