//
//  AppDelegate.h
//  demo
//
//  Created by Simon Strandgaard on 12/05/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {

    NSWindow* window;
	NSString* m_temporary_application_directory;
}

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, retain) NSString* temporaryApplicationDirectory;

@end
