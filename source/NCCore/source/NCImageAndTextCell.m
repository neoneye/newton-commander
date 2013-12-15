//
//  NCImageAndTextCell.m
//  NCCore
//
//  Created by Simon Strandgaard on 24/05/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NCLog.h"
#import "NCTimeProfiler.h"
#import "NCImageAndTextCell.h"


@interface NCImageAndTextCell (Private)
-(NSAttributedString*)appendElipsisToString:(NSAttributedString*)aString
	maxWidth:(float)maxwidth;

@end

@implementation NCImageAndTextCell

@synthesize widthOfImageBox = m_width_of_image_box;


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


- (id)init {
    if ((self = [super init])) {
		m_width_of_image_box = 16;
	
		m_image2 = nil;
        [self setLineBreakMode:NSLineBreakByTruncatingTail];
        [self setTruncatesLastVisibleLine:YES];
        [self setSelectable:YES];
    }
    return self;
}

- (void)dealloc {
	m_image2 = nil;
}

-(void)setImage2:(NSImage *)anImage {
    if (anImage != m_image2) {
        m_image2 = anImage;
    }
}

-(NSImage*)image2 {
    return m_image2;
}


- (id)copyWithZone:(NSZone *)zone {
    NCImageAndTextCell* cell = (NCImageAndTextCell*)[super copyWithZone:zone];

    // The image ivar will be directly copied; we need to retain or copy it.
    cell->m_image2 = m_image2;

	cell->m_width_of_image_box = m_width_of_image_box;

    return cell;
}

- (NSRect)imageRectForBounds:(NSRect)cellFrame {
    NSRect result;
    if (m_image2 != nil) {
        result.size = [m_image2 size];
        result.size.width = m_width_of_image_box;
        result.origin = cellFrame.origin;
        result.origin.x += [self paddingLeft];
        result.origin.y += ceil((cellFrame.size.height - result.size.height) / 2);
    } else {
        result = NSZeroRect;
    }
    return result;
}

// We could manually implement expansionFrameWithFrame:inView: and drawWithExpansionFrame:inView: or just properly implement titleRectForBounds to get expansion tooltips to automatically work for us
- (NSRect)titleRectForBounds:(NSRect)cellFrame {
    NSRect result;
    if (m_image2 != nil) {
        result = cellFrame;
		float padding_left = [self paddingLeft];
        result.origin.x += padding_left + m_width_of_image_box;
        result.size.width -= padding_left + m_width_of_image_box;
    } else {
        result = [super titleRectForBounds:cellFrame];
    }
    return result;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent {
    NSRect textFrame, imageFrame;
    NSDivideRect (aRect, &imageFrame, &textFrame, [self paddingLeft] + m_width_of_image_box, NSMinXEdge);
	textFrame.size.width -= [self paddingRight];
	// textFrame.origin.y -= 15;
	// textFrame.size.height += 15 + 15;
    [super editWithFrame: textFrame inView: controlView editor:textObj delegate:anObject event: theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength {
    NSRect textFrame, imageFrame;
    NSDivideRect (aRect, &imageFrame, &textFrame, [self paddingLeft] + m_width_of_image_box, NSMinXEdge);
	textFrame.size.width -= [self paddingRight];
	// textFrame.origin.y -= 15;
	// textFrame.size.height += 15 + 15;
    [super selectWithFrame: textFrame inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	// return;
	//uint64_t t0 = mach_absolute_time();
    if (m_image2 != nil) {
		float img_padding_left = [self paddingLeft];
        NSRect imageFrame;
        NSSize imageSize = [m_image2 size];
        NSDivideRect(cellFrame, &imageFrame, &cellFrame, img_padding_left + m_width_of_image_box, NSMinXEdge);
        if ([self drawsBackground]) {
            [[self backgroundColor] set];
            NSRectFill(imageFrame);
        }
        imageFrame.size.width -= img_padding_left;
        imageFrame.origin.x += img_padding_left;   
        imageFrame.origin.x += ceil((NSWidth(imageFrame) - imageSize.width) / 2);
        imageFrame.size = imageSize;

        if ([controlView isFlipped]) {
            imageFrame.origin.y += ceil((cellFrame.size.height + imageFrame.size.height) / 2);
        } else {
            imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
        }

        [m_image2 compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
    }
	
	NSRect frame = cellFrame;
	
	BOOL old_anti_alias = YES;
	if(![self antiAlias]) {
		old_anti_alias = [[NSGraphicsContext currentContext] shouldAntialias];
		[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	}

	
	NSAttributedString* s = nil;
	{
		NSMutableDictionary* attr = [[NSMutableDictionary alloc] init];
		id obj = [self color0];
		if(obj) [attr setObject:obj forKey:NSForegroundColorAttributeName];

		obj = [self font];
		if(obj) [attr setObject:obj forKey:NSFontAttributeName];

		s = [[NSAttributedString alloc] 
			initWithString:[self stringValue] attributes:attr];
	}
	// NSAttributedString* s = [self attributedStringValue];

	// float padding_left = m_padding_left;
	float padding_left = 0;
	float padding_right = [self paddingRight];
	float offset_y = [self offsetY];

	float max_width = NSWidth(frame) - (padding_left + padding_right);
	s = [self appendElipsisToString:s maxWidth:max_width];

	NSPoint point = NSMakePoint(
		frame.origin.x + padding_left,
		frame.origin.y + offset_y
	);
	
	if([self alignment] == NSRightTextAlignment) {
		point.x = NSMaxX(frame) - [s size].width - padding_right;
	}
	
	point.x = floorf(point.x);
	point.y = floorf(point.y);
	
	[s drawAtPoint:point];

	if(![self antiAlias]) {
		[[NSGraphicsContext currentContext] setShouldAntialias:old_anti_alias];
	}
	//uint64_t t1 = mach_absolute_time();
	//double elapsed0 = subtract_times(t1, t0);
	// LOG_DEBUG(@"%.6fs", elapsed0);
}

- (NSSize)cellSize {
    NSSize cellSize = [super cellSize];
    if (m_image2 != nil) {
        cellSize.width += m_width_of_image_box;
        // cellSize.width += [m_image2 size].width;
    }
    // cellSize.width += 3;
    return cellSize;
}

- (NSUInteger)hitTestForEvent:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView {
    NSPoint point = [controlView convertPoint:[event locationInWindow] fromView:nil];
    // If we have an image, we need to see if the user clicked on the image portion.
    if (m_image2 != nil) {
        // This code closely mimics drawWithFrame:inView:
		float img_padding_left = [self paddingLeft];
        NSSize imageSize = [m_image2 size];
        NSRect imageFrame;
        NSDivideRect(cellFrame, &imageFrame, &cellFrame, img_padding_left + m_width_of_image_box, NSMinXEdge);
        
        imageFrame.origin.x += img_padding_left;
        imageFrame.size = imageSize;
        // If the point is in the image rect, then it is a content hit
        if (NSMouseInRect(point, imageFrame, [controlView isFlipped])) {
            // We consider this just a content area. It is not trackable, nor it it editable text. If it was, we would or in the additional items.
            // By returning the correct parts, we allow NSTableView to correctly begin an edit when the text portion is clicked on.
            return NSCellHitContentArea;
        }        
    }
    // At this point, the cellFrame has been modified to exclude the portion for the image. Let the superclass handle the hit testing at this point.
    return [super hitTestForEvent:event inRect:cellFrame ofView:controlView];    
}

@end
