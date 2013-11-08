/*********************************************************************
JFActionPrefController.h - UI allowing you to customize the action menu

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#import "MBPreferencesController.h"

@interface JFActionPrefItem : NSObject {
	NSString* name;               
	NSString* path;
	NSImage* icon;
}
@property (copy) NSString* name;
@property (copy) NSString* path;
@property (copy) NSImage* icon;
@end


@interface JFActionPrefController : NSViewController <MBPreferencesModule> {
	IBOutlet NSArrayController* m_action_items;
	IBOutlet NSTableView* m_tableview;
}

-(NSString*)title;
-(NSString*)identifier;
-(NSImage*)image;

-(IBAction)addOrRemoveAction:(id)sender;
-(IBAction)autoAddApplicationsAction:(id)sender;

@end