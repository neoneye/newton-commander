//
//  CMOperationController.h
//  worker
//
//  Created by Simon Strandgaard on 20/05/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CMOperation.h"




/*
CMOperation == Copy Move Operation
*/
@interface CMOperationController : NSObject {
	int m_operation_type;
	NSString* m_source_dir;
	NSString* m_target_dir;
	NSArray* m_name_array;
	id<CMOperationDelegate> m_operation_delegate;
	NSArray* m_traversal_object_array;
	NSArray* m_exclude_file_pattern_array;
	NSArray* m_exclude_directory_pattern_array;
	NSArray* m_exclude_file_regexp_array;
	NSArray* m_exclude_directory_regexp_array;
}
@property (nonatomic, assign) int operationType;
@property (nonatomic, retain) NSString* sourceDir;
@property (nonatomic, retain) NSString* targetDir;
@property (nonatomic, retain) NSArray* nameArray;
@property (nonatomic, assign) id<CMOperationDelegate> operationDelegate;
@property (nonatomic, retain) NSArray* traversalObjectArray;
@property (nonatomic, retain) NSArray* excludeFilePatternArray;
@property (nonatomic, retain) NSArray* excludeDirectoryPatternArray;
@property (nonatomic, retain) NSArray* excludeFileRegexpArray;
@property (nonatomic, retain) NSArray* excludeDirectoryRegexpArray;

-(void)run;

@end
