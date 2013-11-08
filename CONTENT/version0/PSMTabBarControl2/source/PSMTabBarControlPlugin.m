//
//  PSMTabBarControl.m
//  PSMTabBarControl
//
//  Created by Simon Strandgaard on 21/01/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "PSMTabBarControlPlugin.h"

@implementation PSMTabBarControlPlugin
- (NSArray *)libraryNibNames {
    return [NSArray arrayWithObject:@"PSMTabBarControlLibrary"];
}

- (NSArray *)requiredFrameworks {
    return [NSArray arrayWithObjects:[NSBundle bundleWithIdentifier:@"com.positivespinmedia.PSMTabBarControlFramework"], nil];
}

@end
