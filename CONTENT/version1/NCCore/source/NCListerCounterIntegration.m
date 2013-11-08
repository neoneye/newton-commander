//
//  NCListerCounterIntegration.m
//  NCCore
//
//  Created by Simon Strandgaard on 15/02/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <InterfaceBuilderKit/InterfaceBuilderKit.h>
#import <NCCore/NCListerCounter.h>
#import "NCListerCounterInspector.h"

@implementation NCListerCounter ( NCListerCounterIntegration )

- (void)ibPopulateKeyPaths:(NSMutableDictionary *)keyPaths {
    [super ibPopulateKeyPaths:keyPaths];

	// Remove the comments and replace "MyFirstProperty" and "MySecondProperty" 
	// in the following line with a list of your view's KVC-compliant properties.
    // [[keyPaths objectForKey:IBAttributeKeyPaths] addObjectsFromArray:[NSArray arrayWithObjects:/* @"MyFirstProperty", @"MySecondProperty",*/ nil]];
    [[keyPaths objectForKey:IBAttributeKeyPaths] addObjectsFromArray:[NSArray arrayWithObjects:@"numberOfDirs", @"numberOfSelectedDirs", nil]];
}

- (void)ibPopulateAttributeInspectorClasses:(NSMutableArray *)classes {
    [super ibPopulateAttributeInspectorClasses:classes];
	// Replace "NCListerCounterIntegrationInspector" with the name of your inspector class.
    [classes addObject:[NCListerCounterInspector class]];
} /**/

-(IBInset)ibLayoutInset {
    IBInset inset = {0, 5, 0, 5};
    return inset;
}

-(NSSize)ibMinimumSize { return NSMakeSize(80,25); }
-(NSSize)ibMaximumSize { return NSMakeSize(100000,25); }

- (NSArray *)ibDefaultChildren {
	return [NSArray array];
}

- (NSView *)ibDesignableContentView {
	return self;
}

@end
