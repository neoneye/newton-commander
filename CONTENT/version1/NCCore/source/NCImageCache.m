//
//  NCImageCache.m
//  NCCore
//
//  Created by Simon Strandgaard on 25/08/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "NCImageCache.h"


@implementation NCImageCache

@synthesize dict = m_dict;

-(id)init {
    self = [super init];
	if(self == nil) {
		return nil;
	}
	self.dict = [[[NSMutableDictionary alloc] initWithCapacity:500] autorelease];
	return self;
}

-(NSImage*)imageForTag:(int)tag {
	id key = [NSNumber numberWithInt:tag];
	id thing = [m_dict objectForKey:key];
	if(![thing isKindOfClass:[NSImage class]]) {
		return nil;
	}
	return (NSImage*)thing;
}

-(void)setImage:(NSImage*)image forTag:(int)tag {
	id key = [NSNumber numberWithInt:tag];
	if(image) {
		[m_dict setObject:image forKey:key];
	} else {
		[m_dict removeObjectForKey:key];
	}
}

@end
