/*********************************************************************
AppDelegate.mm - Experiments with tabviews

Copyright (c) 2010 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#import "AppDelegate.h"
#import "RBSplitView.h"
#import "PSMTabBarControl.h"


@implementation AppDelegate

-(id)init {
	self = [super init];
    if(self) {
    }
    return self;
}

-(void)applicationDidFinishLaunching:(NSNotification*)notification {
	[RBSplitView class];
	
	// hook up add tab button
	[[m_tabbar addTabButton] setTarget:self];
	[[m_tabbar addTabButton] setAction:@selector(addNewTab:)];
}

- (IBAction)addNewTab:(id)sender
{
    NSTabViewItem *newItem = [[[NSTabViewItem alloc] initWithIdentifier:@"ident"] autorelease];
    [newItem setLabel:@"Untitled"];
    [m_tabview addTabViewItem:newItem];
    [m_tabview selectTabViewItem:newItem];
}

@end
