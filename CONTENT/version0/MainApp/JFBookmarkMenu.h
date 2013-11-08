/*********************************************************************
JFBookmarkMenu.h - the dropdown menu accessible from the main menu

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/

@interface JFBookmarkMenuItem : NSObject <NSCoding> {
	NSString* name;
	NSString* path;
}
@property (copy) NSString* name;
@property (copy) NSString* path;
@end


@interface JFBookmarkMenu : NSObject {
	id m_delegate;
	NSMutableArray* m_items;
	NSMenu* m_menu;
}
+(JFBookmarkMenu*)shared;

-(void)setMenu:(NSMenu*)menu;
-(void)populateWithDummyData;
-(void)setDelegate:(id)delegate;

-(void)setBookmarkItems:(NSArray*)items;

-(void)rebuildMenu;

-(NSArray*)bookmarkItems;

-(void)loadDefaults;
-(void)writeDefaults;
@end


@interface NSObject (JFBookmarkMenu)
-(void)jumpToBookmarkPath:(NSString*)path;
-(void)customizeBookmarkMenu;
@end
