//
//  CommandLineInterface.m
//  worker
//
//  Created by Simon Strandgaard on 20/05/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import "CommandLineInterface.h"
#import "CJSONDeserializer.h"
#import "CMOperationController.h"


#define CHAR_CR 10
#define CHAR_LF 13


@implementation CLICommand

@synthesize action = m_action;
@synthesize name = m_name;

+(CLICommand*)commandName:(NSString*)aName action:(SEL)anAction {
	CLICommand* cmd = [[[CLICommand alloc] init] autorelease];
	cmd.name = aName;
	cmd.action = anAction;
	return cmd;
}

@end




@interface CommandLineInterface ()
-(void)readConfigFile:(NSString*)path;
-(void)assignConfiguration:(NSDictionary*)dict;
-(void)commandWelcome:(NSArray*)arguments;
-(void)commandPing:(NSArray*)arguments;
-(void)commandExit:(NSArray*)arguments;
-(void)commandHelp:(NSArray*)arguments;
-(void)commandStatus:(NSArray*)arguments;
-(void)commandStart:(NSArray*)arguments;
@end

@implementation CommandLineInterface

@synthesize running = m_running;
@synthesize commandArray = m_command_array;
@synthesize sourceDir = m_source_dir;
@synthesize targetDir = m_target_dir;
@synthesize nameArray = m_name_array;
@synthesize excludeFilePatternArray = m_exclude_file_pattern_array;
@synthesize excludeDirectoryPatternArray = m_exclude_directory_pattern_array;

- (id)init {
    self = [super init];
    if(self) {
		m_operation_type = kCommandLineOperationTypeUnspecified;
		m_error_code = kCommandLineConfigurationInvalid;
		m_running = YES;
		self.commandArray = [NSArray arrayWithObjects:
	   		[CLICommand commandName:@"welcome" action:@selector(commandWelcome:)],
	 		[CLICommand commandName:@"ping" action:@selector(commandPing:)],
			[CLICommand commandName:@"exit" action:@selector(commandExit:)],
			[CLICommand commandName:@"quit" action:@selector(commandExit:)],
			[CLICommand commandName:@"help" action:@selector(commandHelp:)],
			[CLICommand commandName:@"status" action:@selector(commandStatus:)],
			[CLICommand commandName:@"start" action:@selector(commandStart:)],
			nil
		];
    }
    return self;
}

-(void)readConfigFile:(NSString*)path {
	NSError* error = nil;
	
	NSData* data = [NSData dataWithContentsOfFile:path options:NSDataReadingUncached error:&error];
	if((!data) || (error)) {
		NSLog(@"%s ERROR: no data from file: %@", _cmd, path);
		m_error_code |= kCommandLineReadConfigNoData;
		return;
	}

    id output = [[CJSONDeserializer deserializer] deserialize:data error:&error];
	if((!output) || (error)) {
		NSLog(@"%s ERROR: failed to deserialize file: %@", _cmd, path);
		m_error_code |= kCommandLineReadConfigDeserialize;
		return;
	}

	BOOL is_dictionary = [output isKindOfClass:[NSDictionary class]];
	if(!is_dictionary) {
		NSLog(@"%s ERROR: root container must be a dictionary, when trying to read file: %@", _cmd, path);
		m_error_code |= kCommandLineReadConfigDictionary;
		return;
	}
	NSDictionary* dict = (NSDictionary*)output;
	
	// NSLog(@"%s dict: %@", _cmd, dict);
	
	[self assignConfiguration:dict];
}

