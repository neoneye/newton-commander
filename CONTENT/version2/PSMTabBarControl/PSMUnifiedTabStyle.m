//
//  PSMUnifiedTabStyle.m
//  --------------------
//
//  Created by Keith Blount on 30/04/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "PSMUnifiedTabStyle.h"
#import "PSMTabBarCell.h"
#import "PSMTabBarControl.h"
#import "NSBezierPath_AMShading.h"

#define kPSMUnifiedObjectCounterRadius 7.0
#define kPSMUnifiedCounterMinWidth 20

@interface PSMUnifiedTabStyle (Private)
- (void)drawInteriorWithTabCell:(PSMTabBarCell *)cell inView:(NSView*)controlView;
@end

@implementation PSMUnifiedTabStyle

- (NSString *)name {
	return @"Unified";
}

#pragma mark -
#pragma mark Creation/Destruction

- (id) init {
	if((self = [super init])) {
		unifiedCloseButton = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabClose_Front"]];
		unifiedCloseButtonDown = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabClose_Front_Pressed"]];
		unifiedCloseButtonOver = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabClose_Front_Rollover"]];

		unifiedCloseDirtyButton = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabCloseDirty_Front"]];
		unifiedCloseDirtyButtonDown = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabCloseDirty_Front_Pressed"]];
		unifiedCloseDirtyButtonOver = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabCloseDirty_Front_Rollover"]];

		_addTabButtonImage = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabNew"]];
		_addTabButtonPressedImage = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabNewPressed"]];
		_addTabButtonRolloverImage = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabNewRollover"]];

		_objectCountStringAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[[NSFontManager sharedFontManager] convertFont:[NSFont fontWithName:@"Helvetica" size:11.0] toHaveTrait:NSBoldFontMask], NSFontAttributeName,
										[[NSColor whiteColor] colorWithAlphaComponent:0.85], NSForegroundColorAttributeName,
										nil, nil];

		leftMargin = 5.0;
	}
	return self;
}

- (void)dealloc {
	[unifiedCloseButton release];
	[unifiedCloseButtonDown release];
	[unifiedCloseButtonOver release];
	[unifiedCloseDirtyButton release];
	[unifiedCloseDirtyButtonDown release];
	[unifiedCloseDirtyButtonOver release];
	[_addTabButtonImage release];
	[_addTabButtonPressedImage release];
	[_addTabButtonRolloverImage release];

	[_objectCountStringAttributes release];

	[super dealloc];
}

#pragma mark -
#pragma mark Control Specific

- (void)setLeftMarginForTabBarControl:(CGFloat)margin {
	leftMargin = margin;
}

- (CGFloat)leftMarginForTabBarControl {
	return leftMargin;
}

- (CGFloat)rightMarginForTabBarControl {
	return 24.0f;
}

- (CGFloat)topMarginForTabBarControl {
	return 10.0f;
}

- (void)setOrientation:(PSMTabBarOrientation)value {
}

#pragma mark -
#pragma mark Add Tab Button

- (NSImage *)addTabButtonImage {
	return _addTabButtonImage;
}

- (NSImage *)addTabButtonPressedImage {
	return _addTabButtonPressedImage;
}

- (NSImage *)addTabButtonRolloverImage {
	return _addTabButtonRolloverImage;
}

#pragma mark -
#pragma mark Cell Specific

- (NSRect)dragRectForTabCell:(PSMTabBarCell *)cell orientation:(PSMTabBarOrientation)orientation {
	NSRect dragRect = [cell frame];
	dragRect.size.width++;
	return dragRect;
}

- (NSRect)closeButtonRectForTabCell:(PSMTabBarCell *)cell withFrame:(NSRect)cellFrame {
	if([cell hasCloseButton] == NO) {
		return NSZeroRect;
	}

	NSRect result;
	result.size = [unifiedCloseButton size];
	result.origin.x = cellFrame.origin.x + MARGIN_X;
	result.origin.y = cellFrame.origin.y + MARGIN_Y + 1.0;

	return result;
}

