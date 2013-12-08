//
//  sc_tov_copier.m
//  SharedCode Core+Worker
//
//  Created by Simon Strandgaard on 24/07/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#import "CMOperation.h"
#import "NSFileManager+ResourceFork.h"
#import "NSFileManager+FinderInfo.h"
#include "CMFunctions.h"


#define LOG_ERROR NSLog


NSString* NSStringFromPosixError(int code) {
	char message[1024];
	message[0] = 0;
	strerror_r(code, message, 1024);
	return [NSString stringWithFormat:@"ERRNO#%i %s", code, message];
}


@interface CMOperation ()
-(void)copyDataFrom:(NSString*)sourceFile to:(NSString*)targetFile;
-(void)appendDataFrom:(NSString*)sourceFile to:(NSString*)targetFile;
-(void)copyFileFrom:(NSString*)sourceFile to:(NSString*)targetFile;
@end

@implementation CMOperation

@synthesize operationType = m_operation_type;
@synthesize sourcePath = m_source_path;
@synthesize targetPath = m_target_path;
@synthesize bytesCopied = m_bytes_copied;
@synthesize delegate = m_delegate;

-(id)init {
	self = [super init];
    if(self) {
    }
    return self;
}

-(void)throwStatus:(NSUInteger)status posixError:(int)error_code message:(NSString*)message, ... {
	va_list ap;
	va_start(ap,message);
	NSString* message2 = [[[NSString alloc] initWithFormat:message arguments:ap] autorelease];
	va_end(ap);

	NSString* error_text = NSStringFromPosixError(error_code);
	NSString* status_message = [NSString stringWithFormat:@"ERROR status: %i\nposix-code: %@\nmessage: %@", (int)status, error_text, message2];
	// LOG_ERROR(@"%@", status_message);

	NSException *e = [NSException
        exceptionWithName:@"CMOperationFailed"
        reason:status_message
        userInfo:nil];
	@throw e;
}

-(void)copyDataFrom:(NSString*)sourceFile to:(NSString*)targetFile {
	const char* source_path = [sourceFile fileSystemRepresentation];
	const char* target_path = [targetFile fileSystemRepresentation];

	unsigned long long bytes_copied = 0;

	// copy the data fork
	int fd0 = open(source_path, O_RDONLY);
	if(fd0 == -1) {
		[self throwStatus:kOperationStatusUnknownFile posixError:errno 
			message:@"open source file %s", source_path];
	}

	int fd1 = open(target_path, O_EXCL | O_CREAT | O_WRONLY, 0700);   // NOTE: 0700, may not be the safest mode to use here?
	if(fd1 == -1) {
		if(fd0 >= 0) { close(fd0); }
		[self throwStatus:kOperationStatusUnknownFile posixError:errno 
			message:@"open target file %s", target_path];
	}

	copy_data_fd(fd0, fd1, &bytes_copied);

	if(fd0 >= 0) { close(fd0); }
	if(fd1 >= 0) { close(fd1); }

	// keep track of how many bytes we have copied so far, 
	// so we can update progressbars accordingly
	m_bytes_copied += bytes_copied;
}

-(void)appendDataFrom:(NSString*)sourceFile to:(NSString*)targetFile {
	const char* source_path = [sourceFile fileSystemRepresentation];
	const char* target_path = [targetFile fileSystemRepresentation];

	unsigned long long bytes_copied = 0;

	// copy the data fork
	int fd0 = open(source_path, O_RDONLY);
	if(fd0 == -1) {
		[self throwStatus:kOperationStatusUnknownFile posixError:errno 
			message:@"open source file %s", source_path];
	}

	int fd1 = open(target_path, O_WRONLY | O_APPEND);
	if(fd1 == -1) {
		if(fd0 >= 0) { close(fd0); }
		[self throwStatus:kOperationStatusUnknownFile posixError:errno 
			message:@"open target file %s", target_path];
	}

	copy_data_fd(fd0, fd1, &bytes_copied);

	if(fd0 >= 0) { close(fd0); }
	if(fd1 >= 0) { close(fd1); }

	// keep track of how many bytes we have copied so far, 
	// so we can update progressbars accordingly
	m_bytes_copied += bytes_copied;
}

