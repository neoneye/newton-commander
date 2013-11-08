/*********************************************************************
JFCopy.mm - UI for copying files

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#import "JFCopy.h"
#import "JFSystemCopy.h"


@implementation JFCopyItem
@synthesize name, status, scanStatus, size, count;
@end


@interface JFCopy (Private)
-(void)initSystemCopy;
-(void)fadeFromView:(NSView*)old_view toView:(NSView*)new_view;
-(void)assignItems;
-(void)updateProgress;
-(NSString*)stringWithBytes:(double)bytes;
@end

@implementation JFCopy

-(id)init {
	self = [super init];
    if(self) {
		m_confirm_sheet = nil;
		m_progress_sheet = nil;
		m_completed_sheet = nil;
		m_window = nil;
		m_delegate = nil;
		m_system_copy = nil;
		m_source_names = nil;
		m_source_path = nil;
		m_target_path = nil;
		m_bytes_total = 0;
		m_bytes_copied = 0;
    }
    return self;
}

-(void)initSystemCopy {
	if(m_system_copy != nil) {
		return;
	}
	m_system_copy = [[JFSystemCopy alloc] init];
	[m_system_copy setDelegate:self];
	[m_system_copy startThread];
}

-(void)load {
	if(m_window != nil) {
		return;
	}
	
	// NSLog(@"%s loadNib", _cmd);
    BOOL ok = [NSBundle loadNibNamed: @"Copy" owner: self];
	NSAssert(ok, @"Copy.nib must be present");
	NSAssert(m_window, @"Copy.nib must initialize m_window");

	NSRect orig_frame = [m_window frame];

	NSView* views[3] = {
		m_progress_sheet, 
		m_confirm_sheet,
		m_completed_sheet
	};
	for(unsigned int i=0; i<(sizeof(views) / sizeof(NSView*)); ++i) {
		NSView* v = views[i];
		[v setAutoresizesSubviews:NO];
		[v setHidden:YES];
		[v setFrameOrigin:NSZeroPoint];
		[m_window setFrame:[NSWindow frameRectForContentRect:[v frame] styleMask:NSTitledWindowMask] display:NO];
		[v setAutoresizesSubviews:YES];
	    [[m_window contentView] addSubview:v];
	}

	{
		NSRect f = orig_frame;
		if(f.size.width < 400) {
			f.size.width = 400;
		} else
		if(f.size.width > 1200) {
			f.size.width = 1200;
		}
		if(f.size.height < 400) {
			f.size.height = 400;
		} else
		if(f.size.height > 1200) {
			f.size.height = 1200;
		}
		[m_window setFrame:f display:NO];
	}
	
	{
		[m_progress_indicator setMinValue:0];
		[m_progress_indicator setMaxValue:100];
	}
}

-(IBAction)fillWithDummyData:(id)sender {
	NSMutableArray* items = [NSMutableArray arrayWithCapacity:20];
	{
		JFCopyItem* item = [[JFCopyItem alloc] init];
		[item setName:@"File11"];
		[item setStatus:@"OK"];
		[item setSize:50000];
		[items addObject:item];
	}
	{
		JFCopyItem* item = [[JFCopyItem alloc] init];
		[item setName:@"Dirname"];
		[item setStatus:@"Transfering 4%"];
		[item setSize:50];
		[items addObject:item];
	}
	{
		JFCopyItem* item = [[JFCopyItem alloc] init];
		[item setName:@"File 3"];
		[item setStatus:@"Waiting"];
		[item setSize:256];
		[items addObject:item];
	}
	{
		JFCopyItem* item = [[JFCopyItem alloc] init];
		[item setName:@"File 4"];
		[item setStatus:@"-"];
		[item setSize:42];
		[items addObject:item];
	}
	{
		JFCopyItem* item = [[JFCopyItem alloc] init];
		[item setName:@"File 5"];
		[item setStatus:@"-"];
		[item setSize:999999];
		[items addObject:item];
	}
	{
		JFCopyItem* item = [[JFCopyItem alloc] init];
		[item setName:@"File 6"];
		[item setStatus:@"-"];
		[item setSize:4096];
		[items addObject:item];
	}
	[m_copy_items setContent:items];
}

-(void)assignItems {
	NSMutableArray* items = [NSMutableArray arrayWithCapacity:20];

	id thing;
	NSEnumerator* en = [m_source_names objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[NSString class]] == NO) {
			continue;
		}
		NSString* name = (NSString*)thing;

		JFCopyItem* item = [[JFCopyItem alloc] init];
		[item setName:name];
		[item setStatus:@"-"];
		[item setScanStatus:@"?"];
		[item setSize:0];
		[items addObject:item];
	}	
	[m_copy_items setContent:items];
}

-(void)beginSheetForWindow:(NSWindow*)parent_window {
	[self initSystemCopy];
	[self load];

	m_bytes_total = 0;
	m_bytes_copied = 0;
	
	[m_confirm_sheet setHidden:NO];
	[m_completed_sheet setHidden:YES];
	[m_progress_sheet setHidden:YES];

	[m_confirm_sheet_button setEnabled:NO];
	[m_progress_sheet_button setKeyEquivalent:@""];
	[m_confirm_sheet_button setKeyEquivalent:@""];
	[m_progress_sheet_button setKeyEquivalent:@"\e"];
	[m_confirm_sheet_button setKeyEquivalent:@"\r"];
	
	[m_progress_indicator setDoubleValue:0];
	
	[m_confirm_source_path setStringValue:m_source_path];
	[m_confirm_target_path setStringValue:m_target_path];
	[m_progress_source_path setStringValue:m_source_path];
	[m_progress_target_path setStringValue:m_target_path];
	
	[self initSystemCopy];
	[m_system_copy setNames:m_source_names];
	[m_system_copy setSourceDir:m_source_path];
	[m_system_copy setTargetDir:m_target_path];


	[m_confirm_summary setStringValue:@"Counting items…"];
	
	[self assignItems];

    [NSApp 
		beginSheet: m_window
        modalForWindow: parent_window
		modalDelegate: self
		didEndSelector: nil //@selector(didEndSheet:returnCode:contextInfo:)
		contextInfo: nil
	];

	[m_system_copy prepare];
}

-(IBAction)cancelAction:(id)sender {
	// NSLog(@"%s", _cmd);
	[m_window close];
	[NSApp endSheet:m_window returnCode:0];
	// [self showPerformSheet:nil];
	
	[m_system_copy abort];                              
	[m_system_copy stop];
}

-(IBAction)startCopyingAction:(id)sender {
	// NSLog(@"%s", _cmd);

	[m_progress_sheet_button setTitle:@"Abort"];
	[m_progress_sheet_button setKeyEquivalent:@"\e"];
	
	[m_progress_indicator setUsesThreadedAnimation:YES];

	[self fadeFromView:m_confirm_sheet toView:m_progress_sheet];
	// [self fadeFromView:m_confirm_sheet toView:m_completed_sheet];

	[m_system_copy start];

/*	[self performSelector: @selector(completedCopyOperation)
	           withObject: nil
	           afterDelay: 1.5f];/**/
}

