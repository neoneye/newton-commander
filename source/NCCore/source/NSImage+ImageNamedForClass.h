//
//  NSImage+BundleExtensions.h
//  NCCore
//
//  Created by Simon Strandgaard on 07/05/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSImage (NCImageNamedForClass)

+(NSImage*)imageNamed:(NSString*)name forClass:(Class)aClass;

@end