-(void)copyFileFrom:(NSString*)sourceFile to:(NSString*)targetFile {
	const char* source_path = [sourceFile fileSystemRepresentation];
	const char* target_path = [targetFile fileSystemRepresentation];

	[self copyDataFrom:sourceFile to:targetFile];

	/*
	NOTE: This is not optimal. We open the files, transfer data, close the files.
	Then we copy resourcefork and finderinfo using the filenames.
	And finally we open the files, transfer metadata, close the files.
	Would it be possible to use file descriptors all the way, so that we only have to open them one time only?
	I suspect this hurts performance a lot.
	*/

	/*
	copy the resource fork
	only FILES have a resource fork. 
	DIRS/Symlinks/FIFOs/Char/Block doesn't have resource fork.
	*/
	[[NSFileManager defaultManager]	copyResourceForkFrom:sourceFile to:targetFile];
	
	// copy finder info
	[[NSFileManager defaultManager] copyFinderInfoFrom:sourceFile to:targetFile];

	{
		int from_fd = open(source_path, O_RDONLY);
		if(from_fd < 0) {
			[self throwStatus:kOperationStatusUnknownFile posixError:errno 
				message:@"open source file %s", source_path];
		}
		struct stat from_st;
		if(fstat(from_fd, &from_st) < 0) {
			close(from_fd);
			[self throwStatus:kOperationStatusUnknownFile posixError:errno 
				message:@"stat source file %s", source_path];
		}
		int to_fd = open(target_path, O_WRONLY);
		if(to_fd < 0) {
			close(from_fd);
			[self throwStatus:kOperationStatusUnknownFile posixError:errno 
				message:@"stat target file %s", target_path];
		}
		int flags = NC_COPYFILE_ALL;
		nc_copyfile_fd(&from_st, from_fd, to_fd, flags);

		close(to_fd);
		close(from_fd);
	}
}

