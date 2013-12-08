/*
TODO: remove the NCTabbedPathBar class it's no longer used
*/
//
//  NCTabbedPathBar.h
//  NCCore
//
//  Created by Simon Strandgaard on 06/03/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class MAAttachedWindow;

@interface NCTabbedPathBar : NSView {
	NSPopUpButton* m_popupbutton;
	NSTextField* m_textfield;

	int m_number_of_tabs;    
	int m_selected_index;
	BOOL m_is_active;

	// NSString* m_path;
	MAAttachedWindow* m_tooltip;
}
@property (assign) IBOutlet NSPopUpButton* popUpButton;
@property (assign) IBOutlet NSTextField* textField;
@property (retain) MAAttachedWindow* tooltip;
@property int numberOfTabs;
@property int selectedIndex;
@property BOOL isActive;
// @property NSString* path;

-(void)reloadTabs;


-(void)setPath:(NSString*)path;

-(IBAction)showTooltip:(id)sender;
-(IBAction)hideTooltip:(id)sender;


@end
