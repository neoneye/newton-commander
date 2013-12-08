//
//  sc_transfer.h
//  SharedCode Core+Worker
//
//  Created by Simon Strandgaard on 23/07/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#include <Foundation/Foundation.h>


@protocol TransferOperationDelegate;

@class TransferOperationThread;


@interface TransferOperation : NSObject {
	TransferOperationThread* m_thread;
	id<TransferOperationDelegate> m_delegate;
	NSArray* m_names;
	NSString* m_from_dir;
	NSString* m_to_dir; 
	
	// YES=move operation. NO=copy operation
	BOOL m_is_move;
}
@property (assign) id<TransferOperationDelegate> delegate;
@property (retain) NSArray* names;
@property (retain) NSString* fromDir;
@property (retain) NSString* toDir;
@property BOOL isMove;

+(TransferOperation*)copyOperation;
+(TransferOperation*)moveOperation;


-(void)performScan;
-(void)performOperation;
-(void)abortOperation;
-(void)dump;

@end // class TransferOperation



@protocol TransferOperationDelegate <NSObject>

-(void)transferOperation:(TransferOperation*)operation response:(NSDictionary*)dict forKey:(NSString*)key;

@end // protocol TransferOperationDelegate

