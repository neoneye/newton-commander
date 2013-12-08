//
//  sc_scanner.m
//  SharedCode Core+Worker
//
//  Created by Simon Strandgaard on 24/07/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "CMScanner.h"
#import "CMTraversalObject.h"
#import "NSString+Regexp.h"
#include <fts.h>
#include <sys/stat.h>


NSNumber* number_with_inode(ino_t inode) {
	return [NSNumber numberWithUnsignedLongLong:(unsigned long long)inode];
}


@implementation CMScanner

@synthesize bytesTotal = m_bytes_total;
@synthesize countTotal = m_count_total;
@synthesize excludeFileRegexpArray = m_exclude_file_regexp_array;
@synthesize excludeDirectoryRegexpArray = m_exclude_directory_regexp_array;

-(id)init {
	self = [super init];
    if(self) {
		m_traversal_object_array = [[NSMutableArray alloc] initWithCapacity:10000];
		m_inode_dict = [[NSMutableDictionary alloc] initWithCapacity:10000];
		m_error = NO;
		m_bytes_total = 0;
		m_count_total = 0;
    }
    return self;
}

-(void)dealloc {
	[m_traversal_object_array release];
	[m_inode_dict release];
	
    [super dealloc];
}

-(NSArray*)traversalObjects {
	return [m_traversal_object_array copy];
}

