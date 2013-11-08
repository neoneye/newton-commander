//
//  NCPreferencesGeneralController.m
//  NCCore
//
//  Created by Simon Strandgaard on 20/03/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "NCPreferencesGeneralController.h"


@implementation NCPreferencesGeneralController

- (NSString *)title
{
	return NSLocalizedString(@"General", @"Title of 'General' preference pane");
}

- (NSString *)identifier
{
	return @"GeneralPane";
}

- (NSImage *)image
{
	return [NSImage imageNamed:@"NSPreferencesGeneral"];
}

@end
