//
//  PSMTabBarControlView.m
//  PSMTabBarControl
//
//  Created by Simon Strandgaard on 21/01/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <InterfaceBuilderKit/InterfaceBuilderKit.h>
#import "PSMTabBarControl.h"
#import "PSMTabBarControlInspector.h"


@implementation PSMTabBarControl ( PSMTabBarControlIntegration )

- (void)ibPopulateKeyPaths:(NSMutableDictionary *)keyPaths {
    [super ibPopulateKeyPaths:keyPaths];
	
	// Remove the comments and replace "MyFirstProperty" and "MySecondProperty" 
	// in the following line with a list of your view's KVC-compliant properties.
    [[keyPaths objectForKey:IBAttributeKeyPaths] addObjectsFromArray:
		[NSArray arrayWithObjects:@"tabView", @"partnerView", @"delegate", /* @"MyFirstProperty", @"MySecondProperty",*/ nil]];
}

- (void)ibPopulateAttributeInspectorClasses:(NSMutableArray *)classes {
    [super ibPopulateAttributeInspectorClasses:classes];
    [classes addObject:[PSMTabBarControlInspector class]];
}

- (NSSize)ibMinimumSize { return NSMakeSize(80,22); }
- (NSSize)ibMaximumSize { return NSMakeSize(100000,22); }

@end
