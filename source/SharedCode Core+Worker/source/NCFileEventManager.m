//
//  NCFileEventManager.m
//  NCCore
//
//  Created by Simon Strandgaard on 24/04/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

/*
http://developer.apple.com/mac/articles/cocoa/filesystemevents.html

http://developer.apple.com/mac/library/documentation/Darwin/Reference/FSEvents_Ref/FSEvents_h/index.html#//apple_ref/c/func/FSEventStreamCreate

http://developer.apple.com/mac/library/documentation/Darwin/Reference/FSEvents_Ref/FSEvents_h/index.html#//apple_ref/c/tdef/FSEventStreamCallback
*/

#import "NCLog.h"
#import "NCFileEventManager.h"
#include <CoreServices/CoreServices.h>

struct NCFileEventManagerPrivate {
	FSEventStreamRef stream;
    FSEventStreamContext context;
};


/*

FSEventStreamEventFlags
enum { 
    kFSEventStreamEventFlagNone = 0x00000000, 
    kFSEventStreamEventFlagMustScanSubDirs = 0x00000001, 
    kFSEventStreamEventFlagUserDropped = 0x00000002, 
    kFSEventStreamEventFlagKernelDropped = 0x00000004, 
    kFSEventStreamEventFlagEventIdsWrapped = 0x00000008, 
    kFSEventStreamEventFlagHistoryDone = 0x00000010, 
    kFSEventStreamEventFlagRootChanged = 0x00000020, 
    kFSEventStreamEventFlagMount = 0x00000040, 
    kFSEventStreamEventFlagUnmount = 0x00000080 
};

*/
static void NCFileEventManager__Callback(ConstFSEventStreamRef streamRef, void *clientCallBackInfo, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]) {
	NCFileEventManager* fem = (__bridge NCFileEventManager*)clientCallBackInfo;
	NSDate *time = [NSDate date]; /* it..doesnt..tell..us..when.. ugh! */
	NSMutableArray* result = [NSMutableArray array];
	char **paths = eventPaths;
	int i;
	for (i = 0; i < numEvents; i++) {
		[result addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithUnsignedLongLong:eventIds[i]], @"id",
			[NSString stringWithUTF8String:paths[i]], @"path",
			[NSString stringWithFormat:@"%04x",(unsigned int)eventFlags[i]] , @"flag",
			time , @"time",
			NULL]];
	}

    dispatch_async(dispatch_get_main_queue(), ^{
		[fem notify:result];
	});
}



@implementation NCFileEventManager

-(id)init {
	// NSLog(@"%s NCFileEventManager", _cmd);
	if ((self = [super init]) != nil) {
		m_private = (struct NCFileEventManagerPrivate*)malloc(sizeof(NCFileEventManagerPrivate));
		m_paths_to_watch = nil;
		m_is_running = NO;
		m_delegate = nil;
	}
	return self;
}

-(void)dealloc {
	[self stop];
	
	if(m_private != NULL) {
		free(m_private);
		m_private = NULL;
	}
	[self setPathsToWatch:nil];
}

-(void)setDelegate:(NSObject <NCFileEventManagerDelegate> *)delegate {
	m_delegate = delegate;
}


-(void)start {
	if(!m_private) return;
	if(m_is_running) return;
	if(m_paths_to_watch == nil) return;
	if([m_paths_to_watch count] < 1) return;
	
	NSArray *paths_to_watch = m_paths_to_watch;
    
    m_private->context.info = (__bridge void*)self;
    m_private->context.version = 0;
    m_private->context.copyDescription = NULL;
    m_private->context.release = NULL;
    m_private->context.retain = NULL;

	FSEventStreamCreateFlags flags = kFSEventStreamCreateFlagNone;
	// flags |= kFSEventStreamCreateFlagIgnoreSelf;
	// flags |= kFSEventStreamCreateFlagNoDefer;
	
	CFTimeInterval interval = 1.0;

    m_private->stream = FSEventStreamCreate(
		NULL,
        &NCFileEventManager__Callback,
        &m_private->context,
        (__bridge CFArrayRef)paths_to_watch,
        kFSEventStreamEventIdSinceNow,
        interval,
		flags
    );
    
    FSEventStreamScheduleWithRunLoop(
		m_private->stream, 
		CFRunLoopGetCurrent(), 
		kCFRunLoopDefaultMode
	);

	FSEventStreamStart(m_private->stream);

	m_is_running = YES;
}

-(void)stop {
	if(!m_private) return;
	if(!m_is_running) return;

	FSEventStreamStop(m_private->stream);
    FSEventStreamInvalidate(m_private->stream);
    FSEventStreamRelease(m_private->stream);

	m_is_running = NO;
}

-(void)notify:(NSArray*)ary {
	// LOG_DEBUG(@"called: %@", ary);
	if ([m_delegate respondsToSelector:@selector(fileEventManager:changeOccured:)]) {
		[m_delegate fileEventManager:self changeOccured:ary];
	}
}

-(void)setPathsToWatch:(NSArray*)paths {
	// LOG_DEBUG(@"called: %@", paths);
	
	BOOL was_running = m_is_running;
	[self stop];
	
	m_paths_to_watch = paths;

	if(was_running) [self start];
}

@end
