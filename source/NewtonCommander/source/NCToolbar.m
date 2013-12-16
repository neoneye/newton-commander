//
//  NCToolbar.m
//  NewtonCommander
//
//  Created by Simon Strandgaard on 10/03/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "NCLog.h"
#import "NCToolbar.h"
#include <sys/types.h>
#include <pwd.h>
#include <grp.h>

#define opcoders_filter_left_panel_toolbar_item_identifier "Opcoders Filter Left Panel Toolboar Item"
#define opcoders_filter_right_panel_toolbar_item_identifier "Opcoders Filter Right Panel Toolboar Item"
#define opcoders_reload_toolbar_item_identifier "Opcoders Reload Toolboar Item"
#define opcoders_help_toolbar_item_identifier "Opcoders Help Toolboar Item"
#define opcoders_menu_toolbar_item_identifier "Opcoders Menu Toolboar Item"
#define opcoders_view_toolbar_item_identifier "Opcoders View Toolboar Item"
#define opcoders_edit_toolbar_item_identifier "Opcoders Edit Toolboar Item"
#define opcoders_copy_toolbar_item_identifier "Opcoders Copy Toolboar Item"
#define opcoders_move_toolbar_item_identifier "Opcoders Move Toolboar Item"
#define opcoders_mkdir_toolbar_item_identifier "Opcoders MakeDir Toolboar Item"
#define opcoders_delete_toolbar_item_identifier "Opcoders Delete Toolboar Item"
#define opcoders_switch_user_toolbar_item_identifier "Opcoders Switch User Toolboar Item"


struct ItemDescriptor {
	const char* identifier;
	const char* label;
	const char* tooltip;
	const char* iconname;
	int tag;
	int is_button;
};


struct ItemDescriptor item_descriptors[] = {
	// reload
	opcoders_reload_toolbar_item_identifier,
	"Reload",
	"Refresh the info",
	// @"color_reload",
	"icon_reload",
	// @"icon_reload2",
	// @"icon_reload3",
	kNCReloadToolbarItemTag,
	1,

	// help
	opcoders_help_toolbar_item_identifier,
    "Help",
	"Help make sense of the current item (F1)",
	// @"color_help",
	"icon_info",
	kNCHelpToolbarItemTag,
	1,

	// menu
	opcoders_menu_toolbar_item_identifier,
	"Menu",
	"User menu (F2)",
	// nil,
	"icon_gear",
	kNCMenuToolbarItemTag,
	1,

	// view
	opcoders_view_toolbar_item_identifier,
	"View",
	"View the content of the file (F3)",
	// @"color_view",
	"icon_eye",
	kNCViewToolbarItemTag,
	1,

	// edit
	opcoders_edit_toolbar_item_identifier,
	"Edit",
	"Edit the content of the file (F4)",
	// @"color_edit",   
	"icon_pencil",
	kNCEditToolbarItemTag,
	1,

	// copy
	opcoders_copy_toolbar_item_identifier,
	"Copy",
	"Copy items (F5)",
	// @"color_copy",
	"icon_copy",
	kNCCopyToolbarItemTag,
	1,

	// move
	opcoders_move_toolbar_item_identifier,
	"Move",
	"Move items (F6)",
	// @"color_move",
	"icon_move",
	kNCMoveToolbarItemTag,
	1,

	// mkdir (or mkfile or mklink)
	opcoders_mkdir_toolbar_item_identifier,
	"MkDir",
	"Create a new folder (F7)",
	// @"color_mkdir",
	"icon_create",
	kNCMakeDirToolbarItemTag,
	1,

	// delete
	opcoders_delete_toolbar_item_identifier,
	"Delete",
	"Move items to trash (F8)",
	// @"color_delete",
	"icon_remove",
	kNCDeleteToolbarItemTag,
	1,

	// switch user
	opcoders_switch_user_toolbar_item_identifier,
	"Switch User",
	"Run as a different user",
	nil,
	kNCSwitchUserToolbarItemTag,
	0,
};


@implementation NCToolbar

@synthesize delegate = m_delegate;
@synthesize item6 = m_item6;
@synthesize item7 = m_item7;

-(void)attachToWindow:(NSWindow*)window {
    // create the toolbar object
    NSToolbar* tb = [[[NSToolbar alloc] initWithIdentifier:@"MainWindowToolbar"] autorelease];

    // set initial toolbar properties
    [tb setAllowsUserCustomization:YES];
    [tb setAutosavesConfiguration:YES];
    // [tb setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    [tb setDisplayMode:NSToolbarDisplayModeIconOnly];
	[tb setShowsBaselineSeparator:NO];
	[tb setSizeMode:NSToolbarSizeModeSmall];

    // set our controller as the toolbar delegate
    [tb setDelegate:self];

    // attach the toolbar to our window
    [window setToolbar:tb];
}

