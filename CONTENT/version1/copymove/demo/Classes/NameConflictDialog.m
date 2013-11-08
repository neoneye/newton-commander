//
//  NameConflictDialog.m
//  demo
//
//  Created by Simon Strandgaard on 12/05/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import "NameConflictDialog.h"
#import "CombinedButtonAndPopUp.h"
#import "NSImage+QuickLook.h"
#import "AppDelegate.h"


@interface NameConflictDialog ()
-(NSURL*)createThumbnailForPath:(NSString*)path tempName:(NSString*)tempName;
@end

@implementation NameConflictDialog

@synthesize destructiveButton = m_destructive_button;
@synthesize nonDestructiveButton = m_non_destructive_button;
@synthesize destructiveMenu = m_destructive_menu;
@synthesize nonDestructiveMenu = m_non_destructive_menu;
@synthesize webView = m_web_view;
@synthesize sourceImageURL = m_source_image_url;
@synthesize targetImageURL = m_target_image_url;

+(NameConflictDialog*)shared {
	static NameConflictDialog* instance = nil;
	if(!instance) {
		instance = [[NameConflictDialog alloc] init];
	}
	return instance;
}

-(id)init {
	if (self = [super initWithWindowNibName:@"NameConflictDialog" owner:self]) {
	}
	return self;
}

-(NSURL*)createThumbnailForPath:(NSString*)path tempName:(NSString*)tempName {
	NSSize size = NSMakeSize(300, 300);
	NSImage* image = [NSImage imageWithPreviewOfFileAtPath:path ofSize:size asIcon:NO];
	
	for(id thing in [image representations]) {
		if(![thing isKindOfClass:[NSBitmapImageRep class]]) {
			continue;
		}
		NSBitmapImageRep* rep = (NSBitmapImageRep*)thing;
		
		AppDelegate* appdel = [[NSApplication sharedApplication] delegate];

		NSString* filename = [appdel.temporaryApplicationDirectory stringByAppendingPathComponent:tempName];
		// NSString* filename = [@"~/Desktop/test.png" stringByExpandingTildeInPath];

		NSData* data = [rep representationUsingType: NSPNGFileType properties: nil];
		BOOL ok = [data writeToFile:filename atomically:NO];
		NSLog(@"%s ok: %i\n%@", _cmd, (int)ok, filename);
		
		return [NSURL fileURLWithPath:filename isDirectory:NO];
	}
	return nil;
}

- (void)windowDidLoad {
	NSLog(@"%s", _cmd);

	{
		NSString* path = @"/Users/neoneye/Desktop/Screen shot 2011-05-08 at 17.02.18.png";
		self.sourceImageURL = [self createThumbnailForPath:path tempName:@"source_image.png"];
	}
	{
		NSString* path = @"/Users/neoneye/Desktop/Screen shot 2011-05-11 at 23.20.18.png";
		self.targetImageURL = [self createThumbnailForPath:path tempName:@"target_image.png"];
	}
	
	{
		[self.destructiveButton installMenu:self.destructiveMenu];
		[self.nonDestructiveButton installMenu:self.nonDestructiveMenu];
	}
	
	{
		[self.destructiveButton setPullsDown:YES];
		[self.nonDestructiveButton setPullsDown:YES];
	}

	{
		self.destructiveButton.action = @selector(destructiveButtonAction:);
		self.destructiveButton.target = self;
		
		self.nonDestructiveButton.action = @selector(nonDestructiveButtonAction:);
		self.nonDestructiveButton.target = self;
	}
	
	{
		// NSString* path = [[NSBundle mainBundle] pathForResource:@"name_conflict" ofType:@"html"]; 
		NSURL* url = [[NSBundle mainBundle] URLForResource:@"name_conflict" withExtension:@"html"]; 
		// NSURL* url = [NSURL fileURLWithPath:path isDirectory:NO];
		// NSURL* url = [NSURL URLWithString:@"http://www.b2knet.com/"];
		
		NSLog(@"%s url: %@", _cmd, url);
		NSURLRequest* req = [NSURLRequest requestWithURL:url];
		[[self.webView mainFrame] loadRequest:req];
	}
}

-(void)destructiveButtonAction:(id)sender {
	NSLog(@"%s", _cmd);
}

-(void)nonDestructiveButtonAction:(id)sender {
	NSLog(@"%s", _cmd);
}

-(void)doSomething:(id)sender {
	NSLog(@"%s", _cmd);
}

-(void)doAnotherThing:(id)sender {
	NSLog(@"%s", _cmd);
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	NSLog(@"%s <-----------------", _cmd);

	{
		NSURL* url = self.sourceImageURL;
		NSString* s = [NSString stringWithFormat:@"set_source_image('%@')", url];
		NSString* res = [self.webView stringByEvaluatingJavaScriptFromString:s];
		NSLog(@"%s set_source_image: %@", _cmd, res);
	}
	{
		NSURL* url = self.targetImageURL;
		NSString* s = [NSString stringWithFormat:@"set_target_image('%@')", url];
		NSString* res = [self.webView stringByEvaluatingJavaScriptFromString:s];
		NSLog(@"%s set_target_image: %@", _cmd, res);
	}

}

@end
