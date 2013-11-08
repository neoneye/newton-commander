//
//  OPCommanderPanelView.m
//  OPCommanderPanel
//
//  Created by Simon Strandgaard on 18/01/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <InterfaceBuilderKit/InterfaceBuilderKit.h>
#import <OPCommanderPanel/OPCommanderPanelView.h>
#import "OPCommanderPanelInspector.h"


@implementation OPCommanderPanelView ( OPCommanderPanelView )

- (void)ibPopulateKeyPaths:(NSMutableDictionary *)keyPaths {
    [super ibPopulateKeyPaths:keyPaths];
	
	// Remove the comments and replace "MyFirstProperty" and "MySecondProperty" 
	// in the following line with a list of your view's KVC-compliant properties.
    [[keyPaths objectForKey:IBAttributeKeyPaths] addObjectsFromArray:[NSArray arrayWithObjects:/* @"MyFirstProperty", @"MySecondProperty",*/ nil]];
}

- (void)ibPopulateAttributeInspectorClasses:(NSMutableArray *)classes {
    [super ibPopulateAttributeInspectorClasses:classes];
    [classes addObject:[OPCommanderPanelInspector class]];
}

@end
