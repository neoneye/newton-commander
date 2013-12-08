/*
IDEA: rename from NCMakeLinkController to NCCreateItemSheet, where item can be: dir, file, link, file from template
IDEA: merge with NCMakeDirController
IDEA: merge with NCMakeFileController
*/
//
//  NCMakeLinkController.h
//  NCCore
//
//  Created by Simon Strandgaard on 26/04/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NCMakeLinkController : NSWindowController {
	id m_delegate;
	IBOutlet NSTextField* m_link_name_textfield;                         
	IBOutlet NSTextField* m_link_target_textfield;
	NSString* m_working_dir;          
	NSString* m_link_name;          
	NSString* m_link_target;          
}
@property (assign) IBOutlet id delegate;
@property(nonatomic, retain) NSString* workingDir;
@property(nonatomic, retain) NSString* linkName;
@property(nonatomic, retain) NSString* linkTarget;
+(NCMakeLinkController*)shared;

-(void)beginSheetForWindow:(NSWindow*)parentWindow;

-(IBAction)cancelAction:(id)sender;
-(IBAction)submitAction:(id)sender;
-(IBAction)textAction:(id)sender;

@end

@interface NSObject (NCMakeLinkControllerDelegate)
-(void)makeLinkController:(NCMakeLinkController*)ctrl didMakeLink:(NSString*)path;
@end