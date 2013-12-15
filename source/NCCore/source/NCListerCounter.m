//
//  NCListerCounter.m
//  NCCore
//
//  Created by Simon Strandgaard on 15/02/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NCListerCounter.h"
#import "NCCommon.h"

@implementation NCListerCounter

@synthesize numberOfDirs = _numberOfDirs;
@synthesize numberOfSelectedDirs = _numberOfSelectedDirs;
@synthesize numberOfFiles = _numberOfFiles;
@synthesize numberOfSelectedFiles = _numberOfSelectedFiles;
@synthesize sizeOfItems = _sizeOfItems;
@synthesize sizeOfSelectedItems = _sizeOfSelectedItems;

-(id)init {
 
	self = [super init];
	if(self) {
		_numberOfDirs = 201;
		_numberOfSelectedDirs = 101;
		_numberOfFiles = 202;
		_numberOfSelectedFiles = 102;
		_sizeOfItems = 203;
		_sizeOfSelectedItems = 103;
	}
 
	return self;
}

- (void)setNumberOfSelectedDirs:(int)n {
	_numberOfSelectedDirs = n;
	[self setNeedsDisplay:YES];
}

- (void)setNumberOfDirs:(int)n {
	_numberOfDirs = n;
	[self setNeedsDisplay:YES];
}

- (void)setNumberOfSelectedFiles:(int)n {
	_numberOfSelectedFiles = n;
	[self setNeedsDisplay:YES];
}

- (void)setNumberOfFiles:(int)n {
	_numberOfFiles = n;
	[self setNeedsDisplay:YES];
}

- (void)setSizeOfSelectedItems:(unsigned long long)n {
	_sizeOfSelectedItems = n;
	[self setNeedsDisplay:YES];
}

- (void)setSizeOfItems:(unsigned long long)n {
	_sizeOfItems = n;
	[self setNeedsDisplay:YES];
}

- (BOOL)isOpaque {
	return NO;
}

