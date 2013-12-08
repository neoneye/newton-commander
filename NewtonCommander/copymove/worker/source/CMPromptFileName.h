//
//  CMPromptFileName.h
//  worker
//
//  Created by Simon Strandgaard on 29/05/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
	// retry
	kCMPromptFileNameActionRetry = 0,
	
	// abort the entire operation
	kCMPromptFileNameActionStop,

	// skip it, don't try to copy/move it
	kCMPromptFileNameActionSkip,
	
	// rename the source file
	kCMPromptFileNameActionRenameSource,

	// rename the target file
	kCMPromptFileNameActionRenameTarget,
	
	// overwrite the file
	kCMPromptFileNameActionReplace,

	// append to the file
	kCMPromptFileNameActionAppend,
};

@interface CMPromptFileName : NSObject {
	NSString* m_source_path;
	NSString* m_target_path;
	int m_action;
	NSString* m_resolved_name;
}
@property (nonatomic, retain) NSString* sourcePath;
@property (nonatomic, retain) NSString* targetPath;
@property (nonatomic, assign) int action;
@property (nonatomic, retain) NSString* resolvedName;

@end
