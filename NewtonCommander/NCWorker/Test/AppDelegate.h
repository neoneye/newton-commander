//
//  NCWorkerAppDelegate.h
//  NCWorker
//
//  Created by Simon Strandgaard on 30/05/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCWorker.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NCWorkerController> {
    NSWindow *window;   
    NSTextView* textview;
	NCWorker* m_worker;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextView* textview;

-(void)append:(NSString*)s;

-(void)request1;
-(void)request2;

@end
