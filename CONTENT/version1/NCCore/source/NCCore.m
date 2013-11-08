//
//  NCCore.m
//  NCCore
//
//  Created by Simon Strandgaard on 24/01/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "NCCore.h"

@implementation NCCore
-(NSArray *)libraryNibNames {
    return [NSArray arrayWithObject:@"NCCoreLibrary"];
}

-(NSArray *)requiredFrameworks {
    return [NSArray arrayWithObjects:[NSBundle bundleWithIdentifier:@"com.opcoders.NCCoreFramework"], nil];
}

-(NSString *)label {
	return @"NCCore";
}

@end
