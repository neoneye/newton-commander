//
//  sc_tov_copier.h
//  SharedCode Core+Worker
//
//  Created by Simon Strandgaard on 24/07/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sc_traversal_objects.h"

enum {
	kCopierStatusOK               = 0x0000,

	// a file or dir already exist at the destination. Do you want to overwrite it?
	kCopierStatusExist            = 0x0001,

	// some other error occured
	kCopierStatusUnknownDir       = 0x1001,
	kCopierStatusUnknownFile      = 0x1002,
	kCopierStatusUnknownHardlink  = 0x1003,
	kCopierStatusUnknownSymlink   = 0x1004,
	kCopierStatusUnknownFifo      = 0x1005,
	kCopierStatusUnknownChar      = 0x1006,
	kCopierStatusUnknownBlock     = 0x1007,
	kCopierStatusUnknownOther     = 0x1008,
};

@interface TOVCopier : NSObject <TraversalObjectVisitor> {
	NSString* m_source_path;
	NSString* m_target_path;
	unsigned long long m_bytes_copied;
	
	NSUInteger m_status_code;
	NSString* m_status_message;
}
@property (strong) NSString* sourcePath;
@property (strong) NSString* targetPath;
@property (assign) unsigned long long bytesCopied;
@property NSUInteger statusCode;
@property (strong) NSString* statusMessage;

-(void)setStatus:(NSUInteger)status posixError:(int)error_code message:(NSString*)message, ...;

-(NSString*)result;

-(NSString*)convert:(NSString*)path;
@end
