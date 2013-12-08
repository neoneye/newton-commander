//
//  NCWorkerAppDelegate.m
//  NCWorker
//
//  Created by Simon Strandgaard on 30/05/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window;
@synthesize textview;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

	m_worker = [[NCWorker alloc] initWithController:self label:@"left_panel"];
	
	[self request1];
	[self performSelector: @selector(request2) withObject: nil afterDelay: 1.5f];
}

-(void)request1 {
	NSLog(@"request1");
	NSArray* keys = [NSArray arrayWithObjects:@"operation", @"path", nil];
	NSArray* objects = [NSArray arrayWithObjects:@"list", @"/", nil];
	NSDictionary* dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	
	NSString* s = [NSString stringWithFormat:@"REQUEST\n%@\n\n", dict];
	[self append:s];
	[m_worker request:dict];
}

-(void)request2 {
	NSLog(@"request2");
	NSArray* keys = [NSArray arrayWithObjects:@"operation", @"path", nil];
	// NSArray* objects = [NSArray arrayWithObjects:@"list", @"/.fseventsd", nil];
	NSArray* objects = [NSArray arrayWithObjects:@"list", @"/Volumes", nil];
	NSDictionary* dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	
	NSString* s = [NSString stringWithFormat:@"REQUEST\n%@\n\n", dict];
	[self append:s];
	[m_worker request:dict];
}

-(void)worker:(NCWorker*)worker response:(NSDictionary*)dict {
	NSLog(@"%@ %@", NSStringFromSelector(_cmd), dict);
	
	NSString* s = [NSString stringWithFormat:@"RESPONSE\n%@\n\n", dict];
	[self append:s];
}

-(void)append:(NSString*)s {
	NSAttributedString* as = [[NSAttributedString alloc] initWithString:s];
	NSTextStorage* storage = [textview textStorage];
	[storage beginEditing];
	[storage appendAttributedString:as];
	[storage endEditing];
}

@end
