//
//  NCDateCell.m
//  NCCore
//
//  Created by Simon Strandgaard on 14/08/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

/*

YYYY-MM-dd HH:mm:ss
YYYY-MM-dd HH:mm
YYYY-MM-dd
YY-MM-dd
YYMMdd
YYYY
today 16:30
yesterday 16:30
y.day 16:30
TDA 16:30   (today)
YDA 16:30   (yesterday)
17 minutes ago
17 hours ago
5 days ago
just now
yesterday
	
*/

#import "NCLog.h"
#import "NCTimeProfiler.h"
#import "NCDateCell.h"
#include <mach/mach_time.h>


static CGColorRef CGColorCreateFromNSColor (CGColorSpaceRef colorSpace, NSColor *color)
{
	NSColor *deviceColor = [color colorUsingColorSpaceName:
	NSDeviceRGBColorSpace];

	CGFloat components[4];
	[deviceColor getRed: &components[0] green: &components[1] blue: &components[2] alpha: &components[3]];

	return CGColorCreate (colorSpace, components);
}

CGFloat xGetLineHeightForFont(CTFontRef iFont) {
    check(iFont != NULL);
	CGRect r = CTFontGetBoundingBox(iFont);
	return r.size.height + r.origin.y;
}

CGFloat GetLineHeightForFont(CTFontRef iFont)
{
    CGFloat lineHeight = 0.0;
 
    check(iFont != NULL);
 
    // Get the ascent from the font, already scaled for the font's size
    lineHeight += CTFontGetAscent(iFont);
 
    // Get the descent from the font, already scaled for the font's size
    lineHeight += CTFontGetDescent(iFont);
 
    // Get the leading from the font, already scaled for the font's size
    lineHeight += CTFontGetLeading(iFont);
 
    return lineHeight;
}

CGFloat yGetLineHeightForFont(CTFontRef iFont)
{
    CGFloat lineHeight = 0.0;
 
    check(iFont != NULL);
 
    // Get the ascent from the font, already scaled for the font's size
    lineHeight += CTFontGetAscent(iFont);
 
    // Get the descent from the font, already scaled for the font's size
    // lineHeight += CTFontGetDescent(iFont);
 
    // Get the leading from the font, already scaled for the font's size
    // lineHeight += CTFontGetLeading(iFont);
 
    return lineHeight;
}


/*
Inspired by jQuery's date to string

returns a CFString that the caller must release using CFRelease
returns NULL if date is in the future or older than 7 days
*/
CFStringRef CFStringCreateFromTime(double seconds_until_now) {
	NSTimeInterval diff = seconds_until_now;
	NSInteger day_diff = floorf(diff / 86400.0);  // 86400 seconds per day (24 hours * 60 minuts * 60 seconds)

	if(day_diff < 0) {
		return NULL; // the future
	}
	
	if(day_diff == 0) {
		if(diff < 0) {
			return NULL; // the future
		}
		if(diff < 60) {
			// "Just now" as in jquery
			return CFRetain(CFSTR("Just now"));
		}
		if(diff < 120) {
			// "1 minute ago" as in jquery
			return CFRetain(CFSTR("1 minute ago"));
		}
		if(diff < 3600) {
			int v = floorf(diff / 60);
			// "17 minutes ago" as in jquery
			return CFStringCreateWithFormat(NULL, NULL, CFSTR("%i minutes ago"), v);
		}
		if(diff < 7200) {
			// "1 hour ago" as in jquery
			return CFRetain(CFSTR("1 hour ago"));
		}
		if(diff < 86400) {
			int v = floorf(diff / 3600);
			// "17 hours ago" as in jquery
			return CFStringCreateWithFormat(NULL, NULL, CFSTR("%i hours ago"), v);
		}
	} else
	if(day_diff == 1) {
		// "yesterday" as in jquery
		return CFRetain(CFSTR("Yesterday"));
	} else
	if(day_diff < 7) {
		int v = floorf(day_diff);
		// "17 days ago" as in jquery
		return CFStringCreateWithFormat(NULL, NULL, CFSTR("%i days ago"), v);
	}
	return NULL; // the past
}


