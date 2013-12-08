//
//  sc_scanner.h
//  SharedCode Core+Worker
//
//  Created by Simon Strandgaard on 24/07/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#include <Foundation/Foundation.h>


@class TraversalObject;

/*
TODO: error handling. m_error is there, but no code for dealing with errors.
*/
@interface TraversalScanner : NSObject {
	BOOL m_error;
	NSMutableArray* m_traversal_object_array;
	NSMutableDictionary* m_inode_dict;

	unsigned long long m_bytes_total; // filesize in bytes
	unsigned long long m_count_total; // number of items
}
@property (assign) unsigned long long bytesTotal;
@property (assign) unsigned long long countTotal;

-(void)addObject:(TraversalObject*)obj;

-(void)appendTraverseDataForPath:(NSString*)absolute_path;

-(NSArray*)traversalObjects;
@end
