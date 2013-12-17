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

@protocol NCToolbarDelegate <NSObject>
-(void)didClickToolbarItem:(int)tag;
-(void)switchToUser:(int)user_id;
@end

@interface NCToolbar : NSObject <NSToolbarDelegate>
@property (nonatomic, weak) NSObject <NCToolbarDelegate> *delegate;
-(void)attachToWindow:(NSWindow*)window;
-(void)update;
@end
