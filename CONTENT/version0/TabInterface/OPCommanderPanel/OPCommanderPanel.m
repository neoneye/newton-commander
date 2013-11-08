//
//  OPCommanderPanel.m
//  OPCommanderPanel
//
//  Created by Simon Strandgaard on 18/01/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "OPCommanderPanel.h"

@implementation OPCommanderPanel
- (NSArray *)libraryNibNames {
    return [NSArray arrayWithObject:@"OPCommanderPanelLibrary"];
}

- (NSArray *)requiredFrameworks {
    return [NSArray arrayWithObjects:
		[NSBundle bundleWithIdentifier:@"com.opcoders.OPCommanderPanel"], 
		[NSBundle bundleWithIdentifier:@"com.positivespinmedia.PSMTabBarControlFramework"], 
		nil
	];
}

- (void)xdidLoad {
	NSLog(@"%s", _cmd);

/*	// hook up add tab button
	[[m_tabbar addTabButton] setTarget:self];
	[[m_tabbar addTabButton] setAction:@selector(addNewTab:)]; */

	[super didLoad];
}

@end