/*
Inspired by StackOverflow's date to string

returns a CFString that the caller must release using CFRelease
returns NULL if date is in the future or older than 7 days
*/
CFStringRef CFStringCreateCompactFromTime(double seconds_until_now) {
	NSTimeInterval diff = seconds_until_now;
	NSInteger day_diff = floorf(diff / 86400.0);  // 86400 seconds per day (24 hours * 60 minuts * 60 seconds)

	if(day_diff < 0) {
		return NULL; // the future
	}
	
	if(day_diff == 0) {
		if(diff < 0) {
			return NULL; // the future
		}
		if(diff < 60) {
			return CFRetain(CFSTR("Now"));
		}
		if(diff < 3600) {
			int v = floorf(diff / 60);
			// x minutes ago, e.g: "17m" or "17m ago" as on stackoverflow
			return CFStringCreateWithFormat(NULL, NULL, CFSTR("%im"), v);
		}
		if(diff < 86400) {
			int v = floorf(diff / 3600);
			// x hours ago, e.g: "17h" or "17h ago" as on stackoverflow
			return CFStringCreateWithFormat(NULL, NULL, CFSTR("%ih"), v);
		}
	} else
	if(day_diff < 7) {
		int v = floorf(day_diff);
		// x days ago, e.g: "17d" or "17d ago" as on stackoverflow
		return CFStringCreateWithFormat(NULL, NULL, CFSTR("%id"), v);
	}
	return NULL; // the past
}


@interface NCDateCell (Private)
// -(NSAttributedString*)appendElipsisToString:(NSAttributedString*)aString maxWidth:(float)maxwidth;

// - (void)originalDrawInteriorWithFrame:(NSRect)frame inView:(NSView *)view;
- (void)coretextDrawInteriorWithFrame:(NSRect)frame inView:(NSView *)view;

@end

@implementation NCDateCell

@synthesize textStorage   = m_text_storage;
@synthesize textContainer = m_text_container;
@synthesize layoutManager = m_layout_manager;
@synthesize paraStyle     = m_para_style;
@synthesize attr          = m_attr;
@synthesize dateFormatterVerbose = m_date_formatter_verbose;
@synthesize dateFormatterCompact = m_date_formatter_compact;
@synthesize widthOfVerboseText = m_width_of_verbose_text;


-(id)init {
    if ((self = [super init])) {
		m_date_formatter_verbose = nil;
		m_date_formatter_compact = nil;
		
		m_width_of_verbose_text = 0;
		
		m_attr_string = NULL; // lazy initialization in drawRect
		m_ellipsis = NULL; // lazy initialization in drawRect
		m_attr0 = NULL; // lazy initialization in drawRect
		m_attr1 = NULL; // lazy initialization in drawRect
    }
    return self;
}

- (void)dealloc {
    if(m_attr_string) {
        CFRelease(m_attr_string);
		m_attr_string = NULL;
	}
    if(m_ellipsis) {
        CFRelease(m_ellipsis);
		m_ellipsis = NULL;
	}
    if(m_attr0) {
        CFRelease(m_attr0);
		m_attr0 = NULL;
	}
    if(m_attr1) {
        CFRelease(m_attr1);
		m_attr1 = NULL;
	}
    
}

- (id)copyWithZone:(NSZone *)zone {
    NCDateCell* cell = (NCDateCell*)[super copyWithZone:zone];

	cell->m_date_formatter_verbose = nil;
	cell->m_date_formatter_compact = nil;

	cell->m_width_of_verbose_text = 0;
	cell->m_attr_string = NULL; // lazy initialization in drawRect
	cell->m_ellipsis = NULL; // lazy initialization in drawRect
	cell->m_attr0 = NULL; // lazy initialization in drawRect
	cell->m_attr1 = NULL; // lazy initialization in drawRect


    return cell;
}



#if 0
/*
Ensure that the string is able to render within the
specified max-width. Text outside the max-width is removed.
If there is overflow then an ellipsis char is appended.
*/
-(NSAttributedString*)appendElipsisToString:(NSAttributedString*)aString
	maxWidth:(float)maxwidth 
{
	{
		float w = [aString size].width;
		if(w <= maxwidth) {
			return aString;
		}
	}

	static NSString* ellipsis = nil;
    if(ellipsis == nil) {
		const unichar ellipsis_char = 0x2026;
		ellipsis = [[NSString alloc] initWithCharacters:&ellipsis_char length:1];
    }

	NSMutableAttributedString* ms = [aString mutableCopy];
	int truncate_begin = [ms length] - 1;
	for(int i=0; (i<100) && (truncate_begin >= 2); ++i) {
		float w = [ms size].width;
		if(w < maxwidth) break;
		truncate_begin--;
		NSRange range = NSMakeRange(truncate_begin, 2);
		[ms replaceCharactersInRange:range withString:ellipsis];
	}
	return ms;
}

