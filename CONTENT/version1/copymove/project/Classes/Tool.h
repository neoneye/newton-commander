//
//  Tool.h
//  project
//
//  Created by Simon Strandgaard on 23/04/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ExpectResult;

@interface Tool : NSObject {
	NSTask* m_task;
	NSFileHandle* m_read_handle;
	NSFileHandle* m_write_handle;
}

@property (nonatomic, retain) NSTask* task;
@property (nonatomic, retain) NSFileHandle* readHandle;
@property (nonatomic, retain) NSFileHandle* writeHandle;

-(void)start;
-(void)stop;

-(ExpectResult*)expect:(NSString*)pattern;

-(void)write:(NSString*)s;

@end
