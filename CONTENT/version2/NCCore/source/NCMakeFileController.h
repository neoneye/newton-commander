/*
IDEA: rename from NCMakeFileController to NCCreateItemSheet, where item can be: dir, file, link, file from template
IDEA: merge with NCMakeDirController
IDEA: merge with NCMakeLinkController
*/
//
//  NCMakeFileController.h
//  NCCore
//
//  Created by Simon Strandgaard on 24/04/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NCMakeFileController : NSWindowController {
	id m_delegate;
	IBOutlet NSTextField* m_textfield;
	NSString* m_working_dir;
	NSString* m_suggest_name;          
}
@property (assign) IBOutlet id delegate;
@property(nonatomic, retain) NSString* suggestName;
@property(nonatomic, retain) NSString* workingDir;
+(NCMakeFileController*)shared;

-(void)beginSheetForWindow:(NSWindow*)parentWindow;

-(IBAction)cancelAction:(id)sender;
-(IBAction)submitAction:(id)sender;
-(IBAction)textAction:(id)sender;

@end

@interface NSObject (NCMakeFileControllerDelegate)
-(void)makeFileController:(NCMakeFileController*)ctrl didMakeFile:(NSString*)path;
@end