-(void)completedCopyOperation {
	// [self fadeFromView:m_progress_sheet toView:m_completed_sheet];
	[m_progress_sheet_button setTitle:@"OK"];
	[m_progress_sheet_button setKeyEquivalent:@"\r"];
	[m_progress_indicator setDoubleValue:101];
}

-(void)fadeFromView:(NSView*)old_view toView:(NSView*)new_view {
	NSWindow* window = m_window;
	
    NSDictionary *old_fade_out = nil;
    if(old_view != nil) {
        old_fade_out = [NSDictionary dictionaryWithObjectsAndKeys:
			old_view, NSViewAnimationTargetKey,
			NSViewAnimationFadeOutEffect,
			NSViewAnimationEffectKey, 
			nil
		];
    }

    NSDictionary* new_fade_out = [NSDictionary dictionaryWithObjectsAndKeys:
		new_view, NSViewAnimationTargetKey,
		NSViewAnimationFadeInEffect,
		NSViewAnimationEffectKey, 
		nil
	];
    NSArray* animations = [NSArray arrayWithObjects:
		new_fade_out, 
		old_fade_out, 
		nil
	];
    NSViewAnimation* animation = [[NSViewAnimation alloc]
		initWithViewAnimations: animations];
    [animation setAnimationBlockingMode: NSAnimationBlocking];
    [animation setDuration: 0.25];

    [animation startAnimation]; // because it's blocking, once it returns, we're done

    [animation release];

	[old_view setHidden:YES];
}


