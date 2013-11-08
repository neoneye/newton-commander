/*********************************************************************
JFIgnorePrefController.h - ignore list settings

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#import "MBPreferencesController.h"

@interface JFIgnorePrefItem : NSObject {
	NSString* name;
}
@property (copy) NSString* name;
@end


@interface JFIgnorePrefController : NSViewController <MBPreferencesModule> {
	IBOutlet NSArrayController* m_items;
	IBOutlet NSTableView* m_tableview;
}

-(NSString*)title;
-(NSString*)identifier;
-(NSImage*)image;

-(IBAction)addOrRemoveItem:(id)sender;
-(IBAction)autoAddItemsAction:(id)sender;

@end