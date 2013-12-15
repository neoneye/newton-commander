//
//  NCPreferencesAdvancedController.m
//  NCCore
//
//  Created by Simon Strandgaard on 20/03/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NCPreferencesAdvancedController.h"


@implementation NCPreferencesAdvancedController

- (NSString *)title
{
	return NSLocalizedString(@"Advanced", @"Title of 'Advanced' preference pane");
}

- (NSString *)identifier
{
	return @"AdvancedPane";
}

- (NSImage *)image
{
	return [NSImage imageNamed:@"NSPreferencesGeneral"];
}

@end
