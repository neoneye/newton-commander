//
//  projectAppDelegate.h
//  project
//
//  Created by Simon Strandgaard on 23/04/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface projectAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
