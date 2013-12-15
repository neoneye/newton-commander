//
//  NCMoveSheet.m
//  NCCore
//
//  Created by Simon Strandgaard on 14/08/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NCLog.h"
#import "NCMoveSheet.h"
#import "NSView+SubviewExtensions.h"
#import "NCMoveOperationDummy.h"
#import "NCCommon.h"
#import "NCPathControl.h"


@implementation NCMoveSheetItem
@synthesize name, message, bytes, count;

-(NSString*)description {
	return [NSString stringWithFormat: 
		@"NCMoveSheetItem(%qi, %qi, %@, %@)", bytes, count, message, name];
}

+(NSArray*)itemsFromNames:(NSArray*)ary {
	NSMutableArray* result = [NSMutableArray arrayWithCapacity:[ary count]];
	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[NSString class]]) {
			NCMoveSheetItem* item = [[NCMoveSheetItem alloc] init];
			[item setName:(NSString*)thing];                        
			[item setMessage:@"?"];
			[item setCount:1];
			[item setBytes:0];
			[result addObject:item];
		}
	}
	return result;
}

@end



@interface NCMoveSheet (Private)

-(void)scanProgressResponse:(NSDictionary*)dict;
-(void)scanCompleteResponse:(NSDictionary*)dict;

-(void)transferProgressResponse:(NSDictionary*)dict;
-(void)transferProgressItemResponse:(NSDictionary*)dict;
-(void)transferCompleteResponse:(NSDictionary*)dict;

@end

@implementation NCMoveSheet
@synthesize delegate = m_delegate;
@synthesize confirmView = m_confirm_view;
@synthesize progressView = m_progress_view;
@synthesize confirmSummary = m_confirm_summary;
@synthesize confirmButton = m_confirm_button;
@synthesize progressIndicator = m_progress_indicator;
@synthesize abortButton = m_abort_button;
@synthesize progressSummary = m_progress_summary;
@synthesize confirmCloseWhenFinishedButton = m_confirm_close_when_finished_button;
@synthesize progressCloseWhenFinishedButton = m_progress_close_when_finished_button;
@synthesize names = m_names;
@synthesize sourceDir = m_source_dir;
@synthesize targetDir = m_target_dir;
@synthesize progressItems = m_progress_items;
@synthesize moveOperation = m_move_operation;
@synthesize confirmSourcePath = m_confirm_source_path;
@synthesize confirmTargetPath = m_confirm_target_path;
@synthesize progressSourcePath = m_progress_source_path;
@synthesize progressTargetPath = m_progress_target_path;

#pragma mark -
#pragma mark Setup code

+(NCMoveSheet*)shared {
    static NCMoveSheet* shared = nil;
    if(!shared) {
        shared = [[NCMoveSheet allocWithZone:NULL] init];
    }
    return shared;
}

- (id)init {
	NSBundle* bundle = [NSBundle mainBundle];
	NSAssert(bundle, @"must be in the framework bundle");
	NSString* path = [bundle pathForResource:@"MoveSheet" ofType:@"nib"];
	NSAssert(path, @"nib is not found in the framework bundle");
    self = [super initWithWindowNibPath:path owner:self];
	if(self) {

	}
    return self;
}


- (void)awakeFromNib {
	// LOG_DEBUG(@"called");
}