- (NSRect)iconRectForTabCell:(PSMTabBarCell *)cell {
	NSRect cellFrame = [cell frame];

	if([cell hasIcon] == NO) {
		return NSZeroRect;
	}

	NSRect result;
	result.size = NSMakeSize(kPSMTabBarIconWidth, kPSMTabBarIconWidth);
	result.origin.x = cellFrame.origin.x + MARGIN_X;
	result.origin.y = cellFrame.origin.y + MARGIN_Y - 1.0;

	if([cell hasCloseButton] && ![cell isCloseButtonSuppressed]) {
		result.origin.x += [unifiedCloseButton size].width + kPSMTabBarCellPadding;
	}

	return result;
}

- (NSRect)indicatorRectForTabCell:(PSMTabBarCell *)cell {
	NSRect cellFrame = [cell frame];

	if([[cell indicator] isHidden]) {
		return NSZeroRect;
	}

	NSRect result;
	result.size = NSMakeSize(kPSMTabBarIndicatorWidth, kPSMTabBarIndicatorWidth);
	result.origin.x = cellFrame.origin.x + cellFrame.size.width - MARGIN_X - kPSMTabBarIndicatorWidth;
	result.origin.y = cellFrame.origin.y + MARGIN_Y - 1.0;

	return result;
}

- (NSRect)objectCounterRectForTabCell:(PSMTabBarCell *)cell {
	NSRect cellFrame = [cell frame];

	if([cell count] == 0) {
		return NSZeroRect;
	}

	CGFloat countWidth = [[self attributedObjectCountValueForTabCell:cell] size].width;
	countWidth += (2 * kPSMUnifiedObjectCounterRadius - 6.0);
	if(countWidth < kPSMUnifiedCounterMinWidth) {
		countWidth = kPSMUnifiedCounterMinWidth;
	}

	NSRect result;
	result.size = NSMakeSize(countWidth, 2 * kPSMUnifiedObjectCounterRadius); // temp
	result.origin.x = cellFrame.origin.x + cellFrame.size.width - MARGIN_X - result.size.width;
	result.origin.y = cellFrame.origin.y + MARGIN_Y + 1.0;

	if(![[cell indicator] isHidden]) {
		result.origin.x -= kPSMTabBarIndicatorWidth + kPSMTabBarCellPadding;
	}

	return result;
}


- (CGFloat)minimumWidthOfTabCell:(PSMTabBarCell *)cell {
	CGFloat resultWidth = 0.0;

	// left margin
	resultWidth = MARGIN_X;

	// close button?
	if([cell hasCloseButton] && ![cell isCloseButtonSuppressed]) {
		resultWidth += [unifiedCloseButton size].width + kPSMTabBarCellPadding;
	}

	// icon?
	if([cell hasIcon]) {
		resultWidth += kPSMTabBarIconWidth + kPSMTabBarCellPadding;
	}

	// the label
	resultWidth += kPSMMinimumTitleWidth;

	// object counter?
	if([cell count] > 0) {
		resultWidth += [self objectCounterRectForTabCell:cell].size.width + kPSMTabBarCellPadding;
	}

	// indicator?
	if([[cell indicator] isHidden] == NO) {
		resultWidth += kPSMTabBarCellPadding + kPSMTabBarIndicatorWidth;
	}

	// right margin
	resultWidth += MARGIN_X;

	return ceil(resultWidth);
}

- (CGFloat)desiredWidthOfTabCell:(PSMTabBarCell *)cell {
	CGFloat resultWidth = 0.0;

	// left margin
	resultWidth = MARGIN_X;

	// close button?
	if([cell hasCloseButton] && ![cell isCloseButtonSuppressed]) {
		resultWidth += [unifiedCloseButton size].width + kPSMTabBarCellPadding;
	}

	// icon?
	if([cell hasIcon]) {
		resultWidth += kPSMTabBarIconWidth + kPSMTabBarCellPadding;
	}

	// the label
	resultWidth += [[cell attributedStringValue] size].width;

	// object counter?
	if([cell count] > 0) {
		resultWidth += [self objectCounterRectForTabCell:cell].size.width + kPSMTabBarCellPadding;
	}

	// indicator?
	if([[cell indicator] isHidden] == NO) {
		resultWidth += kPSMTabBarCellPadding + kPSMTabBarIndicatorWidth;
	}

	// right margin
	resultWidth += MARGIN_X;

	return ceil(resultWidth);
}

