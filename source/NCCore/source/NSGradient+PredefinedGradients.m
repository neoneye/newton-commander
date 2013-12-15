//
//  NSGradient+ThemeExtensions.m
//  cocoa_clickable_headercell
//
//  Created by Simon Strandgaard on 03/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NSGradient+PredefinedGradients.h"


@implementation NSGradient (NCPredefinedGradients)

/*
g = Gradient.new
g.add([0.333])
g.add([0.859], [0.804], [0.733])
g.add([0.333])
puts g.result(25)
*/
+(id)tableHeaderGradient {
    return [[NSGradient alloc] initWithColorsAndLocations:
		[NSColor colorWithCalibratedWhite:0.333 alpha:1.000], 0.000,
		[NSColor colorWithCalibratedWhite:0.333 alpha:1.000], 0.040,
		[NSColor colorWithCalibratedWhite:0.859 alpha:1.000], 0.040,
		[NSColor colorWithCalibratedWhite:0.804 alpha:1.000], 0.500,
		[NSColor colorWithCalibratedWhite:0.733 alpha:1.000], 0.960,
		[NSColor colorWithCalibratedWhite:0.333 alpha:1.000], 0.960,
		[NSColor colorWithCalibratedWhite:0.333 alpha:1.000], 1.000,
		nil];  // height: 25 pixels
}

/*
g = Gradient.new
g.add([0.333])
g.add([0.769], [0.663], [0.584])
g.add([0.333])
puts g.result(25)
*/
+(id)tableHeaderPressedGradient {
    return [[NSGradient alloc] initWithColorsAndLocations:
		[NSColor colorWithCalibratedWhite:0.333 alpha:1.000], 0.000,
		[NSColor colorWithCalibratedWhite:0.333 alpha:1.000], 0.040,
		[NSColor colorWithCalibratedWhite:0.769 alpha:1.000], 0.040,
		[NSColor colorWithCalibratedWhite:0.663 alpha:1.000], 0.500,
		[NSColor colorWithCalibratedWhite:0.584 alpha:1.000], 0.960,
		[NSColor colorWithCalibratedWhite:0.333 alpha:1.000], 0.960,
		[NSColor colorWithCalibratedWhite:0.333 alpha:1.000], 1.000,
		nil];  // height: 25 pixels
}

/*
g = Gradient.new
g.add([0.333])
g.add([0.772, 0.812, 0.861], [0.649, 0.699, 0.782], [0.508, 0.575, 0.689])
g.add([0.333])
puts g.result(25)
*/
+(id)tableHeaderSelectedGradient {
    return [[NSGradient alloc] initWithColorsAndLocations:
		[NSColor colorWithCalibratedWhite:0.333 alpha:1.000], 0.000,
		[NSColor colorWithCalibratedWhite:0.333 alpha:1.000], 0.040,
		[NSColor colorWithCalibratedRed:0.772 green:0.812 blue:0.861 alpha:1.000], 0.040,
		[NSColor colorWithCalibratedRed:0.649 green:0.699 blue:0.782 alpha:1.000], 0.500,
		[NSColor colorWithCalibratedRed:0.508 green:0.575 blue:0.689 alpha:1.000], 0.960,
		[NSColor colorWithCalibratedWhite:0.333 alpha:1.000], 0.960,
		[NSColor colorWithCalibratedWhite:0.333 alpha:1.000], 1.000,
		nil];  // height: 25 pixels
}

/*
g = Gradient.new
g.add([0.333])
g.add([0.665, 0.718, 0.788], [0.503, 0.567, 0.678], [0.346, 0.422, 0.551])
g.add([0.333])
puts g.result(25)
*/
+(id)tableHeaderSelectedPressedGradient {
    return [[NSGradient alloc] initWithColorsAndLocations:
		[NSColor colorWithCalibratedWhite:0.333 alpha:1.000], 0.000,
		[NSColor colorWithCalibratedWhite:0.333 alpha:1.000], 0.040,
		[NSColor colorWithCalibratedRed:0.665 green:0.718 blue:0.788 alpha:1.000], 0.040,
		[NSColor colorWithCalibratedRed:0.503 green:0.567 blue:0.678 alpha:1.000], 0.500,
		[NSColor colorWithCalibratedRed:0.346 green:0.422 blue:0.551 alpha:1.000], 0.960,
		[NSColor colorWithCalibratedWhite:0.333 alpha:1.000], 0.960,
		[NSColor colorWithCalibratedWhite:0.333 alpha:1.000], 1.000,
		nil];  // height: 25 pixels
}

