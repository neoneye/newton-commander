//
//  NCListerTableView.h
//  NCCore
//
//  Created by Simon Strandgaard on 03/02/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NCLister;

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
@property (retain) NCLister* lister;

@property (retain) NSColor* backgroundColor;
@property (retain) NSColor* firstRowBackgroundColor;
@property (retain) NSColor* firstRowBackgroundInactiveColor;
@property (retain) NSColor* evenRowBackgroundColor;
@property (retain) NSColor* evenRowBackgroundInactiveColor;
@property (retain) NSColor* oddRowBackgroundColor;
@property (retain) NSColor* oddRowBackgroundInactiveColor;
@property (retain) NSColor* selectedRowBackgroundColor;
@property (retain) NSColor* selectedRowBackgroundInactiveColor;
@property (retain) NSColor* cursorRowBackgroundColor;
@property (retain) NSColor* cursorRowBackgroundInactiveColor;


-(id)initWithFrame:(NSRect)frame lister:(NCLister*)lister;

-(void)adjustThemeForDictionary:(NSDictionary*)dict;
+(NSDictionary*)whiteTheme;     
+(NSDictionary*)grayTheme;
+(NSDictionary*)blackTheme;


@end

@interface NSObject (NCListerTableViewDelegate)
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