/*- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view {
	[[NSColor redColor] set];
	frame = NSInsetRect(frame, 5, 5);
	NSRectFill(frame);
	[super drawWithFrame:frame inView:view];
}*/

-(void)ydrawInteriorWithFrame:(NSRect)frame inView:(NSView *)view {
	uint64_t t0 = mach_absolute_time();

	id obj = [self objectValue];
	if(![obj isKindOfClass:[NSDate class]]) {
/*		[[NSColor redColor] set];
		NSRectFill(frame); */
		return;
	}

	NSGraphicsContext* context = [NSGraphicsContext currentContext];
	[context saveGraphicsState];
	[context setShouldAntialias:[self antiAlias]];
	
	NSDate* date = (NSDate*)obj;
	NSString* s = [date description];

	NSTextStorage*   text_storage = m_text_storage;
	NSLayoutManager* layout_manager = m_layout_manager;
	NSTextContainer* text_container = m_text_container;
	NSMutableParagraphStyle* para_style = m_para_style;
	NSDictionary* attr = m_attr;



	if(!layout_manager) {
		NSColor* color0 = [self color0];
		NSColor* color1 = [self color1];
		NSFont* font = [self font];

		text_storage = [[[NSTextStorage alloc] init] autorelease];
		self.textStorage = text_storage;
		text_container = [[[NSTextContainer alloc] initWithContainerSize:frame.size] autorelease];
		self.textContainer = text_container;
		layout_manager = [[[NSLayoutManager alloc] init] autorelease];
		self.layoutManager = layout_manager;

		para_style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		self.paraStyle = para_style;
		[para_style setLineBreakMode:NSLineBreakByTruncatingTail];
		
		attr = [NSDictionary dictionaryWithObjectsAndKeys:
			font,NSFontAttributeName,
			para_style,NSParagraphStyleAttributeName,
			color0, NSForegroundColorAttributeName,
			nil];
		self.attr = attr;

		[layout_manager addTextContainer:text_container];
		[text_storage addLayoutManager:layout_manager];
		[text_container setLineFragmentPadding:0.0];
	} else {
		// range = NSMakeRange(0, [text_storage length]);
	}
	

	NSRange range = NSMakeRange(0, [text_storage length]);
	[text_storage replaceCharactersInRange:range withString:s];

	range = NSMakeRange(0, [text_storage length]);
	[text_storage addAttributes:attr range:range];

	[text_container setContainerSize:frame.size];

	NSPoint origin = frame.origin;
	
	[layout_manager drawGlyphsForGlyphRange:range atPoint:origin];
	
	[[NSGraphicsContext currentContext] restoreGraphicsState];
	uint64_t t1 = mach_absolute_time();
	double elapsed0 = subtract_times(t1, t0);
	// LOG_DEBUG(@"%.6fs", elapsed0);
}

-(void)xdrawInteriorWithFrame:(NSRect)frame inView:(NSView *)view {
	uint64_t t0 = mach_absolute_time();

	id obj = [self objectValue];
	if(![obj isKindOfClass:[NSDate class]]) {
/*		[[NSColor redColor] set];
		NSRectFill(frame); */
		return;
	}

	NSGraphicsContext* context = [NSGraphicsContext currentContext];
	[context saveGraphicsState];
	[context setShouldAntialias:[self antiAlias]];

	NSDate* date = (NSDate*)obj;
	NSString* s = [date description];

	NSColor* color0 = [self color0];
	NSColor* color1 = [self color1];
	NSFont* font = [self font];


	NSTextStorage* text_storage = [[[NSTextStorage alloc] initWithString:s] autorelease];
	NSTextContainer* text_container = [[[NSTextContainer alloc] initWithContainerSize:frame.size] autorelease];
	NSLayoutManager* layout_manager = [[[NSLayoutManager alloc] init] autorelease];

	NSRange range = NSMakeRange(0, [text_storage length]);


	NSMutableParagraphStyle* para_style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	// [para_style setLineBreakMode:NSLineBreakByWordWrapping];
	// [para_style setAlignment:NSCenterTextAlignment];
	[text_storage addAttribute:NSParagraphStyleAttributeName value:para_style range:range];
	[text_storage addAttribute:NSForegroundColorAttributeName value:color0 range:range];

	[layout_manager addTextContainer:text_container];
	[text_storage addLayoutManager:layout_manager];
	[text_storage addAttribute:NSFontAttributeName value:font range:range];
	[text_container setLineFragmentPadding:0.0];

	(void) [layout_manager glyphRangeForTextContainer:text_container];
	
	NSPoint origin = frame.origin;
	
	[layout_manager drawGlyphsForGlyphRange:range atPoint:origin];
	
	[[NSGraphicsContext currentContext] restoreGraphicsState];
	uint64_t t1 = mach_absolute_time();
	double elapsed0 = subtract_times(t1, t0);
	// LOG_DEBUG(@"%.6fs", elapsed0);
}