-(void)windowDidLoad {
	// LOG_DEBUG(@"called");
	NSView* view0 = m_confirm_view;
	NSView* view1 = m_progress_view;
	NSWindow* window = [self window];
	NSAssert(view0, @"view0 must be initialize in nib");
	NSAssert(view1, @"view1 must be initialize in nib");
	NSAssert(window, @"window must be initialize in nib");

	NSView* cv = [[NSView alloc] initWithFrame:[window frame]];
	[window setContentView:cv];
	[cv setAutoresizesSubviews:YES];

	[cv addResizedSubview:view0];
	[cv addResizedSubview:view1];

	[view0 setHidden:NO];
	[view1 setHidden:YES];
	
	 
	[m_confirm_source_path bind:@"path" toObject: self
		withKeyPath:@"sourceDir" options:nil];
	[m_confirm_target_path bind:@"path" toObject: self
		withKeyPath:@"targetDir" options:nil];
	[m_progress_source_path bind:@"path" toObject: self
		withKeyPath:@"sourceDir" options:nil];
	[m_progress_target_path bind:@"path" toObject: self
		withKeyPath:@"targetDir" options:nil];
		
	[m_confirm_source_path activate];
	[m_confirm_target_path deactivate];
	[m_progress_source_path activate];
	[m_progress_target_path deactivate];
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
	
	// [self updateCheckboxes];
	
	if(!m_move_operation) {
		[self setMoveOperation:[[NCMoveOperationDummy alloc] init]];
	}
	NSAssert(m_move_operation, @"moveOperation should not be nil at this point");
	[m_move_operation setMoveOperationDelegate:self];

	NSArray* names = [self names];
	NSString* src = [self sourceDir];
	NSString* dst = [self targetDir];

	NSArray* ary = [NCMoveSheetItem itemsFromNames:names];
	[m_progress_items setContent:ary];

	[m_confirm_summary setStringValue:@"Counting items…"];
	[m_progress_indicator setDoubleValue:0];

	[m_confirm_button setTitle:@"Counting…"];
	[m_confirm_button setEnabled:NO];
	[m_confirm_button setKeyEquivalent:@""];

	[m_abort_button setTitle:@"Cancel"];
	[m_abort_button setKeyEquivalent:@"\e"];
	
	[m_progress_view setHidden:YES];
	[m_confirm_view setHidden:NO];
    [NSApp 
		beginSheet: window
        modalForWindow: parentWindow
		modalDelegate: self
		didEndSelector: nil //@selector(didEndSheet:returnCode:contextInfo:)
		contextInfo: nil
	];
	
	// LOG_DEBUG(@"%s move from: %@", _cmd, m_source_paths);
	// LOG_DEBUG(@"%s move to dir: %@", _cmd, m_target_path);

	[m_move_operation setMoveOperationNames:names];
  	[m_move_operation setMoveOperationSourceDir:src];
	[m_move_operation setMoveOperationTargetDir:dst]; 
	[m_move_operation prepareMoveOperation];
}


#pragma mark -
#pragma mark Close sheet when we are done

-(void)closeSheet {
	// NSAssert(m_move_operation, @"moveOperation should not be nil at this point");
	// [m_move_operation setMoveOperationDelegate:nil];

	[[self window] close];
	[NSApp endSheet:[self window] returnCode:0];
}

#pragma mark -
#pragma mark Abort the operation

-(IBAction)cancelAction:(id)sender {
	// LOG_DEBUG(@"%s", _cmd);

	[self closeSheet];

/*	if([m_delegate respondsToSelector:@selector(transferSheetDidClose:)]) {
		[m_delegate transferSheetDidClose:self];
	}*/
}

-(IBAction)submitAction:(id)sender {

	NSView* oldView = m_confirm_view;
	NSView* newView = m_progress_view;
	
    NSDictionary *oldFadeOut = nil;
    if (oldView != nil) {
        oldFadeOut = [NSDictionary dictionaryWithObjectsAndKeys:
                                   oldView, NSViewAnimationTargetKey,
                                   NSViewAnimationFadeOutEffect,
                                   NSViewAnimationEffectKey, nil];
    }

    NSDictionary *newFadeIn;
    newFadeIn = [NSDictionary dictionaryWithObjectsAndKeys:
                                  newView, NSViewAnimationTargetKey,
                              NSViewAnimationFadeInEffect,
                              NSViewAnimationEffectKey, nil];

    NSArray *animations;
    animations = [NSArray arrayWithObjects:
								newFadeIn, 
								oldFadeOut, nil];

    NSViewAnimation *animation;
    animation = [[NSViewAnimation alloc]
                    initWithViewAnimations: animations];

    [animation setAnimationBlockingMode: NSAnimationBlocking];
    [animation setDuration: 0.25];

    [animation startAnimation]; // because it's blocking, once it returns, we're done


	[m_confirm_view setHidden:YES];
	
	[self performSelector: @selector(executeOperation)
	           withObject: nil
	           afterDelay: 0.f];
}

-(void)executeOperation {
	[m_move_operation executeMoveOperation];
}

