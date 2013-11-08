//
//  OPCommanderPanelView.h
//  OPCommanderPanel
//
//  Created by Simon Strandgaard on 18/01/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PSMTabBarControl;

@interface OPCommanderPanelView : NSView {
	IBOutlet NSTabView* m_tabview;
	IBOutlet PSMTabBarControl* m_tabbar;
}

- (IBAction)addNewTab:(id)sender;

@end