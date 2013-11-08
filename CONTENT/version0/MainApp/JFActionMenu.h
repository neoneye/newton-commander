/*********************************************************************
JFActionMenu.h - the popup menu accessible within the main window

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/

@interface JFActionMenuItem : NSObject <NSCoding> {
	NSString* name;
	NSString* app;
}
@property (copy) NSString* name;
@property (copy) NSString* app;
@end


@interface JFActionMenu : NSObject {
	id m_delegate;
	NSMutableArray* m_action_items;
	NSMenu* m_menu;
	NSString* m_path;
	NSArray* m_dock_apps;
}
+(JFActionMenu*)shared;
-(void)setDelegate:(id)delegate;

-(void)setActionItems:(NSArray*)items;
-(NSArray*)actionItems;

-(void)buildMenu;
-(NSMenu*)menu;

-(void)setPath:(NSString*)path;

-(void)loadDefaults;
-(void)writeDefaults;
@end


@interface NSObject (JFActionMenu)
-(void)customizeActionMenu;
@end