-(void)setDelegate:(id)delegate { m_delegate = delegate; }
-(id)delegate { return m_delegate; }

-(NSString*)description {
	return [NSString stringWithFormat: 
		@"JFCopy\n"
	];
}

-(void)setNames:(NSArray*)v {
 	v = [v copy]; 
	[m_source_names release]; 
	m_source_names = v;
}

-(void)setSourcePath:(NSString*)v {
 	v = [v copy]; 
	[m_source_path release]; 
	m_source_path = v;
}

-(void)setTargetPath:(NSString*)v {
 	v = [v copy]; 
	[m_target_path release]; 
	m_target_path = v;
}

-(NSString*)sourcePath { return m_source_path; }
-(NSString*)targetPath { return m_target_path; }


-(void)copy:(JFSystemCopy*)sysCopy 
	 willScanName:(NSString*)name
{
	NSArray* ary = [m_copy_items content];
	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[JFCopyItem class]]) {
			JFCopyItem* item = (JFCopyItem*)thing;
			if([[item name] isEqual:name]) {
	  			[item setScanStatus:@"Counting items…"];
			}
		}
	}
}

-(void)copy:(JFSystemCopy*)sysCopy 
  nowScanningName:(NSString*)name 
             size:(unsigned long long)bytes
 	        count:(unsigned long long)count
{
	NSArray* ary = [m_copy_items content];
	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[JFCopyItem class]]) {
			JFCopyItem* item = (JFCopyItem*)thing;
			if([[item name] isEqual:name]) {
	  			[item setSize:bytes];      
	  			[item setCount:count];
	  			[item setScanStatus:@"Counting items…"];
			}
		}
	}
}

-(void)copy:(JFSystemCopy*)sysCopy 
      didScanName:(NSString*)name 
             size:(unsigned long long)bytes
 	        count:(unsigned long long)count
{
	// NSLog(@"%s %@ %llu", _cmd, name, bytes);

	NSArray* ary = [m_copy_items content];
	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[JFCopyItem class]]) {
			JFCopyItem* item = (JFCopyItem*)thing;
			if([[item name] isEqual:name]) {
	  			[item setSize:bytes];      
	  			[item setCount:count];
	  			[item setScanStatus:@"Ready"];
			}
		}
	}
}

-(void)copy:(JFSystemCopy*)sysCopy
	updateScanSummarySize:(unsigned long long)bytes 
	count:(unsigned long long)count 
{
	NSString* s0 = [self stringWithBytes:bytes];
	[m_confirm_summary setStringValue:
		[NSString stringWithFormat:@"Counting… %llu items (%@)", count, s0]];

	m_bytes_total = bytes;
	m_bytes_copied = 0;
	m_bytes_per_second = 0;
}

-(void)copy:(JFSystemCopy*)sysCopy
	scanSummarySize:(unsigned long long)bytes 
	count:(unsigned long long)count 
{
	NSString* s0 = [self stringWithBytes:bytes];
	[m_confirm_summary setStringValue:
		[NSString stringWithFormat:@"%llu items (%@) to be copied", count, s0]];

	m_bytes_total = bytes;
	m_bytes_copied = 0;
	m_bytes_per_second = 0;
}