-(void)visitDir:(CMTraversalObjectDir*)obj {
	if(obj.exclude) {
		return; // ignore this object
	}
	
	NSString* origSourcePath = self.sourcePath;
	NSString* origTargetPath = self.targetPath;


	NSString* source_path_objc = [self.sourcePath stringByAppendingPathComponent:[obj path]];
	NSString* target_path_objc = [self.targetPath stringByAppendingPathComponent:[obj path]];
	const char* source_path = [source_path_objc fileSystemRepresentation];
	const char* target_path = [target_path_objc fileSystemRepresentation];
	
	
	BOOL should_create_directory = YES;
	BOOL should_copy_details = YES;


	do {
		/*
		ensure that no directory already exists
		this prevent us from overwriting a file if it already exists,
		since open() with O_CREAT doesn't complain if a file already exist
		*/
		struct stat to_st;
		if(lstat(target_path, &to_st) != 0) {
			break;
		}
		
		// TODO: check wether stat is a directory

		CMPromptDirectoryName* prompt = [[[CMPromptDirectoryName alloc] init] autorelease];
		prompt.sourcePath = source_path_objc;
		prompt.targetPath = target_path_objc;

		if([self.delegate respondsToSelector:@selector(operation:promptDirectoryName:)]) {
			[self.delegate operation:self promptDirectoryName:prompt];
		}
		
		NSLog(@"%s action: %i", _cmd, prompt.action);

		if(prompt.action == kCMPromptDirectoryNameActionRetry) {
			// retry is the same as running this loop again
			continue;
 		}

		if(prompt.action == kCMPromptDirectoryNameActionStop) {
			[self throwStatus:kOperationStatusExist posixError:EEXIST 
				message:@"stat target file %s", target_path];
		}

		if(prompt.action == kCMPromptDirectoryNameActionSkip) {
			NSLog(@"%s SKIP", _cmd);
			// TODO: delete source file when moving
			return;
		}
		
		if(prompt.action == kCMPromptDirectoryNameActionRenameSource) {
			NSLog(@"%s RENAME SOURCE %@", _cmd, prompt.resolvedName);
			target_path_objc = [self.targetPath stringByAppendingPathComponent:prompt.resolvedName];
			target_path = [target_path_objc fileSystemRepresentation];
			continue;
		}
		
		if(prompt.action == kCMPromptDirectoryNameActionRenameTarget) {
			NSLog(@"%s RENAME TARGET %@", _cmd, prompt.resolvedName);
			NSString* path_objc = [self.targetPath stringByAppendingPathComponent:prompt.resolvedName];
			const char* path = [path_objc fileSystemRepresentation];
			rename(target_path, path);
			continue;
		}
		
		if(prompt.action == kCMPromptDirectoryNameActionReplace) {

			NSString* delete_path_objc = [target_path_objc stringByAppendingString:@"___deleted"];
			const char* delete_path = [delete_path_objc fileSystemRepresentation];
			
			// TODO: delete source dir when moving
			// TODO: delete target dir when moving
			rename(target_path, delete_path);
			break;
		}

		if(prompt.action == kCMPromptDirectoryNameActionMerge) {
			should_create_directory = NO;
			should_copy_details = NO;
			break;
		}


		[self throwStatus:kOperationStatusExist posixError:EEXIST 
			message:@"unknown action chosen: %i", prompt.action];
	} while(1);

	
	if(should_create_directory) {
		if(mkdir(target_path, 0700) < 0) {
			if(errno == EEXIST) {
				[self throwStatus:kOperationStatusExist posixError:errno 
					message:@"mkdir %s", target_path];
			} else {
				[self throwStatus:kOperationStatusUnknownDir posixError:errno 
					message:@"mkdir %s", target_path];
			}
		}
	}
                                
	// copy/move content of subdirs recursively
	{
		self.sourcePath = source_path_objc;
		self.targetPath = target_path_objc;
		for(CMTraversalObject* child_obj in obj.childTraversalObjects) {
			[child_obj accept:self];
		}
		self.sourcePath = origSourcePath;
		self.targetPath = origTargetPath;
	}

	if(should_copy_details) {
		// copy finder info
		[[NSFileManager defaultManager] copyFinderInfoFrom:source_path_objc to:target_path_objc];

		int from_fd = open(source_path, O_DIRECTORY);
		if(from_fd < 0) {
			[self throwStatus:kOperationStatusUnknownDir posixError:errno 
				message:@"open source dir %s", source_path];
		}
		struct stat from_st;
		if(fstat(from_fd, &from_st) < 0) {
			close(from_fd);
			[self throwStatus:kOperationStatusUnknownDir posixError:errno 
				message:@"stat source dir %s", source_path];
		}
		int to_fd = open(target_path, O_DIRECTORY);
		if(to_fd < 0) {
			close(from_fd);
			[self throwStatus:kOperationStatusUnknownDir posixError:errno 
				message:@"open target dir %s", target_path];
		}
		int flags = NC_COPYFILE_ALL;
		nc_copyfile_fd(&from_st, from_fd, to_fd, flags);

		close(to_fd);
		close(from_fd);
	}

	if(m_operation_type == CMOperationTypeMove) {
		NSString* delete_path_objc = [source_path_objc stringByAppendingString:@"___deleted"];
		const char* delete_path = [delete_path_objc fileSystemRepresentation];
		rename(source_path, delete_path);

		// TODO: delete source directory when moving
	}
}

