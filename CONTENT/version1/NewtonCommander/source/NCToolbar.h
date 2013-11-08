//
//  NCToolbar.h
//  NewtonCommander
//
//  Created by Simon Strandgaard on 10/03/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum {
	kNCHelpToolbarItemTag = 100,
	kNCMenuToolbarItemTag = 200,
	kNCViewToolbarItemTag = 300,
	kNCEditToolbarItemTag = 400,
	kNCCopyToolbarItemTag = 500,
	kNCMoveToolbarItemTag = 600,
	kNCRenameToolbarItemTag = 601,
	kNCMakeDirToolbarItemTag = 700,
	kNCMakeFileToolbarItemTag = 701,
	kNCDeleteToolbarItemTag = 800,
	kNCReloadToolbarItemTag = 1200,    
	kNCSwitchUserToolbarItemTag = 1300,
};

@interface NCToolbar : NSObject <NSToolbarDelegate> {
	id m_delegate;
	NSToolbarItem* m_item6;
	NSToolbarItem* m_item7;
}
@property (nonatomic,assign) IBOutlet id delegate;
@property (retain) NSToolbarItem* item6;
@property (retain) NSToolbarItem* item7;


@end

@interface NSObject (NCToolbarDelegate)

-(void)attachToWindow:(NSWindow*)window;

-(void)didClickToolbarItem:(int)tag;

-(void)switchToUser:(int)user_id;

-(void)update;
@end