-(void)moveOperation:(id<NCMoveOperationProtocol>)move_operation response:(NSDictionary*)dict {
	NSString* response_type = [dict objectForKey:@"response_type"];
	NSDictionary* response_object = [dict objectForKey:@"response_object"];
	NSAssert(response_type, @"response_type must be non-nil");
	NSAssert(response_object, @"response_object must be non-nil");
	// LOG_DEBUG(@"response-type: %@\nresponse-object: %@", response_type, response_object);

	if([response_type isEqual:@"scan-progress"]) { 
		[self scanProgressResponse:response_object];
	} else
	if([response_type isEqual:@"scan-complete"]) { 
		[self scanCompleteResponse:response_object];
	} else
	if([response_type isEqual:@"transfer-progress"]) { 
		[self transferProgressResponse:response_object];
	} else
	if([response_type isEqual:@"transfer-progress-item"]) { 
		[self transferProgressItemResponse:response_object];
	} else
	if([response_type isEqual:@"transfer-complete"]) { 
		[self transferCompleteResponse:response_object];
	} else {
		LOG_DEBUG(@"unknown response: %@", dict);
	}
}

-(void)scanProgressResponse:(NSDictionary*)dict {
	// LOG_DEBUG(@"called: %@", dict);

	unsigned long long bt = [[dict objectForKey:@"bytesTotal"] unsignedLongLongValue];
	unsigned long long ic = [[dict objectForKey:@"countTotal"] unsignedLongLongValue];
	NSString* s1 = NCSuffixStringForBytes(bt);
	NSString* s = [NSString stringWithFormat:@"%llu items (%@) to be copied", ic, s1];
	[m_confirm_summary setStringValue:s];
	
	NSString* name = [dict objectForKey:@"name"];
	unsigned long long bytes = [[dict objectForKey:@"bytesItem"] unsignedLongLongValue];
	unsigned long long count = [[dict objectForKey:@"countItem"] unsignedLongLongValue];
	NSString* message = @"Ready";

	NSEnumerator* enumerator = [[m_progress_items content] objectEnumerator];
	for(NCMoveSheetItem* item in enumerator) {
		if([[item name] isEqual:name]) {
  			[item setBytes:bytes];      
  			[item setCount:count];
  			[item setMessage:message];
		}
	}
}

-(void)scanCompleteResponse:(NSDictionary*)dict {
	// LOG_DEBUG(@"called: %@", dict);
	unsigned long long bt = [[dict objectForKey:@"bytesTotal"] unsignedLongLongValue];
	unsigned long long ic = [[dict objectForKey:@"countTotal"] unsignedLongLongValue];
	NSString* s1 = NCSuffixStringForBytes(bt);
	NSString* s = [NSString stringWithFormat:@"%llu items (%@) to be moved", ic, s1];
	[m_confirm_summary setStringValue:s];

	[m_confirm_button setTitle:@"Start Moving"];
	[m_confirm_button setEnabled:YES];
	[m_confirm_button setKeyEquivalent:@"\r"];
}

