/*********************************************************************
JFGeneralPrefController.h - misc global settings

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#import "MBPreferencesController.h"

@interface JFGeneralPrefController : NSViewController <MBPreferencesModule> {

}

-(NSString*)identifier;
-(NSImage*)image;

@end