- (void)tdrawInteriorWithFrame:(NSRect)xframe inView:(NSView *)view {
	id obj = [self objectValue];
	if(![obj isKindOfClass:[NSDate class]]) {
/*		[[NSColor redColor] set];
		NSRectFill(frame); */
		return;
	}

	NSDate* date = (NSDate*)obj;
	NSString* s = [date description];
	if(![s isKindOfClass:[NSString class]]) {
		[[NSColor redColor] set];
		NSRectFill(xframe);
		return;
	}


	NSColor* nsColor = [self textColor];
	// float padding_left = m_padding_left;
	// float offset_y = m_offset_y;
	float padding_left = [self paddingLeft];
	float offset_y = [self offsetY];


	CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
	CGContextSetTextMatrix(context, CGAffineTransformMakeScale(1, -1));
	// CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	CGContextSetShouldAntialias(context, [self antiAlias]);

	// Initialize a rectangular path.
	CGMutablePathRef path = CGPathCreateMutable();
	CGRect bounds = CGRectMake(xframe.origin.x, xframe.origin.y, xframe.size.width, xframe.size.height);
	CGPathAddRect(path, NULL, bounds);

	// Initialize an attributed string.
	CFStringRef string = (CFStringRef)s;
	int count = CFStringGetLength(string);
	// CFMutableAttributedStringRef attrString = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
	// CFAttributedStringReplaceString (attrString, CFRangeMake(0, 0), string);

	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB ();
	CGColorRef cgColor = CGColorCreateFromNSColor (colorSpace, nsColor);
	CGColorSpaceRelease (colorSpace);
	// CFAttributedStringSetAttribute(attrString, CFRangeMake(0, count), kCTForegroundColorAttributeName, cgColor);
	

	// Prepare font
	NSFont* nsfont = [self font];
	NSString* fontname = [nsfont fontName];
	CGFloat fontsize = [nsfont pointSize];
	CTFontRef font = CTFontCreateWithName((CFStringRef)fontname, fontsize, NULL);

	// Create an attributed string
	CFStringRef keys[] = { kCTFontAttributeName, kCTForegroundColorAttributeName };
	CFTypeRef values[] = { font, cgColor };
	CFDictionaryRef attr = CFDictionaryCreate(
		NULL, 
		(const void **)&keys, 
		(const void **)&values,
		sizeof(keys) / sizeof(keys[0]), 
		&kCFTypeDictionaryKeyCallBacks, 
		&kCFTypeDictionaryValueCallBacks
	);
	CFAttributedStringRef attrString = CFAttributedStringCreate(NULL, string, attr);
	// CFRelease(attr);

#if 1

	// Draw the string
	CTLineRef line = CTLineCreateWithAttributedString(attrString);
	CGContextSetTextPosition(
		context, 
		xframe.origin.x + padding_left, 
		xframe.origin.y + xframe.size.height /*- offset_y */
	);
	CTLineDraw(line, context);

#else	

	// Create the framesetter with the attributed string.
	CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(attrString);
	CFRelease(attrString);

	// Create the frame and draw it into the graphics context
	CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
	CFRelease(framesetter);

	// CGContextScaleCTM(context, 1.0f, 1.0f);
    // CGContextTranslateCTM(context, 0.0f, -xframe.size.height);

	CTFrameDraw(frame, context);
	CFRelease(frame);

#endif

	CGColorRelease (cgColor);
	// Clean up
	//CFRelease(line);
	//CFRelease(attrString);
	//CFRelease(font);
}

