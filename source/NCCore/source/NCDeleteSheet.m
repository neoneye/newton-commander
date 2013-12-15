//
//  NCDeleteSheet.m
//  NCCore
//
//  Created by Simon Strandgaard on 28/04/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

/*
IDEA: use a nib file for the deletesheet, because we want to show 
many more controls.

IDEA: what about volumes that has no trashcan, should we offer a 
"permanent-delete" button? This is solved elegantly in muCommander

IDEA: make a list of files being deleted, with a big "cancel" button,
in case someone have second thoughts.
*/
#import "NCDeleteSheet.h"
#import "NCLog.h"


@implementation NCDeleteSheet

@synthesize delegate = m_delegate;
@synthesize paths = m_paths;

+(NCDeleteSheet*)shared {
    static NCDeleteSheet* shared = nil;
    if(!shared) {
        shared = [[NCDeleteSheet allocWithZone:NULL] init];
    }
    return shared;
}

- (id)init {
	if(self = [super init]) {
	}
    return self;
}

-(void)beginSheetForWindow:(NSWindow*)window {
	//NSLog(@"deleteController %s %@", _cmd, m_paths);
	
	int n_items = [m_paths count];
	if(n_items < 1) return;
	
	NSString* msg = @"Delete the item?";
	msg = [NSString stringWithFormat:@"Delete %i items?", n_items];

	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert addButtonWithTitle:@"Cancel"];
	[alert setMessageText:msg];
	[alert setInformativeText:@"Items will be moved to trash."];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert beginSheetModalForWindow:window 
		modalDelegate:self 
		didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) 
		contextInfo:nil];
}

-(void)alertDidEnd:(NSAlert*)alert
        returnCode:(NSInteger)rc 
       contextInfo:(void*)ctx
{
	// NSLog(@"%s", _cmd);
	if(rc != NSAlertFirstButtonReturn) {
		//NSLog(@"delete was cancelled by user");
		return;
	}
	LOG_DEBUG(@"deleting items...");

	NSEnumerator* e = [m_paths objectEnumerator];
	NSString* path;
	while((path = [e nextObject])) {
		LOG_DEBUG(@"deleting: %@", path);

		OSStatus status = 0;

		FSRef ref;
		status = FSPathMakeRefWithOptions(
			(const UInt8 *)[path fileSystemRepresentation], 
			kFSPathMakeRefDoNotFollowLeafSymlink,
			&ref, 
			NULL
		);	
		NSAssert((status == 0), @"failed to make FSRef");

		status = FSMoveObjectToTrashSync(
			&ref,
			NULL,
			kFSFileOperationDefaultOptions
		);

		if(status == 0) {
			LOG_DEBUG(@"moved item to trash successfully: %@", path);
		} else {
			LOG_WARNING(@"ERROR: couldn't move item to trash. Code=%i item=%@", (int)status, path);
		}
	}
	LOG_DEBUG(@"DONE: deleting items!");


	if([m_delegate respondsToSelector:@selector(deleteControllerDidDelete:)]) {
		[m_delegate deleteControllerDidDelete:self];
	}
}

@end
