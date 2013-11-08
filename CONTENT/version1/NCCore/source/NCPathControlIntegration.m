//
//  NCPathControlIntegration.m
//  NCCore
//
//  Created by Simon Strandgaard on 03/08/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <InterfaceBuilderKit/InterfaceBuilderKit.h>
#import <NCCore/NCPathControl.h>
// #import "MyInspector.h"

@implementation NCPathControl ( NCPathControlIntegration )

- (void)ibPopulateKeyPaths:(NSMutableDictionary *)keyPaths {
    [super ibPopulateKeyPaths:keyPaths];

	// Remove the comments and replace "MyFirstProperty" and "MySecondProperty" 
	// in the following line with a list of your view's KVC-compliant properties.
    [[keyPaths objectForKey:IBAttributeKeyPaths] addObjectsFromArray:[NSArray arrayWithObjects:/* @"MyFirstProperty", @"MySecondProperty",*/ nil]];
}

/*- (void)ibPopulateAttributeInspectorClasses:(NSMutableArray *)classes {
    [super ibPopulateAttributeInspectorClasses:classes];
	// Replace "NCPathControlIntegrationInspector" with the name of your inspector class.
    [classes addObject:[NCPathControlIntegrationInspector class]];
} /**/

@end