- (CGFloat)tabCellHeight {
	return kPSMTabBarControlHeight;
}

#pragma mark -
#pragma mark Cell Values

- (NSAttributedString *)attributedObjectCountValueForTabCell:(PSMTabBarCell *)cell {
	NSString *contents = [NSString stringWithFormat:@"%lu", (unsigned long)[cell count]];
	return [[[NSMutableAttributedString alloc] initWithString:contents attributes:_objectCountStringAttributes] autorelease];
}

- (NSAttributedString *)attributedStringValueForTabCell:(PSMTabBarCell *)cell {
	NSMutableAttributedString *attrStr;
	NSString * contents = [cell stringValue];
	attrStr = [[[NSMutableAttributedString alloc] initWithString:contents] autorelease];
	NSRange range = NSMakeRange(0, [contents length]);

	[attrStr addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:11.0] range:range];

	// Paragraph Style for Truncating Long Text
	static NSMutableParagraphStyle *TruncatingTailParagraphStyle = nil;
	if(!TruncatingTailParagraphStyle) {
		TruncatingTailParagraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] retain];
		[TruncatingTailParagraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	}
	[attrStr addAttribute:NSParagraphStyleAttributeName value:TruncatingTailParagraphStyle range:range];

	return attrStr;
}

#pragma mark -
#pragma mark ---- drawing ----

- (void)drawTabCell:(PSMTabBarCell *)cell {
	NSRect cellFrame = [cell frame];

	NSToolbar *toolbar = [[[cell controlView] window] toolbar];
	BOOL showsBaselineSeparator = (toolbar && [toolbar respondsToSelector:@selector(showsBaselineSeparator)] && [toolbar showsBaselineSeparator]);
	if(!showsBaselineSeparator) {
		cellFrame.origin.y += 1.0;
		cellFrame.size.height -= 1.0;
	}

	NSColor * lineColor = nil;
	NSBezierPath* bezier = [NSBezierPath bezierPath];
	lineColor = [NSColor colorWithCalibratedWhite:0.576 alpha:1.0];

	if(!showsBaselineSeparator || [cell state] == NSOnState) {
		// selected tab
		NSRect aRect = NSMakeRect(cellFrame.origin.x + 0.5, cellFrame.origin.y - 0.5, cellFrame.size.width, cellFrame.size.height);

		// frame
		CGFloat radius = MIN(6.0, 0.5f * MIN(NSWidth(aRect), NSHeight(aRect)));
		NSRect rect = NSInsetRect(aRect, radius, radius);

		[bezier appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMinY(rect)) radius:radius startAngle:180.0 endAngle:270.0];

		[bezier appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMinY(rect)) radius:radius startAngle:270.0 endAngle:360.0];

		NSPoint cornerPoint = NSMakePoint(NSMaxX(aRect), NSMaxY(aRect));
		[bezier appendBezierPathWithPoints:&cornerPoint count:1];

		cornerPoint = NSMakePoint(NSMinX(aRect), NSMaxY(aRect));
		[bezier appendBezierPathWithPoints:&cornerPoint count:1];

		[bezier closePath];

		//[[NSColor windowBackgroundColor] set];
		//[bezier fill];
		if([NSApp isActive]) {
			if([cell state] == NSOnState) {
				[bezier linearGradientFillWithStartColor:[NSColor colorWithCalibratedWhite:0.99 alpha:1.0]
				 endColor:[NSColor colorWithCalibratedWhite:0.941 alpha:1.0]];
			} else if([cell isHighlighted]) {
				[bezier linearGradientFillWithStartColor:[NSColor colorWithCalibratedWhite:0.80 alpha:1.0]
				 endColor:[NSColor colorWithCalibratedWhite:0.80 alpha:1.0]];
			} else {
				[bezier linearGradientFillWithStartColor:[NSColor colorWithCalibratedWhite:0.835 alpha:1.0]
				 endColor:[NSColor colorWithCalibratedWhite:0.843 alpha:1.0]];
			}
		}

		[lineColor set];
		[bezier stroke];
	}   else{
		// unselected tab
		NSRect aRect = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
		aRect.origin.y += 0.5;
		aRect.origin.x += 1.5;
		aRect.size.width -= 1;

		aRect.origin.x -= 1;
		aRect.size.width += 1;

		// rollover
		if([cell isHighlighted]) {
			[[NSColor colorWithCalibratedWhite:0.0 alpha:0.1] set];
			NSRectFillUsingOperation(aRect, NSCompositeSourceAtop);
		}

		// frame

		[lineColor set];
		[bezier moveToPoint:NSMakePoint(aRect.origin.x + aRect.size.width, aRect.origin.y - 0.5)];
		if(!([cell tabState] & PSMTab_RightIsSelectedMask)) {
			[bezier lineToPoint:NSMakePoint(NSMaxX(aRect), NSMaxY(aRect))];
		}

		[bezier stroke];

		// Create a thin lighter line next to the dividing line for a bezel effect
		if(!([cell tabState] & PSMTab_RightIsSelectedMask)) {
			[[[NSColor whiteColor] colorWithAlphaComponent:0.5] set];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX(aRect) + 1.0, aRect.origin.y - 0.5)
			 toPoint:NSMakePoint(NSMaxX(aRect) + 1.0, NSMaxY(aRect) - 2.5)];
		}

		// If this is the leftmost tab, we want to draw a line on the left, too
		if([cell tabState] & PSMTab_PositionLeftMask) {
			[lineColor set];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(aRect.origin.x, aRect.origin.y - 0.5)
			 toPoint:NSMakePoint(aRect.origin.x, NSMaxY(aRect) - 2.5)];
			[[[NSColor whiteColor] colorWithAlphaComponent:0.5] set];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(aRect.origin.x + 1.0, aRect.origin.y - 0.5)
			 toPoint:NSMakePoint(aRect.origin.x + 1.0, NSMaxY(aRect) - 2.5)];
		}
	}

	[self drawInteriorWithTabCell:cell inView:[cell controlView]];
}


