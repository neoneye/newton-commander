//
//  CombinedButtonAndPopUp.m
//  demo
//
//  Created by Simon Strandgaard on 12/05/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import "CombinedButtonAndPopUp.h"
#import "CombinedButtonAndPopUpCell.h"


@interface CombinedButtonAndPopUp ()
-(NSMenu*)convertMenu:(NSMenu*)aMenu;
@end

@implementation CombinedButtonAndPopUp

+(Class)cellClass {
    return [CombinedButtonAndPopUpCell class];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super initWithCoder:decoder])
	{
		if (![[self cell] isKindOfClass:[CombinedButtonAndPopUpCell class]])
		{
			CombinedButtonAndPopUpCell* cell = [[CombinedButtonAndPopUpCell alloc] initTextCell:@"" pullsDown:YES];
			[self setCell:cell];
			[cell release];
		}
	}

	{
		NSMenu *popupMenu = [NSMenu new];
		[popupMenu addItem:[[NSMenuItem new] autorelease]]; //you must add a blank item first!
		[popupMenu addItemWithTitle:NSLocalizedString(@"Item 1", nil) action:@selector(dummyItemAction:) keyEquivalent:@""];
		[popupMenu addItem:[NSMenuItem separatorItem]];
		[popupMenu addItemWithTitle:NSLocalizedString(@"Item 2", nil) action:@selector(dummyItemAction:) keyEquivalent:@""];
		[[popupMenu itemArray] makeObjectsPerformSelector:@selector(setTarget:) withObject:self];
		[self installMenu:popupMenu];
	}

	return self;
}

-(void)installMenu:(NSMenu*)menu {
	
	menu = [self convertMenu:menu];

	NSString* found_title = @"-";
	NSArray* items = [menu itemArray];
	for(NSMenuItem* item in items) {
		if(!item.title) continue;
		if(!item.action) continue;
		found_title = item.title;
		break;
	}

	
	[[self cell] setMenu:menu];
	[[self cell] setTitle:found_title];
}

-(NSMenu*)convertMenu:(NSMenu*)aMenu {
	NSMenu* menu = [[[NSMenu alloc] init] autorelease];
	[menu addItem:[[NSMenuItem new] autorelease]]; //you must add a blank item first!
	                      
	NSArray* items = [aMenu itemArray];
	for(NSMenuItem* item in items) {
		NSMenuItem* item_clone = nil;
		
		if([item isSeparatorItem]) {
			item_clone = [NSMenuItem separatorItem];
		} else {
			item_clone = [[[NSMenuItem alloc] 
				initWithTitle:[item title] 
				action:[item action] 
				keyEquivalent:[item keyEquivalent]
			] autorelease];
		}
		NSLog(@"%s %@ -> %@", _cmd, item, item_clone);

		[menu addItem:item_clone];
	}
	
	return menu;
}

-(void)dummyItemAction:(id)sender {
	NSLog(@"%s", _cmd);
}

- (void)performClick:(id)sender {
    [[self cell] performClick:sender];
}


@end
