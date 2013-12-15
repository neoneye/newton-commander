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
	id __unsafe_unretained m_delegate;
	IBOutlet NSTextField* m_textfield;
	NSString* m_working_dir;
	NSString* m_suggest_name;          
}
@property (unsafe_unretained) IBOutlet id delegate;
@property(nonatomic, strong) NSString* suggestName;
@property(nonatomic, strong) NSString* workingDir;
+(NCMakeFileController*)shared;

-(void)beginSheetForWindow:(NSWindow*)parentWindow;

-(IBAction)cancelAction:(id)sender;
-(IBAction)submitAction:(id)sender;
-(IBAction)textAction:(id)sender;

@end

@interface NSObject (NCMakeFileControllerDelegate)
-(void)makeFileController:(NCMakeFileController*)ctrl didMakeFile:(NSString*)path;
@end