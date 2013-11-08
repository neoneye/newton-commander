/*********************************************************************
KCCopySheet.mm - controls the modal dialog for "copying"

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#include "KCCopySheet.h"
#include "KCCopy.h"


@implementation KCCopySheetItem

- (id)init {
    self = [super init];
	if(self) {
		name = nil;
		status = nil;
		size = 0;
		progress = 0;
		state = 0;
	}
    return self;
}

-(void)setName:(NSString*)v { v = [v copy]; [name release]; name = v; }
-(NSString*)name { return name; }

-(void)setSize:(unsigned long long)v { size = v; }
-(unsigned long long)size { return size; }

-(void)setProgress:(float)v { progress = v; }
-(float)progress { return progress; }

-(void)setState:(int)v { state = v; }
-(int)state { return state; }

-(void)setStatus:(NSString*)v { v = [v copy]; [status release]; status = v; }

-(NSString*)status {
	return status;
/*	if(state == 0) {
		return @"-";
	}
	if(state == 1) {
		return [NSString stringWithFormat:@"%.2f %%", progress * 100.f];
	}
	if(state == 2) {
		return @"OK";
	}
	return @"ERROR"; */
}

-(NSString*)description {
	return [NSString stringWithFormat: 
		@"KCCopySheetItem(%qi, %.2f, %@)", size, progress, name];
}

-(void)dealloc {
	[name release];
    [super dealloc];
}

@end


@implementation KCCopySheet

+(KCCopySheet*)shared {
    static KCCopySheet* shared = nil;
    if(!shared) {
        shared = [[KCCopySheet allocWithZone:NULL] init];
    }
    return shared;
}

- (id)init {
    self = [super init];
	if(self) {
		m_parent_window = nil;
		m_ask_for_target_path = nil;
		m_copy_items = nil;
		m_source_path = nil;
		m_target_path = nil;
		m_ask_view = nil;
		m_perform_view = nil;
		m_window = nil;
		m_copy = nil;
		m_exec_path = nil;
	}
    return self;
}

-(void)loadBundle {
	if(m_window == nil) {
		NSLog(@"%s loadNib", _cmd);
        [NSBundle loadNibNamed: @"CopySheet" owner: self];

	    [[m_window contentView] addSubview:m_ask_view];
	    [[m_window contentView] addSubview:m_perform_view];
		[m_ask_view setHidden:YES];
		[m_perform_view setHidden:YES];


		{
			NSView* v = m_perform_view;
			[v setAutoresizesSubviews:NO];
			[v setFrameOrigin:NSZeroPoint];
			[m_window setFrame:[NSWindow frameRectForContentRect:[v frame] styleMask:NSTitledWindowMask] display:NO];
			[v setAutoresizesSubviews:YES];
		}
		{
			NSView* v = m_ask_view;
			[v setAutoresizesSubviews:NO];
			[v setFrameOrigin:NSZeroPoint];
			[m_window setFrame:[NSWindow frameRectForContentRect:[v frame] styleMask:NSTitledWindowMask] display:NO];
			[v setAutoresizesSubviews:YES];
		}

	}
	NSAssert(m_copy_items != nil, @"ask_items not initialized by .nib");
	NSAssert(m_ask_for_target_path != nil, @"ask_for_target_path not initialized by .nib");
}

-(void)setParentWindow:(NSWindow*)window {
	[window retain];
	[m_parent_window autorelease];
	m_parent_window = window;
}

-(void)setExecPath:(NSString*)path {
	[path retain];
	[m_exec_path autorelease];
	m_exec_path = path;
}


-(void)showAskSheet {
	[self loadBundle];

	[m_ask_view setHidden:NO];
	[m_perform_view setHidden:YES];

    [NSApp 
		beginSheet: m_window
        modalForWindow: m_parent_window
		modalDelegate: self
		didEndSelector: nil //@selector(didEndSheet:returnCode:contextInfo:)
		contextInfo: nil
	];
}

-(void)showPerformSheet {
/*	[self loadBundle];
    [NSApp 
		beginSheet: m_perform_window
        modalForWindow: m_parent_window
		modalDelegate: self
		didEndSelector: nil //@selector(didEndSheet:returnCode:contextInfo:)
		contextInfo: nil
	];*/
}

-(IBAction)askCancelAction:(id)sender {
	NSLog(@"%s", _cmd);
	[m_window close];
	[NSApp endSheet:m_window returnCode:0];
	// [self showPerformSheet:nil];
}

-(IBAction)askSubmitAction:(id)sender {
	NSLog(@"%s OK", _cmd);


	NSWindow* window = m_window;
	NSView* oldView = m_ask_view;
	NSView* newView = m_perform_view;
	
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

    [animation release];

	[m_ask_view setHidden:YES];
	
	[self performSelector: @selector(startCopyOperation)
	           withObject: nil
	           afterDelay: 0.f];
}

