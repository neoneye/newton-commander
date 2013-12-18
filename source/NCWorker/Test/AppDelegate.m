//
// AppDelegate.m
// Newton Commander
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "AppDelegate.h"
#import "NCWorker.h"

@interface AppDelegate () <NSApplicationDelegate, NCWorkerController>

@property (weak) IBOutlet NSWindow *window;
@property (unsafe_unretained) IBOutlet NSTextView* textview;
@property (nonatomic, strong) NCWorker* worker;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

	self.worker = [[NCWorker alloc] initWithController:self label:@"left_panel"];
	
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
	[self.worker request:dict];
}

-(void)request2 {
	NSLog(@"request2");
	NSArray* keys = [NSArray arrayWithObjects:@"operation", @"path", nil];
	// NSArray* objects = [NSArray arrayWithObjects:@"list", @"/.fseventsd", nil];
	NSArray* objects = [NSArray arrayWithObjects:@"list", @"/Volumes", nil];
	NSDictionary* dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	
	NSString* s = [NSString stringWithFormat:@"REQUEST\n%@\n\n", dict];
	[self append:s];
	[self.worker request:dict];
}

-(void)worker:(NCWorker*)worker response:(NSDictionary*)dict {
	NSLog(@"%@ %@", NSStringFromSelector(_cmd), dict);
	
	NSString* s = [NSString stringWithFormat:@"RESPONSE\n%@\n\n", dict];
	[self append:s];
}

-(void)append:(NSString*)s {
	NSAttributedString* as = [[NSAttributedString alloc] initWithString:s];
	NSTextStorage* storage = [self.textview textStorage];
	[storage beginEditing];
	[storage appendAttributedString:as];
	[storage endEditing];
}

@end