- (void)drawInteriorWithTabCell:(PSMTabBarCell *)cell inView:(NSView*)controlView {
	NSRect cellFrame = [cell frame];
	CGFloat labelPosition = cellFrame.origin.x + MARGIN_X;

	// close button
	if([cell hasCloseButton] && ![cell isCloseButtonSuppressed]) {
		NSSize closeButtonSize = NSZeroSize;
		NSRect closeButtonRect = [cell closeButtonRectForFrame:cellFrame];
		NSImage * closeButton = nil;

		closeButton = [cell isEdited] ? unifiedCloseDirtyButton : unifiedCloseButton;

		if([cell closeButtonOver]) {
			closeButton = [cell isEdited] ? unifiedCloseDirtyButtonOver : unifiedCloseButtonOver;
		}
		if([cell closeButtonPressed]) {
			closeButton = [cell isEdited] ? unifiedCloseDirtyButtonDown : unifiedCloseButtonDown;
		}

		closeButtonSize = [closeButton size];
		if([controlView isFlipped]) {
			closeButtonRect.origin.y += closeButtonRect.size.height;
		}

		[closeButton compositeToPoint:closeButtonRect.origin operation:NSCompositeSourceOver fraction:1.0];

		// scoot label over
		labelPosition += closeButtonSize.width + kPSMTabBarCellPadding;
	}

	// icon
	if([cell hasIcon]) {
		NSRect iconRect = [self iconRectForTabCell:cell];
        NSImage *icon = nil;
        NSSize iconSize = NSMakeSize(20, 20);
        if([[[cell representedObject] identifier] respondsToSelector:@selector(icon)]) {
            icon = [[[cell representedObject] identifier] valueForKey:@"icon"];
            iconSize = [icon size];
        }
		if([controlView isFlipped]) {
			iconRect.origin.y += iconRect.size.height;
		}

		// center in available space (in case icon image is smaller than kPSMTabBarIconWidth)
		if(iconSize.width < kPSMTabBarIconWidth) {
			iconRect.origin.x += (kPSMTabBarIconWidth - iconSize.width) / 2.0;
		}
		if(iconSize.height < kPSMTabBarIconWidth) {
			iconRect.origin.y -= (kPSMTabBarIconWidth - iconSize.height) / 2.0;
		}

		[icon compositeToPoint:iconRect.origin operation:NSCompositeSourceOver fraction:1.0];

		// scoot label over
		labelPosition += iconRect.size.width + kPSMTabBarCellPadding;
	}

	// label rect
	NSRect labelRect;
	labelRect.origin.x = labelPosition;
	labelRect.size.width = cellFrame.size.width - (labelRect.origin.x - cellFrame.origin.x) - kPSMTabBarCellPadding;
	NSSize s = [[cell attributedStringValue] size];
	labelRect.origin.y = cellFrame.origin.y + (cellFrame.size.height - s.height) / 2.0 - 1.0;
	labelRect.size.height = s.height;

	if(![[cell indicator] isHidden]) {
		labelRect.size.width -= (kPSMTabBarIndicatorWidth + kPSMTabBarCellPadding);
	}

	// object counter
	if([cell count] > 0) {
		[[cell countColor] ?: [NSColor colorWithCalibratedWhite:0.3 alpha:0.6] set];
		NSBezierPath *path = [NSBezierPath bezierPath];
		NSRect myRect = [self objectCounterRectForTabCell:cell];
		myRect.origin.y -= 1.0;
		[path moveToPoint:NSMakePoint(myRect.origin.x + kPSMUnifiedObjectCounterRadius, myRect.origin.y)];
		[path lineToPoint:NSMakePoint(myRect.origin.x + myRect.size.width - kPSMUnifiedObjectCounterRadius, myRect.origin.y)];
		[path appendBezierPathWithArcWithCenter:NSMakePoint(myRect.origin.x + myRect.size.width - kPSMUnifiedObjectCounterRadius, myRect.origin.y + kPSMUnifiedObjectCounterRadius) radius:kPSMUnifiedObjectCounterRadius startAngle:270.0 endAngle:90.0];
		[path lineToPoint:NSMakePoint(myRect.origin.x + kPSMUnifiedObjectCounterRadius, myRect.origin.y + myRect.size.height)];
		[path appendBezierPathWithArcWithCenter:NSMakePoint(myRect.origin.x + kPSMUnifiedObjectCounterRadius, myRect.origin.y + kPSMUnifiedObjectCounterRadius) radius:kPSMUnifiedObjectCounterRadius startAngle:90.0 endAngle:270.0];
		[path fill];

		// draw attributed string centered in area
		NSRect counterStringRect;
		NSAttributedString *counterString = [self attributedObjectCountValueForTabCell:cell];
		counterStringRect.size = [counterString size];
		counterStringRect.origin.x = myRect.origin.x + ((myRect.size.width - counterStringRect.size.width) / 2.0) + 0.25;
		counterStringRect.origin.y = myRect.origin.y + ((myRect.size.height - counterStringRect.size.height) / 2.0) + 0.5;
		[counterString drawInRect:counterStringRect];

		labelRect.size.width -= myRect.size.width + kPSMTabBarCellPadding;
	}

	// label
	[[cell attributedStringValue] drawInRect:labelRect];
}

