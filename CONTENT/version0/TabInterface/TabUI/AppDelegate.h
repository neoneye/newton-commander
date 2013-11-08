/*********************************************************************
AppDelegate.h - Experiments with tabviews

Copyright (c) 2010 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/

@class PSMTabBarControl;
@interface AppDelegate : NSObject {
	IBOutlet NSTabView* m_tabview;
	IBOutlet PSMTabBarControl* m_tabbar;
}

- (IBAction)addNewTab:(id)sender;

@end
