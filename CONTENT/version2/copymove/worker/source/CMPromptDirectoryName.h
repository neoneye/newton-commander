//
//  CMPromptDirectoryName.h
//  worker
//
//  Created by Simon Strandgaard on 02/06/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
	// retry
	kCMPromptDirectoryNameActionRetry = 0,
	
	// abort the entire operation
	kCMPromptDirectoryNameActionStop,

	// skip it, don't try to copy/move it
	kCMPromptDirectoryNameActionSkip,
	
	// rename the source directory
	kCMPromptDirectoryNameActionRenameSource,

	// rename the target directory
	kCMPromptDirectoryNameActionRenameTarget,

	// delete the target directory before copy/move
	kCMPromptDirectoryNameActionReplace,
	
	// preserve content of target directory through copy/move operation
	kCMPromptDirectoryNameActionMerge,
};

@interface CMPromptDirectoryName : NSObject {
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
