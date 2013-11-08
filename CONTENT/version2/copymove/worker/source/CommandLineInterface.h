//
//  CommandLineInterface.h
//  worker
//
//  Created by Simon Strandgaard on 20/05/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CMOperation.h"

enum {
	kCommandLineConfigurationInvalid                        = 1 << 0,
	kCommandLineEvaluateArgumentsTooFew                     = 1 << 1,
	kCommandLineEvaluateArgumentsIllegalMode                = 1 << 2,
	kCommandLineEvaluateArgumentsTooMany                    = 1 << 3,
	kCommandLineReadConfigNoData                            = 1 << 4,
	kCommandLineReadConfigDeserialize                       = 1 << 5,
	kCommandLineReadConfigDictionary                        = 1 << 6,
	kCommandLineAssignConfigUnknownOperation                = 1 << 7,
	kCommandLineAssignConfigInvalidSourceDir                = 1 << 8,
	kCommandLineAssignConfigInvalidTargetDir                = 1 << 9,
	kCommandLineAssignConfigInvalidNames                    = 1 << 10,
	kCommandLineAssignConfigInvalidExcludeFilePatterns      = 1 << 11,
	kCommandLineAssignConfigInvalidExcludeDirectoryPatterns = 1 << 12,
};

enum {
	kCommandLineOperationTypeUnspecified = 0,
	kCommandLineOperationTypeCopy = 1,
	kCommandLineOperationTypeMove = 2,
};

@interface CLICommand : NSObject {
	SEL m_action;
	NSString* m_name;
}
@property (nonatomic, assign) SEL action;
@property (nonatomic, retain) NSString* name;
+(CLICommand*)commandName:(NSString*)aName action:(SEL)anAction;
@end


@interface CommandLineInterface : NSObject <CMOperationDelegate> {
	BOOL m_running;
	NSArray* m_command_array;
	int m_error_code;
	int m_operation_type;
	NSString* m_source_dir;
	NSString* m_target_dir;
	NSArray* m_name_array;
	NSArray* m_exclude_file_pattern_array;
	NSArray* m_exclude_directory_pattern_array;
}
@property (nonatomic, assign) BOOL running;
@property (nonatomic, retain) NSArray* commandArray;
@property (nonatomic, retain) NSString* sourceDir;
@property (nonatomic, retain) NSString* targetDir;
@property (nonatomic, retain) NSArray* nameArray;
@property (nonatomic, retain) NSArray* excludeFilePatternArray;
@property (nonatomic, retain) NSArray* excludeDirectoryPatternArray;

+(void)runWithArguments:(NSArray*)arguments;
-(void)executeCommand:(NSString*)command arguments:(NSArray*)arguments;
-(void)readConfigFile:(NSString*)path;

@end
