//
//  NCListerTableView.h
//  NCCore
//
//  Created by Simon Strandgaard on 03/02/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NCLister;
@class NCListerTableView;


@protocol NCListerTableViewDelegate <NSObject>
-(void)tableView:(NCListerTableView*)tableview markRow:(int)row;
-(void)tabKeyPressed:(id)sender;
-(void)switchToNextTab:(id)sender;
-(void)switchToPrevTab:(id)sender;
-(void)closeTab:(id)sender;
-(void)activateTableView:(id)sender;
-(BOOL)isActiveTableView;
-(void)showLeftContextMenu:(id)sender;
-(void)showRightContextMenu:(id)sender;
@end

@interface NCListerTableView : NSTableView {
	NCLister* m_lister;

	// theming
	NSColor* m_background_color;

	NSColor* m_first_row_background_color;
	NSColor* m_first_row_background_inactive_color;

	NSColor* m_even_row_background_color;
	NSColor* m_even_row_background_inactive_color;

	NSColor* m_odd_row_background_color;
	NSColor* m_odd_row_background_inactive_color;

	NSColor* m_selected_row_background_color;
	NSColor* m_selected_row_background_inactive_color;

	NSColor* m_cursor_row_background_color;
	NSColor* m_cursor_row_background_inactive_color;

}
@property (strong) NCLister* lister;

@property (strong) NSColor* backgroundColor;
@property (strong) NSColor* firstRowBackgroundColor;
@property (strong) NSColor* firstRowBackgroundInactiveColor;
@property (strong) NSColor* evenRowBackgroundColor;
@property (strong) NSColor* evenRowBackgroundInactiveColor;
@property (strong) NSColor* oddRowBackgroundColor;
@property (strong) NSColor* oddRowBackgroundInactiveColor;
@property (strong) NSColor* selectedRowBackgroundColor;
@property (strong) NSColor* selectedRowBackgroundInactiveColor;
@property (strong) NSColor* cursorRowBackgroundColor;
@property (strong) NSColor* cursorRowBackgroundInactiveColor;


-(id)initWithFrame:(NSRect)frame lister:(NCLister*)lister;

-(void)adjustThemeForDictionary:(NSDictionary*)dict;
+(NSDictionary*)whiteTheme;     
+(NSDictionary*)grayTheme;
+(NSDictionary*)blackTheme;


@end

