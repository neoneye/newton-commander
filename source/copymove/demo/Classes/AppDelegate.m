//
//  AppDelegate.m
//  demo
//
//  Created by Simon Strandgaard on 12/05/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import "AppDelegate.h"
#import "NameConflictDialog.h"

@interface AppDelegate ()
-(void)createTmpAppDir;
@end

@implementation AppDelegate

@synthesize window;
@synthesize temporaryApplicationDirectory = m_temporary_application_directory;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[self createTmpAppDir];

	[[NameConflictDialog shared] showWindow:nil];
}

-(void)createTmpAppDir {
	NSString* basedir = NSTemporaryDirectory();

	NSString* date_string = [[NSCalendarDate calendarDate]
		descriptionWithCalendarFormat:@"%Y%m%d_%H%M%S"];
		
	NSString* s = [NSString stringWithFormat:@"NewtonCommander%@", date_string];
	NSString* path = [basedir stringByAppendingPathComponent:s];
	
	NSFileManager* fm = [NSFileManager defaultManager];
	
	NSError* error = nil;
	BOOL ok = [fm createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:&error];
	if(!ok) {
		NSLog(@"%s failed to create tempdir: %@\n%@", _cmd, path, error);
		exit(EXIT_FAILURE);
	}
	
	NSLog(@"%s created tempdir: %@", _cmd, path);
	self.temporaryApplicationDirectory = path;
}

@end
