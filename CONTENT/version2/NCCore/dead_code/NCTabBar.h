/*
TODO: remove the NCTabBar class it's no longer used
*/
//
//  NCTabBar.h
//  NCCore
//
//  Created by Simon Strandgaard on 24/01/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NCTabBar : NSView {
	int m_number_of_tabs;    
	int m_selected_index;
	BOOL m_is_active;
}
@property int numberOfTabs;
@property int selectedIndex;
@property BOOL isActive;

+(NSString*)testInfo;


-(IBAction)newTab:(id)sender;

-(IBAction)switchToNextTab:(id)sender;
-(IBAction)switchToPrevTab:(id)sender;

-(void)closeTab:(id)sender;

@end