- (void)originalDrawInteriorWithFrame:(NSRect)frame inView:(NSView *)view {
	// return;
	uint64_t t0 = mach_absolute_time();
	id obj = [self objectValue];
	if(![obj isKindOfClass:[NSDate class]]) {
/*		[[NSColor redColor] set];
		NSRectFill(frame); */
		return;
	}

	NSDate* date = (NSDate*)obj;

	// float padding_left = m_padding_left;
	// float offset_y = m_offset_y;
	float padding_left = [self paddingLeft];
	float offset_y = [self offsetY];

	// NCListerCellStyle* style = self.style;
	

	NSColor* color0 = [self color0];
	NSColor* color1 = [self color1];
	NSFont* font = [self font];


	[[NSGraphicsContext currentContext] saveGraphicsState];
	
	[[NSGraphicsContext currentContext] setShouldAntialias:[self antiAlias]];



	NSMutableDictionary* attr0 = [[[NSMutableDictionary alloc] init] autorelease];
	if(color0) [attr0 setObject:color0 forKey:NSForegroundColorAttributeName];
	if(font) [attr0 setObject:font forKey:NSFontAttributeName];
	NSMutableDictionary* attr1 = [[[NSMutableDictionary alloc] init] autorelease];
	if(color1) [attr1 setObject:color1 forKey:NSForegroundColorAttributeName];
	if(font) [attr1 setObject:font forKey:NSFontAttributeName];


	NSAttributedString* s_dash = [[[NSAttributedString alloc] 
		initWithString:@"-" attributes:attr1] autorelease];

	NSAttributedString* s_space = [[[NSAttributedString alloc] 
		initWithString:@" " attributes:attr1] autorelease];

	NSAttributedString* s_colon = [[[NSAttributedString alloc] 
		initWithString:@":" attributes:attr1] autorelease];

	/*
	
	YYYY-MM-dd HH:mm:ss
	YYYY-MM-dd HH:mm
	YYYY-MM-dd
	YY-MM-dd
	YYYY
	today 16:30
	yesterday 16:30
	y.day 16:30
	TDA 16:30   (today)
	YDA 16:30   (yesterday)
	
		
	*/
	NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateFormat:@"yyyy"];
	NSAttributedString* s_year = [[[NSAttributedString alloc] 
		initWithString:[dateFormatter stringFromDate:date] attributes:attr0] autorelease];

	[dateFormatter setDateFormat:@"MM"];
	NSAttributedString* s_month = [[[NSAttributedString alloc] 
		initWithString:[dateFormatter stringFromDate:date] attributes:attr0] autorelease];

	[dateFormatter setDateFormat:@"dd"];
	NSAttributedString* s_day = [[[NSAttributedString alloc] 
		initWithString:[dateFormatter stringFromDate:date] attributes:attr0] autorelease];

	[dateFormatter setDateFormat:@"HH"];
	NSAttributedString* s_hour = [[[NSAttributedString alloc] 
		initWithString:[dateFormatter stringFromDate:date] attributes:attr0] autorelease];

	[dateFormatter setDateFormat:@"mm"];
	NSAttributedString* s_minute = [[[NSAttributedString alloc] 
		initWithString:[dateFormatter stringFromDate:date] attributes:attr0] autorelease];

	[dateFormatter setDateFormat:@"ss"];
	NSAttributedString* s_second = [[[NSAttributedString alloc] 
		initWithString:[dateFormatter stringFromDate:date] attributes:attr0] autorelease];

	NSMutableAttributedString* vs = [[[NSMutableAttributedString alloc] init] autorelease];
	[vs appendAttributedString:s_year];
	[vs appendAttributedString:s_dash];
	[vs appendAttributedString:s_month];
	[vs appendAttributedString:s_dash];
	[vs appendAttributedString:s_day];
	[vs appendAttributedString:s_space];
	[vs appendAttributedString:s_hour];
	[vs appendAttributedString:s_colon];
	[vs appendAttributedString:s_minute];
	[vs appendAttributedString:s_colon];
	[vs appendAttributedString:s_second];


	NSTimeInterval diff = -[date timeIntervalSinceNow];
	NSInteger day_diff = floorf(diff / 86400.0);  // 86400 seconds per day (24 hours * 60 minuts * 60 seconds)

	BOOL format_pretty = YES;
	BOOL format_year_month_day = NO;
	BOOL format_verbose = (!format_pretty);

	NSMutableAttributedString* s = [[[NSMutableAttributedString alloc] init] autorelease];
	if(format_pretty) do {
		NSString* s1 = nil;
		if(day_diff < 0) {
			// the future
		} else
		if(day_diff == 0) {
			if(diff < 0) {
				// the future
			} else
			if(diff < 60) {
				s1 = @"Just now";
			} else
			if(diff < 120) {
				s1 = @"1 minute ago";
				// IDEA: "1m" as on stackoverflow
			} else
			if(diff < 3600) {
				int v = floorf(diff / 60);
				s1 = [NSString stringWithFormat:@"%i minutes ago", v];
				// IDEA: "17m" as on stackoverflow
			} else
			if(diff < 7200) {
				s1 = @"1 hour ago";
				// IDEA: "1h" as on stackoverflow
			} else
			if(diff < 86400) {
				int v = floorf(diff / 3600);
				s1 = [NSString stringWithFormat:@"%i hours ago", v];
				// IDEA: "17h" as on stackoverflow
			}
		} else
		if(day_diff == 1) {
			s1 = @"Yesterday";
			// IDEA: "1d" as on stackoverflow
		} else
		if(day_diff < 7) {
			int v = floorf(day_diff);
			s1 = [NSString stringWithFormat:@"%i days ago", v];
			// IDEA: "17d" as on stackoverflow
		}
		
		if(!s1) {
			format_year_month_day = YES;
			break;
		}
		
		NSAttributedString* as1 = [[[NSAttributedString alloc] 
			initWithString:s1 attributes:attr0] autorelease];
		[s appendAttributedString:as1];
	} while(0);

	if(format_year_month_day) {
		[s appendAttributedString:s_year];
		[s appendAttributedString:s_dash];
		[s appendAttributedString:s_month];
		[s appendAttributedString:s_dash];
		[s appendAttributedString:s_day];
	}

	float vs_width = [vs size].width + padding_left + padding_left;
	if(NSWidth(frame) >= vs_width) {
		format_verbose = YES;
	}

	if(format_verbose) {
		// [s appendAttributedString:vs];
		s = vs;
	}

	// NSString* s = [date descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S" timeZone:nil locale:nil];


	s = [self appendElipsisToString:s maxWidth:NSWidth(frame) - padding_left];

	
	
	NSPoint point = NSMakePoint(
		NSMinX(frame) + padding_left,  
		NSMinY(frame) + offset_y
	);
	
	[s drawAtPoint:point];

	[[NSGraphicsContext currentContext] restoreGraphicsState];
	uint64_t t1 = mach_absolute_time();
	double elapsed0 = subtract_times(t1, t0);
	// LOG_DEBUG(@"%.6fs", elapsed0);
}

