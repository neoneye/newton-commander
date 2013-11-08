//
//  NCTabBarInspector.m
//  NCCore
//
//  Created by Simon Strandgaard on 24/01/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "NCTabBarInspector.h"

@implementation NCTabBarInspector

- (NSString *)viewNibName {
    return @"NCTabBarInspector";
}

- (void)refresh {
	// Synchronize your inspector's content view with the currently selected objects
	[super refresh];
}

@end
