//
//  NSTabView+SwitchExtensions.m
//  NCCore
//
//  Created by Simon Strandgaard on 03/07/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "NSTabView+SwitchExtensions.h"


@implementation NSTabView (SwitchExtensions)

-(void)selectNextOrFirstTabViewItem:(id)sender {
	NSInteger n = [self numberOfTabViewItems];
	if(n < 1) return;
	
	NSInteger index = 0;
	NSTabViewItem* item = [self selectedTabViewItem];
	if(item) {
		index = [self indexOfTabViewItem:item];
		index++;
		if(index >= n) {
			index = 0;
		}
	}
	[self selectTabViewItemAtIndex:index];
}

-(void)selectPreviousOrLastTabViewItem:(id)sender {
	NSInteger n = [self numberOfTabViewItems];
	if(n < 1) return;
	
	NSInteger index = 0;
	NSTabViewItem* item = [self selectedTabViewItem];
	if(item) {
		index = [self indexOfTabViewItem:item];
		if(index > 0) {
			index--;
		} else {
			index = n - 1;
		}
	}
	[self selectTabViewItemAtIndex:index];
}

-(void)removeAllTabs:(id)sender {
	NSEnumerator* e = [[self tabViewItems] objectEnumerator];
	NSTabViewItem* item;
	while(item = [e nextObject]) {
		[self removeTabViewItem:item];
	}
}


@end
