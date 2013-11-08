//
//  AppDelegate.h
//  Kill
//
//  Created by Simon Strandgaard on 04/06/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WorkerParent.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, WorkerParentDelegate> {
    NSWindow *m_window;
	NSTextView *m_status_textview;
	NSTextView *m_log_textview;
	NSPopUpButton *m_switch_user_popupbutton;
	WorkerParent *m_worker_parent;
}

@property (nonatomic, assign) IBOutlet NSWindow *window;
@property (nonatomic, assign) IBOutlet NSTextView *statusTextView;
@property (nonatomic, assign) IBOutlet NSTextView *logTextView;
@property (nonatomic, assign) IBOutlet NSPopUpButton *switchUserPopUpButton;
@property (nonatomic, retain) WorkerParent *workerParent;

-(IBAction)switchUserAction:(id)sender;

-(IBAction)killParentAction:(id)sender;

-(IBAction)sigkillChildAction:(id)sender;
-(IBAction)sigtermChildAction:(id)sender;
-(IBAction)sigintChildAction:(id)sender;

-(IBAction)restartAction:(id)sender;

-(IBAction)exitFailureChildAction:(id)sender;
-(IBAction)exitSuccessChildAction:(id)sender;
-(IBAction)exceptionChildAction:(id)sender;
-(IBAction)abortChildAction:(id)sender;

-(IBAction)pingAction:(id)sender;
-(IBAction)unknownAction:(id)sender;
-(IBAction)test1Action:(id)sender;
-(IBAction)test2Action:(id)sender;

@end
