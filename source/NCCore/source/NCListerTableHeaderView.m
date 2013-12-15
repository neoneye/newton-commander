//
//  NCListerTableHeaderView.m
//  NCCore
//
//  Created by Simon Strandgaard on 11/02/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NCListerTableHeaderView.h"


@implementation NCListerTableHeaderView


- (BOOL)becomeFirstResponder {
	// NSLog(@"%s", _cmd);
	return [super becomeFirstResponder];
}


@end
