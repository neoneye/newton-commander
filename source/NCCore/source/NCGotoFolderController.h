//
//  NCGotoFolderController.h
//  NCCore
//
//  Created by Simon Strandgaard on 23/05/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NCGotoFolderController : NSWindowController {
	id __unsafe_unretained m_delegate;
	NSTextField* __weak m_textfield;
}
@property (unsafe_unretained) IBOutlet id delegate;
@property (weak) IBOutlet NSTextField* textfield;
+(NCGotoFolderController*)shared;

-(void)beginSheetForWindow:(NSWindow*)window;

-(IBAction)cancelAction:(id)sender;
-(IBAction)submitAction:(id)sender;

@end

@interface NSObject (NCGotoFolderControllerDelegate)

/*
return YES if the dir was changed successful, so that the sheet can be closed
return NO if the dir couldn't be changed, in which case we don't want to close the sheet
*/
-(BOOL)makeGotoFolderController:(NCGotoFolderController*)ctrl gotoFolder:(NSString*)path;
@end