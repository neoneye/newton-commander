//
//  NCListerDataSourceAdvanced.h
//  NCCore
//
//  Created by Simon Strandgaard on 10/07/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#import "NCListerDataSource.h"
#import "NCWorker.h"
#import "NCCopyOperationProtocol.h"
#import "NCMoveOperationProtocol.h"

@class NCTimeProfilerSetWorkingDir;

@interface NCListerDataSourceAdvanced : NSObject <NCListerDataSource, NCWorkerController, NCCopyOperationProtocol, NCMoveOperationProtocol> {
	NCWorker* m_worker;
	NCTimeProfilerSetWorkingDir* m_profiler;

	// file listing
	NSString* m_working_dir;
	NSString* m_resolved_working_dir;
	NSArray* m_items;

	// file copying
	id<NCCopyOperationDelegate> m_copy_operation_delegate;
	NSArray* m_copy_operation_names;
	NSString* m_copy_operation_source_dir;
	NSString* m_copy_operation_target_dir;

	// file moving
	id<NCMoveOperationDelegate> m_move_operation_delegate;
	NSArray* m_move_operation_names;
	NSString* m_move_operation_source_dir;
	NSString* m_move_operation_target_dir;
}
@property (strong) NCWorker* worker;

@property (nonatomic, weak) id<NCListerDataSourceDelegate> delegate;

-(void)setWorkingDir:(NSString*)path;

-(void)reload;

-(void)switchToUser:(int)user_id;

-(id<NCCopyOperationProtocol>)copyOperation;
-(id<NCMoveOperationProtocol>)moveOperation;

@end