-(void)scanItem:(NSString*)absolute_path {
	NSAssert([absolute_path isAbsolutePath], @"absolute_path must be absolute");
	

	NSMutableArray* dir_stack = [NSMutableArray arrayWithCapacity:50];
	NSMutableArray* objects_in_current_dir = [NSMutableArray arrayWithCapacity:10000];

	const char* fsrep = [absolute_path fileSystemRepresentation];
	char* fsrep_copy = strdup(fsrep);
	char* const path_array[] = { fsrep_copy, NULL };

	/*
	NOTE: do not use the FTS_COMFOLLOW option. In the beginning I used it
	until I discovered that my symlinks was turned into hardlinks when
	copying files. so we don't use this.

	IDEA: check out the FTS_XDEV option.. is it useful?
	*/
	FTS* ftsp = fts_open(path_array, FTS_PHYSICAL | FTS_NOCHDIR, NULL);
	if(!ftsp) {
		perror("fts_open");
		m_error = YES;
		return;
	}
	FTSENT* chp = fts_children(ftsp, 0);
	if(!chp) {
        // no files to traverse
    	return;
	}

	char symlink_path[PATH_MAX+1];

	FTSENT *p;
	while((p = fts_read(ftsp)) != NULL) {
		ino_t inode = p->fts_statp->st_ino;
		NSNumber* inode_number = number_with_inode(inode);

		NSString* relative_path = nil;
		if(p->fts_path != NULL) { 
			relative_path = [NSString stringWithUTF8String:p->fts_name];
		}

		switch(p->fts_info) {
		case FTS_D: {
			// Directory, pre-order traversal
			BOOL should_be_excluded = [relative_path compareToRegexpArray:self.excludeDirectoryRegexpArray];
/*			if(should_be_excluded) {
				NSLog(@"%s directory should be excluded %@", _cmd, relative_path);
			}*/
			
			id found_obj = [m_inode_dict objectForKey:inode_number];
			if(found_obj != nil) {
				CMTraversalObjectHardlink* obj = [[[CMTraversalObjectHardlink alloc] init] autorelease];
				obj.exclude = should_be_excluded;
				obj.path = relative_path;
				[obj setLink:found_obj];
				[objects_in_current_dir addObject:obj];
				m_count_total++;
				
				fts_set(ftsp, p, FTS_SKIP); // don't scan subdirs
				
			} else {
				CMTraversalObjectDir* obj = [[[CMTraversalObjectDir alloc] init] autorelease];
				obj.exclude = should_be_excluded;
				obj.path = relative_path;
				[objects_in_current_dir addObject:obj];
				m_count_total++;
				// IDEA: also obtain size of resource fork

				[m_inode_dict setObject:obj forKey:inode_number];
				[dir_stack addObject:objects_in_current_dir];
				objects_in_current_dir = [NSMutableArray arrayWithCapacity:10000];
				
				if(should_be_excluded) {
					fts_set(ftsp, p, FTS_SKIP); // don't scan subdirs
				}
			}
			break; }
		case FTS_DP: {
			// Directory, post-order traversal
			NSArray* objects_in_subdir = [NSArray arrayWithArray:objects_in_current_dir];
			objects_in_current_dir = [[[dir_stack lastObject] retain] autorelease];
			[dir_stack removeLastObject];
			id thing = [objects_in_current_dir lastObject];
			if([thing isKindOfClass:[CMTraversalObjectDir class]]) {
				CMTraversalObjectDir* obj = (CMTraversalObjectDir*)thing;
				obj.childTraversalObjects = objects_in_subdir;
			}

			// NOTE: does not count as an item so we dont do m_count_total++;
			break; }
			
		case FTS_F: {
			// File
			BOOL should_be_excluded = [relative_path compareToRegexpArray:self.excludeFileRegexpArray];
/*			if(should_be_excluded) {
				NSLog(@"%s file should be excluded %@", _cmd, relative_path);
			}*/
			
			id found_obj = [m_inode_dict objectForKey:inode_number];
			if(found_obj != nil) {
				CMTraversalObjectHardlink* obj = [[[CMTraversalObjectHardlink alloc] init] autorelease];
				obj.exclude = should_be_excluded;
				obj.path = relative_path;
				[obj setLink:found_obj];
				[objects_in_current_dir addObject:obj];
				m_count_total++;
			} else {
				CMTraversalObjectFile* obj = [[[CMTraversalObjectFile alloc] init] autorelease];
				obj.exclude = should_be_excluded;
				obj.path = relative_path;
				[objects_in_current_dir addObject:obj];
				[m_inode_dict setObject:obj forKey:inode_number];

				m_count_total++;
				m_bytes_total += p->fts_statp->st_size;
				
				// IDEA: also obtain size of resource fork
			}
			break; }
			
		case FTS_SL: {
			// Symlink
			// it is NOT possible to create a hardlink to a symlink. 
			// So no need to deal check for hardlinks

			NSString* sl_path = nil;
			int len = readlink(p->fts_path, symlink_path, sizeof(symlink_path) - 1);
			if(len >= 0) {
				symlink_path[len] = '\0';
				sl_path = [NSString stringWithUTF8String:symlink_path];
			}
			CMTraversalObjectSymlink* obj = [[[CMTraversalObjectSymlink alloc] init] autorelease];
			[obj setPath:relative_path];
			[obj setLinkPath:sl_path];
			[objects_in_current_dir addObject:obj];
			m_count_total++;
			m_bytes_total += p->fts_statp->st_size;
			break; }
			
		case FTS_DEFAULT: {
			// Special types
			if(S_ISFIFO(p->fts_statp->st_mode)) {
				// FIFO
				id found_obj = [m_inode_dict objectForKey:inode_number];
				if(found_obj != nil) {
					// it IS possible to create a hardlink to a fifo.
					CMTraversalObjectHardlink* obj = [[[CMTraversalObjectHardlink alloc] init] autorelease];
					[obj setPath:relative_path];
					[obj setLink:found_obj];
					[objects_in_current_dir addObject:obj];
					m_count_total++;
				} else {
					CMTraversalObjectFifo* obj = [[[CMTraversalObjectFifo alloc] init] autorelease];
					[obj setPath:relative_path];
					[objects_in_current_dir addObject:obj];
					[m_inode_dict setObject:obj forKey:inode_number];
					m_count_total++;
					m_bytes_total += p->fts_statp->st_size;
				}
			} else
			if(S_ISCHR(p->fts_statp->st_mode)) {
				// CHAR DEVICE
				CMTraversalObjectChar* obj = [[[CMTraversalObjectChar alloc] init] autorelease];
				[obj setMajor:major(p->fts_statp->st_rdev)];
				[obj setMinor:minor(p->fts_statp->st_rdev)];
				[obj setPath:relative_path];
				[objects_in_current_dir addObject:obj];
				m_count_total++;
				m_bytes_total += p->fts_statp->st_size;
			} else
			if(S_ISBLK(p->fts_statp->st_mode)) {
				// BLOCK DEVICE
				CMTraversalObjectBlock* obj = [[[CMTraversalObjectBlock alloc] init] autorelease];
				[obj setMajor:major(p->fts_statp->st_rdev)];
				[obj setMinor:minor(p->fts_statp->st_rdev)];
				[obj setPath:relative_path];
				[objects_in_current_dir addObject:obj];
				m_count_total++;
				m_bytes_total += p->fts_statp->st_size;
			} else
			{
				// Sockets, Whiteout, are there any others?
				CMTraversalObjectOther* obj = [[[CMTraversalObjectOther alloc] init] autorelease];
				[obj setPath:relative_path];
				[objects_in_current_dir addObject:obj];
				m_count_total++;
				m_bytes_total += p->fts_statp->st_size;
			}
			break; }
		default: {
			NSLog(@"ERROR: ignoring unknown file type: %@", relative_path);
			break; }
		}
	}
	fts_close(ftsp);
	
	// LOG_DEBUG(@"count: %lld", m_count_total);
	// LOG_DEBUG(@"size: %lld", m_bytes_total);
	
	[m_traversal_object_array addObjectsFromArray:objects_in_current_dir];
	
	free(fsrep_copy);
}

@end
