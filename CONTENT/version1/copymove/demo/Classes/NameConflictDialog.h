//
//  NameConflictDialog.h
//  demo
//
//  Created by Simon Strandgaard on 12/05/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>


@class CombinedButtonAndPopUp;

@interface NameConflictDialog : NSWindowController {
	CombinedButtonAndPopUp* m_destructive_button;
	CombinedButtonAndPopUp* m_non_destructive_button;
	NSMenu* m_destructive_menu;
	NSMenu* m_non_destructive_menu;
	WebView* m_web_view;
	
	NSURL* m_source_image_url;
	NSURL* m_target_image_url;
}
@property (nonatomic, retain) IBOutlet CombinedButtonAndPopUp* destructiveButton;
@property (nonatomic, retain) IBOutlet CombinedButtonAndPopUp* nonDestructiveButton;
@property (nonatomic, retain) IBOutlet NSMenu* destructiveMenu;
@property (nonatomic, retain) IBOutlet NSMenu* nonDestructiveMenu;
@property (nonatomic, retain) IBOutlet WebView* webView;
@property (nonatomic, retain) NSURL* sourceImageURL;
@property (nonatomic, retain) NSURL* targetImageURL;

+(NameConflictDialog*)shared;

@end
