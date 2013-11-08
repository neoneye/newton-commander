//
//  OPCommanderPanelInspector.m
//  OPCommanderPanel
//
//  Created by Simon Strandgaard on 18/01/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "OPCommanderPanelInspector.h"

@implementation OPCommanderPanelInspector

- (NSString *)viewNibName {
	return @"OPCommanderPanelInspector";
}

- (void)refresh {
	// Synchronize your inspector's content view with the currently selected objects.
	[super refresh];
}

@end
