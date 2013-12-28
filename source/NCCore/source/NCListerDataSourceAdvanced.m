//
//  NCListerDataSourceAdvanced.m
//  NCCore
//
//  Created by Simon Strandgaard on 10/07/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

/*
IDEA: I need a better name than NCListerDataSourceAdvanced... some ideas:
 1. NCFileSystemProxy
 2. NCWorkerBridge
 3. NCWorkerProxy
 4. NCWorkerAdaptor
 5. NCWorkerWrapper
 6. NCWorkerProxy

*/

#import "NCLog.h"
#import "NCListerDataSourceAdvanced.h"
#import "NCListerItem.h"
#import "NCFileItem.h"
#import "NCFileManager.h"
#import "NCTimeProfiler.h"
#import "FPOCsvWriter.h"


@interface NCListerDataSourceAdvanced (Private)
-(void)setItems:(NSArray*)items;
-(void)setResolvedWorkingDir:(NSString*)path;
-(void)workerResponseCopy:(NSDictionary*)dict;
-(void)workerResponseMove:(NSDictionary*)dict;
-(void)workerResponseList:(NSDictionary*)dict;
-(void)workerResponseMonitor:(NSDictionary*)dict;
@end

@implementation NCListerDataSourceAdvanced

@synthesize worker = m_worker;

- (id)init {
    if(self = [super init]) {
		m_working_dir = nil;
		m_resolved_working_dir = nil;
		m_items = nil;
		m_profiler = [[NCTimeProfilerSetWorkingDir alloc] init];
		m_worker = [[NCWorker alloc] initWithController:self label:@"TODO_insert_label_here"];
		
		m_copy_operation_names = nil;
		m_copy_operation_source_dir = nil;
		m_copy_operation_target_dir = nil;
	}
	return self;
}

- (void)dealloc {
	m_working_dir = nil;
	
	m_resolved_working_dir = nil;
	
	m_items = nil;

	m_profiler = nil;


	[self setCopyOperationNames:nil];
	[self setCopyOperationSourceDir:nil];
	[self setCopyOperationTargetDir:nil];

}


-(void)setWorkingDir:(NSString*)path {
	if(m_working_dir != path) {
		m_working_dir = [path copy];
	}
}

-(void)setResolvedWorkingDir:(NSString*)path {
	if(m_resolved_working_dir != path) {
		m_resolved_working_dir = [path copy];
	}
}

-(void)setItems:(NSArray*)items {
	if(m_items != items) {
		m_items = [items copy];
	}
}

-(void)switchToUser:(int)user_id {
	// LOG_DEBUG(@"switch to user: %i", user_id);
	[m_worker setUid:user_id];
	[m_worker restart];
}

#pragma mark -
#pragma mark Do something based on the response

-(void)worker:(NCWorker*)worker response:(NSDictionary*)dict {
    NSString* operation = [dict objectForKey:@"operation"];
	if([operation isEqual:@"list"]) {
		[self workerResponseList:dict];
	} else
	if([operation isEqual:@"monitor"]) {
		[self workerResponseMonitor:dict];
	} else
	if([operation isEqual:@"copy"]) {
		[self workerResponseCopy:dict];
	} else
	if([operation isEqual:@"move"]) {
		[self workerResponseMove:dict];
	} else {
		LOG_ERROR(@"ERROR: unknown response: %@", dict);
	}
}

#pragma mark -
#pragma mark List operation

-(void)reload {
	NSString* path = m_working_dir;
	NSArray* keys = [NSArray arrayWithObjects:@"operation", @"path", nil];
	NSArray* objects = [NSArray arrayWithObjects:@"list", path, nil];
	NSDictionary* dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	
	// LOG_DEBUG(@"REQUEST\n%@\n\n", dict);
	[m_worker request:dict];
}

