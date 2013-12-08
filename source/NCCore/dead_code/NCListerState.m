//
//  NCListerState.m
//  NCCore
//
//  Created by Simon Strandgaard on 29/03/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "NCListerState.h"


@implementation NCListerState

@synthesize workingDir = m_working_dir;

-(id)initWithCoder:(NSCoder*)coder {
	NSLog(@"%s NCListerState", _cmd);
	if(self = [super init]) {
        self.workingDir = [coder decodeObjectForKey:@"workingDir"];
		
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder*)coder {
	NSLog(@"%s NCListerState", _cmd);
	[coder encodeObject:[self workingDir] forKey:@"workingDir"];
}



@end
