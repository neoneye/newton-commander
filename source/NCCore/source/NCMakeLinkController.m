//
//  NCMakeLinkController.m
//  NCCore
//
//  Created by Simon Strandgaard on 26/04/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


/*

IDEA: add button: "relative from this dir" which assign a
link target path that is relative from the current working dir.

IDEA: add button: "relative from homedir" which assign a
link target path that is relative from the user's homedir.

IDEA: add button: "absolute" which assign a
link target path that is absolute.


IDEA: currently we can only create symlinks.. we want also to create aliases and hardlinks

NSURL *src = [NSURL URLWithString:@"file:///Users/bjh/Desktop/temp.m"];
NSURL *dest = [NSURL URLWithString:@"file:///Users/bjh/Desktop/myalias"];

NSData *bookmarkData = [src bookmarkDataWithOptions:NSURLBookmarkCreationSuitableForBookmarkFile
                  includingResourceValuesForKeys:nil
                                   relativeToURL:nil
                                           error:NULL];
[NSURL writeBookmarkData:bookmarkData
                toURL:dest
              options:0
                error:NULL];

*/

#import "NCLog.h"
#import "NCMakeLinkController.h"


@implementation NCMakeLinkController

@synthesize delegate = m_delegate;
@synthesize workingDir = m_working_dir;
@synthesize linkName = m_link_name;
@synthesize linkTarget = m_link_target;

+(NCMakeLinkController*)shared {
    static NCMakeLinkController* shared = nil;
    if(!shared) {
        shared = [[NCMakeLinkController allocWithZone:NULL] init];
    }
    return shared;
}

- (id)init {
	NSBundle* bundle = [NSBundle bundleForClass:[self class]];
	NSAssert(bundle, @"must be in the framework bundle");
	NSString* path = [bundle pathForResource:@"MakeLink" ofType:@"nib"];
	NSAssert(path, @"nib is not found in the framework bundle");
    self = [super initWithWindowNibPath:path owner:self];
	if(self) {
	}
    return self;
}

-(void)beginSheetForWindow:(NSWindow*)parentWindow {
	/*
	Wait until we are 100% sure that the nib has been fully loaded
	ensure that the window is loaded before we start operating
	on the views. [self window] invokes loadWindow internally.
	This method will wait until the load is completed.
	
	For more info, see
	NSWindowController - (NSWindow *)window
	*/
	NSWindow* window = [self window];
	NSAssert(window, @"loadWindow is supposed to init the window");

	// TODO: use suggest name code as in the makedir and makefile controllers
	[m_link_name_textfield setStringValue:m_link_name];
	[m_link_target_textfield setStringValue:m_link_target];

    [NSApp 
		beginSheet: window
        modalForWindow: parentWindow
		modalDelegate: self
		didEndSelector: nil //@selector(didEndSheet:returnCode:contextInfo:)
		contextInfo: nil
	];
}

-(IBAction)cancelAction:(id)sender {
	[[self window] close];
	[NSApp endSheet:[self window] returnCode:0];
}

-(IBAction)submitAction:(id)sender {
	NSString* target_path = [m_link_target_textfield stringValue];
	NSString* name = [m_link_name_textfield stringValue];
	NSString* path = [m_working_dir stringByAppendingPathComponent:name];
	
	NSString* unsafe_wdir = [path stringByDeletingLastPathComponent];
	if(![m_working_dir isEqual:unsafe_wdir]) {
		/*
		we don't want unsafe filenames, e.g: "../../unsafe/dir/filename.txt"
		we only want "filename.txt"
		*/
		LOG_DEBUG(@"ERROR: %s name is unsafe: %@", _cmd, name);
		return;
	}
	
	if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		LOG_DEBUG(@"ERROR: %s name is already taken: %@", _cmd, name);
		return;
	}
	
	//NSData* contents = [NSData data];
	
	//NSDictionary* attr = nil;
	// NSDictionary* attr = [NSDictionary dictionary];
	/*
	NSFileOwnerAccountName
	NSFileGroupOwnerAccountName
	NSFilePosixPermissions
	NSFileCreationDate
	NSFileModificationDate
	*/

	NSError* error = nil;
	BOOL ok = [[NSFileManager defaultManager] 
		createSymbolicLinkAtPath:path withDestinationPath:target_path error:&error];
	if(ok) {
		LOG_DEBUG(@"%s link created successfully:  %@  ->  %@", _cmd, path, target_path);
	} else {
		LOG_DEBUG(@"ERROR: %s couldn't create link:  %@  ->  %@\nerror: %@", _cmd, path, target_path, error);
		return;
	}
	
	/*
	TODO: warn the user if the link-target is invalid, but allow the user to create it
	*/
	
	[[self window] close];
	[NSApp endSheet:[self window] returnCode:0];

	if([m_delegate respondsToSelector:@selector(makeLinkController:didMakeLink:)]) {
		[m_delegate makeLinkController:self didMakeLink:path];
	}
}

-(IBAction)textAction:(id)sender {
	// IDEA: continuously check if the filename is available/taken and show status
	// LOG_DEBUG(@"%s", _cmd);
}

@end
