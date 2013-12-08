//
//  NCTabbedPathBar.m
//  NCCore
//
//  Created by Simon Strandgaard on 06/03/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "NCTabbedPathBar.h"
#import "MAAttachedWindow.h"

// #define kNCTabbedPathBarPath @"path"


@interface NCTabbedPathBar (Private)
-(void)normalize;
@end


@implementation NCTabbedPathBar

@synthesize popUpButton = m_popupbutton; 
@synthesize textField = m_textfield; 
@synthesize tooltip = m_tooltip; 

@synthesize selectedIndex = m_selected_index;
@synthesize numberOfTabs = m_number_of_tabs;
@synthesize isActive = m_is_active;

// @synthesize path = m_path;


/*+ (void)initialize {
    [self exposeBinding:kNCTabbedPathBarPath];
}

- (Class)valueClassForBinding:(NSString *)binding {
    if ([binding isEqualToString:kNCTabbedPathBarPath]) {
        return [NSString class];
    } else {
        return [super valueClassForBinding:binding];
    }
} */


- (id)initWithCoder:(NSCoder *)coder {
	// NSLog(@"%s tabbedpathbar", _cmd);
	if ((self = [super initWithCoder:coder]) != nil) {
		[self setPopUpButton:[coder decodeObjectForKey:@"NCTabbedPathBarPopUpButton"]];
		[self setTextField:[coder decodeObjectForKey:@"NCTabbedPathBarTextField"]];

		m_selected_index = 0;
		m_number_of_tabs = 1;
		m_is_active = NO;
		[self reloadTabs];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder*)coder {
	// NSLog(@"%s tabbedpathbar", _cmd);
    [super encodeWithCoder:coder];
	[coder encodeObject:[self popUpButton] forKey:@"NCTabbedPathBarPopUpButton"];
	[coder encodeObject:[self textField] forKey:@"NCTabbedPathBarTextField"];
}

-(void)normalize {
	if(m_number_of_tabs < 1) {
		m_number_of_tabs = 1;
	}
	if(m_selected_index < 0) {
		m_selected_index = 0;
	}
	if(m_selected_index >= m_number_of_tabs) {
		m_selected_index = m_number_of_tabs - 1;
	}
}

-(void)reloadTabs {
	[self normalize];
	
	NSMutableArray* titles = [NSMutableArray arrayWithCapacity:m_number_of_tabs];
	int i;
	for(i=0; i<m_number_of_tabs; i++) {
		[titles addObject:[NSString stringWithFormat:@"%i of %i", (i+1), m_number_of_tabs]];
	}
	[m_popupbutton removeAllItems];
	[m_popupbutton addItemsWithTitles:titles];
	[m_popupbutton selectItemAtIndex:m_selected_index];
	[m_popupbutton synchronizeTitleAndSelectedItem];
}

-(void)setPath:(NSString*)path {
	// NSLog(@"%s %@ %@", _cmd, path, m_textfield);
	[m_textfield setStringValue:path];
}

-(IBAction)showTooltip:(id)sender {
	// NSLog(@"%s %@", _cmd, [self window]);

	NSColor* color0 = [NSColor whiteColor];
	NSMutableDictionary* attr0 = [[[NSMutableDictionary alloc] init] autorelease];
	[attr0 setObject:color0 forKey:NSForegroundColorAttributeName];
	[attr0 setObject:[NSFont systemFontOfSize:18] forKey:NSFontAttributeName];
	NSString* sx = @"/usr/local/oiuxcv/oiucx/nnwemn/bin/X11/tmp/wine/xyz/var";

	NSRect textview_frame = NSMakeRect(0, 0, 500, 50);
	
	
	NSPoint point = NSMakePoint( NSMidX([m_popupbutton frame]), NSMidY([m_popupbutton frame]) );
	point = [[[self window] contentView] convertPoint:point fromView:self];
	
	NSTextView* textview = [[[NSTextView alloc] initWithFrame:textview_frame] autorelease];
	[textview setDrawsBackground:NO];
	{
		NSAttributedString* as = [[[NSAttributedString alloc] 
			initWithString:sx attributes:attr0] autorelease];
		[[textview textStorage] setAttributedString:as];
	}

    MAAttachedWindow* w = [[MAAttachedWindow alloc] initWithView:textview 
                                            attachedToPoint:point 
                                                   inWindow:[self window] 
                                                     onSide:MAPositionBottomRight 
                                                 atDistance:8];
    [w setBorderColor:[NSColor whiteColor]];
    [w setBackgroundColor:[NSColor colorWithCalibratedWhite:0.15 alpha:0.85]];
    [w setViewMargin:20];
    [w setBorderWidth:2];
    [w setCornerRadius:10];
    [w setHasArrow:YES];
    [w setDrawsRoundCornerBesideArrow:YES];
    [w setArrowBaseWidth:25];
    [w setArrowHeight:15];

	[[self window] addChildWindow:w ordered:NSWindowAbove];

	[self setTooltip:w];
	[w release];
	
	[self performSelector:@selector(hideTooltip:) withObject:nil afterDelay:5];
}

-(IBAction)hideTooltip:(id)sender {
	NSLog(@"%s", _cmd);
// 	TODO: order out the tooltip window

	MAAttachedWindow* w = [self tooltip];
	if(w != nil) {
	    [[self window] removeChildWindow:w];
	    [w orderOut:self];
		[self setTooltip:nil];
	}
}


@end
