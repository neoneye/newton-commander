//
//  CMPromptDirectoryName.m
//  worker
//
//  Created by Simon Strandgaard on 02/06/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import "CMPromptDirectoryName.h"


@implementation CMPromptDirectoryName

@synthesize sourcePath = m_source_path;
@synthesize targetPath = m_target_path;
@synthesize resolvedName = m_resolved_name;
@synthesize action = m_action;

-(id)init {
	self = [super init];
    if(self) {
		m_action = kCMPromptDirectoryNameActionRetry;
    }
    return self;
}


@end
