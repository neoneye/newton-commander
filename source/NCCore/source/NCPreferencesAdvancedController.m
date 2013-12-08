//
//  NCPreferencesAdvancedController.m
//  NCCore
//
//  Created by Simon Strandgaard on 20/03/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

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
