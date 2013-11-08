/*********************************************************************
JFGeneralPrefController.mm - misc global settings

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#import "JFGeneralPrefController.h"


@implementation JFGeneralPrefController

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
