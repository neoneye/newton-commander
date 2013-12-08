//
//  NSGradient+ThemeExtensions.h
//  cocoa_clickable_headercell
//
//  Created by Simon Strandgaard on 03/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSGradient (NCPredefinedGradients)

// same colors as in iTunes 8.2.1 (6)
+(id)tableHeaderGradient;
+(id)tableHeaderPressedGradient;
+(id)tableHeaderSelectedGradient;
+(id)tableHeaderSelectedPressedGradient;


+(id)pinkGradient;
+(id)darkPinkGradient;

+(id)blackDividerGradient;
+(id)blackWindowGradient;


+(id)blueSelectedRowGradient;

+(id)grayDiskUsageGradient;


+(id)pathControlGradient;

@end
