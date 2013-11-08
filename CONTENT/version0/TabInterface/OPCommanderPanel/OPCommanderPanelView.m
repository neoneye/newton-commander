//
//  OPCommanderPanelView.m
//  OPCommanderPanel
//
//  Created by Simon Strandgaard on 18/01/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "OPCommanderPanelView.h"
#import <PSMTabBarControl/PSMTabBarControl.h>

@implementation OPCommanderPanelView

-(void)drawRect:(NSRect)rect {
	NSRect r1 = NSMakeRect(
		NSMinX(rect), 
		NSMinY(rect),
		floorf(NSWidth(rect) * 0.5),
		NSHeight(rect)
	);
	NSRect r2 = r1;
	r2.origin.x += NSWidth(r1);

	[[NSColor redColor] set];
	// [self.leftColor set];
	NSRectFill(r1);
	[[NSColor blueColor] set];
	NSRectFill(r2);
}

- (IBAction)addNewTab:(id)sender {
    NSTabViewItem *newItem = [[[NSTabViewItem alloc] initWithIdentifier:@"ident"] autorelease];
    [newItem setLabel:@"Untitled"];
    [m_tabview addTabViewItem:newItem];
    [m_tabview selectTabViewItem:newItem];
} 

+ (void)load {
	NSLog(@"%s", _cmd);
	
}

- (void)awakeFromNib {
	NSLog(@"%s", _cmd);
	
/*	NSButton* b = [[NSButton alloc] initWithFrame:NSMakeRect(5, 5, 100, 100)];
	[b autorelease];
	[m_tabbar addSubview:b]; /**/
	
	[m_tabbar setTabView:m_tabview];
	[m_tabview setDelegate:m_tabbar];

	// hook up add tab button
	// [[m_tabbar addTabButton] setTarget:self];
	// [[m_tabbar addTabButton] setAction:@selector(addNewTab:)];
	
}

@end
