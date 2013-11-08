//
//  NCPreferencesMenuController.h
//  NCCore
//
//  Created by Simon Strandgaard on 24/03/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "MBPreferencesController.h"

@interface NCUserDefaultMenuItem : NSObject {
	NSString* name;               
	NSString* path;
}
@property (copy) NSString* name;
@property (copy) NSString* path;

+(void)saveDefaultItems:(NSArray*)items forKey:(NSString*)key;
+(NSArray*)loadDefaultItemsForKey:(NSString*)key;

@end


@interface NCPreferencesMenuItem : NSObject {
	NSString* name;               
	NSString* path;
	NSImage* icon;
}
@property (copy) NSString* name;
@property (copy) NSString* path;
@property (copy) NSImage* icon;
+(NCPreferencesMenuItem*)itemWithPath:(NSString*)path;
@end


@interface NCPreferencesMenuController : NSViewController <MBPreferencesModule, NSTableViewDelegate, NSTableViewDataSource> {
	IBOutlet NSArrayController* m_items;
	IBOutlet NSTableView* m_tableview;
}

-(NSString*)identifier;
-(NSImage*)image;

-(IBAction)autoAddApplicationsAction:(id)sender;
-(IBAction)addApplicationAction:(id)sender;

-(NSString*)userDefaultIdentifier;

@end


@interface NCPreferencesLeftMenuController : NCPreferencesMenuController {
}
+(NSArray*)loadDefaultItems;
@end

@interface NCPreferencesRightMenuController : NCPreferencesMenuController {
}
+(NSArray*)loadDefaultItems;
@end