- (void)drawBackgroundInRect:(NSRect)rect {
	//Draw for our whole bounds; it'll be automatically clipped to fit the appropriate drawing area
	rect = [tabBar bounds];

	NSRect gradientRect = rect;
	gradientRect.size.height -= 1.0;

	NSBezierPath *path = [NSBezierPath bezierPathWithRect:gradientRect];
	[path linearGradientFillWithStartColor:[NSColor colorWithCalibratedWhite:0.835 alpha:1.0]
	 endColor:[NSColor colorWithCalibratedWhite:0.843 alpha:1.0]];
	[[NSColor colorWithCalibratedWhite:0.576 alpha:1.0] set];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(rect.origin.x, NSMaxY(rect) - 0.5)
	 toPoint:NSMakePoint(NSMaxX(rect), NSMaxY(rect) - 0.5)];

	if(![[[tabBar tabView] window] isKeyWindow]) {
		[[NSColor windowBackgroundColor] set];
		NSRectFill(gradientRect);
	}
}

- (void)drawTabBar:(PSMTabBarControl *)bar inRect:(NSRect)rect {
	tabBar = bar;
	[self drawBackgroundInRect:rect];

	// no tab view == not connected
	if(![bar tabView]) {
		NSRect labelRect = rect;
		labelRect.size.height -= 4.0;
		labelRect.origin.y += 4.0;
		NSMutableAttributedString *attrStr;
		NSString *contents = @"PSMTabBarControl";
		attrStr = [[[NSMutableAttributedString alloc] initWithString:contents] autorelease];
		NSRange range = NSMakeRange(0, [contents length]);
		[attrStr addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:11.0] range:range];
		NSMutableParagraphStyle *centeredParagraphStyle = nil;
		if(!centeredParagraphStyle) {
			centeredParagraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] retain];
			[centeredParagraphStyle setAlignment:NSCenterTextAlignment];
		}
		[attrStr addAttribute:NSParagraphStyleAttributeName value:centeredParagraphStyle range:range];
		[attrStr drawInRect:labelRect];
		return;
	}

	// draw cells
	NSEnumerator *e = [[bar cells] objectEnumerator];
	PSMTabBarCell *cell;
	while((cell = [e nextObject])) {
		if([bar isAnimating] || (![cell isInOverflowMenu] && NSIntersectsRect([cell frame], rect))) {
			[cell drawWithFrame:[cell frame] inView:bar];
		}
	}
}

