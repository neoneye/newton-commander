//
//  NCCopyOperationDummy.m
//  NCCore
//
//  Created by Simon Strandgaard on 22/07/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NCLog.h"
#import "NCCopyOperationDummy.h"


@implementation NCCopyOperationDummy

-(void)setCopyOperationNames:(NSArray*)names {
	LOG_DEBUG(@"names: %@", names);
}

-(void)setCopyOperationSourceDir:(NSString*)fromDir {
	LOG_DEBUG(@"sourcedir: %@", fromDir);
}

-(void)setCopyOperationTargetDir:(NSString*)toDir {
	LOG_DEBUG(@"targetdir: %@", toDir);
}

-(void)prepareCopyOperation {
	LOG_DEBUG(@"called");
}

-(void)executeCopyOperation {
	LOG_DEBUG(@"called");
}

-(void)setCopyOperationDelegate:(id<NCCopyOperationDelegate>)delegate {
	LOG_DEBUG(@"called");
}

-(void)abortCopyOperation {
	LOG_DEBUG(@"called");
}

@end
