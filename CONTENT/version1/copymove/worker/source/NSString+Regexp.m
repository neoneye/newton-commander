//
//  NSString+Regexp.m
//  worker
//
//  Created by Simon Strandgaard on 02/06/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import "NSString+Regexp.h"
#import "OnigRegexp.h"


@implementation NSString (Regexp)

-(BOOL)compareToRegexpArray:(NSArray*)anArray {
	if(![anArray isKindOfClass:[NSArray class]]) { return NO; }
	
	for(id thing in anArray) {
		if(![thing isKindOfClass:[OnigRegexp class]]) {
			continue;
		}
		OnigRegexp* regexp = (OnigRegexp*)thing;
		OnigResult* r = [regexp search:self];
		if(r) {
			return YES;
		}
	}
	return NO;
}

@end
