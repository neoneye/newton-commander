/*********************************************************************
JFBookmarkPrefController.h - bookmark settings

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#import "MBPreferencesController.h"

@interface JFBookmarkPrefItem : NSObject {
	NSString* shortcut;
	NSString* name;               
	NSString* path;
}
@property (copy) NSString* shortcut;
@property (copy) NSString* name;
@property (copy) NSString* path;
@end


@interface JFBookmarkPrefController : NSViewController <MBPreferencesModule> {
	IBOutlet NSArrayController* m_bookmark_items;
	IBOutlet NSTableView* m_tableview;
}

-(NSString*)title;
-(NSString*)identifier;
-(NSImage*)image;

-(IBAction)addOrRemoveBookmark:(id)sender;
-(IBAction)autoAddBookmarksAction:(id)sender;

@end