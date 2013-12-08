//
//  NSImage+BundleExtensions.m
//  NCCore
//
//  Created by Simon Strandgaard on 07/05/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "NCLog.h"
#import "NSImage+ImageNamedForClass.h"


@implementation NSImage (NCImageNamedForClass)

+(NSImage*)imageNamed:(NSString*)name forClass:(Class)aClass {
	NSBundle* our_bundle = [NSBundle bundleForClass:aClass];
	if(!our_bundle) {
		LOG_WARNING(@"ERROR: imageFromName, cannot find our bundle");
		return nil;
	}
	
	NSString* path = [our_bundle pathForImageResource:name];
	if(!path) {
		LOG_WARNING(@"ERROR: imageFromName, cannot obtain path for %@", name);
		return nil;
	}
	
	NSImage* image = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
	if(!image) {
		LOG_WARNING(@"ERROR: imageFromName, cannot obtain image at path %@", path);
		return nil;
	}
	
	return image;
}

@end