-(NSArray*)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:
//		[NSString stringWithUTF8String:opcoders_filter_left_panel_toolbar_item_identifier],
//		[NSString stringWithUTF8String:opcoders_filter_right_panel_toolbar_item_identifier],
		[NSString stringWithUTF8String:opcoders_switch_user_toolbar_item_identifier],
		[NSString stringWithUTF8String:opcoders_help_toolbar_item_identifier],
		[NSString stringWithUTF8String:opcoders_menu_toolbar_item_identifier],
		[NSString stringWithUTF8String:opcoders_view_toolbar_item_identifier],
		[NSString stringWithUTF8String:opcoders_edit_toolbar_item_identifier],
		[NSString stringWithUTF8String:opcoders_copy_toolbar_item_identifier],
		[NSString stringWithUTF8String:opcoders_move_toolbar_item_identifier],
		[NSString stringWithUTF8String:opcoders_mkdir_toolbar_item_identifier],
		[NSString stringWithUTF8String:opcoders_delete_toolbar_item_identifier],
		[NSString stringWithUTF8String:opcoders_reload_toolbar_item_identifier],
        NSToolbarFlexibleSpaceItemIdentifier,
        NSToolbarSpaceItemIdentifier, 
        NSToolbarSeparatorItemIdentifier, 
		nil
	];
}

-(NSArray*)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:
//		[NSString stringWithUTF8String:opcoders_filter_left_panel_toolbar_item_identifier],
		[NSString stringWithUTF8String:opcoders_switch_user_toolbar_item_identifier],
		NSToolbarFlexibleSpaceItemIdentifier,
		[NSString stringWithUTF8String:opcoders_help_toolbar_item_identifier],
		[NSString stringWithUTF8String:opcoders_menu_toolbar_item_identifier],
		[NSString stringWithUTF8String:opcoders_view_toolbar_item_identifier],
		[NSString stringWithUTF8String:opcoders_edit_toolbar_item_identifier],
		[NSString stringWithUTF8String:opcoders_copy_toolbar_item_identifier],
		[NSString stringWithUTF8String:opcoders_move_toolbar_item_identifier],
		[NSString stringWithUTF8String:opcoders_mkdir_toolbar_item_identifier],
		[NSString stringWithUTF8String:opcoders_delete_toolbar_item_identifier],
		 NSToolbarFlexibleSpaceItemIdentifier,
		[NSString stringWithUTF8String:opcoders_reload_toolbar_item_identifier],
//		[NSString stringWithUTF8String:opcoders_filter_right_panel_toolbar_item_identifier],
		nil
	];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)ident
 willBeInsertedIntoToolbar:(BOOL)flag
{
	int n = sizeof(item_descriptors) / sizeof(struct ItemDescriptor);

	int i;
	for(i=0; i<n; i++) {
		const char *c_identifier = item_descriptors[i].identifier;
		NSString* identifier = [NSString stringWithUTF8String:c_identifier];
		if(![ident isEqualTo:identifier]) continue;

		int tag = item_descriptors[i].tag;
		const char* c_tooltip = item_descriptors[i].tooltip;
		const char* c_label = item_descriptors[i].label;
		const char* c_iconname = item_descriptors[i].iconname;
		BOOL is_button = (item_descriptors[i].is_button != 0);

		NSString* tooltip = [NSString stringWithUTF8String:c_tooltip];
		NSString* label = [NSString stringWithUTF8String:c_label];
		
		NSImage* icon = nil;
		if (c_iconname) {
			NSString* iconname = [NSString stringWithUTF8String:c_iconname];
			icon = [NSImage imageNamed:iconname];
		}


	    NSToolbarItem* item = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];
        [item setLabel:label];
        [item setPaletteLabel:label];
        [item setToolTip:tooltip];
		
		if(is_button) {
			NSButton* v = [[[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 40, 25)] autorelease];
			[v setTitle:@""];
			[v setBezelStyle:NSTexturedRoundedBezelStyle];
			[v setImagePosition:NSImageOnly];
	        [v setImage:icon];
	        [v setTarget:self];
	        [v setAction:@selector(toolbarAction:)];
	        [v setTag:tag];
	        [item setTag:tag];
			[item setView:v];
		} else
		if(icon) {
	        [item setImage:icon];
	        [item setTarget:self];
	        [item setAction:@selector(toolbarAction:)];
	        [item setTag:tag];
		}
			
		if(tag == kNCMoveToolbarItemTag) {
			[self setItem6:item];
		} else
		if(tag == kNCMakeDirToolbarItemTag) {
			[self setItem7:item];
		} else
		if(tag == kNCSwitchUserToolbarItemTag) {
			const char* username = getlogin();
			// LOG_DEBUG(@"username: %s", username);

			NSPopUpButton* button = [[[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 0, 200, 24) pullsDown:NO] autorelease];
			NSMenu* menu = [button menu];

			/*
			NICE: obtain the System Preferences Accounts and display them in the top of 
			the switch-user menu, so that it's easy to switch user. The getgrnam() code
			doesn't work and only returns some of my account names. It's supposed to
			return all the names.
			*/
/*			struct group* gr;
			gr = getgrnam("staff");
			if(gr) {
				int i;
				for (i=0; gr->gr_mem[i]!=0; ++i) {
					LOG_DEBUG(@"STAFF MEMBER: %s",gr->gr_mem[i]);
				}
			}
			gr = getgrnam("admin");
			if(gr) {
				int i;
				for (i=0; gr->gr_mem[i]!=0; ++i) {
					LOG_DEBUG(@"ADMIN MEMBER: %s",gr->gr_mem[i]);
				}
			} */

			NSMenuItem* found_mi = nil;
			struct passwd *pw;
			setpwent();
			while ((pw = getpwent())) {
				NSString* title = [NSString stringWithFormat:@"%s | %d", pw->pw_name, pw->pw_uid];
				NSMenuItem* mi = [[[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""] autorelease];
				[mi setTag:pw->pw_uid];
				
				if(strcmp(username, pw->pw_name) == 0) {
					// LOG_DEBUG(@"found a match: %@", mi);
					found_mi = mi;
				}
				
				[menu addItem:mi];
			}
			endpwent();


	        [button setTarget:self];
	        [button setAction:@selector(switchUserAction:)];
			[[button cell] setBezelStyle:NSTexturedRoundedBezelStyle];
			[[button cell] setArrowPosition:NSPopUpArrowAtBottom];
			[[button cell] setFont:[NSFont systemFontOfSize:14]];
			[item setView:button];
			[button selectItem:found_mi];


			/*
			PROBLEM: In Xcode's toolbar the popupbuttons are actually pulldowns. However if I enable pulldowns
			then the popupbutton becomes unusable. When the user tries to select another item then
			nothing happens. So we cannot use pulldowns
			
			HACK: we are not using pulldowns, so the menu doesn't popup the same way as in Xcode, 
			but it's usable and most people won't notice.
			*/
			// [button setPullsDown:YES];
		}
		
		return item;
	}

	return nil;
}