-(void)assignConfiguration:(NSDictionary*)dict {
	m_error_code |= kCommandLineAssignConfigUnknownOperation;
	m_error_code |= kCommandLineAssignConfigInvalidSourceDir;
	m_error_code |= kCommandLineAssignConfigInvalidTargetDir;
	m_error_code |= kCommandLineAssignConfigInvalidNames;
	m_error_code |= kCommandLineAssignConfigInvalidExcludeFilePatterns;
	m_error_code |= kCommandLineAssignConfigInvalidExcludeDirectoryPatterns;

	do {
		id thing = [dict objectForKey:@"operation"];
		if(![thing isKindOfClass:[NSString class]]) break;

		NSString* s = (NSString*)thing; 
		if([s isEqualToString:@"copy"]) {
			m_operation_type = kCommandLineOperationTypeCopy;
			m_error_code &= ~kCommandLineAssignConfigUnknownOperation;
		} else 
		if([s isEqualToString:@"move"]) {
			m_operation_type = kCommandLineOperationTypeMove;
			m_error_code &= ~kCommandLineAssignConfigUnknownOperation;
		}
	} while(0);

	do {
		id thing = [dict objectForKey:@"source"];
		if(![thing isKindOfClass:[NSString class]]) break;

		NSString* path = (NSString*)thing;
		
		BOOL isdir = NO;
		BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isdir];
		if((!exists) || (!isdir)) {
			break;
		}

		m_error_code &= ~kCommandLineAssignConfigInvalidSourceDir;
		self.sourceDir = path;
	} while(0);

	do {
		id thing = [dict objectForKey:@"target"];
		if(![thing isKindOfClass:[NSString class]]) break;

		NSString* path = (NSString*)thing;
		
		BOOL isdir = NO;
		BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isdir];
		if((!exists) || (!isdir)) {
			break;
		}

		m_error_code &= ~kCommandLineAssignConfigInvalidTargetDir;
		self.targetDir = path;
	} while(0);

	do {
		id thing = [dict objectForKey:@"names"];
		// NSLog(@"%s names: %@", _cmd, thing);
		if(![thing isKindOfClass:[NSArray class]]) break;

		NSArray* string_array = (NSArray*)thing;
		BOOL all_strings = YES;
		for(id thing1 in string_array) {
			if(![thing1 isKindOfClass:[NSString class]]) {
				// NSLog(@"%s not a string: %@", _cmd, thing1);
				all_strings = NO;
			}
		}
		
		if(!all_strings) break;
		
		m_error_code &= ~kCommandLineAssignConfigInvalidNames;
		self.nameArray = string_array;
	} while(0);
	
	do {
		id thing = [dict objectForKey:@"exclude_file_patterns"];
		// NSLog(@"%s exclude_file_patterns: %@", _cmd, thing);
		if(![thing isKindOfClass:[NSArray class]]) break;

		NSArray* string_array = (NSArray*)thing;
		BOOL all_strings = YES;
		for(id thing1 in string_array) {
			if(![thing1 isKindOfClass:[NSString class]]) {
				// NSLog(@"%s not a string: %@", _cmd, thing1);
				all_strings = NO;
			}
		}
		
		if(!all_strings) break;
		
		m_error_code &= ~kCommandLineAssignConfigInvalidExcludeFilePatterns;
		self.excludeFilePatternArray = string_array;
	} while(0);
	
	do {
		id thing = [dict objectForKey:@"exclude_dir_patterns"];
		// NSLog(@"%s exclude_file_patterns: %@", _cmd, thing);
		if(![thing isKindOfClass:[NSArray class]]) break;

		NSArray* string_array = (NSArray*)thing;
		BOOL all_strings = YES;
		for(id thing1 in string_array) {
			if(![thing1 isKindOfClass:[NSString class]]) {
				// NSLog(@"%s not a string: %@", _cmd, thing1);
				all_strings = NO;
			}
		}
		
		if(!all_strings) break;
		
		m_error_code &= ~kCommandLineAssignConfigInvalidExcludeDirectoryPatterns;
		self.excludeDirectoryPatternArray = string_array;
	} while(0);
	
	// the configuration is good so we clear the invalid bit, 
	m_error_code &= ~kCommandLineConfigurationInvalid;
}

-(void)executeCommand:(NSString*)command arguments:(NSArray*)arguments {
	
	BOOL unknown_command = YES;
	for(CLICommand* cmd in self.commandArray) {
		if([cmd.name isEqualToString:command]) {
			unknown_command = NO;
			[self performSelector:cmd.action withObject:arguments];
			break;
		}
	}
	
	if(unknown_command) {
		NSString* s = [NSString stringWithFormat:@"ERROR: unknown command: %@\narguments: %@\n\ntype 'help' to see what commands are available\n", command, arguments];
		printf("%s", [s UTF8String]);
	}
	
	if(m_running) {
		printf("PROMPT> ");
		fflush(stdout);
	}
}

-(void)evaluateString:(NSString*)s {
	// NSLog(@"%s s: %@", _cmd, s);
	NSArray* components = [s componentsSeparatedByString:@" "];
	
	NSString* command = @"eval_error";
	NSArray* arguments = nil;
	
	int n = [components count];
	if(n >= 1) {
		command = [components objectAtIndex:0];
		NSRange range = NSMakeRange(1, n-1);
		arguments = [components subarrayWithRange:range];
	}

	[self executeCommand:command arguments:arguments];
}

