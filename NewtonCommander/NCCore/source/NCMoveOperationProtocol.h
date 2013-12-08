//
//  NCMoveOperationProtocol.h
//  NCCore
//
//  Created by Simon Strandgaard on 22/07/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol NCMoveOperationDelegate;

@protocol NCMoveOperationProtocol <NSObject>

-(void)setMoveOperationDelegate:(id<NCMoveOperationDelegate>)delegate;

-(void)setMoveOperationNames:(NSArray*)names;
-(void)setMoveOperationSourceDir:(NSString*)fromDir;
-(void)setMoveOperationTargetDir:(NSString*)toDir;

-(void)prepareMoveOperation;
-(void)executeMoveOperation;
-(void)abortMoveOperation;

@end

#pragma mark -

@protocol NCMoveOperationDelegate <NSObject>

-(void)moveOperation:(id<NCMoveOperationProtocol>)move_operation response:(NSDictionary*)dict;

@end