-(void)workerResponseList:(NSDictionary*)dict {
	{
		/*
		HACK: objective C cannot decode an object if it doesn't know the class.
		or so it seems to me. It raised the following exception and decoding failed.
		*** class error for 'NCFileItem': class not loaded
		
		SOLUTION: create a dummy object, lets objective C know about the class,
		so it can be decoded correct.
		*/
		(void) [[NCFileItem alloc] init];
	}

    NSString* phase = [dict objectForKey:@"phase"];
	// LOG_DEBUG(@"%s phase: %@", _cmd, phase);
	NSUInteger progress = 0;
	if([@"resolveStep" isEqualToString:phase]) {
		progress = 10;
	} else
	if([@"obtainNames" isEqualToString:phase]) {
		progress = 20;
	} else
	if([@"ObtainTypes" isEqualToString:phase]) {
		progress = 30;
	} else
	if([@"AnalyzeLinks" isEqualToString:phase]) {
		progress = 40;
	} else
	if([@"DetectAliases" isEqualToString:phase]) {
		progress = 50;
	} else
	if([@"StatRemainingItems" isEqualToString:phase]) {
		progress = 60;
	} else
	if([@"Spotlight" isEqualToString:phase]) {
		progress = 70;
	} else
	if([@"AccessControlList" isEqualToString:phase]) {
		progress = 80;
	} else
	if([@"last" isEqualToString:phase]) {
		progress = 100;
	}
	
    NSString* resolved_path = [dict objectForKey:@"resolved_path"];
	if(resolved_path) {
		// LOG_DEBUG(@"resolved_path: %@", resolved_path);
		if([self.delegate respondsToSelector:@selector(listerDataSource:resolvedPath:)]) {
			[self.delegate listerDataSource:self resolvedPath:resolved_path];
		}
	} else {
		// LOG_DEBUG(@"not resolved");
	}
	
	
    NSData* items_data = [dict objectForKey:@"items"];
	if(items_data) {
		// LOG_DEBUG(@"%s items_data: %@", _cmd, items_data);
		NSArray* items = (NSArray*)[NSUnarchiver unarchiveObjectWithData:items_data];
		// NSArray* items = (NSArray*)[NSKeyedUnarchiver unarchiveObjectWithData:items_data];
	
		// LOG_DEBUG(@"%s items: %@", _cmd, items);

		// convert from NCFileItem's to NCListerItem's
		NSMutableArray* result_items = [NSMutableArray arrayWithCapacity:[items count]+1];
		NSEnumerator* e = [items objectEnumerator];
		NCFileItem* item;
		while((item = [e nextObject])) {
			[result_items addObject:[NCListerItem listerItemFromFileItem:item]];
		}


#if 1
		{
			// deep copy
			NSArray* result_items2 = [[NSArray alloc] initWithArray:result_items copyItems:YES];

			SEL sel = @selector(listerDataSource:updateItems:progress:);
			if([self.delegate respondsToSelector:sel]) {

				id obj = self.delegate;
				id arg2 = self;
				id arg3 = result_items2;
				NSUInteger arg4 = progress;


				NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:sel]];
				[inv setTarget:obj];
				[inv setSelector:sel];
				// arguments starts at 2, since 0 is the target and 1 is the selector
				[inv setArgument:&arg2 atIndex:2]; // datasource = self
				[inv setArgument:&arg3 atIndex:3]; // items = the items
				[inv setArgument:&arg4 atIndex:4]; // readymask = the phase that we are in
				[inv retainArguments];
				[inv invoke];
			}
		}
#endif
		
		{
			if([phase isEqualToString:@"last"]) {
				if([self.delegate respondsToSelector:@selector(listerDataSourceFinishedLoading:)]) {
					[self.delegate listerDataSourceFinishedLoading:self];
				}
			}
		}
	}
	
}


#pragma mark -
#pragma mark Monitor directory

-(void)workerResponseMonitor:(NSDictionary*)dict {
	// LOG_DEBUG(@"this dir needs reload");
	if([self.delegate respondsToSelector:@selector(fileSystemDidChange:)]) {
		[self.delegate fileSystemDidChange:self];
	}
}


#pragma mark -
#pragma mark Copy operation

-(void)setCopyOperationDelegate:(id<NCCopyOperationDelegate>)delegate {
	// LOG_DEBUG(@"%s", _cmd);
	m_copy_operation_delegate = delegate;
}

-(id <NCCopyOperationProtocol>)copyOperation {
	// LOG_DEBUG(@"%s get NCCopyOperationProtocol instance", _cmd);
	return self;
}

-(void)setCopyOperationNames:(NSArray*)names {
	if(m_copy_operation_names != names) {
		m_copy_operation_names = [names copy];
	}
}

-(void)setCopyOperationSourceDir:(NSString*)fromDir {
	if(m_copy_operation_source_dir != fromDir) {
		m_copy_operation_source_dir = [fromDir copy];
	}
}

-(void)setCopyOperationTargetDir:(NSString*)toDir {
	if(m_copy_operation_target_dir != toDir) {
		m_copy_operation_target_dir = [toDir copy];
	}
}

