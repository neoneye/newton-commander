//
//  sc_tov_copier.h
//  SharedCode Core+Worker
//
//  Created by Simon Strandgaard on 24/07/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CMTraversalObject.h"
#import "CMPromptFileName.h"
#import "CMPromptDirectoryName.h"

enum {
	kOperationStatusOK               = 0x0000,

	// a file or dir already exist at the destination. Do you want to overwrite it?
	kOperationStatusExist            = 0x0001,

	// some other error occured
	kOperationStatusUnknownDir       = 0x1001,
	kOperationStatusUnknownFile      = 0x1002,
	kOperationStatusUnknownHardlink  = 0x1003,
	kOperationStatusUnknownSymlink   = 0x1004,
	kOperationStatusUnknownFifo      = 0x1005,
	kOperationStatusUnknownChar      = 0x1006,
	kOperationStatusUnknownBlock     = 0x1007,
	kOperationStatusUnknownOther     = 0x1008,
};

enum {
	CMOperationTypeCopy = 1,
	CMOperationTypeMove = 2,
};


@class CMOperation;

@protocol CMOperationDelegate <NSObject>
-(void)operation:(CMOperation*)anOperation promptFileName:(CMPromptFileName*)prompt;
-(void)operation:(CMOperation*)anOperation promptDirectoryName:(CMPromptDirectoryName*)prompt;
@end


@interface CMOperation : NSObject <CMTraversalObjectVisitor> {
	int m_operation_type;
	NSString* m_source_path;
	NSString* m_target_path;
	unsigned long long m_bytes_copied;
	
	id<CMOperationDelegate> m_delegate;
}
@property (nonatomic, assign) int operationType;
@property (retain) NSString* sourcePath;
@property (retain) NSString* targetPath;
@property (assign) unsigned long long bytesCopied;
@property (assign) id<CMOperationDelegate> delegate;

-(void)throwStatus:(NSUInteger)status posixError:(int)error_code message:(NSString*)message, ...;

@end
