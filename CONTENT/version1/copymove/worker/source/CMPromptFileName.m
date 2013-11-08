//
//  CMPromptFileName.m
//  worker
//
//  Created by Simon Strandgaard on 29/05/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import "CMPromptFileName.h"


@implementation CMPromptFileName

@synthesize sourcePath = m_source_path;
@synthesize targetPath = m_target_path;
@synthesize resolvedName = m_resolved_name;
@synthesize action = m_action;

-(id)init {
	self = [super init];
    if(self) {
		m_action = kCMPromptFileNameActionRetry;
    }
    return self;
}


@end