- (void)drawRect:(NSRect)dirtyRect {
#if 1  // this function alone yields about 12 Kbytes assembler code in the framework !!!
	NSRect bounds = [self bounds];


	{
		NSRect slice, junk;
		NSDivideRect(bounds, &slice, &junk, 1, NSMaxYEdge);
		bounds = junk;
		[[NSColor colorWithCalibratedWhite:0.333 alpha:1.000] set];
		NSRectFill(slice);
	}

   	NSRect rect = NSInsetRect(bounds, 8, 0);
	NSDrawWindowBackground(bounds);

/*	[[NSColor whiteColor] set];
	NSRectFill(rect); */

	NSShadow* shadow0 = [[NSShadow alloc] init];
	[shadow0 setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.2]];
	[shadow0 setShadowOffset:NSMakeSize(0, -1)];
	[shadow0 setShadowBlurRadius:1.0];

	NSShadow* shadow1 = [[NSShadow alloc] init];
	[shadow1 setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.6]];
	[shadow1 setShadowOffset:NSMakeSize(0, -1)];
	[shadow1 setShadowBlurRadius:1.0];

	NSColor* color0 = [NSColor colorWithCalibratedWhite:0.08 alpha:1.000];
	NSColor* color1 = [NSColor colorWithCalibratedWhite:0.04 alpha:1.000];
	
	NSMutableDictionary* attr0 = [[NSMutableDictionary alloc] init];
	[attr0 setObject:color0 forKey:NSForegroundColorAttributeName];
	[attr0 setObject:[NSFont systemFontOfSize:12] forKey:NSFontAttributeName];
	[attr0 setObject:shadow0 forKey:NSShadowAttributeName];

	NSMutableDictionary* attr1 = [[NSMutableDictionary alloc] init];
	[attr1 setObject:color1 forKey:NSForegroundColorAttributeName];
	[attr1 setObject:[NSFont boldSystemFontOfSize:12] forKey:NSFontAttributeName];
	[attr1 setObject:shadow1 forKey:NSShadowAttributeName];
	
	NSMutableAttributedString* s_dirs_long     = [[NSMutableAttributedString alloc] init];
	NSMutableAttributedString* s_files_long    = [[NSMutableAttributedString alloc] init];
	NSMutableAttributedString* s_bytes_long    = [[NSMutableAttributedString alloc] init];
	NSMutableAttributedString* s_dirs_short    = [[NSMutableAttributedString alloc] init];
	NSMutableAttributedString* s_files_short   = [[NSMutableAttributedString alloc] init];
	NSMutableAttributedString* s_bytes_short   = [[NSMutableAttributedString alloc] init];
	NSMutableAttributedString* s_dirs_compact  = [[NSMutableAttributedString alloc] init];
	NSMutableAttributedString* s_files_compact = [[NSMutableAttributedString alloc] init];
	NSMutableAttributedString* s_bytes_compact = [[NSMutableAttributedString alloc] init];
	
	
	int dirs_total = _numberOfDirs;
	int files_total = _numberOfFiles;
	unsigned long long bytes_total = _sizeOfItems;

	int dirs_selected = _numberOfSelectedDirs;
	int files_selected = _numberOfSelectedFiles;
	unsigned long long bytes_selected = _sizeOfSelectedItems;
	
	BOOL zero_dirs  = (dirs_selected == 0);
	BOOL zero_files = (files_selected == 0);
	BOOL zero_bytes = (bytes_selected == 0);
	BOOL none_selected = zero_dirs && zero_files && zero_bytes;
	
	const char* name_dirs = (dirs_total == 1) ? "dir" : "dirs";
	const char* name_files = (files_total == 1) ? "file" : "files";
	const char* name_bytes = (bytes_total == 1) ? "byte" : "bytes";
	
	if(none_selected) {
		{
			NSString* s = [NSString stringWithFormat:@"%d %s\t", dirs_total, name_dirs];
			NSAttributedString* as = [[NSAttributedString alloc] 
				initWithString:s attributes:attr0];
			[s_dirs_long appendAttributedString:as];
		}
		{
			NSString* s = [NSString stringWithFormat:@"%d\t", dirs_total];
			NSAttributedString* as = [[NSAttributedString alloc] 
				initWithString:s attributes:attr0];
			[s_dirs_short appendAttributedString:as];
			[s_dirs_compact appendAttributedString:as];
		}
	} else {
		{ 
			NSString* s = [NSString stringWithFormat:@"%d", dirs_selected];
			NSMutableDictionary* attr = (dirs_selected == 0) ? attr0 : attr1;
			NSAttributedString* as = [[NSAttributedString alloc] 
				initWithString:s attributes:attr];
			[s_dirs_long appendAttributedString:as];
			[s_dirs_short appendAttributedString:as];
			[s_dirs_compact appendAttributedString:as];
		}
		{
			NSString* s = [NSString stringWithFormat:@" of %d %s\t", dirs_total, name_dirs];
			NSAttributedString* as = [[NSAttributedString alloc] 
				initWithString:s attributes:attr0];
			[s_dirs_long appendAttributedString:as];
		}
		{
			NSString* s = [NSString stringWithFormat:@" / %d\t", dirs_total];
			NSAttributedString* as = [[NSAttributedString alloc] 
				initWithString:s attributes:attr0];
			[s_dirs_short appendAttributedString:as];
		}
		{
			NSString* s = @"\t";
			NSAttributedString* as = [[NSAttributedString alloc] 
				initWithString:s attributes:attr0];
			[s_dirs_compact appendAttributedString:as];
		}
	}
	

	if(none_selected) {
		{
			NSString* s = [NSString stringWithFormat:@"%d %s\t", files_total, name_files];
			NSAttributedString* as = [[NSAttributedString alloc] 
				initWithString:s attributes:attr0];
			[s_files_long appendAttributedString:as];
		}
		{
			NSString* s = [NSString stringWithFormat:@"%d\t", files_total];
			NSAttributedString* as = [[NSAttributedString alloc] 
				initWithString:s attributes:attr0];
			[s_files_short appendAttributedString:as];
			[s_files_compact appendAttributedString:as];
		}
	} else {
		{ 
			NSString* s = [NSString stringWithFormat:@"%d", files_selected];
			NSMutableDictionary* attr = (files_selected == 0) ? attr0 : attr1;
			NSAttributedString* as = [[NSAttributedString alloc] 
				initWithString:s attributes:attr];
			[s_files_long appendAttributedString:as];
			[s_files_short appendAttributedString:as]; 
			[s_files_compact appendAttributedString:as];
		}
		{
			NSString* s = [NSString stringWithFormat:@" of %d %s\t", files_total, name_files];
			NSAttributedString* as = [[NSAttributedString alloc] 
				initWithString:s attributes:attr0];
			[s_files_long appendAttributedString:as];
		}
		{
			NSString* s = [NSString stringWithFormat:@" / %d\t", files_total];
			NSAttributedString* as = [[NSAttributedString alloc] 
				initWithString:s attributes:attr0];
			[s_files_short appendAttributedString:as];
		}
		{
			NSString* s = @"\t";
			NSAttributedString* as = [[NSAttributedString alloc] 
				initWithString:s attributes:attr0];
			[s_files_compact appendAttributedString:as];
		}
	}
	
	if(none_selected) {
		if(bytes_total < 1000) {
			NSString* s = [NSString stringWithFormat:@"%i %s", (int)(bytes_total), name_bytes];
			NSAttributedString* as = [[NSAttributedString alloc] 
				initWithString:s attributes:attr0];
			[s_bytes_long appendAttributedString:as];
		} else {
			NSString* s = NCSuffixStringForBytes(bytes_total);
			NSAttributedString* as = [[NSAttributedString alloc] 
				initWithString:s attributes:attr0];
			[s_bytes_long appendAttributedString:as];
		}
		{
			NSString* s = NCSuffixStringForBytes(bytes_total);
			NSAttributedString* as = [[NSAttributedString alloc] 
				initWithString:s attributes:attr0];
			[s_bytes_short appendAttributedString:as];
			[s_bytes_compact appendAttributedString:as];
		}
	} else {
		{ 
			NSString* s = NCSuffixStringForBytes(bytes_selected);
			NSMutableDictionary* attr = ((dirs_selected == 0) && (files_selected == 0)) ? attr0 : attr1;
			NSAttributedString* as = [[NSAttributedString alloc] 
				initWithString:s attributes:attr];
			[s_bytes_long appendAttributedString:as];           
			[s_bytes_short appendAttributedString:as];
			[s_bytes_compact appendAttributedString:as];
		}
		{
			NSString* s1 = NCSuffixStringForBytes(bytes_total);
			NSString* s = [NSString stringWithFormat:@" of %@", s1];
			NSAttributedString* as = [[NSAttributedString alloc] 
				initWithString:s attributes:attr0];
			[s_bytes_long appendAttributedString:as];
		}
		{
			NSString* s1 = NCSuffixStringForBytes(bytes_total);
			NSString* s = [NSString stringWithFormat:@" / %@", s1];
			NSAttributedString* as = [[NSAttributedString alloc] 
				initWithString:s attributes:attr0];
			[s_bytes_short appendAttributedString:as];
		}
	}

	NSMutableAttributedString* result_long = [[NSMutableAttributedString alloc] init];
	[result_long appendAttributedString:s_dirs_long];
	[result_long appendAttributedString:s_files_long];
	[result_long appendAttributedString:s_bytes_long];

	NSMutableAttributedString* result_short = [[NSMutableAttributedString alloc] init];
	[result_short appendAttributedString:s_dirs_short];
	[result_short appendAttributedString:s_files_short];
	[result_short appendAttributedString:s_bytes_short];

	NSMutableAttributedString* result_compact = [[NSMutableAttributedString alloc] init];
	[result_compact appendAttributedString:s_dirs_compact];
	[result_compact appendAttributedString:s_files_compact];
	[result_compact appendAttributedString:s_bytes_compact];

	NSRect bound_dirs_long   = [s_dirs_long boundingRectWithSize:rect.size options:0];
	NSRect bound_files_long  = [s_files_long boundingRectWithSize:rect.size options:0];
	NSRect bound_bytes_long  = [s_bytes_long boundingRectWithSize:rect.size options:0];
	NSRect bound_dirs_short  = [s_dirs_short boundingRectWithSize:rect.size options:0];
	NSRect bound_files_short = [s_files_short boundingRectWithSize:rect.size options:0];
	NSRect bound_bytes_short = [s_bytes_short boundingRectWithSize:rect.size options:0];
	NSRect bound_dirs_compact  = [s_dirs_compact boundingRectWithSize:rect.size options:0];
	NSRect bound_files_compact = [s_files_compact boundingRectWithSize:rect.size options:0];
	NSRect bound_bytes_compact = [s_bytes_compact boundingRectWithSize:rect.size options:0];


	{
		float l0 = 0;
	
		float l1 = NSWidth(bound_dirs_long) + (
			NSWidth(rect) -
			NSWidth(bound_dirs_long) - 
			NSWidth(bound_files_long) - 
			NSWidth(bound_bytes_long)) / 2.0;

		float l2 = NSWidth(rect);

		NSMutableArray* tabs = [NSMutableArray arrayWithCapacity:4];
		[tabs addObject:[[NSTextTab alloc] initWithType:NSLeftTabStopType location:l0]];
		[tabs addObject:[[NSTextTab alloc] initWithType:NSLeftTabStopType location:l1]];
		[tabs addObject:[[NSTextTab alloc] initWithType:NSRightTabStopType location:l2]];


		NSMutableParagraphStyle* ps = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[ps setTabStops:tabs];
		// [ps setFirstLineHeadIndent:8];
		// [ps setHeadIndent:0.3];
		// [ps setTailIndent:0.3];

		[result_long addAttribute:NSParagraphStyleAttributeName
			value:ps range:NSMakeRange(0,[result_long length]) ];
	}

	{
		float l0 = 0;
	
		float l1 = NSWidth(bound_dirs_short) + (
			NSWidth(rect) -
			NSWidth(bound_dirs_short) - 
			NSWidth(bound_files_short) - 
			NSWidth(bound_bytes_short)) / 2.0;

		float l2 = NSWidth(rect);

		NSMutableArray* tabs = [NSMutableArray arrayWithCapacity:4];
		[tabs addObject:[[NSTextTab alloc] initWithType:NSLeftTabStopType location:l0]];
		[tabs addObject:[[NSTextTab alloc] initWithType:NSLeftTabStopType location:l1]];
		[tabs addObject:[[NSTextTab alloc] initWithType:NSRightTabStopType location:l2]];


		NSMutableParagraphStyle* ps = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[ps setTabStops:tabs];

		[result_short addAttribute:NSParagraphStyleAttributeName
			value:ps range:NSMakeRange(0,[result_short length]) ];
	}

	{
		float l0 = 0;
	
		float l1 = NSWidth(bound_dirs_compact) + (
			NSWidth(rect) -
			NSWidth(bound_dirs_compact) - 
			NSWidth(bound_files_compact) - 
			NSWidth(bound_bytes_compact)) / 2.0;

		float l2 = NSWidth(rect);

		NSMutableArray* tabs = [NSMutableArray arrayWithCapacity:4];
		[tabs addObject:[[NSTextTab alloc] initWithType:NSLeftTabStopType location:l0]];
		[tabs addObject:[[NSTextTab alloc] initWithType:NSLeftTabStopType location:l1]];
		[tabs addObject:[[NSTextTab alloc] initWithType:NSRightTabStopType location:l2]];


		NSMutableParagraphStyle* ps = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[ps setTabStops:tabs];

		[result_compact addAttribute:NSParagraphStyleAttributeName
			value:ps range:NSMakeRange(0,[result_compact length]) ];
	}

	
	NSMutableAttributedString* result = result_long;
	
	NSRect boundingRect_long = [result_long boundingRectWithSize:rect.size options:0];
	NSRect boundingRect_short = [result_short boundingRectWithSize:rect.size options:0];
	NSRect boundingRect_compact = [result_compact boundingRectWithSize:rect.size options:0];
	NSRect boundingRect = boundingRect_long;

	if(NSWidth(boundingRect) > NSWidth(rect)) {
		result = result_short;
		boundingRect = boundingRect_short;
	}
	if(NSWidth(boundingRect) > NSWidth(rect)) {
		result = result_compact;
		boundingRect = boundingRect_compact;
	}
	
	
	NSPoint rectCenter;
	rectCenter.x = NSMidX(rect);
	rectCenter.y = NSMidY(rect);
	
	NSPoint drawPoint = rectCenter;
	drawPoint.x -= boundingRect.size.width / 2;
	drawPoint.y -= boundingRect.size.height / 2;
	
	drawPoint.x = roundf(drawPoint.x);
	drawPoint.y = roundf(drawPoint.y);
	
	[result drawAtPoint:drawPoint];
#endif
}

/*- (NSView *)hitTest:(NSPoint)aPoint {
	return nil;
} */

/*- (BOOL)mouseDownCanMoveWindow {
	return YES;
}*/

@end
