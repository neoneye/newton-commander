//
//  WorkerCommand.m
//  Kill
//
//  Created by Simon Strandgaard on 05/06/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import "WorkerCommand.h"


@interface WorkerCommandBlock : WorkerCommand {
	WorkerDictionaryBlock m_block;
}
-(void)setBlock:(WorkerDictionaryBlock)aBlock;
@end

@implementation WorkerCommandBlock
-(void)setBlock:(WorkerDictionaryBlock)aBlock {
	[m_block release];
	m_block = [aBlock copy];
}

-(void)run:(NSDictionary*)aDictionary {
	if(m_block) {
		m_block(aDictionary);
	}
}
@end


@implementation WorkerCommand
+(WorkerCommand*)commandWithBlock:(WorkerDictionaryBlock)aBlock {
	WorkerCommandBlock* command = [[[WorkerCommandBlock alloc] init] autorelease];
	[command setBlock:aBlock];
	return command;
}

-(void)run:(NSDictionary*)aDictionary {
	// do nothing
}
@end