-(IBAction)performAbortAction:(id)sender {
	NSLog(@"%s", _cmd);
	[m_window close];
	[NSApp endSheet:m_window returnCode:0];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    // [m_window orderOut:self];
}

-(void)setNames:(NSArray*)ary {
	// NSLog(@"%s %@", _cmd, ary);
#if 0
	KCCopySheetItem* item = [[[KCCopySheetItem alloc] init] autorelease];
	[item setName:@"atrium debris"];
	[m_copy_items addObject:item];
	return;
#endif
	NSMutableArray* result = [NSMutableArray arrayWithCapacity:[ary count]];
	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[NSString class]]) {
			NSString* name = (NSString*)thing;

			KCCopySheetItem* item = [[[KCCopySheetItem alloc] init] autorelease];
			[item setName:name];
			
			[result addObject:item];
		}
	}
	[m_copy_items setContent:result];
}

-(void)setSourcePath:(NSString*)v {
 	v = [v copy]; 
	[m_source_path release]; 
	m_source_path = v;
}

-(NSString*)sourcePath { return m_source_path; }
-(NSString*)targetPath { return m_target_path; }


-(void)setTargetPath:(NSString*)v {
 	v = [v copy]; 
	[m_target_path release]; 
	m_target_path = v;
	
	[m_ask_for_target_path setStringValue:v];
}


#if 0
-(NSArray*)selectedPaths {
	NSArray* ary = [m_column_name objectsAtIndexes:m_fileselected_set];
	NSMutableArray* result = [NSMutableArray arrayWithCapacity:[ary count]];

	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[NSString class]]) {
			NSString* name = (NSString*)thing;
			NSString* path = [m_path stringByAppendingPathComponent:name];
			[result addObject:path];
		}
	}
	
	return [result copy];
}
#endif

-(void)startCopyOperation {
	NSLog(@"%s  path: %@", _cmd, m_exec_path);
	
	if(m_copy == nil) {
		m_copy = [[KCCopy alloc] initWithName:@"copy" path:m_exec_path];
		[m_copy setDelegate:self];
		[m_copy start];
	}
}

-(void)processDidLaunch {
	// NSLog(@"KCCopySheet %s", _cmd);

	NSArray* ary = [m_copy_items arrangedObjects];
	NSMutableArray* result = [NSMutableArray arrayWithCapacity:[ary count]];
	// NSLog(@"%s ary: %@", _cmd, ary);
	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[KCCopySheetItem class]]) {
			NSString* name = [(KCCopySheetItem*)thing name];
			[result addObject:name];
		}
	}
	// NSLog(@"names: %@", result);
	
	[m_copy setNames:result];
	[m_copy setSourcePath:m_source_path];
	[m_copy setTargetPath:m_target_path];
	[m_copy startCopyOperation];
}

-(void)copyProgress:(float)progress name:(NSString*)name {
	// NSLog(@"KCCopySheet %s %.2f %@", _cmd, progress, name);
	NSArray* ary = [m_copy_items content];
	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[KCCopySheetItem class]]) {
			KCCopySheetItem* item = (KCCopySheetItem*)thing;
			if([[item name] isEqual:name]) {
			 	[item setProgress:progress];
			
				int iprogress = (int)floorf(progress * 100.f);
			   	[item setStatus:[NSString stringWithFormat:@"%i %%", iprogress]];
			}
		}
	}
}

-(void)willCopy:(NSString*)name {
	// NSLog(@"KCCopySheet %s %@", _cmd, name);
	NSArray* ary = [m_copy_items content];
	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[KCCopySheetItem class]]) {
			KCCopySheetItem* item = (KCCopySheetItem*)thing;
			if([[item name] isEqual:name]) {
				[item setProgress:0];
	  			[item setState:1];
	  			[item setStatus:@"will copy"];
			}
		}
	}
}

-(void)didCopy:(NSString*)name {
	// NSLog(@"KCCopySheet %s %@", _cmd, name);
	NSArray* ary = [m_copy_items content];
	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[KCCopySheetItem class]]) {
			KCCopySheetItem* item = (KCCopySheetItem*)thing;
			if([[item name] isEqual:name]) {
				[item setProgress:1];
				[item setState:2];
	  			[item setStatus:@"OK"];
			}
		}
	}
}

-(void)doneCopying {
	NSLog(@"%s", _cmd);
}

-(void)dealloc {
	[m_parent_window release];
	[m_copy release];
	[m_exec_path release];
	
    [super dealloc];
}

@end