-(void)visitFile:(CMTraversalObjectFile*)obj {
	if(obj.exclude) {
		return; // ignore this object
	}

	NSString* source_path_objc = [self.sourcePath stringByAppendingPathComponent:[obj path]];
	NSString* target_path_objc = [self.targetPath stringByAppendingPathComponent:[obj path]];
	const char* source_path = [source_path_objc fileSystemRepresentation];
	const char* target_path = [target_path_objc fileSystemRepresentation];
	
	// NSLog(@"%s\nsource_path: %s\ntarget_path: %s", _cmd, source_path, target_path);
	BOOL should_append = NO;

	do {
		/*
		ensure that no file already exists
		this prevent us from overwriting a file if it already exists,
		since open() with O_CREAT doesn't complain if a file already exist
		*/
		struct stat to_st;
		if(lstat(target_path, &to_st) != 0) {
			break;
		}

		// TODO: check wether stat is a file

		CMPromptFileName* prompt = [[[CMPromptFileName alloc] init] autorelease];
		prompt.sourcePath = source_path_objc;
		prompt.targetPath = target_path_objc;

		if([self.delegate respondsToSelector:@selector(operation:promptFileName:)]) {
			[self.delegate operation:self promptFileName:prompt];
		}
		
		NSLog(@"%s action: %i", _cmd, prompt.action);

		if(prompt.action == kCMPromptFileNameActionRetry) {
			// retry is the same as running this loop again
			continue;
 		}
		
		if(prompt.action == kCMPromptFileNameActionStop) {
			[self throwStatus:kOperationStatusExist posixError:EEXIST 
				message:@"stat target file %s", target_path];
		}

		if(prompt.action == kCMPromptFileNameActionSkip) {
			NSLog(@"%s SKIP", _cmd);
			// TODO: delete source file when moving
			return;
		}
		
		if(prompt.action == kCMPromptFileNameActionRenameSource) {
			NSLog(@"%s RENAME SOURCE %@", _cmd, prompt.resolvedName);
			target_path_objc = [self.targetPath stringByAppendingPathComponent:prompt.resolvedName];
			target_path = [target_path_objc fileSystemRepresentation];
			continue;
		}
		
		if(prompt.action == kCMPromptFileNameActionRenameTarget) {
			NSLog(@"%s RENAME TARGET %@", _cmd, prompt.resolvedName);
			NSString* path_objc = [self.targetPath stringByAppendingPathComponent:prompt.resolvedName];
			const char* path = [path_objc fileSystemRepresentation];
			rename(target_path, path);
			continue;
		}

		if(prompt.action == kCMPromptFileNameActionReplace) {

			NSString* delete_path_objc = [target_path_objc stringByAppendingString:@"___deleted"];
			const char* delete_path = [delete_path_objc fileSystemRepresentation];
			
			// TODO: delete source file when moving
			// TODO: delete target file when moving
			rename(target_path, delete_path);
			break;
		}

		if(prompt.action == kCMPromptFileNameActionAppend) {
			should_append = YES;
			break;
		}

		[self throwStatus:kOperationStatusExist posixError:EEXIST 
			message:@"unknown action chosen: %i", prompt.action];
	} while(1);

	if(should_append) {
		[self appendDataFrom:source_path_objc to:target_path_objc];
	} else {
		[self copyFileFrom:source_path_objc to:target_path_objc];
	}
	
	if(m_operation_type == CMOperationTypeMove) {
		NSString* delete_path_objc = [source_path_objc stringByAppendingString:@"___deleted"];
		const char* delete_path = [delete_path_objc fileSystemRepresentation];
		rename(source_path, delete_path);

		// TODO: delete source file when moving
	}
}

-(void)visitHardlink:(CMTraversalObjectHardlink*)obj {
	if(obj.exclude) {
		return; // ignore this object
	}
	
	// TODO: name collision handling

	const char* link_path = [[obj linkPath] fileSystemRepresentation];
	const char* target_path = [[self.targetPath stringByAppendingPathComponent:[obj path]] fileSystemRepresentation];
	if(link(link_path, target_path) < 0) {
		[self throwStatus:kOperationStatusUnknownHardlink posixError:errno 
			message:@"hardlink %s %s", link_path, target_path];
	}
	
	// TODO: delete source file when moving
}