#pragma mark -
#pragma mark Archiving

- (void)encodeWithCoder:(NSCoder *)aCoder {
	//[super encodeWithCoder:aCoder];
	if([aCoder allowsKeyedCoding]) {
		[aCoder encodeObject:unifiedCloseButton forKey:@"unifiedCloseButton"];
		[aCoder encodeObject:unifiedCloseButtonDown forKey:@"unifiedCloseButtonDown"];
		[aCoder encodeObject:unifiedCloseButtonOver forKey:@"unifiedCloseButtonOver"];
		[aCoder encodeObject:unifiedCloseDirtyButton forKey:@"unifiedCloseDirtyButton"];
		[aCoder encodeObject:unifiedCloseDirtyButtonDown forKey:@"unifiedCloseDirtyButtonDown"];
		[aCoder encodeObject:unifiedCloseDirtyButtonOver forKey:@"unifiedCloseDirtyButtonOver"];
		[aCoder encodeObject:_addTabButtonImage forKey:@"addTabButtonImage"];
		[aCoder encodeObject:_addTabButtonPressedImage forKey:@"addTabButtonPressedImage"];
		[aCoder encodeObject:_addTabButtonRolloverImage forKey:@"addTabButtonRolloverImage"];
	}
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	// self = [super initWithCoder:aDecoder];
	//if (self) {
	if([aDecoder allowsKeyedCoding]) {
		unifiedCloseButton = [[aDecoder decodeObjectForKey:@"unifiedCloseButton"] retain];
		unifiedCloseButtonDown = [[aDecoder decodeObjectForKey:@"unifiedCloseButtonDown"] retain];
		unifiedCloseButtonOver = [[aDecoder decodeObjectForKey:@"unifiedCloseButtonOver"] retain];
		unifiedCloseDirtyButton = [[aDecoder decodeObjectForKey:@"unifiedCloseDirtyButton"] retain];
		unifiedCloseDirtyButtonDown = [[aDecoder decodeObjectForKey:@"unifiedCloseDirtyButtonDown"] retain];
		unifiedCloseDirtyButtonOver = [[aDecoder decodeObjectForKey:@"unifiedCloseDirtyButtonOver"] retain];
		_addTabButtonImage = [[aDecoder decodeObjectForKey:@"addTabButtonImage"] retain];
		_addTabButtonPressedImage = [[aDecoder decodeObjectForKey:@"addTabButtonPressedImage"] retain];
		_addTabButtonRolloverImage = [[aDecoder decodeObjectForKey:@"addTabButtonRolloverImage"] retain];
	}
	//}
	return self;
}

@end
