//
//  sc_scanner.m
//  SharedCode Core+Worker
//
//  Created by Simon Strandgaard on 24/07/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "NCLog.h"
#import "sc_scanner.h"
#import "sc_traversal_objects.h"
#include <fts.h>
#include <sys/stat.h>

NSNumber* number_with_inode(ino_t inode) {
	return [NSNumber numberWithUnsignedLongLong:(unsigned long long)inode];
}


@implementation TraversalScanner

@synthesize bytesTotal = m_bytes_total;
@synthesize countTotal = m_count_total;

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
	m_traversal_object_array = nil;
	m_inode_dict = nil;
}

-(NSArray*)traversalObjects {
	return [m_traversal_object_array copy];
}

-(void)addObject:(TraversalObject*)obj {
	[m_traversal_object_array addObject:obj];
}

-(void)appendTraverseDataForPath:(NSString*)absolute_path {
	NSAssert([absolute_path isAbsolutePath], @"path must be absolute");
	
	char* path_array[2];
	path_array[0] = (char*)[absolute_path fileSystemRepresentation];
	path_array[1] = NULL;
	
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

		NSString* path_str = nil;
		if(p->fts_path != NULL) { 
			path_str = [NSString stringWithUTF8String:p->fts_path];
		}

		switch(p->fts_info) {
		case FTS_D: {
			// Directory, pre-order traversal
			id found_obj = [m_inode_dict objectForKey:inode_number];
			if(found_obj != nil) {
				TOHardlink* obj = [[TOHardlink alloc] init];
				[obj setPath:path_str];
				[obj setLink:found_obj];
				[m_traversal_object_array addObject:obj];
				m_count_total++;
				
				fts_set(ftsp, p, FTS_SKIP);
				
			} else {
				TODirPre* obj = [[TODirPre alloc] init];
				[obj setPath:path_str];
				[m_traversal_object_array addObject:obj];
				[m_inode_dict setObject:obj forKey:inode_number];
				m_count_total++;
				m_bytes_total += p->fts_statp->st_size;
			}
			break; }
		case FTS_DP: {
			// Directory, post-order traversal
			TODirPost* obj = [[TODirPost alloc] init];
			[obj setPath:path_str];
			[m_traversal_object_array addObject:obj];
			// NOTE: does not count as an item so we dont do m_count_total++;
			break; }
			
		case FTS_F: {
			// File
			id found_obj = [m_inode_dict objectForKey:inode_number];
			if(found_obj != nil) {
				TOHardlink* obj = [[TOHardlink alloc] init];
				[obj setPath:path_str];
				[obj setLink:found_obj];
				[m_traversal_object_array addObject:obj];
				m_count_total++;
			} else {
				TOFile* obj = [[TOFile alloc] init];
				[obj setPath:path_str];
				[m_traversal_object_array addObject:obj];
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
			TOSymlink* obj = [[TOSymlink alloc] init];
			[obj setPath:path_str];
			[obj setLinkPath:sl_path];
			[m_traversal_object_array addObject:obj];
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
					TOHardlink* obj = [[TOHardlink alloc] init];
					[obj setPath:path_str];
					[obj setLink:found_obj];
					[m_traversal_object_array addObject:obj];
					m_count_total++;
				} else {
					TOFifo* obj = [[TOFifo alloc] init];
					[obj setPath:path_str];
					[m_traversal_object_array addObject:obj];
					[m_inode_dict setObject:obj forKey:inode_number];
					m_count_total++;
					m_bytes_total += p->fts_statp->st_size;
				}
			} else
			if(S_ISCHR(p->fts_statp->st_mode)) {
				// CHAR DEVICE
				TOChar* obj = [[TOChar alloc] init];
				[obj setMajor:major(p->fts_statp->st_rdev)];
				[obj setMinor:minor(p->fts_statp->st_rdev)];
				[obj setPath:path_str];
				[m_traversal_object_array addObject:obj];
				m_count_total++;
				m_bytes_total += p->fts_statp->st_size;
			} else
			if(S_ISBLK(p->fts_statp->st_mode)) {
				// BLOCK DEVICE
				TOBlock* obj = [[TOBlock alloc] init];
				[obj setMajor:major(p->fts_statp->st_rdev)];
				[obj setMinor:minor(p->fts_statp->st_rdev)];
				[obj setPath:path_str];
				[m_traversal_object_array addObject:obj];
				m_count_total++;
				m_bytes_total += p->fts_statp->st_size;
			} else
			{
				// Sockets, Whiteout, are there any others?
				TOOther* obj = [[TOOther alloc] init];
				[obj setPath:path_str];
				[m_traversal_object_array addObject:obj];
				m_count_total++;
				m_bytes_total += p->fts_statp->st_size;
			}
			break; }
		default: {
			LOG_DEBUG(@"ignoring unknown file type: %@", path_str);
			break; }
		}
	}
	fts_close(ftsp);
	
	// LOG_DEBUG(@"count: %lld", m_count_total);
	// LOG_DEBUG(@"size: %lld", m_bytes_total);
}

@end
