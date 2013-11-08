//
//  NCTabbedPathBarIntegration.m
//  NCCore
//
//  Created by Simon Strandgaard on 06/03/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <InterfaceBuilderKit/InterfaceBuilderKit.h>
#import <NCCore/NCTabbedPathBar.h>

@implementation NCTabbedPathBar ( NCTabbedPathBarIntegration )

- (void)ibPopulateKeyPaths:(NSMutableDictionary *)keyPaths {
    [super ibPopulateKeyPaths:keyPaths];

	// Remove the comments and replace "MyFirstProperty" and "MySecondProperty" 
	// in the following line with a list of your view's KVC-compliant properties.
    [[keyPaths objectForKey:IBAttributeKeyPaths] addObjectsFromArray:[NSArray arrayWithObjects:/* @"MyFirstProperty", @"MySecondProperty",*/ nil]];
}

/*- (void)ibPopulateAttributeInspectorClasses:(NSMutableArray *)classes {
    [super ibPopulateAttributeInspectorClasses:classes];
	// Replace "NCTabbedPathBarIntegrationInspector" with the name of your inspector class.
    [classes addObject:[NCTabbedPathBarIntegrationInspector class]];
}*/

-(IBInset)ibLayoutInset {
    IBInset inset = {5, 7, 5, 7};
    return inset;
}

-(NSSize)ibMinimumSize { return NSMakeSize(120,22); }
-(NSSize)ibMaximumSize { return NSMakeSize(100000,22); }


@end