-(void)transferProgressResponse:(NSDictionary*)dict {
	// update the progressbar
    NSNumber* progress_number = [dict objectForKey:@"progress"];
	double progress = [progress_number doubleValue] * 100.0;
	[m_progress_indicator setDoubleValue:progress];

	// pretty print the remaining time
    NSNumber* time_remaining_number = [dict objectForKey:@"time_remaining"];
	double time_remaining = [time_remaining_number doubleValue];
	unsigned long long time_remaining_i = (unsigned long long)time_remaining;
	int rem_seconds = time_remaining_i % 60;
	time_remaining_i /= 60; // discard the seconds
	int rem_minutes = time_remaining_i % 60;
	time_remaining_i /= 60; // discard the minutes
	int rem_hours = time_remaining_i % 24;
	time_remaining_i /= 24; // discard the hours
	unsigned long long rem_days = time_remaining_i;
	NSString* remaining_str = @"remaining time unknown";
	if(time_remaining < 0) {
		// forever
	} else
	if(time_remaining < 0.5) {
		remaining_str = @"less than 5 seconds remaining";
	} else
	if(time_remaining < 60) { // upto 1 minute
		remaining_str = [NSString stringWithFormat:@"%.f seconds remaining", time_remaining];
	} else
	if(time_remaining < 45 * 60) { // upto 45 minutes
		remaining_str = [NSString stringWithFormat:@"%02i:%02i seconds remaining", rem_minutes, rem_seconds];
	} else
	if(time_remaining < 60 * 60 * 12) { // upto 12 hours
		remaining_str = [NSString stringWithFormat:@"%i hours and %02i:%02i seconds remaining", rem_hours, rem_minutes, rem_seconds];
	} else { // beyond 12 hours
		remaining_str = [NSString stringWithFormat:@"%llu days, %i hours, %02i:%02i seconds", rem_days, rem_hours, rem_minutes, rem_seconds];
	}

	// pretty print the total number of bytes to be copied
    NSNumber* bytes_total_number = [dict objectForKey:@"bytes_total"];
	unsigned long long bytes_total = [bytes_total_number unsignedLongLongValue];
	NSString* bytes_total_str = @"0 bytes";
	if((bytes_total > 1) && (bytes_total < 1000)) {
		bytes_total_str = [NSString stringWithFormat:@"%llu bytes", bytes_total];
	} else {
		bytes_total_str = NCSuffixStringForBytes(bytes_total);
	}

	// pretty print the actual number of bytes that has been copied so far
    NSNumber* bytes_number = [dict objectForKey:@"bytes"];
	unsigned long long bytes = [bytes_number unsignedLongLongValue];
	NSString* bytes_str = @"0 bytes";
	if((bytes > 1) && (bytes < 1000)) {
		bytes_str = [NSString stringWithFormat:@"%llu bytes", bytes];
	} else {
		bytes_str = NCSuffixStringForBytes(bytes);
	}
	
	// pretty print the transfer speed
    NSNumber* bytes_per_second_number = [dict objectForKey:@"bytes_per_second"];
	double bytes_per_second = [bytes_per_second_number doubleValue];
	unsigned long long bps_i = (unsigned long long)bytes_per_second;
	NSString* bps_str = @"0 bytes";
	if((bytes_per_second >= 0.01) && (bps_i < 1000)) {
		bps_str = [NSString stringWithFormat:@"%.2f bytes", bytes_per_second];
	} else {
		bps_str = NCSuffixStringForBytes(bps_i);
	}

	// display our pretty printed message
	NSString* s = [NSString stringWithFormat:@"%@ of %@ (%@/sec) - %@", bytes_str, bytes_total_str, bps_str, remaining_str];
	[m_progress_summary setStringValue:s];
}

-(void)transferProgressItemResponse:(NSDictionary*)dict {
    NSString* name = [dict objectForKey:@"name"];
    NSString* message = [dict objectForKey:@"message"];

	NSEnumerator* enumerator = [[m_progress_items content] objectEnumerator];
	for(NCMoveSheetItem* item in enumerator) {
		if([[item name] isEqual:name]) {
  			// [item setBytes:bytes];      
  			// [item setCount:count];
  			[item setMessage:message];
		}
	}

	if([m_delegate respondsToSelector:@selector(copySheetDidFinish:)]) {
		[m_delegate performSelector:@selector(copySheetDidFinish:) withObject:self];
	}
}

-(void)transferCompleteResponse:(NSDictionary*)dict {
	// LOG_DEBUG(@"called: %@", dict);
	
    NSNumber* elapsed_number = [dict objectForKey:@"elapsed"];
	double elapsed = [elapsed_number doubleValue];

    NSNumber* bytes_number = [dict objectForKey:@"bytes"];
	unsigned long long bytes = [bytes_number unsignedLongLongValue];
	NSString* bytes_str = @"0 bytes";
	if((bytes > 1) && (bytes < 1000)) {
		bytes_str = [NSString stringWithFormat:@"%llu bytes", bytes];
	} else {
		bytes_str = NCSuffixStringForBytes(bytes);
	}
	
    NSNumber* bytes_per_second_number = [dict objectForKey:@"bytes_per_second"];
	double bytes_per_second = [bytes_per_second_number doubleValue];
	unsigned long long bps_i = (unsigned long long)bytes_per_second;
	NSString* bps_str = @"0 bytes";
	if((bytes_per_second >= 0.01) && (bps_i < 1000)) {
		bps_str = [NSString stringWithFormat:@"%.2f bytes", bytes_per_second];
	} else {
		bps_str = NCSuffixStringForBytes(bps_i);
	}

	NSString* s = [NSString stringWithFormat:@"%@ copied in %.2f seconds (%@/sec)", bytes_str, elapsed, bps_str];
	[m_progress_summary setStringValue:s];
	
	[m_abort_button setTitle:@"OK"];
	[m_abort_button setKeyEquivalent:@"\r"];
	[m_progress_indicator setDoubleValue:101];
	
	
/*	TODO: close when finished in the move sheet
	if([self closeWhenFinished]) {
		[self performSelector:@selector(closeSheet) withObject:nil afterDelay:0.3];
	}*/
}

@end