-(void)evaluateArguments:(NSArray*)arguments {
	NSString* json_path = nil;
	
	int index = 0;
	for(NSString* argument in arguments) {
		if(index == 0) {
			// program name.. do nothing
		} else
		if(index == 1) {
			// mode name
			if(![argument isEqualToString:@"json"]) {
				printf("ERROR: argument#1 is wrong. Only 'json' mode is allowed\n");
				m_error_code |= kCommandLineEvaluateArgumentsIllegalMode;
				return;
			}
		} else 
		if(index == 2) {
			// path to json config file
			json_path = argument;
		} else {
			printf("ERROR: too many arguments\n");
			m_error_code |= kCommandLineEvaluateArgumentsTooMany;
			return;
		}
		index++;
	}

	if(!json_path) {
		printf("ERROR: too few arguments. Example:  worker json path_to_config_json\n");
		m_error_code |= kCommandLineEvaluateArgumentsTooFew;
		return;
	}
	
	// NSLog(@"%s reading configuration: %@", _cmd, json_path);
	[self readConfigFile:json_path];
}


+(void)runWithArguments:(NSArray*)arguments {
	CommandLineInterface* cli = [[[CommandLineInterface alloc] init] autorelease];
	
	[cli commandWelcome:nil];
	[cli evaluateArguments:arguments];
	[cli evaluateString:@"status"];
	
	NSMutableString* buf = [NSMutableString stringWithCapacity:200];
	while(cli.running) {
		int ch = getchar();
		if((ch == CHAR_CR) || (ch == CHAR_LF)) {
			[cli evaluateString:buf];
			[buf setString:@""];
		} else {
			[buf appendFormat:@"%c", ch];
		}
	}
}

-(void)commandWelcome:(NSArray*)arguments {
	printf("version 0.1\n");
	printf("date 2011-05-20\n");
	printf("welcome to opcoders.com's copymove tool, part of Newton Commander\n");
	printf("type 'help' to see what commands are available\n");
}

-(void)commandPing:(NSArray*)arguments {
	printf("pong\n");
}

-(void)commandExit:(NSArray*)arguments {
	m_running = NO;
}

-(void)commandHelp:(NSArray*)arguments {
	printf("opcoders.com's copymove tool\n\n");
    printf("Commands available:\n");
    printf("  exit             Quit this tool\n");
    printf("  help             Show help\n");
    printf("  ping             Makes it easier to determine if commands are working\n");
    printf("  status           Obtain the status code\n");
    printf("  start            Start the operation, either copy or move\n");
}

-(void)commandStatus:(NSArray*)arguments {
	if(m_error_code) {
		printf("STATUS=ERROR_%i\n", m_error_code);
	} else {
		printf("STATUS=OK\n");
	}
}

-(void)commandStart:(NSArray*)arguments {
	if(m_error_code != 0) {
		printf("ERROR: there is a status error. This command can only run when all errors have been resolved.\n");
		return;
	}
	
	// NSLog(@"%s", _cmd);

	CMOperationController* controller = [[[CMOperationController alloc] init] autorelease];
	controller.sourceDir = self.sourceDir;
	controller.targetDir = self.targetDir;
	controller.nameArray = self.nameArray;
	controller.excludeFilePatternArray = self.excludeFilePatternArray;
	controller.excludeDirectoryPatternArray = self.excludeDirectoryPatternArray;
	controller.operationDelegate = self;
	
	if(m_operation_type == kCommandLineOperationTypeMove) {
		controller.operationType = CMOperationTypeMove;
	} else {
		controller.operationType = CMOperationTypeCopy;
	}
	
	[controller run];
}

