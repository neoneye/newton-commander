//
// NCWorkerPluginAdvanced.h
// Newton Commander
//
#import "NCWorkerPlugin.h"
#import "sc_transfer.h"

@class TransferOperation;
@class NCFileEventManager;

@interface NCWorkerPluginAdvanced : NSObject <NCWorkerPlugin, TransferOperationDelegate> {
	id<NCWorkerPluginDelegate> m_delegate;
	NSMutableArray* m_queue;
	NSString* m_working_dir;
	NSString* m_resolved_working_dir;
	NSArray* m_items;
	TransferOperation* m_copy_operation;
	TransferOperation* m_move_operation;
	NCFileEventManager* m_file_event_manager;
}

-(void)setDelegate:(id<NCWorkerPluginDelegate>)delegate;

-(void)request:(NSDictionary*)dict;

@end
