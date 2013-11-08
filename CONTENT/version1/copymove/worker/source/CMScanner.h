//
//  sc_scanner.h
//  SharedCode Core+Worker
//
//  Created by Simon Strandgaard on 24/07/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Foundation/Foundation.h>


/*
TODO: error handling. m_error is there, but no code for dealing with errors.
*/
@interface CMScanner : NSObject {
	BOOL m_error;
	NSMutableArray* m_traversal_object_array;
	NSMutableDictionary* m_inode_dict;
	NSArray* m_exclude_file_regexp_array;
	NSArray* m_exclude_directory_regexp_array;

	unsigned long long m_bytes_total; // filesize in bytes
	unsigned long long m_count_total; // number of items
}
@property (assign) unsigned long long bytesTotal;
@property (assign) unsigned long long countTotal;
@property (nonatomic, retain) NSArray* excludeFileRegexpArray;
@property (nonatomic, retain) NSArray* excludeDirectoryRegexpArray;

-(void)scanItem:(NSString*)absolute_path;

-(NSArray*)traversalObjects;
@end