-(void)readyToCopy:(JFSystemCopy*)sysCopy {
	// NSLog(@"%s", _cmd);
	[m_confirm_sheet_button setEnabled:YES];
}

-(void)copy:(JFSystemCopy*)sysCopy 
	 willCopyName:(NSString*)name
{
	// NSLog(@"%s %@", _cmd, name);
	NSArray* ary = [m_copy_items content];
	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[JFCopyItem class]]) {
			JFCopyItem* item = (JFCopyItem*)thing;
			if([[item name] isEqual:name]) {
	  			[item setStatus:@"Copying..."];
			}
		}
	}
}

-(void)copy:(JFSystemCopy*)sysCopy 
	copyingName:(NSString*)name 
	progress:(double)progress 
{
	NSArray* ary = [m_copy_items content];
	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[JFCopyItem class]]) {
			JFCopyItem* item = (JFCopyItem*)thing;
			if([[item name] isEqual:name]) {
	  			[item setStatus:[NSString stringWithFormat:@"%.2f%%", progress]];
			}
		}
	}
}


-(void)copy:(JFSystemCopy*)sysCopy 
	 didCopyName:(NSString*)name
{
	// NSLog(@"%s %@", _cmd, name);
	NSArray* ary = [m_copy_items content];
	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[JFCopyItem class]]) {
			JFCopyItem* item = (JFCopyItem*)thing;
			if([[item name] isEqual:name]) {
	  			[item setStatus:@"Done"];
			}
		}
	}
}

-(void)copy:(JFSystemCopy*)sysCopy 
	nowCopyingItem:(NSString*)item
{
	// NSLog(@"%s %@", _cmd, item);
	NSString* s = [NSString stringWithFormat:@"Copying: %@", item];
	[m_progress_name_of_current_item setStringValue:s];
}

-(void)copy:(JFSystemCopy*)sysCopy 
	transferedBytes:(unsigned long long)bytes 
{
	// NSLog(@"%s %llu", _cmd, bytes);
	m_bytes_copied = bytes;
	[self updateProgress];
}

-(void)updateProgress {
	double a = m_bytes_copied;
	double b = m_bytes_total;
	double progress = 101;
	if(m_bytes_copied < m_bytes_total) {
		progress = (b > 0) ? 99.0 * a / b : 0;
	}

	double rem = 0;
	double va = m_bytes_copied;
	double vb = m_bytes_total;
	double vdiff = vb - va;
	if(m_bytes_per_second > 10) {
		rem = vdiff / m_bytes_per_second;
	}

	NSString* s0 = [self stringWithBytes:m_bytes_copied];
	NSString* s1 = [self stringWithBytes:m_bytes_total];
	NSString* s2 = [self stringWithBytes:m_bytes_per_second];
	NSString* s = [NSString stringWithFormat:
		@"%@ of %@ (%@/sec) — %.f seconds remaining", 
		s0, s1, s2, rem
	];

	[m_progress_indicator setDoubleValue:progress];
	[m_progress_summary setStringValue:s];
}

-(NSString*)stringWithBytes:(double)value {
	double bytes_base = 1000;

	unsigned int unit = 0;
	if(value < 5000) {
		unit = 0;
	} else 
	if(value < 5000 * bytes_base) {
		unit = 1;
		value /= bytes_base;
	} else 
	if(value < 5000 * bytes_base * bytes_base) {
		unit = 2;
		value /= bytes_base;
		value /= bytes_base;
	} else {
		unit = 3;
		value /= bytes_base;
		value /= bytes_base;
		value /= bytes_base;
	}
	
	const char* units[] = { "bytes", "Kb", "Mb", "Gb" };
	return [NSString stringWithFormat:@"%.2f %s", value, units[unit]];
}