-(IBAction)switchUserAction:(id)sender {
	NSMenuItem* mi = [sender selectedItem];
	int tag = [mi tag];
	// LOG_DEBUG(@"mi: %@  tag: %i", mi, tag);
	id del = m_delegate;
	SEL sel = @selector(switchToUser:);
	if([del respondsToSelector:sel]) {
		NSMethodSignature* sig = [del methodSignatureForSelector:sel];
		NSAssert(sig, @"NSMethodSignature must not be nil");
		NSInvocation* inv = [NSInvocation invocationWithMethodSignature:sig];
		NSAssert(inv, @"NSInvocation must not be nil");
		[inv setSelector:sel];
		[inv setArgument:&tag atIndex:2]; 
		[inv invokeWithTarget:del];
	}
}

-(IBAction)toolbarAction:(id)sender {
	int tag = [sender tag];
	// LOG_DEBUG(@"%i", tag);
	id del = m_delegate;
	SEL sel = @selector(didClickToolbarItem:);
	if([del respondsToSelector:sel]) {
		NSMethodSignature* sig = [del methodSignatureForSelector:sel];
		NSAssert(sig, @"NSMethodSignature must not be nil");
		NSInvocation* inv = [NSInvocation invocationWithMethodSignature:sig];
		NSAssert(inv, @"NSInvocation must not be nil");
		[inv setSelector:sel];
		[inv setArgument:&tag atIndex:2]; 
		[inv invokeWithTarget:del];
	}
}

-(void)update {
	NSUInteger flags = [NSEvent modifierFlags];
	// LOG_DEBUG(@"flags: %i", (int)flags);

	//BOOL is_cmd = ((flags & NSCommandKeyMask) != 0);
	//BOOL is_alt = ((flags & NSAlternateKeyMask) != 0);
	//BOOL is_ctrl = ((flags & NSControlKeyMask) != 0);
	BOOL is_shft = ((flags & NSShiftKeyMask) != 0);
	

	if(is_shft) {
	    // [m_item7 setImage:[NSImage imageNamed:@"color_mkfile"]];
        [m_item7 setLabel:@"MkFile"];
        // [m_item7 setTooltip:@"no tooltip"];
        [m_item7 setTag:kNCMakeFileToolbarItemTag];
	} else {
        // [m_item7 setImage:[NSImage imageNamed:@"color_mkdir"]];
        [m_item7 setLabel:@"MkDir"];
        // [m_item7 setTooltip:@"no tooltip"];
        [m_item7 setTag:kNCMakeDirToolbarItemTag];
	}

	if(is_shft) {
        // [m_item6 setImage:[NSImage imageNamed:@"color_rename"]];
        [m_item6 setLabel:@"Rename"];
        // [m_item6 setTooltip:@"no tooltip"];
        [m_item6 setTag:kNCRenameToolbarItemTag];
	} else {
	    // [m_item6 setImage:[NSImage imageNamed:@"color_move"]];
        [m_item6 setLabel:@"Move"];
        // [m_item6 setTooltip:@"no tooltip"];
        [m_item6 setTag:kNCMoveToolbarItemTag];
	}
}

@end