#endif

- (void)coretextDrawInteriorWithFrame:(NSRect)frame inView:(NSView *)view {
	// uint64_t t0 = mach_absolute_time();
	id obj = [self objectValue];
	if(![obj isKindOfClass:[NSDate class]]) {
/*		[[NSColor redColor] set];
		NSRectFill(frame); */
		return;
	}
	NSDate* date = (NSDate*)obj;


	float padding_left = [self paddingLeft];
	float padding_right = [self paddingRight];
	float coretext_offset_y = [self coretextOffsetY];

	float available_width = NSWidth(frame) - padding_left - padding_right;


	// figure out what needs to be re-computed based on which setters functions was used since last time
	BOOL need_compute_attrs = NO;            
	BOOL need_compute_ellipsis = NO;            
	BOOL need_compute_maxwidth = NO;
	NSUInteger dirty_mask = [self dirtyMask];
	if(dirty_mask) {
		if(dirty_mask & (kNCListerCellDirtyFont | kNCListerCellDirtyColor | kNCListerCellDirtyMarked | kNCListerCellDirtyHighlighted)) {
			need_compute_attrs = YES;
		}
		if(dirty_mask & kNCListerCellDirtyFont) {
			need_compute_ellipsis = YES;
			need_compute_maxwidth = YES;
		}
		[self setDirtyMask:0];
	}


	// lazy initialize attr0, attr1 so we don't spend time on allocating it over and over
	if(need_compute_attrs) {
	    if(m_attr0) { CFRelease(m_attr0); m_attr0 = NULL; }
	    if(m_attr1) { CFRelease(m_attr1); m_attr1 = NULL; }
	}
	if((m_attr0 == NULL) || (m_attr1 == NULL)) {
	
		NSColor* color0 = [self color0];
		NSColor* color1 = [self color1];
		NSFont* font = [self font];
		NSAssert(color0, @"must not be nil at this point");
		NSAssert(color1, @"must not be nil at this point");
		NSAssert(font, @"must not be nil at this point");

		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB ();
		CGColorRef cgColor0 = CGColorCreateFromNSColor(colorSpace, color0);
		CGColorRef cgColor1 = CGColorCreateFromNSColor(colorSpace, color1);
		CGColorSpaceRelease (colorSpace);

		CTFontRef cgFont = (__bridge CTFontRef)font;  // NOTE: toll free bridge between NSFont and CFFont so we can safely cast

		// lazy initialize the attr0 dictionary so we don't spend time on allocating it over and over
		if(m_attr0 == NULL) {
			CFStringRef keys[] = { kCTFontAttributeName, kCTForegroundColorAttributeName };
			CFTypeRef values[] = { cgFont, cgColor0 };
			m_attr0 = CFDictionaryCreate(
				NULL, 
				(const void **)&keys, 
				(const void **)&values,
				sizeof(keys) / sizeof(keys[0]), 
				&kCFTypeDictionaryKeyCallBacks, 
				&kCFTypeDictionaryValueCallBacks
			);
			NSAssert(m_attr0, @"must not be NULL at this point");
		}

		// lazy initialize the attr1 dictionary so we don't spend time on allocating it over and over
		if(m_attr1 == NULL) {
			CFStringRef keys[] = { kCTFontAttributeName, kCTForegroundColorAttributeName };
			CFTypeRef values[] = { cgFont, cgColor1 };
			m_attr1 = CFDictionaryCreate(
				NULL, 
				(const void **)&keys, 
				(const void **)&values,
				sizeof(keys) / sizeof(keys[0]), 
				&kCFTypeDictionaryKeyCallBacks, 
				&kCFTypeDictionaryValueCallBacks
			);
			NSAssert(m_attr1, @"must not be NULL at this point");
		}
	}
	NSAssert(m_attr0, @"must not be NULL at this point");
	NSAssert(m_attr1, @"must not be NULL at this point");
	CFDictionaryRef attr0 = m_attr0;
	CFDictionaryRef attr1 = m_attr1;


	// lazy initialize the ellipsis string so we don't spend time on allocating it over and over
	if(need_compute_ellipsis) {
	    if(m_ellipsis) { CFRelease(m_ellipsis); m_ellipsis = NULL; }
	}
	if(m_ellipsis == NULL) {
		// NOTE: we are only interested in the font.. we don't care about colors, 
		// so we can use attr0, which is re-populated both when font and colors changes
		// however colors doesn't matter for us, so for this reason we use it.
		UniChar elip=0x2026;
		CFStringRef elipString=CFStringCreateWithCharacters(NULL, &elip, 1);
		CFAttributedStringRef elipAttrString=CFAttributedStringCreate(NULL, elipString, attr0);
		m_ellipsis=CTLineCreateWithAttributedString(elipAttrString);
		CFRelease(elipAttrString);
		CFRelease(elipString);
		NSAssert(m_ellipsis, @"must not be NULL at this point");
	}
	NSAssert(m_ellipsis, @"must not be NULL at this point");


	// lazy initialize attrString so we don't spend time on allocating it over and over
	if(m_attr_string == NULL) {
		m_attr_string = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
	}
	NSAssert(m_attr_string, @"must not be NULL at this point");
	CFMutableAttributedStringRef attrString = m_attr_string;



	CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
	CGContextSetTextMatrix(context, CGAffineTransformMakeScale(1, -1));
	CGContextSetShouldAntialias(context, [self antiAlias]);


	// lazy compute the max width of the verbose string
	if(need_compute_maxwidth) {
		CFAttributedStringReplaceString(attrString, CFRangeMake(0, CFAttributedStringGetLength(attrString)), CFSTR("2010-12-24 23:59:59"));
		CFAttributedStringSetAttributes(attrString, CFRangeMake(0, CFAttributedStringGetLength(attrString)), attr0, YES);
		CTLineRef line = CTLineCreateWithAttributedString(attrString);
		CGRect ib = CTLineGetImageBounds(line, context);
		CFRelease(line);
		m_width_of_verbose_text = ib.size.width;
		// LOG_DEBUG(@"found width: %.3f", m_width_of_verbose_text);
	}

	// ensure that the string is empty
	CFAttributedStringReplaceString(attrString, CFRangeMake(0, CFAttributedStringGetLength(attrString)), CFSTR(""));

	// attempt using the short format if there room enough
	if(available_width < m_width_of_verbose_text) {

		NSTimeInterval diff = -[date timeIntervalSinceNow];
		CFStringRef ss = CFStringCreateFromTime(diff);
		// CFStringRef ss = CFStringCreateCompactFromTime(diff);
		if(ss) {
			CFAttributedStringReplaceString(attrString, CFRangeMake(0, CFAttributedStringGetLength(attrString)), (CFStringRef)ss);
			CFAttributedStringSetAttributes(attrString, CFRangeMake(0, CFAttributedStringGetLength(attrString)), attr0, YES);
			CFRelease(ss);
			ss = NULL;
		} else {
			if(m_date_formatter_compact == nil) {
				NSDateFormatter* date_formatter = [[NSDateFormatter alloc] init];
				[date_formatter setDateFormat:@"yyyy-MM-dd"];
				self.dateFormatterCompact = date_formatter;
			}
			NSString* str = [m_date_formatter_compact stringFromDate:date];
			CFAttributedStringReplaceString(attrString, CFRangeMake(0, CFAttributedStringGetLength(attrString)), (CFStringRef)str);

			// assuming that the format is: "yyyy-mm-dd" (10 chars)
			CFAttributedStringSetAttributes(attrString, CFRangeMake(0, 10), attr0, YES);
			CFAttributedStringSetAttributes(attrString, CFRangeMake(4, 1), attr1, YES);
			CFAttributedStringSetAttributes(attrString, CFRangeMake(7, 1), attr1, YES);
		}
	}
	
	// if everything else fails then fallback to using the verbose format
	if(CFAttributedStringGetLength(attrString) < 1) {
		if(m_date_formatter_verbose == nil) {
			NSDateFormatter* date_formatter = [[NSDateFormatter alloc] init];
			[date_formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
			self.dateFormatterVerbose = date_formatter;
		}
		NSString* str = [m_date_formatter_verbose stringFromDate:date];
		CFAttributedStringReplaceString(attrString, CFRangeMake(0, CFAttributedStringGetLength(attrString)), (CFStringRef)str);

		// assuming that the format is: "yyyy-mm-dd hh:mm:ss" (19 chars)
		CFAttributedStringSetAttributes(attrString, CFRangeMake(0, 19), attr0, YES);
		CFAttributedStringSetAttributes(attrString, CFRangeMake(4, 1), attr1, YES);
		CFAttributedStringSetAttributes(attrString, CFRangeMake(7, 1), attr1, YES);
		CFAttributedStringSetAttributes(attrString, CFRangeMake(13, 1), attr1, YES);
		CFAttributedStringSetAttributes(attrString, CFRangeMake(16, 1), attr1, YES);
	}

	CTLineRef line0 = CTLineCreateWithAttributedString(attrString);
	CTLineRef line1 = CTLineCreateTruncatedLine(line0, available_width, kCTLineTruncationEnd, m_ellipsis);

	// CGRect size_of_line = CTLineGetImageBounds(line, context);


	NSPoint point = NSMakePoint(
		NSMinX(frame) + padding_left,  
		// NSMinY(frame) + GetLineHeightForFont(cgFont) - offset_y
		// NSMinY(frame) + GetLineHeightForFont(cgFont) + offset_y
		// NSMinY(frame) + GetLineHeightForFont(cgFont)
		// NSMinY(frame) + size_of_line.size.height
		// NSMinY(frame) + (NSHeight(frame) + GetLineHeightForFont(cgFont)) / 2.0
		// NSMaxY(frame) + offset_y                   
		// NSMaxY(frame) - 6
		NSMaxY(frame) + coretext_offset_y
	);

	CGContextSetTextPosition(context, point.x, point.y);
	CTLineDraw(line1, context);

	CFRelease(line1);
	CFRelease(line0);
	
	// uint64_t t1 = mach_absolute_time();
	// double elapsed0 = subtract_times(t1, t0);
	// LOG_DEBUG(@"%.6fs", elapsed0);
}

- (void)drawInteriorWithFrame:(NSRect)frame inView:(NSView *)view {
#if 0
	[self originalDrawInteriorWithFrame:frame inView:view];
#else
	[self coretextDrawInteriorWithFrame:frame inView:view];
#endif
}

@end
