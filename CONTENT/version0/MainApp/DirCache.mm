/*********************************************************************
DirCache.h - cache for { path => direntries }

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#include "DirCache.h"
#include <sys/types.h>
#include <sys/stat.h>


@implementation DirCacheItem

-(id)init {
	self = [super init];
    if(self) {
		m_last_updated = nil;
		m_filenames = nil;
		m_stat64_vector = nil;
		m_type_vector = nil;
		m_alias_vector = nil;
		m_object_count = 0;
		m_mark_count = 0;
    }
    return self;
}

-(void)setFilenames:(NSArray*)v { [v retain]; [m_filenames release]; m_filenames = v; }
-(NSArray*)filenames { return m_filenames; }

-(void)setStat64Vector:(NSData*)v { 
	[v retain]; 
	[m_stat64_vector release]; 
	m_stat64_vector = v; 
}

-(NSData*)stat64Vector { return m_stat64_vector; }

-(void)setTypeVector:(NSData*)v { 
	[v retain]; 
	[m_type_vector release]; 
	m_type_vector = v; 
}

-(NSData*)typeVector { return m_type_vector; }

-(void)setAliasVector:(NSData*)v { 
	[v retain]; 
	[m_alias_vector release]; 
	m_alias_vector = v; 
}

-(NSData*)aliasVector { return m_alias_vector; }

-(void)setLastUpdated:(NSDate*)v { [v retain]; [m_last_updated release]; m_last_updated = v; }
-(NSDate*)lastUpdated { return m_last_updated; }

-(void)setObjectCount:(int)v { m_object_count = v; }
-(int)objectCount { return m_object_count; }

-(void)setMarkCount:(int)v { m_mark_count = v; }
-(int)markCount { return m_mark_count; }
-(BOOL)isUnmarked { return (m_mark_count <= 0); }
-(void)resetMark { m_mark_count = 0; }
-(void)markAsUsed { m_mark_count = 1; }

-(BOOL)isValid {
	NSUInteger n = m_object_count;
	if(m_filenames != nil) {
		if([m_filenames count] != n) return NO;
	}
	if(m_stat64_vector != nil) {
		NSUInteger expected = n * sizeof(struct stat64);
		if([m_stat64_vector length] != expected) return NO;
	}
	if(m_type_vector != nil) {
		NSUInteger expected = n * sizeof(unsigned int);
		if([m_type_vector length] != expected) return NO;
	}
	if(m_alias_vector != nil) {
		NSUInteger expected = n * sizeof(unsigned int);
		if([m_alias_vector length] != expected) return NO;
	}
	return YES;
}

-(NSString*)description {
	return [NSString stringWithFormat: 
		@"DirCacheItem\n"
		"object_count: %i\n"
		"mark_count: %i\n"
		"last_updated: %@\n"
		"filenames: count=%i\n"
		"stat64_vector: bytes=%i\n"
		"type_vector: bytes=%i\n"
		"alias_vector: bytes=%i", 
		m_object_count,
		m_mark_count,
		m_last_updated,
		(int)[m_filenames count],
		(int)[m_stat64_vector length],
		(int)[m_type_vector length],
		(int)[m_alias_vector length]
	];
}

-(void)dealloc {
	[m_last_updated release];
	[m_filenames release];
	[m_stat64_vector release];
	[m_type_vector release];
	[m_alias_vector release];
    [super dealloc];
}

@end

@interface DirCache (Private)
@end

@implementation DirCache

-(id)init {
	self = [super init];
    if(self) {
		m_dict = [[NSMutableDictionary alloc] initWithCapacity:100];
    }
    return self;
}

+(DirCache*)shared {
    static DirCache* shared = nil;
    if(!shared) {
        shared = [[DirCache allocWithZone:NULL] init];
    }
    return shared;
}

-(void)flush {
	[m_dict removeAllObjects];
}

-(DirCacheItem*)itemForPath:(NSString*)path {
	id thing = [m_dict objectForKey:path];
	if([thing isKindOfClass:[DirCacheItem class]]) {
		return (DirCacheItem*)thing;
	}
	DirCacheItem* item = [[[DirCacheItem alloc] init] autorelease];
	[m_dict setObject:item forKey:path];
	return item;
}

-(void)resetMarks {
	id thing;
	NSEnumerator* en = [m_dict objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[DirCacheItem class]]) {
			[(DirCacheItem*)thing resetMark];
		}
	}
}

-(void)markItemWithPath:(NSString*)path {
	id thing = [m_dict objectForKey:path];
	if([thing isKindOfClass:[DirCacheItem class]]) {
		[(DirCacheItem*)thing markAsUsed];
	}
}

-(void)removeUnmarkedItems {
	NSMutableArray* keys_to_delete =
	    [NSMutableArray arrayWithCapacity:[m_dict count]];
	
	id thing;
	NSEnumerator* en = [m_dict keyEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[NSString class]] == NO) {
			continue;
		}
		NSString* key = (NSString*)thing;
		thing = [m_dict objectForKey:key];
		if([thing isKindOfClass:[DirCacheItem class]] == NO) {
			continue;
		}

		DirCacheItem* item = (DirCacheItem*)thing;
		if([item isUnmarked]) {
			[keys_to_delete addObject:key];
			// NSLog(@"%s UNMARKED - %@", _cmd, key);
		} else {
			// NSLog(@"%s marked! - %@", _cmd, key);
		}
	}

	// NSLog(@"%s keys: %@", _cmd, keys_to_delete);
	[m_dict removeObjectsForKeys:keys_to_delete];
}

-(NSString*)description {
	return [NSString stringWithFormat: 
		@"DirCache\n"
		"m_dict: %@", 
		m_dict
	];
}

-(void)dealloc {
	[m_dict release];

    [super dealloc];
}

@end