-(void)prepareCopyOperation {
	NSArray* keys = [NSArray arrayWithObjects:
		@"operation", 
		@"names", 
		@"fromDir", 
		@"toDir", 
		nil
	];
	NSArray* objects = [NSArray arrayWithObjects:
		@"prepareCopy",
		m_copy_operation_names, 
		m_copy_operation_source_dir, 
		m_copy_operation_target_dir, 
		nil
	];
	NSDictionary* dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	
	// LOG_DEBUG(@"REQUEST\n%@\n\n", dict);
	[m_worker request:dict];
}

-(void)executeCopyOperation {
	NSArray* keys = [NSArray arrayWithObjects:
		@"operation", 
		nil
	];
	NSArray* objects = [NSArray arrayWithObjects:
		@"executeCopy",
		nil
	];
	NSDictionary* dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	
	// LOG_DEBUG(@"REQUEST\n%@\n\n", dict);
	[m_worker request:dict];
}

-(void)abortCopyOperation {
	NSArray* keys = [NSArray arrayWithObjects:
		@"operation", 
		nil
	];
	NSArray* objects = [NSArray arrayWithObjects:
		@"abortCopy",
		nil
	];
	NSDictionary* dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	
	// LOG_DEBUG(@"REQUEST\n%@\n\n", dict);
	[m_worker request:dict];
}

-(void)workerResponseCopy:(NSDictionary*)dict {
	// LOG_DEBUG(@"response: %@", dict);
	// update the progressbar with the progress value we get back
	if([m_copy_operation_delegate respondsToSelector:@selector(copyOperation:response:)]) {
		[m_copy_operation_delegate copyOperation:self response:dict];
	}
}


#pragma mark -
#pragma mark Move operation

-(void)setMoveOperationDelegate:(id<NCMoveOperationDelegate>)delegate {
	// LOG_DEBUG(@"called");
	m_move_operation_delegate = delegate;
}

-(id<NCMoveOperationProtocol>)moveOperation {
	// LOG_DEBUG(@"%s get NCMoveOperationProtocol instance", _cmd);
	return self;
}

-(void)setMoveOperationNames:(NSArray*)names {
	// LOG_DEBUG(@"names: %@", names);
	if(m_move_operation_names != names) {
		m_move_operation_names = [names copy];
	}
}

-(void)setMoveOperationSourceDir:(NSString*)fromDir {
	// LOG_DEBUG(@"sourcedir: %@", fromDir);
	if(m_move_operation_source_dir != fromDir) {
		m_move_operation_source_dir = [fromDir copy];
	}
}

-(void)setMoveOperationTargetDir:(NSString*)toDir {
	// LOG_DEBUG(@"targetdir: %@", toDir);
	if(m_move_operation_target_dir != toDir) {
		m_move_operation_target_dir = [toDir copy];
	}
}

-(void)prepareMoveOperation {
	// LOG_DEBUG(@"called");
	NSArray* keys = [NSArray arrayWithObjects:
		@"operation", 
		@"names", 
		@"fromDir", 
		@"toDir", 
		nil
	];
	NSArray* objects = [NSArray arrayWithObjects:
		@"prepareMove", 
		m_move_operation_names, 
		m_move_operation_source_dir, 
		m_move_operation_target_dir, 
		nil
	];
	NSDictionary* dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	
	// LOG_DEBUG(@"REQUEST\n%@\n\n", dict);
	[m_worker request:dict];
}

-(void)executeMoveOperation {
	// LOG_DEBUG(@"called");
	NSArray* keys = [NSArray arrayWithObjects:
		@"operation", 
		nil
	];
	NSArray* objects = [NSArray arrayWithObjects:
		@"executeMove", 
		nil
	];
	NSDictionary* dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	
	// LOG_DEBUG(@"REQUEST\n%@\n\n", dict);
	[m_worker request:dict];
}

-(void)abortMoveOperation {
	NSArray* keys = [NSArray arrayWithObjects:
		@"operation", 
		nil
	];
	NSArray* objects = [NSArray arrayWithObjects:
		@"abortMove",
		nil
	];
	NSDictionary* dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	
	// LOG_DEBUG(@"REQUEST\n%@\n\n", dict);
	[m_worker request:dict];
}

-(void)workerResponseMove:(NSDictionary*)dict {
	// LOG_DEBUG(@"response: %@", dict);
	// update the progressbar with the progress value we get back
	if([m_move_operation_delegate respondsToSelector:@selector(moveOperation:response:)]) {
		[m_move_operation_delegate moveOperation:self response:dict];
	}
}


#pragma mark -

@end