-(void)copy:(JFSystemCopy*)sysCopy bytesPerSecond:(double)bps {
	// NSLog(@"%s %.3f", _cmd, bps);
	m_bytes_per_second = bps;
	[self updateProgress];
}

-(void)copyCompleted:(JFSystemCopy*)sysCopy 
	bytes:(unsigned long long)bytes
	elapsed:(double)elapsed
{
	[self completedCopyOperation];

	NSString* a = [self stringWithBytes:bytes];


	NSString* s = [NSString stringWithFormat:
		@"%@ transfered in %.2f seconds", 
		a,
		elapsed
	];

	if(elapsed > 1.5) {
		double bytespersecond = (double)(bytes) / elapsed;
		NSString* b = [self stringWithBytes:bytespersecond];
		s = [NSString stringWithFormat:
			@"%@ transfered in %.2f seconds (%@/sec)", 
			a, elapsed, b
		];
	}

	[m_progress_summary setStringValue:s];

	[m_progress_name_of_current_item setStringValue:@"DONE"];
}


-(void)copyActivity:(JFSystemCopy*)sysCopy {
	float progress = [sysCopy progress];
	NSString* name = [sysCopy currentItemName];
	unsigned long long bytes1 = [sysCopy bytesTransfered];
	unsigned long long bytes2 = [sysCopy bytesTotal];
	float bps = [sysCopy bytesPerSecond];
	float rem = [sysCopy secondsRemaining];

	NSString* s1 = [NSString stringWithFormat:@"Copying: %@", name];
	NSString* s2 = [NSString stringWithFormat:
		@"%llu of %llu MB (%.f KB/sec) — %.f seconds remaining", 
		bytes1, 
		bytes2,
		bps,
		rem
	];

	[m_progress_indicator setDoubleValue:progress];
	[m_progress_name_of_current_item setStringValue:s1];
	[m_progress_summary setStringValue:s2];
}

-(void)copyDidComplete:(JFSystemCopy*)sysCopy {
	// NSLog(@"%s complete", _cmd);
	[self completedCopyOperation];
}

-(void)copy:(JFSystemCopy*)sysCopy willCopy:(NSString*)name {
	// NSLog(@"%s %@", _cmd, name);

	NSArray* ary = [m_copy_items content];
	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[JFCopyItem class]]) {
			JFCopyItem* item = (JFCopyItem*)thing;
			if([[item name] isEqual:name]) {
				// [item setProgress:0];
	  			// [item setState:1];
	  			[item setStatus:@"requested"];
			}
		}
	}

}

-(void)copy:(JFSystemCopy*)sysCopy didCopy:(NSString*)name {
	// NSLog(@"%s %@", _cmd, name);

	NSArray* ary = [m_copy_items content];
	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[JFCopyItem class]]) {
			JFCopyItem* item = (JFCopyItem*)thing;
			if([[item name] isEqual:name]) {
				// [item setProgress:0];
	  			// [item setState:1];
	  			[item setStatus:@"OK"];
			}
		}
	}

}

-(void)copy:(JFSystemCopy*)sysCopy name:(NSString*)name copyState:(JFSystemCopyState)state {
	// NSLog(@"%s %@", _cmd, name);

	NSArray* ary = [m_copy_items content];
	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[JFCopyItem class]]) {
			JFCopyItem* item = (JFCopyItem*)thing;
			if([[item name] isEqual:name]) {
				// [item setProgress:0];
	  			// [item setState:1];
	  			[item setStatus:[NSString stringWithFormat:@"%llu", state.bytes_copied]];
			}
		}
	}

}

-(void)dealloc {
	// NSLog(@"%s", _cmd);
	[m_system_copy setDelegate:nil];
	[m_system_copy release];

	[m_source_names release];
	[m_source_path release];
	[m_target_path release];
	
    [super dealloc];
}

@end
