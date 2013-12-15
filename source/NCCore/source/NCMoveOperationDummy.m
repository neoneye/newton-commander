//
//  NCMoveOperationDummy.m
//  NCCore
//
//  Created by Simon Strandgaard on 25/09/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NCLog.h"
#import "NCMoveOperationDummy.h"


@implementation NCMoveOperationDummy

-(void)setMoveOperationNames:(NSArray*)names {
	LOG_DEBUG(@"names: %@", names);
}

-(void)setMoveOperationSourceDir:(NSString*)fromDir {
	LOG_DEBUG(@"sourcedir: %@", fromDir);
}

-(void)setMoveOperationTargetDir:(NSString*)toDir {
	LOG_DEBUG(@"targetdir: %@", toDir);
}

-(void)prepareMoveOperation {
	LOG_DEBUG(@"called");
}

-(void)executeMoveOperation {
	LOG_DEBUG(@"called");
}

-(void)setMoveOperationDelegate:(id<NCMoveOperationDelegate>)delegate {
	LOG_DEBUG(@"called");
}

-(void)abortMoveOperation {
	LOG_DEBUG(@"called");
}

@end
