//
//  NCTableCornerView.m
//  cocoa_clickable_headercell
//
//  Created by Simon Strandgaard on 01/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NCTableCornerView.h"
#import "NSGradient+PredefinedGradients.h"


@implementation NCTableCornerView

@synthesize fillGradient = m_fill_gradient;
@synthesize menuAction = m_menu_action;
@synthesize menuTarget = m_menu_target;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		[self setFillGradient:[NSGradient tableHeaderGradient]];
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
	NSGradient* grad = [self fillGradient];
	
	NSRect r = [self bounds];
    [grad drawInRect:r angle:90.0];
}

- (BOOL)isFlipped {
	return YES;
}

-(void)mouseDown:(NSEvent*)event {
	id obj = m_menu_target;
	SEL sel = m_menu_action;
	if([obj respondsToSelector:sel]) {
		[obj performSelector:sel withObject:self];
		return;
	}
	[super mouseDown:event];
}

-(void)rightMouseDown:(NSEvent*)event {
	id obj = m_menu_target;
	SEL sel = m_menu_action;
	if([obj respondsToSelector:sel]) {
		[obj performSelector:sel withObject:self];
		return;
	}
	[super rightMouseDown:event];
}

@end
