//
//  NCListerCounterInspector.m
//  NCCore
//
//  Created by Simon Strandgaard on 12/03/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "NCListerCounterInspector.h"

@implementation NCListerCounterInspector

- (NSString *)viewNibName {
    return @"NCListerCounterInspector";
}

- (void)refresh {
	// Synchronize your inspector's content view with the currently selected objects
	[super refresh];
}

@end
