//
//  NCInfoView.m
//  NCCore
//
//  Created by Simon Strandgaard on 22/06/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NCLog.h"
#import "NCInfoView.h"

@implementation NCInfoObject

@synthesize name, orientation, x, y;

- (id)init
{
	if (![super init])	return nil;
	
	name		= @"Sample";
	orientation = @"landscape";
	x = 1111;
	y = 4444;
	
	return	self;
}

@end


@interface NCInfoView (Private)
-(void)setupStuff;
-(void)testBinding:(id)sender;
@end

@implementation NCInfoView

@synthesize filename, angle;

-(void)setupStuff {

	m_info = [[NCInfoObject alloc] init];
	m_controller = [[NSObjectController alloc] initWithContent:m_info];

	LOG_DEBUG(@"info: %@", m_info);
	LOG_DEBUG(@"controller: %@", m_controller);

	[self bind:@"filename" toObject:m_controller withKeyPath:@"selection.name" options:nil];
	[self bind:@"angle" toObject:m_controller withKeyPath:@"selection.x" options:nil];


	[self performSelector:@selector(testBinding:) withObject:nil afterDelay:1];

}

-(void)testBinding:(id)sender {
	// m_info.x = 666;
	// [m_info setX:666];
	[m_info setX:100001];
	[m_info setName:@"Hello World"];
}

- (void)awakeFromNib
{
	filename = @"some file name";
	
	NSBundle* our_bundle = [NSBundle bundleForClass:[self class]];
	if(!our_bundle) {
		LOG_ERROR(@"ERROR: infoview, cannot find our bundle");
		return;
	}
	
	NSString* path = [our_bundle pathForResource:@"test" ofType:@"html"];
	if(!path) {
		LOG_ERROR(@"ERROR: infoview, cannot obtain path for resource");
		return;
	}

	LOG_DEBUG(@"%s : html file was found", object_getClassName(self));

	NSURL* url = [NSURL fileURLWithPath:path];
	
	// We'll be our own frame load delegate and receive didFinishLoadForFrame
	[self setFrameLoadDelegate:self];
	[[self mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
	
	// Binding storage
	// in Ruby this would be a hash[bindingName] = { object => ..., keyPath => ... }
	bindingNames = [[NSMutableArray alloc] init];
	bindingObservedObjects = [[NSMutableArray alloc] init];
	bindingObservedKeyPaths = [[NSMutableArray alloc] init];
	
	
	[self setupStuff];
}

////////////////////////////////////////////////////////////////
//
//	Bindings and Key Value Observing
//	http://developer.apple.com/documentation/Cocoa/Conceptual/CocoaBindings/Concepts/HowDoBindingsWork.html	
//	http://homepage.mac.com/mmalc/CocoaExamples/controllers.html (GraphicsBindings)
//
//////////////////////////////////////////////////////////////////

//
//	Bind
//		record what we're being bound to, and observe its changes
//
- (void)bind:(NSString *)binding toObject:(id)observable withKeyPath:(NSString *)keyPath options:(NSDictionary *)options
{
	// What we're bound to
	[bindingNames addObject:[[NSString alloc] initWithString:binding]];
	[bindingObservedObjects addObject:observable];
	[bindingObservedKeyPaths addObject:[[NSString alloc] initWithString:keyPath]];
	
	// Observe binding source
    [observable addObserver:self                  
				forKeyPath:keyPath
				options:0
				context:nil];
				
	// Dispatch first notification
	[self observeValueForKeyPath:keyPath ofObject:observable change:nil context:nil];				
}

//
//	Key Value Observing : any object observed will trigger a call here
//
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	// Get key index
	NSUInteger i;
	int idx = -1;
	for (i=0; i<[bindingObservedKeyPaths count]; i++)
	{
		NSString* bindingKeyPath = [bindingObservedKeyPaths objectAtIndex:i];
		if ([bindingKeyPath isEqualToString:keyPath])
		{
			idx = i;
			break;
		}
	}
	
	// If we don't know that key, bail
	if (idx == -1)
	{
		LOG_ERROR(@"Unknow key %@ in %s.observeValueForKeyPath", keyPath, object_getClassName(self));
		return;
	}
	
	// Dispatch new value to Javascript
	NSString* bindingName		= [bindingNames objectAtIndex:idx];
	id observedObject			= [bindingObservedObjects objectAtIndex:idx];
	id newValue					= [observedObject valueForKeyPath:keyPath];
//	LOG_DEBUG(@"New value %@ %s  %@", keyPath, object_getClassName(object), bindingName);
	[self setValue:newValue forKey:bindingName];
	[[self windowScriptObject] callWebScriptMethod:@"WebViewControl_valueChanged" withArguments:[NSArray arrayWithObjects: bindingName, nil]];
}


- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
//	NSLog(@"LOAD");
}


//
//	Javascript is available
//		Register our custom javascript object in the hosted page
//
- (void)webView:(WebView *)webView windowScriptObjectAvailable:(WebScriptObject *)windowScriptObject
{
	// Register ourselves as window['WebViewControl']
	[windowScriptObject setValue:self forKey:@"WebViewControl"];
}

//
//	Access restriction
//		Choose what methods and properties our ObjC object will expose to Javascript.
//		
+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector {
	return NO;
}
+ (BOOL)isKeyExcludedFromWebScript:(const char *)property {
	return NO;
}

//
//	(called from Javascript) 
///	Setting a new value : 
//		new value is dispatched to binding source
//
- (void)setNewValue:(id)newValue forKey:(NSString*)key
{
	// Get key index
	NSUInteger i;
	int idx = -1;
	for (i=0; i<[bindingNames count]; i++)
	{
		NSString* bindingName = [bindingNames objectAtIndex:i];
		if ([bindingName isEqualToString:key])
		{
			idx = i;
			break;
		}
	}
	// If we don't know that key, bail
	if (idx == -1)
	{
		LOG_ERROR(@"Unknow key %@ in %s.setNewValue", key, object_getClassName(self));
		return;
	}
	

	LOG_DEBUG(@"%s.setNewValue: %@  forKey: %@", object_getClassName(self), newValue, key);

	// Retrieve observed object and keyPath thanks to key
	id observedObject			= [bindingObservedObjects objectAtIndex:idx];
	NSString* observedKeyPath	= [bindingObservedKeyPaths objectAtIndex:idx];
	// Dispatch new value to binding source
	[observedObject setValue:newValue forKeyPath:observedKeyPath];
}

//
//	Don't draw background
//
- (BOOL)drawsBackground
{
	return	NO;
}

@end
