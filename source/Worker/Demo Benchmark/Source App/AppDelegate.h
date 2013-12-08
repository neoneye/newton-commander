//
//  BenchmarkAppDelegate.h
//  Benchmark
//
//  Created by Simon Strandgaard on 04/06/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
