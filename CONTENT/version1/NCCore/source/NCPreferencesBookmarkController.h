//
//  NCPreferencesBookmarkController.h
//  NCCore
//
//  Created by Simon Strandgaard on 22/04/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "MBPreferencesController.h"

@interface NCUserDefaultBookmarkItem : NSObject {
	NSString* name;               
	NSString* path;
}
@property (copy) NSString* name;
@property (copy) NSString* path;

+(void)saveDefaultItems:(NSArray*)items;
+(NSArray*)loadDefaultItems;

@end


@interface NCPreferencesBookmarkItem : NSObject {
	NSString* shortcut;
	NSString* name;               
	NSString* path;
}
@property (copy) NSString* shortcut;
@property (copy) NSString* name;
@property (copy) NSString* path;

+(NCPreferencesBookmarkItem*)itemWithPath:(NSString*)path;
+(NCPreferencesBookmarkItem*)itemWithName:(NSString*)name path:(NSString*)path;
@end


@interface NCPreferencesBookmarkController : NSViewController <MBPreferencesModule, NSTableViewDelegate, NSTableViewDataSource> {
	IBOutlet NSArrayController* m_items;
	IBOutlet NSTableView* m_tableview;
}

-(NSString*)identifier;
-(NSImage*)image;

-(IBAction)autoAddBookmarksAction:(id)sender;
-(IBAction)addBookmarkAction:(id)sender;

-(void)loadUserDefaults;

@end