-(void)visitSymlink:(CMTraversalObjectSymlink*)obj {
	if(obj.exclude) {
		return; // ignore this object
	}

	// TODO: name collision handling

	const char* link_path = [[obj linkPath] fileSystemRepresentation];
	NSString* source_path_objc = [self.sourcePath stringByAppendingPathComponent:[obj path]];
	NSString* target_path_objc = [self.targetPath stringByAppendingPathComponent:[obj path]];
	const char* source_path = [source_path_objc fileSystemRepresentation];
	const char* target_path = [target_path_objc fileSystemRepresentation];

	if(symlink(link_path, target_path) < 0) {
		[self throwStatus:kOperationStatusUnknownSymlink posixError:errno 
			message:@"symlink %s %s", link_path, target_path];
	}

	int from_fd = open(source_path, O_SYMLINK);
	if(from_fd < 0) {
		[self throwStatus:kOperationStatusUnknownSymlink posixError:errno 
			message:@"open source symlink %s", source_path];
	}
	struct stat from_st;
	if(fstat(from_fd, &from_st) < 0) {
		close(from_fd);
		[self throwStatus:kOperationStatusUnknownSymlink posixError:errno 
			message:@"stat source symlink %s", source_path];
	}
	int to_fd = open(target_path, O_SYMLINK);
	if(to_fd < 0) {
		close(from_fd);
		[self throwStatus:kOperationStatusUnknownSymlink posixError:errno 
			message:@"open target symlink %s", target_path];
	}
	int flags = NC_COPYFILE_ALL;
	nc_copyfile_fd(&from_st, from_fd, to_fd, flags);
	
	close(to_fd);
	close(from_fd);

	if(m_operation_type == CMOperationTypeMove) {
		NSString* delete_path_objc = [source_path_objc stringByAppendingString:@"___deleted"];
		const char* delete_path = [delete_path_objc fileSystemRepresentation];
		rename(source_path, delete_path);

		// TODO: delete source symlink when moving
	}
}

-(void)visitFifo:(CMTraversalObjectFifo*)obj {
	if(obj.exclude) {
		return; // ignore this object
	}

	// TODO: name collision handling

	const char* source_path = [[self.sourcePath stringByAppendingPathComponent:[obj path]] fileSystemRepresentation];
	const char* target_path = [[self.targetPath stringByAppendingPathComponent:[obj path]] fileSystemRepresentation];
	if(mkfifo(target_path, 0700) < 0) {
		[self throwStatus:kOperationStatusUnknownFifo posixError:errno 
			message:@"mkfifo %s", target_path];
	}

	int from_fd = open(source_path, O_RDONLY | O_NONBLOCK);
	if(from_fd < 0) {
		[self throwStatus:kOperationStatusUnknownFifo posixError:errno 
			message:@"open source fifo %s", source_path];
	}
	struct stat from_st;
	if(fstat(from_fd, &from_st) < 0) {
		close(from_fd);
		[self throwStatus:kOperationStatusUnknownFifo posixError:errno 
			message:@"stat source fifo %s", source_path];
	}
	int to_fd = open(target_path, O_WRONLY | O_NONBLOCK);
	if(to_fd < 0) {
		close(from_fd);
		[self throwStatus:kOperationStatusUnknownFifo posixError:errno 
			message:@"open target fifo %s", target_path];
	}

	int flags = NC_COPYFILE_ALL;
	flags &= ~NC_COPYFILE_XATTR;
	nc_copyfile_fd(&from_st, from_fd, to_fd, flags);
	
	close(to_fd);
	close(from_fd);

	// TODO: delete source file when moving
}