+(id)pinkGradient {
    return [[NSGradient alloc] initWithColorsAndLocations:
		[NSColor colorWithCalibratedRed:0.904 green:0.532 blue:0.746 alpha:1.000],0.0,
		[NSColor colorWithCalibratedRed:0.836 green:0.393 blue:0.637 alpha:1.000],0.25,
		[NSColor colorWithCalibratedRed:0.794 green:0.292 blue:0.566 alpha:1.000],0.5,
		[NSColor colorWithCalibratedRed:0.741 green:0.182 blue:0.485 alpha:1.000],0.75,
		[NSColor colorWithCalibratedRed:0.700 green:0.115 blue:0.407 alpha:1.000],1.0, 
		nil];
}

+(id)darkPinkGradient {
    return [[NSGradient alloc] initWithColorsAndLocations:
		[NSColor colorWithCalibratedRed:0.804 green:0.432 blue:0.646 alpha:1.000],0.0,
		[NSColor colorWithCalibratedRed:0.736 green:0.293 blue:0.537 alpha:1.000],0.25,
		[NSColor colorWithCalibratedRed:0.694 green:0.192 blue:0.466 alpha:1.000],0.5,
		[NSColor colorWithCalibratedRed:0.641 green:0.082 blue:0.385 alpha:1.000],0.75,
		[NSColor colorWithCalibratedRed:0.600 green:0.015 blue:0.307 alpha:1.000],1.0, 
		nil];
}

+(id)blueSelectedRowGradient {
    return [[NSGradient alloc] initWithColorsAndLocations:
		[NSColor colorWithCalibratedRed:0.215 green:0.411 blue:0.740 alpha:1.000], (CGFloat)0.0,
		[NSColor colorWithCalibratedRed:0.284 green:0.491 blue:0.796 alpha:1.000], (CGFloat)0.03,
		[NSColor colorWithCalibratedRed:0.270 green:0.474 blue:0.777 alpha:1.000], (CGFloat)0.08,
		[NSColor colorWithCalibratedRed:0.225 green:0.424 blue:0.745 alpha:1.000], (CGFloat)0.15,
		[NSColor colorWithCalibratedRed:0.179 green:0.371 blue:0.699 alpha:1.000], (CGFloat)0.5,
		[NSColor colorWithCalibratedRed:0.148 green:0.331 blue:0.672 alpha:1.000], (CGFloat)0.86,
		[NSColor colorWithCalibratedRed:0.130 green:0.308 blue:0.654 alpha:1.000], (CGFloat)0.95,
		[NSColor colorWithCalibratedRed:0.081 green:0.248 blue:0.606 alpha:1.000], (CGFloat)1.0,
		nil];
}

+(id)blackDividerGradient {
    return [[NSGradient alloc] initWithColorsAndLocations:
		[NSColor colorWithCalibratedWhite:0.118 alpha:1.000], (CGFloat)0.0,
		[NSColor colorWithCalibratedWhite:0.163 alpha:1.000], (CGFloat)0.15,
		[NSColor colorWithCalibratedWhite:0.166 alpha:1.000], (CGFloat)0.5,
		[NSColor colorWithCalibratedWhite:0.147 alpha:1.000], (CGFloat)0.85,
		[NSColor colorWithCalibratedWhite:0.118 alpha:1.000], (CGFloat)1.0,
		nil];
}

+(id)blackWindowGradient {
    return [[NSGradient alloc] initWithColorsAndLocations:
		[NSColor colorWithCalibratedRed:0.687 green:0.704 blue:0.737 alpha:1.000], (CGFloat)0.0,
		[NSColor colorWithCalibratedRed:0.687 green:0.704 blue:0.737 alpha:1.000], (CGFloat)0.01,
		[NSColor colorWithCalibratedRed:0.395 green:0.409 blue:0.471 alpha:1.000], (CGFloat)0.01,
		[NSColor colorWithCalibratedRed:0.278 green:0.291 blue:0.337 alpha:1.000], (CGFloat)0.09,
		[NSColor colorWithCalibratedRed:0.215 green:0.224 blue:0.260 alpha:1.000], (CGFloat)0.09,
		[NSColor colorWithCalibratedRed:0.209 green:0.214 blue:0.249 alpha:1.000], (CGFloat)0.5,
		[NSColor colorWithCalibratedRed:0.189 green:0.188 blue:0.219 alpha:1.000], (CGFloat)1.0,
		nil];
}

+(id)grayDiskUsageGradient {
    return [[NSGradient alloc] initWithColorsAndLocations:
		[NSColor colorWithCalibratedWhite:0.826 alpha:1.000], 0.0,
		[NSColor colorWithCalibratedWhite:0.737 alpha:1.000], 0.5,
		[NSColor colorWithCalibratedWhite:0.660 alpha:1.000], 1.0,
		nil];
}

+(id)pathControlGradient {
    return [[NSGradient alloc] initWithColorsAndLocations:
		[NSColor colorWithCalibratedWhite:0.769 alpha:1.000], 0.0,
		[NSColor colorWithCalibratedWhite:0.663 alpha:1.000], 0.5,
		[NSColor colorWithCalibratedWhite:0.584 alpha:1.000], 1.0,
		nil];
}

@end
