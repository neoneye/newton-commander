/*********************************************************************
DirCache.h - cache for { path => direntries }

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#ifndef __OPCODERS_ORTHODOXFILEMANAGER_DIRCACHE_H__
#define __OPCODERS_ORTHODOXFILEMANAGER_DIRCACHE_H__


@interface DirCacheItem : NSObject {
	// when was this cache entry last updated
	NSDate* m_last_updated;
	
	// the cached data
	NSArray* m_filenames;
	NSData* m_type_vector;
	NSData* m_alias_vector;
	NSData* m_stat64_vector;
	int m_object_count;
	
	// garbage collection.. so we can get rid of unused cache entries
	int m_mark_count;
}

// must be an array of NSString's
-(void)setFilenames:(NSArray*)v;
-(NSArray*)filenames;

// must be a NSData containing a vector of stat64 structs
-(void)setStat64Vector:(NSData*)v;
-(NSData*)stat64Vector;

// must be a NSData containing a vector of unsigned int's
-(void)setTypeVector:(NSData*)v;
-(NSData*)typeVector;

// must be a NSData containing a vector of unsigned int's
-(void)setAliasVector:(NSData*)v;
-(NSData*)aliasVector;

-(void)setObjectCount:(int)v;
-(int)objectCount;

// nil = this record has never been updated
-(void)setLastUpdated:(NSDate*)v;
-(NSDate*)lastUpdated;

-(void)setMarkCount:(int)v;
-(int)markCount;
-(void)resetMark;
-(BOOL)isUnmarked;
-(void)markAsUsed;

-(BOOL)isValid;

@end




@interface DirCache : NSObject {
	NSMutableDictionary* m_dict;
}

+(DirCache*)shared;

/*
erase everything in the cache
*/
-(void)flush;


/*
a DirCacheItem is always returned.
a new one is created if there is none in the cache.
*/
-(DirCacheItem*)itemForPath:(NSString*)path;


/*
Mark&Sweep garbage collection strategy to
get rid of the old cache entries.
*/
-(void)resetMarks;
-(void)markItemWithPath:(NSString*)path;
-(void)removeUnmarkedItems;

@end


#endif // __OPCODERS_ORTHODOXFILEMANAGER_DIRCACHE_H__