//
//  LayouterAppDelegate.m
//  Layouter
//
//  Created by Simon Strandgaard on 6/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LayouterAppDelegate.h"
#import "VerticalLayoutView.h"
#import "DebugView.h"


@implementation LayouterAppDelegate

@synthesize window;
@synthesize verticalLayoutView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
	NSView* flexible_view = nil;
    {
		NSRect r = NSMakeRect(0, 0, 50, 50);
        DebugView* v = [[[DebugView alloc] initWithFrame:r] autorelease];
        v.colorName = @"green";
        [self.verticalLayoutView addSubview:v];
    }
    {
		NSRect r = NSMakeRect(0, 0, 50, 50);
        DebugView* v = [[[DebugView alloc] initWithFrame:r] autorelease];
        v.colorName = @"purple";
        [self.verticalLayoutView addSubview:v];
    }

    {
		NSRect r = NSMakeRect(0, 0, 50, 50);
        DebugView* v = [[[DebugView alloc] initWithFrame:r] autorelease];
        v.colorName = @"blue";
        v.insetY = 0;
        [self.verticalLayoutView addSubview:v];
		flexible_view = v;
    }
    
    {
		NSRect r = NSMakeRect(0, 0, 50, 50);
        DebugView* v = [[[DebugView alloc] initWithFrame:r] autorelease];
        v.colorName = @"yellow";
        [self.verticalLayoutView addSubview:v];
    }

    {
		NSRect r = NSMakeRect(0, 0, 50, 50);
        DebugView* v = [[[DebugView alloc] initWithFrame:r] autorelease];
        v.colorName = @"red";
        [self.verticalLayoutView addSubview:v];
    }

	[self.verticalLayoutView setHeight:20 forIndex:0];
	[self.verticalLayoutView setHeight:20 forIndex:1];
	[self.verticalLayoutView setHeight:20 forIndex:2];
	[self.verticalLayoutView setHeight:20 forIndex:3];
	[self.verticalLayoutView setHeight:20 forIndex:4];
	[self.verticalLayoutView setFlexibleView:flexible_view];
}

@end
