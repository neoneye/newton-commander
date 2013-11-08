//
//  demoAppDelegate.h
//  demo
//
//  Created by Simon Strandgaard on 23/01/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PSMTabBarControl;

@interface demoAppDelegate : NSObject <NSApplicationDelegate> {
    IBOutlet NSWindow *window;
	IBOutlet PSMTabBarControl* m_psmtabbar;
	IBOutlet NSTabView* m_tabview;
	
	PSMTabBarControl* m_psmtabbar2;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction)addNewTab:(id)sender;

@end
