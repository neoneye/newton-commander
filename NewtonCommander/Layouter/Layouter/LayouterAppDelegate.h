//
//  LayouterAppDelegate.h
//  Layouter
//
//  Created by Simon Strandgaard on 6/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class VerticalLayoutView;

@interface LayouterAppDelegate : NSObject <NSApplicationDelegate> {
@private
    NSWindow *window;
    VerticalLayoutView *verticalLayoutView;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet VerticalLayoutView *verticalLayoutView;

@end
