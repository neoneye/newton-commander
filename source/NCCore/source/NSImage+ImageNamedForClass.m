//
//  NSImage+BundleExtensions.m
//  NCCore
//
//  Created by Simon Strandgaard on 07/05/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


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
	
	NSImage* image = [[NSImage alloc] initWithContentsOfFile:path];
	if(!image) {
		LOG_WARNING(@"ERROR: imageFromName, cannot obtain image at path %@", path);
		return nil;
	}
	
	return image;
}

@end
