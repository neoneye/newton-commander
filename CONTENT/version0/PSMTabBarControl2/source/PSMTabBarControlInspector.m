//
//  PSMTabBarControlInspector.m
//  PSMTabBarControl
//
//  Created by Simon Strandgaard on 21/01/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "PSMTabBarControlInspector.h"
#import "PSMTabBarControl.h"

@implementation PSMTabBarControlInspector

- (NSString *)viewNibName {
	return @"PSMTabBarControlInspector";
}

- (void)refresh {
	// Synchronize your inspector's content view with the currently selected objects.
	[super refresh];

	[self styleAction:m_style];
}

-(BOOL)supportsMultipleObjectInspection {
	return NO; // unpleasant or not, there's not an easy good way to handle multiple object inspection here
}

-(IBAction)styleAction:(id)sender {
	
	if ([[self inspectedObjects] count] > 0) {
		PSMTabBarControl* tbar = [[self inspectedObjects] objectAtIndex:0];
		if([sender indexOfSelectedItem] == 0) {
			[tbar setStyleNamed:@"Adium"];
		} else
		if([sender indexOfSelectedItem] == 1) {
			[tbar setStyleNamed:@"Aqua"];
		} else
		if([sender indexOfSelectedItem] == 2) {
			[tbar setStyleNamed:@"Metal"];
		} else {
			[tbar setStyleNamed:@"Unified"];
		}
	}
}

@end