-(void)operation:(CMOperation*)anOperation promptFileName:(CMPromptFileName*)prompt {
	NSLog(@"%s  FILENAMECOLLISION\nsource_path: %@\ntarget_path: %@", _cmd, prompt.sourcePath, prompt.targetPath);
	
	printf("OPTION#0: retry\n");
	printf("OPTION#1: stop\n");
	printf("OPTION#2: skip\n");
	printf("OPTION#3: rename_source insert-new-name-here\n");
	printf("OPTION#4: rename_target insert-new-name-here\n");
	printf("OPTION#5: replace\n");
	printf("OPTION#6: append\n");
	
	printf("PROMPT> ");
	fflush(stdout);

	NSMutableString* buf = [NSMutableString stringWithCapacity:200];
	while(1) {
		int ch = getchar();
		if((ch == CHAR_CR) || (ch == CHAR_LF)) {
			break;
		}
		[buf appendFormat:@"%c", ch];
	}
	
	NSLog(@"%s %@", _cmd, buf);
	NSArray* components = [buf componentsSeparatedByString:@" "];
	NSString* component0 = nil;
	NSString* component1 = nil;
	if([components count] >= 1) {
		component0 = [components objectAtIndex:0];
	}
	if([components count] >= 2) {
		component1 = [components objectAtIndex:1];
	}
	
	if([@"retry" isEqualToString:component0]) {
		prompt.action = kCMPromptFileNameActionRetry;
		return;
	}
	if([@"stop" isEqualToString:component0]) {
		prompt.action = kCMPromptFileNameActionStop;
		return;
	}
	if([@"skip" isEqualToString:component0]) {
		prompt.action = kCMPromptFileNameActionSkip;
		return;
	}
	if([@"rename_source" isEqualToString:component0]) {
		prompt.action = kCMPromptFileNameActionRenameSource;
		prompt.resolvedName = component1;
		return;
	}
	if([@"rename_target" isEqualToString:component0]) {
		prompt.action = kCMPromptFileNameActionRenameTarget;
		prompt.resolvedName = component1;
		return;
	}
	if([@"replace" isEqualToString:component0]) {
		prompt.action = kCMPromptFileNameActionReplace;
		return;
	}
	if([@"append" isEqualToString:component0]) {
		prompt.action = kCMPromptFileNameActionAppend;
		return;
	}
	

	NSLog(@"%s ERROR: unknown component0: %@, assuming retry", _cmd, component0);
	prompt.action = kCMPromptFileNameActionRetry;
}

-(void)operation:(CMOperation*)anOperation promptDirectoryName:(CMPromptDirectoryName*)prompt {
	NSLog(@"%s  DIRECTORYNAMECOLLISION\nsource_path: %@\ntarget_path: %@", _cmd, prompt.sourcePath, prompt.targetPath);
	
	printf("OPTION#0: retry\n");
	printf("OPTION#1: stop\n");
	printf("OPTION#2: skip\n");
	printf("OPTION#3: rename_source insert-new-name-here\n");
	printf("OPTION#4: rename_target insert-new-name-here\n");
	printf("OPTION#5: replace\n");
	printf("OPTION#6: merge\n");
	
	printf("PROMPT> ");
	fflush(stdout);

	NSMutableString* buf = [NSMutableString stringWithCapacity:200];
	while(1) {
		int ch = getchar();
		if((ch == CHAR_CR) || (ch == CHAR_LF)) {
			break;
		}
		[buf appendFormat:@"%c", ch];
	}
	
	NSLog(@"%s %@", _cmd, buf);
	NSArray* components = [buf componentsSeparatedByString:@" "];
	NSString* component0 = nil;
	NSString* component1 = nil;
	if([components count] >= 1) {
		component0 = [components objectAtIndex:0];
	}
	if([components count] >= 2) {
		component1 = [components objectAtIndex:1];
	}
	
	if([@"retry" isEqualToString:component0]) {
		prompt.action = kCMPromptDirectoryNameActionRetry;
		return;
	}
	if([@"stop" isEqualToString:component0]) {
		prompt.action = kCMPromptDirectoryNameActionStop;
		return;
	}
	if([@"skip" isEqualToString:component0]) {
		prompt.action = kCMPromptDirectoryNameActionSkip;
		return;
	}
	if([@"rename_source" isEqualToString:component0]) {
		prompt.action = kCMPromptDirectoryNameActionRenameSource;
		prompt.resolvedName = component1;
		return;
	}
	if([@"rename_target" isEqualToString:component0]) {
		prompt.action = kCMPromptDirectoryNameActionRenameTarget;
		prompt.resolvedName = component1;
		return;
	}
	if([@"replace" isEqualToString:component0]) {
		prompt.action = kCMPromptDirectoryNameActionReplace;
		return;
	}
	if([@"merge" isEqualToString:component0]) {
		prompt.action = kCMPromptDirectoryNameActionMerge;
		return;
	}
	

	NSLog(@"%s ERROR: unknown component0: %@, assuming retry", _cmd, component0);
	prompt.action = kCMPromptDirectoryNameActionRetry;
}


@end
