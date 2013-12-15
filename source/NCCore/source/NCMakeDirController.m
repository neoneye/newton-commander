//
//  NCMakeDirController.m
//  NCCore
//
//  Created by Simon Strandgaard on 24/04/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NCLog.h"
#import "NCMakeDirController.h"


@implementation NCMakeDirController

@synthesize delegate = m_delegate;
@synthesize workingDir = m_working_dir;
@synthesize suggestName = m_suggest_name;

+(NCMakeDirController*)shared {
    static NCMakeDirController* shared = nil;
    if(!shared) {
        shared = [[NCMakeDirController allocWithZone:NULL] init];
    }
    return shared;
}

- (id)init {
	NSBundle* bundle = [NSBundle bundleForClass:[self class]];
	NSAssert(bundle, @"must be in the framework bundle");
	NSString* path = [bundle pathForResource:@"MakeDir" ofType:@"nib"];
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

	NSString* name = m_suggest_name ? m_suggest_name : @"";
	[m_textfield setStringValue:name];

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
	
	NSString* name = [m_textfield stringValue];
	NSString* path = [m_working_dir stringByAppendingPathComponent:name];
	
	NSString* unsafe_wdir = [path stringByDeletingLastPathComponent];
	if(![m_working_dir isEqual:unsafe_wdir]) {
		/*
		we don't want unsafe dirnames, e.g: "../../unsafe/dir/dirname"
		we only want "dirname"
		*/
		LOG_DEBUG(@"ERROR: %s dirname is unsafe: %@", _cmd, name);
		return;
	}
	
	if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		LOG_DEBUG(@"ERROR: %s name is already taken: %@", _cmd, name);
		return;
	}
	
	//NSData* contents = [NSData data];
	
	NSDictionary* attr = nil;
	// NSDictionary* attr = [NSDictionary dictionary];
	/*
	NSFileOwnerAccountName
	NSFileGroupOwnerAccountName
	NSFilePosixPermissions
	NSFileCreationDate
	NSFileModificationDate
	*/

	BOOL ok = [[NSFileManager defaultManager] 
		createDirectoryAtPath:path 
		withIntermediateDirectories:NO 
		attributes:attr 
		error:NULL];
	if(ok) {
		LOG_DEBUG(@"%s dir created successfully:  %@", _cmd, path);
	} else {
		LOG_DEBUG(@"ERROR: %s couldn't create dir:  %@", _cmd, path);
		return;
	}
	
	[[self window] close];
	[NSApp endSheet:[self window] returnCode:0];

	if([m_delegate respondsToSelector:@selector(makeDirController:didMakeDir:)]) {
		[m_delegate makeDirController:self didMakeDir:path];
	}
}

-(IBAction)textAction:(id)sender {
	// IDEA: continuously check if the filename is available/taken and show status
	// LOG_DEBUG(@"%s", _cmd);
}

@end