-(void)visitChar:(CMTraversalObjectChar*)obj {
	if(obj.exclude) {
		return; // ignore this object
	}

	// TODO: name collision handling

	const char* source_path = [[self.sourcePath stringByAppendingPathComponent:[obj path]] fileSystemRepresentation];
	const char* target_path = [[self.targetPath stringByAppendingPathComponent:[obj path]] fileSystemRepresentation];
	struct stat st;
	if(stat(source_path, &st) < 0) {
		[self throwStatus:kOperationStatusUnknownChar posixError:errno 
			message:@"stat source char %s", source_path];
	}
	if(mknod(target_path, st.st_mode, st.st_rdev) < 0) {
		[self throwStatus:kOperationStatusUnknownChar posixError:errno 
			message:@"mknod char %s", target_path];
	}

	int from_fd = open(source_path, O_RDONLY);
	if(from_fd < 0) {
		[self throwStatus:kOperationStatusUnknownChar posixError:errno 
			message:@"open source char %s", source_path];
	}
	struct stat from_st;
	if(fstat(from_fd, &from_st) < 0) {
		close(from_fd);
		[self throwStatus:kOperationStatusUnknownChar posixError:errno 
			message:@"stat source char %s", source_path];
	}
	int to_fd = open(target_path, O_WRONLY);
	if(to_fd < 0) {
		close(from_fd);
		[self throwStatus:kOperationStatusUnknownChar posixError:errno 
			message:@"open target char %s", target_path];
	}
	int flags = NC_COPYFILE_ALL;
	flags &= ~NC_COPYFILE_XATTR;
	nc_copyfile_fd(&from_st, from_fd, to_fd, flags);
	
	close(to_fd);
	close(from_fd);

	// TODO: delete source file when moving
}

-(void)visitBlock:(CMTraversalObjectBlock*)obj {
	if(obj.exclude) {
		return; // ignore this object
	}

	// TODO: name collision handling

	const char* source_path = [[self.sourcePath stringByAppendingPathComponent:[obj path]] fileSystemRepresentation];
	const char* target_path = [[self.targetPath stringByAppendingPathComponent:[obj path]] fileSystemRepresentation];
	struct stat st;
	if(stat(source_path, &st) < 0) {
		[self throwStatus:kOperationStatusUnknownBlock posixError:errno 
			message:@"stat source block %s", source_path];
	}
	if(mknod(target_path, st.st_mode, st.st_rdev) < 0) {
		[self throwStatus:kOperationStatusUnknownBlock posixError:errno 
			message:@"mknod block %s", target_path];
	}

	int from_fd = open(source_path, O_RDONLY);
	if(from_fd < 0) {
		[self throwStatus:kOperationStatusUnknownBlock posixError:errno 
			message:@"open source block %s", source_path];
	}
	struct stat from_st;
	if(fstat(from_fd, &from_st) < 0) {
		close(from_fd);
		[self throwStatus:kOperationStatusUnknownBlock posixError:errno 
			message:@"stat source block %s", source_path];
	}
	int to_fd = open(target_path, O_WRONLY);
	if(to_fd < 0) {
		close(from_fd);
		[self throwStatus:kOperationStatusUnknownBlock posixError:errno 
			message:@"open target block %s", target_path];
	}
	int flags = NC_COPYFILE_ALL;
	flags &= ~NC_COPYFILE_XATTR;
	nc_copyfile_fd(&from_st, from_fd, to_fd, flags);
	
	close(to_fd);
	close(from_fd);

	// TODO: delete source file when moving
}

-(void)visitOther:(CMTraversalObjectOther*)obj {
	if(obj.exclude) {
		return; // ignore this object
	}

	// TODO: name collision handling

	// socket and whiteout is not something that we can copy
	/*
	IDEA: create a file with the target_name.. where the content is: 
	Newton Commander - Error - Socket or Other filetype encountered.
	*/
	NSString* s = [obj path];
	[self throwStatus:kOperationStatusUnknownOther posixError:0 
		message:@"Unknown file-type at path %@", s];

	// TODO: delete source file when moving
}

@end
